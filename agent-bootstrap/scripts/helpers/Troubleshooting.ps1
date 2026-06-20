# C:/Skills/agent-bootstrap/scripts/helpers/Troubleshooting.ps1

function Invoke-SovereignInternetDiagnostic {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ErrorMessage
    )

    try {
        Write-SovereignLog -Level "INFO" -Step "AUTO_DIAG" -Message "Initiating Jina web search for fatal error context..."
        
        # Prepare the query for DuckDuckGo
        $Query = "PowerShell Error " + $ErrorMessage
        # We need to escape it to form a proper URL query string
        $EncodedQuery = [uri]::EscapeDataString($Query)
        
        # Construct the reader URL using Jina and DDG
        $Url = "https://r.jina.ai/https://html.duckduckgo.com/html/?q=$EncodedQuery"
        
        # Use simple curl.exe for maximum reliability and bypass of PS-specific invoke-restmethod bugs
        $Result = curl.exe -s --max-time 15 $Url
        
        if ($Result) {
            # Take only the top 40 lines of markdown to avoid massive context bloat
            $Lines = $Result -split "`n" | Select-Object -First 40
            $Summary = $Lines -join "`n"
            
            $LogDir = if ($script:SovereignLogDir) { $script:SovereignLogDir } else { "$PSScriptRoot/../../../LOGS" }
            $DiagPath = Join-Path $LogDir "sovereign-internet-diagnostic.md"
            
            $Content = "## Sovereign Auto-Diagnostic Result`n`n"
            $Content += "**Error:** $ErrorMessage`n`n"
            $Content += "**Timestamp:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
            $Content += "### Web Search Results:`n`n"
            $Content += "$Summary`n`n"
            $Content += "> *Note: Results retrieved dynamically via Jina Reader.*"
            
            [System.IO.File]::WriteAllText($DiagPath, $Content)
            Write-SovereignLog -Level "INFO" -Step "AUTO_DIAG" -Message "Internet diagnostic saved to $DiagPath"
        } else {
            Write-SovereignLog -Level "WARN" -Step "AUTO_DIAG" -Message "Jina API returned empty result or timed out."
        }
    } catch {
        Write-SovereignLog -Level "WARN" -Step "AUTO_DIAG" -Message "Failed to fetch internet diagnostic: $_"
    }
}
