[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Prompt,
    
    [Parameter(Mandatory=$false)]
    [string]$SourceContext,
    
    [Parameter(Mandatory=$false)]
    [string]$Title = "Sovereign OS Task"
)

$SovereignRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$envFile = Join-Path $SovereignRoot ".env"
$apiKey = $null

if (Test-Path $envFile) {
    foreach ($line in (Get-Content $envFile)) {
        if ($line -match "^JULES_API_KEY=(.+)$") {
            $apiKey = $matches[1]
            break
        }
    }
}

if (-not $apiKey) {
    $apiKey = $env:JULES_API_KEY
}

if (-not $apiKey) {
    throw "JULES_API_KEY not found in $envFile or environment variables."
}

$uri = "https://jules.googleapis.com/v1alpha/sessions"
$headers = @{
    "Content-Type" = "application/json"
    "X-Goog-Api-Key" = $apiKey
}

$body = @{
    prompt = $Prompt
    title = $Title
}

if ($SourceContext) {
    $body.sourceContext = @{
        source = $SourceContext
    }
}

$jsonBody = $body | ConvertTo-Json -Depth 5

Write-Host "Dispatching task to Jules..."
try {
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $jsonBody
    Write-Host "Jules session created successfully."
    Write-Host "Session Name: $($response.name)"
    return $response
}
catch {
    throw "Failed to create Jules session: $_"
}
