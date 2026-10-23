. "$PSScriptRoot/validation.ps1"
. "$PSScriptRoot/database.ps1"
. "$PSScriptRoot/contacts.ps1"
function New-Response([int]$status, [hashtable]$body) {
    return @{statusCode=$status; headers=@{'Content-Type'='application/json';
        'Cache-Control'='no-store'}; body=(ConvertTo-Json -InputObject $body -Depth 10 -Compress)}
}
function Invoke-Handler($event) {
    try {
        if ($event.httpMethod -ceq 'POST' -and $event.path -ceq '/api/contact') {
            return New-Response 202 (New-Contact $event)
        }
        if ($event.httpMethod -ceq 'GET' -and $event.path -ceq '/api/people') {
            $claims = $event.requestContext.authorizer.claims
            if (!$claims -or !(Test-Administrator $claims)) {
                return New-Response 403 @{message='Administrator access required.'}
            }
            return New-Response 200 (Get-Contacts $event.queryStringParameters)
        }
        return New-Response 404 @{message='Not found.'}
    } catch [ArgumentException] {
        return New-Response 400 @{message=$_.Exception.Message}
    } catch {
        [Console]::Error.WriteLine('Contact operation failed')
        return New-Response 503 @{message='Unable to complete your request. Please retry.'}
    }
}
