---

## 7.5 — `hl-repo-reader`: Fine-Tuned Codebase Documentation Model

### Overview

`hl-repo-reader` is a parameter-efficient fine-tune of `Qwen3-Coder-32B-Instruct` (the latest dense variant from Alibaba's April 2025 Qwen3-Coder release), adapted specifically for the task of ingesting complete source-code repositories and emitting structured markdown documentation — READMEs, API surface docs, architecture decision records, and inline module-level docstrings synthesized from raw code. The base model was selected over the Qwen2.5-Coder-32B predecessor because Qwen3-Coder was trained on 36 trillion tokens (double the Qwen2.5 pretraining corpus), adds native MCP tool-call support, and ships a hybrid thinking/non-thinking mode that lets us suppress chain-of-thought tokens at inference time to cut output latency during bulk documentation runs.

The fine-tune itself was conducted entirely on-device using Apple's MLX framework directly on the M4 Pro cluster (Site B), bypassing any cloud training dependency. No GPU-partitioned training environment was needed — unified memory on the M4 Pro means the optimizer state, model weights, and activation gradients all coexist in the same physical DRAM pool without PCIe bandwidth constraints between host and device memory.

---

### Why Fine-Tune At All

The Qwen3-Coder-32B base instruct model is a strong general-purpose code model, but its default output format for documentation tasks is inconsistent without heavy prompt engineering. Across 200+ test runs on our internal repository corpus, the base model exhibited:

- Inconsistent heading hierarchy (mixing `##` and `###` for the same semantic level across different runs of the same repo)
- Tendency to hallucinate module interdependencies that don't exist in the actual import graph
- Verbose boilerplate preambles before the actual documentation content, wasting context tokens
- No awareness of our internal annotation conventions (`HSL_DESCRIPTOR` tags, shield badge formatting, traffic flow ASCII diagrams)

Rather than patch this with increasingly long system prompts (which eat into the 128K context window we need for large codebases), we ran a targeted fine-tune on a curated dataset of ~4,200 (repo, documentation) pairs to teach the model our specific output schema.

---

### Base Model: Qwen3-Coder-32B-Instruct

Key properties of the base model relevant to this use case:

| Property | Value |
|---|---|
| Parameters | 32B (dense, not MoE) |
| Quantization used | Q4_K_M (Ollama GGUF via llama.cpp) |
| Context window | 128K tokens (native, no YaRN extrapolation needed) |
| Training tokens | 36T (Qwen3 generation) |
| Thinking mode | Hybrid — can suppress `<think>` blocks via `enable_thinking=False` |
| FIM support | Yes — Fill-In-the-Middle for inline docstring insertion |
| MCP tool support | Yes — used for `repo_tree` and `file_read` tool calls during scan |
| Ollama tag | `qwen3-coder:32b-instruct-q4_K_M` |

At Q4_K_M quantization, the 32B model loads into approximately 18–20GB of unified memory on mm3, leaving ~28GB available for macOS overhead and KV cache. At 128K context (full repository scan), the KV cache consumes roughly 10–12GB depending on the prompt structure. This fits within the 48GB envelope with no swapping observed under normal operating conditions.

Thinking mode is disabled for all documentation runs (`enable_thinking=False` in the Ollama Modelfile) because chain-of-thought output at this context length adds 15–25% additional tokens with no measurable quality improvement on the structured output task. For debugging mode (tracing why the model misidentified an interface boundary), thinking mode can be re-enabled per-session via the `--thinking` flag in `repo_doc_writer.py`.

---

### Fine-Tuning Methodology

**Framework:** Apple MLX (`mlx-lm` package, `mlx-community` fine-tune scripts)  
**Method:** QLoRA (Quantized Low-Rank Adaptation) — 4-bit NF4 base weights, LoRA adapters in BF16  
**LoRA rank:** `r=64`, `alpha=128`, targeting `q_proj`, `v_proj`, `k_proj`, `o_proj`, `gate_proj`, `up_proj`, `down_proj`  
**Training node:** mm1 (48GB unified memory, M4 Pro 14-core CPU, 20-core GPU)  
**Training duration:** ~31 hours across 3 epochs on the 4,200-sample corpus  
**Peak memory during training:** ~38GB (model weights in 4-bit + BF16 adapters + gradient checkpointing)

```bash
# Fine-tune invocation (mlx-lm)
python -m mlx_lm.lora \
  --model qwen3-coder:32b-instruct-q4_K_M \
  --train \
  --data ./training_data/hl-repo-reader/ \
  --iters 8000 \
  --batch-size 2 \
  --lora-layers 32 \
  --lora-rank 64 \
  --lora-alpha 128 \
  --learning-rate 2e-5 \
  --lr-schedule cosine \
  --warmup 200 \
  --grad-checkpoint \
  --adapter-path ./adapters/hl-repo-reader-v2/
```

After training, the LoRA adapters are fused directly into the base model weights using `mlx_lm.fuse`, producing a standalone GGUF file for Ollama:

```bash
# Fuse adapters into base weights
python -m mlx_lm.fuse \
  --model qwen3-coder:32b-instruct-q4_K_M \
  --adapter-path ./adapters/hl-repo-reader-v2/ \
  --save-path ./fused/hl-repo-reader-v2-32b/ \
  --de-quantize

# Re-quantize to Q4_K_M using llama.cpp convert
python llama.cpp/convert_hf_to_gguf.py ./fused/hl-repo-reader-v2-32b/ \
  --outtype q4_K_M \
  --outfile ./gguf/hl-repo-reader-v2-32b-q4_K_M.gguf

# Register in Ollama via Modelfile
ollama create hl-repo-reader -f ./Modelfile.hl-repo-reader
```

The fused model is stored on mm3's local NVMe and replicated to mm5 (the failover Qwen node) via `rsync` over the 10GBASE-T backhaul. Replication runs nightly via a launchd job on mm3.

---

### Training Dataset Construction

The training corpus (`hl-repo-reader-dataset-v2`) consists of 4,200 (input, output) pairs in the ChatML message format expected by Qwen3-Coder's tokenizer. Construction methodology:

**Source repositories (input side):**
- 1,800 pairs sourced from our internal Git repositories across 6 languages (Python, TypeScript, Go, Rust, Bash, YAML-heavy infrastructure repos). Repository content is serialized into a single context-ordered prompt using a deterministic file traversal order: `README.md` first (if present), then source files sorted depth-first by directory, then config files, then tests.
- 1,200 pairs sourced from permissively-licensed public GitHub repositories selected for structural diversity (monorepos, CLI tools, library packages, daemon services). Filtered to exclude repos whose existing documentation was of demonstrably low quality (stub READMEs, missing module docstrings).
- 800 pairs are synthetic: a documentation skeleton was generated by the base Qwen3-Coder-32B model at temperature 0.0 and then manually corrected by a human annotator to enforce our output schema. These synthetic pairs help the model learn to correct its own most common failure modes.
- 400 pairs are adversarial: deliberately obfuscated or poorly-structured code inputs paired with correct documentation outputs, intended to improve robustness on messy real-world codebases.

**Output schema (target side):**
All documentation outputs conform to a schema enforced during dataset construction and validated by a Python linter before inclusion:

```
# Required sections in order:
1.  HSL_DESCRIPTOR comment block (one-line summary, machine-parseable)
2.  Title (H1)
3.  Shields row (OS, runtime, difficulty)
4.  Short prose description (≤150 words, no bullet points)
5.  ## Architecture section with ASCII traffic-flow diagram
6.  ## Components table (name, type, purpose)
7.  ## Configuration section (relevant env vars, config file paths)
8.  ## Deployment section with sequential numbered steps
9.  ## Known Issues section (≥2 entries, non-empty)
10. ## Sources / References
```

Any training pair whose output did not pass the schema linter was excluded from the corpus. This enforces the output structure at training time rather than relying on prompt instructions at inference time.

---

### Ollama Modelfile

The fine-tuned model is registered in Ollama with a custom Modelfile that sets the system prompt, disables thinking mode, pre-configures context length, and sets conservative sampling parameters for deterministic documentation output:

```Dockerfile
# /opt/ollama-models/Modelfile.hl-repo-reader

FROM /opt/gguf/hl-repo-reader-v2-32b-q4_K_M.gguf

# Disable thinking mode — suppress <think> tokens entirely
PARAMETER enable_thinking false

# Full 128K context for whole-repo ingestion
PARAMETER num_ctx 131072

# Low temperature for deterministic structured output
PARAMETER temperature 0.1
PARAMETER top_p 0.9
PARAMETER top_k 20
PARAMETER repeat_penalty 1.05

# Stop generation on our end-of-doc sentinel
PARAMETER stop "<|end_of_doc|>"

SYSTEM """
You are hl-repo-reader, a documentation generation model. Your task is to read
the complete source code of a software repository and produce structured markdown
documentation conforming to the HL documentation schema.

Rules:
- Do not hallucinate function signatures, import paths, or module names.
  If you cannot determine the exact signature from the source, omit it.
- Always include the HSL_DESCRIPTOR comment block as the first line of output.
- ASCII architecture diagrams must reflect actual observed data flows, not assumed ones.
- Known Issues section must contain at least two real issues identified in the code,
  not placeholder text.
- Output ends with <|end_of_doc|> sentinel on its own line.
"""
```

```bash
# Register and verify
ollama create hl-repo-reader -f /opt/ollama-models/Modelfile.hl-repo-reader
ollama show hl-repo-reader --modelinfo
```

---

### Inference Pipeline: `repo_doc_writer.py`

The inference pipeline is a Python script running on mm3. It handles repository serialization, context-window management, streaming output, and WebDAV commit. The full pipeline for a single repository scan:

```
[1] Directory walk + file serialization
        │  Traverses target repo, reads all text files,
        │  skips binary/large files (>512KB), respects .gitignore
        ▼
[2] Token counting + chunking decision
        │  tiktoken estimate of serialized prompt
        │  If <110K tokens → single-pass (full repo in one context)
        │  If >110K tokens → hierarchical: summary pass per directory,
        │                     then synthesis pass over summaries
        ▼
[3] Ollama API call (streaming)
        │  POST http://localhost:11434/api/generate
        │  model: hl-repo-reader
        │  stream: true
        │  options: { num_ctx: 131072, temperature: 0.1 }
        ▼
[4] Stream consumer + sentinel detection
        │  Reads token chunks, writes to output buffer
        │  Stops on <|end_of_doc|> sentinel
        │  Records per-token latency for monitoring
        ▼
[5] Schema linting
        │  Validates output against required section order
        │  Checks HSL_DESCRIPTOR present and parseable
        │  Flags if Known Issues section has <2 entries
        │  On lint failure: logs diff, writes raw output to /mnt/raw/failed/
        ▼
[6] WebDAV write
        │  Writes validated markdown to:
        │  /Volumes/webdav-site-a/docs/<repo_name>/README.generated.md
        │  Preserves existing human-authored README.md if present
        ▼
[7] Git commit (CT-201 post-processing)
        │  Triggered by inotify on the WebDAV mount (Site A, CT-201)
        │  Lint pass #2 (markdown-lint)
        │  git add + git commit -m "auto-doc: <repo_name> <timestamp>"
        │  in local bare repo at /mnt/smb/repos/docs.git
        ▼
[8] Metrics push
           Pushes to Prometheus Pushgateway:
           - hl_repo_reader_tokens_per_second{node="mm3"}
           - hl_repo_reader_context_used_tokens{repo="<name>"}
           - hl_repo_reader_lint_pass{repo="<name>"} 1|0
           - hl_repo_reader_duration_seconds{repo="<name>"}
```

Relevant configuration in `repo_doc_writer.py`:

```python
# config at top of script
OLLAMA_HOST       = "http://localhost:11434"
MODEL_NAME        = "hl-repo-reader"
WEBDAV_MOUNT      = "/Volumes/webdav-site-a/docs"
MAX_SINGLE_PASS   = 110_000    # tokens — above this, use hierarchical mode
SKIP_EXTENSIONS   = {".png", ".jpg", ".gif", ".svg", ".woff", ".ttf",
                     ".lock", ".sum", ".pb", ".bin", ".onnx", ".pt", ".safetensors"}
SKIP_DIRS         = {".git", "node_modules", "__pycache__", ".venv",
                     "vendor", "dist", "build", ".next"}
MAX_FILE_BYTES    = 524_288    # 512KB per file hard cap
PUSHGATEWAY_URL   = "http://100.x.1.2:9091/metrics/job/hl-repo-reader"
THINKING_MODE     = False      # set True for debug runs only
```

---

### Context Window Strategy: Single-Pass vs. Hierarchical

For repositories under ~110K tokens when serialized (roughly 8,000–12,000 lines of source across all files depending on density), the entire codebase fits in a single model call. This is the clean path — the model sees the full import graph, all interface definitions, all configuration schemas, and all test files simultaneously and can reason about cross-module dependencies without any information loss.

For larger repositories, the pipeline falls back to a hierarchical two-pass approach:

**Pass 1 — Per-directory summarization**
Each top-level directory is serialized individually and submitted to `hl-repo-reader` with a directive to produce a structural summary: what the directory contains, what its exported interfaces are, and what its dependencies are. These summaries are compact (~500–800 tokens each).

**Pass 2 — Synthesis**
All per-directory summaries are concatenated (typically 5,000–15,000 tokens total for large repos) and submitted in a single synthesis call with a directive to produce the full schema-conformant documentation.

The hierarchical path trades completeness for tractability. The synthesis pass does not see raw source code — only the summaries — so fine-grained implementation details may be omitted. In practice, for READMEs and architecture documentation this is acceptable. For API-level function documentation, only the single-pass path is used (limited to repos that fit in context).

---

### Comparison: Base Model vs. Fine-Tune

Evaluated on a held-out test set of 80 repositories not seen during training:

| Metric | Qwen3-Coder-32B Base | `hl-repo-reader` v2 |
|---|---|---|
| Schema compliance rate | 34% | 96% |
| HSL_DESCRIPTOR present | 11% | 99% |
| Hallucinated import paths | 18% of docs | 2% of docs |
| Avg. output tokens (same repo) | 3,200 | 1,850 |
| Lint pass rate (markdown-lint) | 61% | 94% |
| Known Issues quality (human eval 1–5) | 2.1 | 4.0 |

The reduction in average output tokens (3,200 → 1,850) is significant for throughput. At ~55 tokens/sec on mm3 with Q4_K_M, the base model takes ~58 seconds per documentation run versus ~34 seconds for the fine-tune on an equivalent repository. Over hundreds of repositories processed weekly by the automated pipeline, this is a meaningful difference in cluster time.

---

### Gemma 4 Integration: Cross-Model Validation

The Site B cluster also runs `gemma4:27b-instruct-q8_0` on mm1 and mm2 for general-purpose inference. In addition to serving as the primary API endpoint for tenants, Gemma 4 is used as a secondary validation pass for `hl-repo-reader` outputs.

**Why Gemma 4:**
Gemma 4's medium models support a 256K context window, which exceeds Qwen3-Coder's 128K native window. For the validation task — reading the generated documentation *and* the source code simultaneously to check for factual errors — Gemma 4's extended context headroom is useful. Gemma 4 was released on April 2, 2026 under Apache 2.0, making it freely deployable on-premise without licensing restrictions.

The validation pipeline (`doc_validator.py` on mm1) takes the `hl-repo-reader` output and runs a secondary Gemma 4 call that:
1. Receives the full generated README plus the original serialized source
2. Checks each factual claim against the source
3. Returns a structured JSON list of potential hallucinations with line references

Any flagged documentation is written to `/mnt/raw/validation-failures/` on Site A rather than committed to the docs Git repository. A human review step is required before those docs are promoted.

```bash
# Gemma 4 validation call (mm1)
curl http://192.168.100.11:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma4:27b-instruct-q8_0",
    "prompt": "<serialized_source>\n\n<generated_doc>\n\nIdentify any factual claims in the documentation that cannot be verified from the source code above. Return JSON.",
    "stream": false,
    "options": {
      "num_ctx": 131072,
      "temperature": 0.0
    }
  }'
```

**Gemma 4 model specs (as deployed on mm1/mm2):**

| Property | Value |
|---|---|
| Base model | `gemma4:27b-instruct` (Google, April 2026) |
| Quantization | Q8_0 (~27GB on-disk, ~29GB loaded) |
| Context window | 128K (native for 27B size) |
| Vision | Yes — SigLIP encoder, multimodal input supported |
| Thinking mode | No (Gemma 4 does not have a separate thinking-mode toggle) |
| Ollama tag | `gemma4:27b-instruct-q8_0` |
| Use case on this cluster | General-purpose tenant API + cross-model doc validation |

The 27B Q8_0 footprint (~29GB) fits mm1's 48GB envelope with roughly 18GB remaining for KV cache. At 128K context, KV cache peaks at ~10–12GB, which fits. For the full 256K context available on Gemma 4's medium-tier sizing, the KV cache would exceed available headroom on a single M4 Pro node at 48GB — so we cap context at 131072 tokens in the Modelfile regardless.

---

### Model Storage & Replication

All GGUF model files live on the local NVMe of each node. There is no network-mounted model storage — the 10GBASE-T switch provides adequate bandwidth for a one-time rsync of a 18GB GGUF, but serving model weights over NFS at inference time would introduce latency spikes that would manifest as irregular token-generation pauses.

```
Model file locations (per-node):
  mm1, mm2: /opt/ollama/models/gemma4-27b-q8_0.gguf          (~27GB)
  mm3:      /opt/ollama/models/hl-repo-reader-v2-32b-q4_K_M.gguf  (~18GB)
  mm4:      /opt/ollama/models/gemma4-27b-q8_0.gguf          (~27GB, failover replica)
  mm5:      /opt/ollama/models/hl-repo-reader-v2-32b-q4_K_M.gguf  (~18GB, failover replica)
```

Replication from primary to replica nodes runs nightly at 02:00 via a launchd job on mm3 and mm1 respectively:

```bash
# /Library/LaunchDaemons/com.hl.model-sync-mm5.plist (relevant Program arg)
rsync -avz --progress --checksum \
  /opt/ollama/models/hl-repo-reader-v2-32b-q4_K_M.gguf \
  mm5.local:/opt/ollama/models/ \
  --bwlimit=800000   # ~800MB/s — well within 10GbE capacity
```

`--checksum` is used instead of `--size-only` to detect any corruption in the GGUF file. If the rsync exits non-zero, a Prometheus gauge `hl_model_sync_status{dst="mm5"}` is set to 0 and Grafana alerts within 5 minutes.

---

### Adapter Version History

| Version | Base model | LoRA rank | Training samples | Notes |
|---|---|---|---|---|
| v1.0 | Qwen2.5-Coder-32B-Instruct | r=32 | 1,400 | Initial fine-tune, limited output schema enforcement |
| v1.5 | Qwen2.5-Coder-32B-Instruct | r=32 | 2,800 | Added adversarial pairs, improved hallucination rate |
| v2.0 | Qwen3-Coder-32B-Instruct | r=64 | 4,200 | Upgraded base, doubled LoRA rank, full schema enforcement |

v2.0 represents a full retrain on the new base model rather than adapter transfer. Adapter transfer between Qwen2.5-Coder and Qwen3-Coder was attempted but produced degraded schema compliance (72% vs 96% for a fresh fine-tune), likely due to tokenizer differences between the two model generations. A clean retrain was faster to produce than debugging the adapter transfer.