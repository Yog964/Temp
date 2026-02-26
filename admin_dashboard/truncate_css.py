
import os

filepath = r"d:\VIT\HackGenX\Version1.1\admin_dashboard\src\index.css"
with open(filepath, "r", encoding="utf-8") as f:
    lines = f.readlines()

# Truncate after the .btn-action-required:hover block
# Looking at the file, it ends at line 1376
new_lines = lines[:1376]

with open(filepath, "w", encoding="utf-8") as f:
    f.writelines(new_lines)

print(f"Truncated {filepath} to 1376 lines.")
