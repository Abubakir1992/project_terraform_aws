function Get-ValidatedContact($event) {
    $raw = $event.body
    if ($event.isBase64Encoded -or $raw -isnot [string] -or
        [Text.Encoding]::UTF8.GetByteCount($raw) -gt 4096) {
        throw [ArgumentException]::new('Invalid request body.')
    }
    try { $data = ConvertFrom-Json -InputObject $raw -AsHashtable -ErrorAction Stop }
    catch { throw [ArgumentException]::new('Invalid JSON.') }
    $limits = @{name=120; email=254; phone=30; interest=40; requestId=36}
    if ($data -isnot [System.Collections.IDictionary] -or $data.Count -ne 6 -or
        @($data.Keys | Where-Object { $_ -cnotin @($limits.Keys) + 'consent' }).Count) {
        throw [ArgumentException]::new('Complete all required fields.')
    }
    foreach ($key in $limits.Keys) {
        $value = $data[$key]
        if ($value -isnot [string] -or !$value.Trim() -or $value.Length -gt $limits[$key]) {
            throw [ArgumentException]::new('Invalid field length.')
        }
        if ($value -match '[\x00-\x1f]') { throw [ArgumentException]::new('Invalid characters.') }
        $data[$key] = $value.Trim()
    }
    if ($data.email -notmatch '^[^\s@]+@[^\s@]+\.[^\s@]+$') {
        throw [ArgumentException]::new('Enter a valid email.')
    }
    if ($data.phone -notmatch '^[+()\d .-]{7,30}$') {
        throw [ArgumentException]::new('Enter a valid phone number.')
    }
    if ($data.interest -cnotin @('All motorcycles','Sport','Heritage','Adventure') -or
        $data.consent -isnot [bool] -or !$data.consent) {
        throw [ArgumentException]::new('Choose an interest and agree to a callback.')
    }
    $uuid = [guid]::Empty
    if (![guid]::TryParseExact($data.requestId, 'D', [ref]$uuid) -or
        $uuid.ToString() -cne $data.requestId) {
        throw [ArgumentException]::new('Invalid request ID.')
    }
    return $data
}
function Test-Administrator($claims) {
    if ($claims.aud -cne $env:CLIENT_ID -or $claims.token_use -cne 'id') { return $false }
    $groups = $claims['cognito:groups']
    if ($groups -is [string]) { $groups = $groups -split '[\s,\[\]\"]+' }
    return $null -ne $groups -and 'administrators' -cin $groups
}
