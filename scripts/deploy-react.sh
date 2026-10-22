#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
config=$(terraform -chdir=terraform-aws-webpage output -json app_config)
bucket=$(terraform -chdir=terraform-aws-webpage output -raw release_bucket)
association=$(terraform -chdir=terraform-aws-webpage output -raw release_association)
cd react-app
npm ci --no-audit --no-fund
npm run build
printf '%s\n' "$config" > dist/app-config.json
aws s3 sync dist "s3://$bucket/site/" --exclude '*.html' --region us-east-1
aws s3 sync dist "s3://$bucket/site/" --exclude '*' --include '*.html' --region us-east-1
aws ssm start-associations-once --association-ids "$association" --region us-east-1
