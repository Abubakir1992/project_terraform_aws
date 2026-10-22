from pathlib import Path
root = Path(__file__).resolve().parents[1]
exclude = {".git", ".terraform", "node_modules", "dist", "__pycache__"}
extensions = {".tf", ".tfvars", ".jsx", ".js", ".mjs", ".py", ".css", ".sh", ".ps1", ".yml", ".html", ".md"}
failures = []
for path in root.rglob("*"):
    if not path.is_file() or set(path.relative_to(root).parts) & exclude:
        continue
    if path.suffix in extensions:
        count = len(path.read_text(encoding="utf-8-sig").splitlines())
        if count > 75:
            failures.append(f"{path.relative_to(root)}: {count}")
assert not failures, "Files exceed 75 lines: " + ", ".join(failures)
print("All maintained source and documentation files are at most 75 lines.")
