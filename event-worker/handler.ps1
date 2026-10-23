function Invoke-Record($record) {
    $payload = $record.body | ConvertFrom-Json -AsHashtable
    if ($record.eventSourceARN -ceq $env:OUTBOX_ARN) {
        $entry = [Amazon.EventBridge.Model.PutEventsRequestEntry]::new()
        $entry.Source = 'moto.contacts'
        $entry.DetailType = 'ContactCreated'
        $entry.EventBusName = $env:BUS_NAME
        $entry.Detail = $payload | ConvertTo-Json -Depth 10 -Compress
        $request = [Amazon.EventBridge.Model.PutEventsRequest]::new()
        $request.Entries = [Collections.Generic.List[Amazon.EventBridge.Model.PutEventsRequestEntry]]::new()
        $request.Entries.Add($entry)
        $result = (Get-AwsClient Events).PutEventsAsync($request).GetAwaiter().GetResult()
        if ($result.FailedEntryCount -gt 0) { throw 'Event delivery failed' }
        return
    }
    $detail = $payload.detail
    $row = @{request_id=$detail.requestId; event_date=$detail.date;
        interest=$detail.interest; requests=1}
    $request = [Amazon.S3.Model.PutObjectRequest]::new()
    $request.BucketName = $env:ANALYTICS_BUCKET
    $request.Key = "contacts/$($detail.requestId).json"
    $request.ContentBody = ($row | ConvertTo-Json -Compress) + "`n"
    $request.ContentType = 'application/json'
    $request.ServerSideEncryptionMethod = [Amazon.S3.ServerSideEncryptionMethod]::AES256
    $null = (Get-AwsClient Storage).PutObjectAsync($request).GetAwaiter().GetResult()
    $notification = [Amazon.SimpleNotificationService.Model.PublishRequest]::new()
    $notification.TopicArn = $env:TOPIC_ARN
    $notification.Subject = 'New motorcycle enquiry'
    $notification.Message = "Request $($detail.requestId) is ready. Open the administrator portal."
    $null = (Get-AwsClient Notifications).PublishAsync($notification).GetAwaiter().GetResult()
}
function Invoke-Handler($event) {
    $failed = @(foreach ($record in $event.Records) {
        try { Invoke-Record $record }
        catch { @{itemIdentifier=$record.messageId} }
    })
    return @{batchItemFailures=$failed}
}
