"""Guard the separation between installation and React deployment."""
from pathlib import Path
import subprocess
import shutil
import os
root = Path(__file__).resolve().parents[1]
script = (root / "terraform-aws-webpage/scripts/install.sh").read_bytes()
assert len(script) < 16384
assert script.startswith(b"#!/bin/bash\n") and b"\r" not in script
for forbidden in [b"<html", b"<!DOCTYPE", b"React", b"npm", b"index.html", b"app-config"]:
    assert forbidden not in script, forbidden
assert b"dnf install" in script and b"amazon-ssm-agent" in script
bash = "C:/Program Files/Git/bin/bash.exe" if os.name == "nt" else shutil.which("bash")
if os.name != "nt" and bash and Path(bash).exists():
    for name in ["install.sh", "deploy.sh"]:
        subprocess.run([bash, "-n", (root / "terraform-aws-webpage/scripts" / name).as_posix()], check=True)
print("Install-only user data verified; Bash syntax checks run in Linux CI.")
