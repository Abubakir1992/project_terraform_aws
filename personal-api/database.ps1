$script:schema = @'
CREATE TABLE IF NOT EXISTS contact_requests (
request_id CHAR(36) PRIMARY KEY, name VARCHAR(120) NOT NULL,
email VARCHAR(254) NOT NULL, phone VARCHAR(30) NOT NULL,
interest VARCHAR(40) NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
'@
function Invoke-Database([string]$sql, [hashtable]$values = @{}) {
    $request = [Amazon.RDSDataService.Model.ExecuteStatementRequest]::new()
    $request.ResourceArn = $env:CLUSTER_ARN
    $request.SecretArn = $env:SECRET_ARN
    $request.Database = $env:DATABASE
    $request.Sql = $sql
    $request.Parameters = [Collections.Generic.List[Amazon.RDSDataService.Model.SqlParameter]]::new()
    foreach ($key in $values.Keys) {
        $parameter = [Amazon.RDSDataService.Model.SqlParameter]::new()
        $parameter.Name = $key
        $parameter.Value = [Amazon.RDSDataService.Model.Field]::new()
        $parameter.Value.StringValue = $values[$key]
        $request.Parameters.Add($parameter)
    }
    return (Get-AwsClient Database).ExecuteStatementAsync($request).GetAwaiter().GetResult()
}
function Get-Contacts($query) {
    $cursor = if ($query -and $query.ContainsKey('cursor')) { $query.cursor } else { '' }
    if ($cursor -isnot [string] -or ($cursor -and $cursor -cnotmatch '^[a-f0-9-]{36}$')) {
        throw [ArgumentException]::new('Invalid cursor.')
    }
    $null = Invoke-Database $script:schema
    $sql = 'SELECT request_id,name,email,phone,interest,created_at FROM contact_requests ' +
           'WHERE request_id > :cursor ORDER BY request_id LIMIT 51'
    $result = Invoke-Database $sql @{cursor=$cursor}
    $columns = @('request_id','name','email','phone','interest','created_at')
    $rows = @(foreach ($record in $result.Records) {
        $row = @{}
        for ($i=0; $i -lt $columns.Count; $i++) { $row[$columns[$i]] = $record[$i].StringValue }
        $row
    })
    $next = if ($rows.Count -gt 50) { $rows[49].request_id } else { '' }
    return @{people=@($rows | Select-Object -First 50); next_cursor=$next}
}
