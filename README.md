# Motohaus: React motorcycle showroom on AWS

Public visitors explore motorcycles and submit name, phone, email and riding interest.
There is no customer login. After a successful submission, a dialog says:
**Our agent will call you.** Administrators sign in at `/admin.html` to read enquiries.
The API verifies Cognito tokens, client ID and administrator group membership.

## Infrastructure

- VPC, two public subnets, ALB and EC2 Auto Scaling, with CloudFront HTTPS.
- WAF on CloudFront and the regional REST API, including rate limits.
- API Gateway → Lambda → encrypted Aurora MySQL through Secrets Manager/Data API.
- SQS outbox → Lambda → EventBridge → SQS → Lambda → SNS notification.
- Private S3 buckets for React releases, CloudTrail, anonymous analytics and Athena results.
- Athena/Glue tables and saved queries for daily enquiry and audit analysis.
- Systems Manager publishes React without SSH. CloudWatch alarms monitor failures/backlogs.

EC2 user data installs applications and starts services. It contains no HTML or React.
React comes only from `react-app/`, deployed independently after Terraform apply.
Terraform now builds and publishes React automatically after a rebuild or frontend/config change.
New Auto Scaling instances install the current S3 release within five minutes through EventBridge Scheduler and SSM.
The ALB checks `/health.txt`, so empty infrastructure remains healthy before deployment.

## Start here

1. Read [deployment](docs/deployment.md), especially the existing-state migration notes.
2. Apply infrastructure using your existing state and AWS CLI credentials.
3. Edit React as desired; run `./scripts/deploy-react.ps1` from PowerShell.
4. Invite an administrator as described in [administrator setup](docs/administrator.md).
5. Open the Terraform `website` output. Customer details appear only in the admin portal.

Local preview: `cd react-app`, `npm ci`, `npm run build`, `npm run preview`.
The preview has no local API and does not pretend to save submissions.

## Files and checks

Components, Lambda handlers, Terraform resources and docs are split into small files.
Every maintained source/documentation file is at most 75 lines; most are below 50.
Generated dependency lock files, bundles and provider files are excluded from that limit.

```sh
cd react-app
npm ci
npm run build
npm test
cd ..
python scripts/build-lambda.py
pwsh -NoProfile -File tests/powershell-api.ps1
pwsh -NoProfile -File tests/powershell-worker.ps1
python tests/check_bootstrap.py
python tests/check_lengths.py
terraform -chdir=terraform-aws-webpage fmt -check -recursive
terraform -chdir=terraform-aws-webpage init -backend=false
terraform -chdir=terraform-aws-webpage validate
```

See [architecture](docs/architecture.md), [analytics](docs/analytics.md),
[operations](docs/operations.md) and [destroy](docs/destroy.md).
Photographs are downloaded into React; attribution and manufacturer references are in
`react-app/public/credits.html`. Photos illustrate riding styles rather than named models.
No AWS apply, destroy or deployment is performed by validation.
