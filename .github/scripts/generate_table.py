import os
import re

ROOT = "."
MAIN_README = "README.md"

descriptor_pattern = re.compile(r"<!--\s*HSL_DESCRIPTOR:\s*(.*?)\s*-->")

rows = []

for item in sorted(os.listdir(ROOT)):
    path = os.path.join(ROOT, item)

    if not os.path.isdir(path):
        continue

    readme = os.path.join(path, "README.md")

    if not os.path.exists(readme):
        continue

    with open(readme, "r", encoding="utf-8") as f:
        content = f.read()

    match = descriptor_pattern.search(content)

    if not match:
        continue

    description = match.group(1)

    row = f"| {item} | {description} | [Open](./{item}) |"
    rows.append(row)

table = "\n".join([
    "| Directory | Description | Link |",
    "|-----------|-------------|------|",
    *rows
])

with open(MAIN_README, "r", encoding="utf-8") as f:
    content = f.read()

start = "<!-- HSL_TABLE_START -->"
end = "<!-- HSL_TABLE_END -->"

new_section = f"{start}\n\n{table}\n\n{end}"

content = re.sub(
    f"{start}.*?{end}",
    new_section,
    content,
    flags=re.DOTALL
)

with open(MAIN_README, "w", encoding="utf-8") as f:
    f.write(content)