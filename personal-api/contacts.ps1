function New-Contact($event) {
    $data = Get-ValidatedContact $event
    $null = Invoke-Database $script:schema
    $sql = 'INSERT IGNORE INTO contact_requests (request_id,name,email,phone,interest) ' +
           'VALUES (:request_id,:name,:email,:phone,:interest)'
    $null = Invoke-Database $sql @{request_id=$data.requestId; name=$data.name;
        email=$data.email; phone=$data.phone; interest=$data.interest}
    $metadata = @{requestId=$data.requestId; interest=$data.interest;
        date=[DateTime]::UtcNow.ToString('yyyy-MM-dd')}
    $request = [Amazon.SQS.Model.SendMessageRequest]::new()
    $request.QueueUrl = $env:OUTBOX_QUEUE
    $request.MessageBody = $metadata | ConvertTo-Json -Compress
    $null = (Get-AwsClient Queue).SendMessageAsync($request).GetAwaiter().GetResult()
    return @{message='Our agent will call you.'; requestId=$data.requestId}
}
