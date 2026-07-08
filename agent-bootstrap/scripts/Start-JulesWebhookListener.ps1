[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [int]$Port = 5050
)

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
            
            try {
                $json = $body | ConvertFrom-Json
                
                # Check if this is a PR from Jules
                if ($json.action -eq "opened" -and $json.pull_request) {
                    $prUser = $json.pull_request.user.login
                    if ($prUser -match "jules") {
                        Write-Host "Detected PR from Jules! Invoking security-sweep.ps1..."
                        Start-Job -ScriptBlock {
                            pwsh -File C:/Skills/agent-bootstrap/scripts/security-sweep.ps1
                        }
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
