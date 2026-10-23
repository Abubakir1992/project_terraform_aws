$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$base = "http://$env:AWS_LAMBDA_RUNTIME_API/2018-06-01/runtime"
try {
    . "$PSScriptRoot/sdk.ps1"
    . "$PSScriptRoot/handler.ps1"
} catch {
    $body = @{errorMessage='PowerShell initialization failed'; errorType='Runtime.InitError'}
    Invoke-RestMethod "$base/init/error" -Method Post -ContentType 'application/json' `
        -Body ($body | ConvertTo-Json -Compress) | Out-Null
    exit 1
}
while ($true) {
    $invocation = Invoke-WebRequest "$base/invocation/next" -TimeoutSec 0
    $requestId = [string]$invocation.Headers['Lambda-Runtime-Aws-Request-Id'][0]
    $env:_X_AMZN_TRACE_ID = [string]$invocation.Headers['Lambda-Runtime-Trace-Id'][0]
    try {
        $event = $invocation.Content | ConvertFrom-Json -AsHashtable
        $result = Invoke-Handler $event
        $body = ConvertTo-Json -InputObject $result -Depth 30 -Compress
        Invoke-RestMethod "$base/invocation/$requestId/response" -Method Post `
            -ContentType 'application/json' -Body ([Text.Encoding]::UTF8.GetBytes($body)) | Out-Null
    } catch {
        [Console]::Error.WriteLine("Invocation failed: $requestId")
        $body = @{errorMessage='Invocation failed'; errorType='PowerShell.HandlerError'}
        Invoke-RestMethod "$base/invocation/$requestId/error" -Method Post `
            -ContentType 'application/json' -Body ($body | ConvertTo-Json -Compress) | Out-Null
    }
}
