. "$PSScriptRoot/powershell-support.ps1"
. "$PSScriptRoot/../event-worker/handler.ps1"
$script:clients.Events = New-MockClient PutEventsAsync {
    param($request)
    $script:entry = $request.Entries[0]
    Complete @{FailedEntryCount=0}
}
$detail = @{requestId='550e8400-e29b-41d4-a716-446655440000'; interest='Sport'; date='2026-10-22'}
$record = @{messageId='one'; eventSourceARN='outbox'; body=($detail | ConvertTo-Json)}
$result = Invoke-Handler @{Records=@($record)}
Assert ($result.batchItemFailures.Count -eq 0) 'relay succeeds'
Assert ($script:entry.Source -eq 'moto.contacts') 'event source preserved'
$script:clients.Events = New-MockClient PutEventsAsync { Complete @{FailedEntryCount=1} }
$result = Invoke-Handler @{Records=@($record)}
Assert ($result.batchItemFailures[0].itemIdentifier -eq 'one') 'failed event retried'
$script:clients.Storage = New-MockClient PutObjectAsync {
    param($request)
    $script:stored = $request
    Complete @{}
}
$script:clients.Notifications = New-MockClient PublishAsync {
    param($request)
    $script:notification = $request
    Complete @{}
}
$record.eventSourceARN='contacts'
$record.body = @{detail=$detail} | ConvertTo-Json
$result = Invoke-Handler @{Records=@($record)}
Assert ($result.batchItemFailures.Count -eq 0) 'notification succeeds'
Assert ($script:stored.Key -eq "contacts/$($detail.requestId).json") 'stable analytics key'
Assert (($script:stored.ContentBody | ConvertFrom-Json).requests -eq 1) 'analytics count'
Assert ($script:notification.Message -notmatch 'email|phone|name') 'notification excludes PII'
$script:clients.Notifications = New-MockClient PublishAsync { throw 'unavailable' }
$result = Invoke-Handler @{Records=@($record)}
Assert ($result.batchItemFailures.Count -eq 1) 'SNS failure retried'
Write-Host "Worker checks passed: $script:checks"
