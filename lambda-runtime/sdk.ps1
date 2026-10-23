$sdkDirectory = if ($env:MOTO_SDK_DIRECTORY) { $env:MOTO_SDK_DIRECTORY } else { '/opt/sdk' }
Add-Type -Path "$sdkDirectory/AWSSDK.Core.dll"
Get-ChildItem "$sdkDirectory/AWSSDK.*.dll" | Where-Object Name -ne 'AWSSDK.Core.dll' |
    ForEach-Object { Add-Type -Path $_.FullName }
$script:clients = @{}
function Get-AwsClient([string]$service) {
    if (!$script:clients.ContainsKey($service)) {
        $types = @{
            Database='Amazon.RDSDataService.AmazonRDSDataServiceClient'
            Queue='Amazon.SQS.AmazonSQSClient'
            Events='Amazon.EventBridge.AmazonEventBridgeClient'
            Notifications='Amazon.SimpleNotificationService.AmazonSimpleNotificationServiceClient'
            Storage='Amazon.S3.AmazonS3Client'
        }
        $script:clients[$service] = New-Object $types[$service]
    }
    return $script:clients[$service]
}
