$ErrorActionPreference = 'Stop'
$env:MOTO_SDK_DIRECTORY = Join-Path $PSScriptRoot '../build/lambda/sdk'
$env:AWS_REGION = 'us-east-1'
$env:CLIENT_ID = 'client'
$env:OUTBOX_ARN = 'outbox'
. "$PSScriptRoot/../lambda-runtime/sdk.ps1"
$script:checks = 0
function Assert($condition, [string]$message) {
    if (!$condition) { throw "FAIL: $message" }
    $script:checks++
}
function New-Payload {
    return @{name='Example Rider'; email='rider@example.com'; phone='+1 555 010 9999';
        interest='Sport'; consent=$true; requestId='550e8400-e29b-41d4-a716-446655440000'}
}
function New-Event($data = (New-Payload)) {
    return @{httpMethod='POST'; path='/api/contact'; body=($data | ConvertTo-Json -Compress)}
}
function New-MockClient([string]$method, [scriptblock]$action) {
    $mock = [pscustomobject]@{}
    $mock | Add-Member -MemberType ScriptMethod -Name $method -Value $action
    return $mock
}
function Complete($value) { return [Threading.Tasks.Task]::FromResult([object]$value) }
