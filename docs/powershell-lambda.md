# PowerShell Lambda functions

Both functions run PowerShell 7.4.21 on the provided.al2023 x86_64 custom runtime.
The shared layer includes PowerShell and pinned AWS SDK for .NET 4 assemblies.
Function code, handlers and the invocation loop are PowerShell; bootstrap starts pwsh.
Python is used only for local packaging and repository maintenance checks.

Run `python scripts/build-lambda.py` before Terraform plan/apply or validation.
The builder verifies the Microsoft runtime SHA256 and downloads pinned NuGet versions.
It builds `build/lambda/runtime.zip`, excluded from Git.
Terraform uploads the layer to the private release bucket's runtime/ prefix.
The three-artifact retention rule applies only to artifacts/github-actions/ ZIPs.
It does not delete the runtime layer or the deployed site.

Run `pwsh -NoProfile -File tests/powershell-api.ps1` and powershell-worker.ps1.
Tests mock AWS clients, while exercising SDK request types and real handler code.
The API retains strict field validation, bound SQL values, admin-group/client checks,
pagination, no-store responses and generic service errors without personal-data logging.
The worker retains partial-batch retries and request-ID-based analytics object keys.
Duplicate SNS notifications remain possible with at-least-once SQS delivery.

Each Lambda has 512 MB to accommodate the PowerShell host and .NET SDK.
Cold starts and memory use may be higher than the earlier Python implementation.
Upgrade PowerShell/SDK versions in lambda-runtime/dependencies.json, rebuild and apply.
Do not package AWS profiles, secrets, contact records or credentials.
