[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SessionId,
    
    [Parameter(Mandatory=$false)]
    [int]$PollIntervalSeconds = 10,
    
    [Parameter(Mandatory=$false)]
    [int]$TimeoutSeconds = 3600
)

# Extract only the ID if a full path like "sessions/123" is provided
if ($SessionId -match "sessions/(.+)") {
    $SessionId = $matches[1]
}

$envFile = "C:\Skills\.env"
$apiKey = $null
if (Test-Path $envFile) {
    foreach ($line in (Get-Content $envFile)) {
        if ($line -match "^JULES_API_KEY=(.+)$") {
            $apiKey = $matches[1]
            break
        }
    }
}
if (-not $apiKey) { $apiKey = $env:JULES_API_KEY }
if (-not $apiKey) { throw "JULES_API_KEY not found." }

$uri = "https://jules.googleapis.com/v1alpha/sessions/$SessionId"
$headers = @{ "X-Goog-Api-Key" = $apiKey }

$startTime = Get-Date
Write-Host "Waiting for Jules session $SessionId to complete..."

while ($true) {
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
    $state = $response.state
    
    Write-Host "Current state: $state"
    
    if ($state -eq "COMPLETED" -or $state -eq "FAILED") {
        Write-Host "Session finished with state: $state"
        return $response
    }
    
    if (((Get-Date) - $startTime).TotalSeconds -gt $TimeoutSeconds) {
        throw "Timeout waiting for session $SessionId."
    }
    
    Start-Sleep -Seconds $PollIntervalSeconds
}
