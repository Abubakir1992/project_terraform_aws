"""Render EC2 user data offline with placeholder public config, then verify it."""
import base64
import json
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "terraform-aws-webpage/ec2.tf").read_text()
start = source.index("base64encode(replace(<<-EOF")
expression = source[start:source.index("\n\n  metadata_options")].strip()
for asset in ("main.jsx", "session.js"):
    expression = expression.replace("${path.module}/../react-app/src/" + asset, (root / "react-app/src" / asset).as_posix())
config = {"apiUrl": "https://example.execute-api.us-east-1.amazonaws.com",
          "authUrl": "https://example.auth.us-east-1.amazoncognito.com",
          "clientId": "example", "redirectUri": "https://app.example.com/"}
with tempfile.TemporaryDirectory() as directory:
    (Path(directory) / "main.tf").write_text(
        "locals {\n app_config = jsondecode(" + json.dumps(json.dumps(config)) + ")\n user_data = " + expression + "\n}\n"
    )
    result = subprocess.run(["terraform", "console", "-no-color"], input="local.user_data\n",
                            text=True, capture_output=True, cwd=directory, check=True)
script = base64.b64decode(json.loads(result.stdout))
assert script.startswith(b"#!/bin/bash\n"), "Invalid shebang or line endings"
assert b"\r" not in script, "Windows line endings in shell script"
assert len(script) <= 16384, "EC2 user data exceeds 16KB"
for marker in (b"\nJSON\n", b"\nHTML\n", b"\nAPACHE\n"):
    assert marker in script, "Heredoc terminator must start in column 1"
subprocess.run(["bash", "-n"], input=script, check=True)
print("Bootstrap shell syntax, heredocs, and size verified:", len(script), "bytes")
