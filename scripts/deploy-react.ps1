$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
function Invoke-Checked { param([scriptblock]$Command)
  & $Command
  if ($LASTEXITCODE -ne 0) { throw "Command failed with exit code $LASTEXITCODE" }
}
Push-Location "$projectRoot/terraform-aws-webpage"
try {
  $config = terraform output -json app_config
  if ($LASTEXITCODE -ne 0) { throw 'Apply Terraform before deploying React.' }
  $bucket = terraform output -raw release_bucket
  $association = terraform output -raw release_association
} finally { Pop-Location }
Push-Location "$projectRoot/react-app"
try {
  Invoke-Checked { npm.cmd ci --no-audit --no-fund }
  Invoke-Checked { npm.cmd run build }
  [IO.File]::WriteAllText((Join-Path $PWD 'dist/app-config.json'), ($config -join "`n"))
  # Assets first. Publish entry pages only after their dependencies are uploaded.
  Invoke-Checked { aws s3 sync dist "s3://$bucket/site/" --exclude '*.html' --region us-east-1 }
  Invoke-Checked { aws s3 sync dist "s3://$bucket/site/" --exclude '*' --include '*.html' --region us-east-1 }
  Invoke-Checked { aws ssm start-associations-once --association-ids $association --region us-east-1 }
  Write-Host 'Release uploaded. SSM installs it now and on new instances within five minutes.'
  Write-Host 'Check the moto-react-release association execution status in Systems Manager.'
} finally { Pop-Location }
