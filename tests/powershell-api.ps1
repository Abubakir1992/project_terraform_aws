. "$PSScriptRoot/powershell-support.ps1"
. "$PSScriptRoot/../personal-api/handler.ps1"
Assert ((Get-ValidatedContact (New-Event)).name -eq 'Example Rider') 'valid contact'
foreach ($change in @(@{email=42},@{email='bad'},@{phone='bad'},@{consent='true'},
    @{consent=$false},@{name="line`nbreak"},@{name=('x'*121)},@{requestId='bad'},
    @{interest='sport'},@{extra='field'})) {
    $data = New-Payload
    foreach ($key in $change.Keys) { $data[$key] = $change[$key] }
    Assert ((Invoke-Handler (New-Event $data)).statusCode -eq 400) 'reject invalid input'
}
foreach ($raw in @('{','[]',('x'*4097))) {
    $event = New-Event; $event.body = $raw
    Assert ((Invoke-Handler $event).statusCode -eq 400) 'reject invalid body'
}
$claims = @{aud='client'; token_use='id'; 'cognito:groups'='administrators'}
Assert (Test-Administrator $claims) 'administrator allowed'
$claims['cognito:groups']='fake-administrators'
Assert (!(Test-Administrator $claims)) 'exact group required'
$claims['cognito:groups']='[administrators other]'; $claims.aud='other'
Assert (!(Test-Administrator $claims)) 'exact audience required'
$event = @{httpMethod='GET'; path='/api/people'}
Assert ((Invoke-Handler $event).statusCode -eq 403) 'anonymous denied before storage'
$script:statements = @()
$script:clients.Database = New-MockClient ExecuteStatementAsync {
    param($request)
    $script:statements += $request
    Complete ([Amazon.RDSDataService.Model.ExecuteStatementResponse]::new())
}
$script:clients.Queue = New-MockClient SendMessageAsync {
    param($request)
    $script:queued = $request.MessageBody
    Complete ([Amazon.SQS.Model.SendMessageResponse]::new())
}
Assert ((Invoke-Handler (New-Event)).statusCode -eq 202) 'success after DB and queue'
Assert ($script:statements[1].Sql -match 'INSERT IGNORE') 'idempotent insert'
Assert ($script:statements[1].Parameters.Count -eq 5) 'parameterized SQL'
$metadata = $script:queued | ConvertFrom-Json -AsHashtable
Assert ($metadata.Count -eq 3 -and !$metadata.ContainsKey('email')) 'no PII in queue'
$script:clients.Queue = New-MockClient SendMessageAsync { throw 'sensitive error' }
$failed = Invoke-Handler (New-Event)
Assert ($failed.statusCode -eq 503 -and $failed.body -notmatch 'sensitive') 'safe queue failure'
$claims.aud='client'; $claims.token_use='access'
Assert (!(Test-Administrator $claims)) 'ID token required'
$script:clients.Database = New-MockClient ExecuteStatementAsync {
    param($request)
    if ($request.Sql -match '^CREATE') { return Complete @{} }
    $records = @(0..50 | ForEach-Object {
        ,@(@{StringValue="$_"},@{},@{},@{},@{},@{})
    })
    Complete @{Records=$records}
}
$page = Get-Contacts @{}
Assert ($page.people.Count -eq 50 -and $page.next_cursor -eq '49') 'pagination'
Write-Host "API checks passed: $script:checks"
