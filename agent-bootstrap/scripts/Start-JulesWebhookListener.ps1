[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [int]$Port = 5050
)

$SovereignRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$envFile = Join-Path $SovereignRoot ".env"
$webhookSecret = $null
if (Test-Path $envFile) {
    foreach ($line in (Get-Content $envFile)) {
        if ($line -match "^WEBHOOK_SECRET=(.+)$") {
            $webhookSecret = $matches[1]
            break
        }
    }
}
if (-not $webhookSecret) {
    $webhookSecret = $env:WEBHOOK_SECRET
}

# Start a lightweight HttpListener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
try {
    $listener.Start()
} catch {
    throw "Failed to start HttpListener on port $Port. Please ensure you are running as Admin if required, or try a different port."
}

Write-Host "Listening for Jules GitHub Webhooks on http://localhost:$Port/"
Write-Host "Press Ctrl+C to stop..."

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        if ($request.HttpMethod -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            
            if ($webhookSecret) {
                $signatureHeader = $request.Headers["X-Hub-Signature-256"]
                if (-not $signatureHeader) {
                    Write-Warning "Missing X-Hub-Signature-256 header."
                    $response.StatusCode = 401
                    $response.Close()
                    continue
                }
                $hmac = [System.Security.Cryptography.HMACSHA256]::new([System.Text.Encoding]::UTF8.GetBytes($webhookSecret))
                $hash = $hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($body))
                $hashString = "sha256=" + ([BitConverter]::ToString($hash) -replace '-', '').ToLower()
                if ($hashString -ne $signatureHeader) {
                    Write-Warning "Invalid webhook signature."
                    $response.StatusCode = 401
                    $response.Close()
                    continue
                }
            }
            
            try {
                $json = $body | ConvertFrom-Json
                
                # Check if this is a PR from Jules
                if ($json.action -eq "opened" -and $json.pull_request) {
                    $prUser = $json.pull_request.user.login
                    if ($prUser -match "jules") {
                        Write-Host "Detected PR from Jules! Invoking security-sweep.ps1..."
                        $SweepScript = Join-Path $PSScriptRoot "security-sweep.ps1"
                        Start-Job -ScriptBlock {
                            param($scriptPath)
                            pwsh -File $scriptPath
                        } -ArgumentList $SweepScript
                    }
                }
            } catch {
                Write-Warning "Failed to parse webhook JSON payload: $_"
            }
        }

        # Respond with 200 OK
        $buffer = [System.Text.Encoding]::UTF8.GetBytes("OK")
        $response.ContentLength64 = $buffer.Length
        $output = $response.OutputStream
        $output.Write($buffer, 0, $buffer.Length)
        $output.Close()
    }
} finally {
    $listener.Stop()
}
