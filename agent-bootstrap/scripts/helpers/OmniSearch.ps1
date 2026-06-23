# OmniSearch.ps1 - Autonomous Internet Routing Engine
# Purpose: Dynamically route failed queries or errors directly to the internet (via Exa, Jina, or gh CLI)
# to autonomously fetch solutions.

function Invoke-OmniSearch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query,

        [ValidateSet("Web", "Code", "GitHub")]
        [string]$Mode = "Web",

        [int]$MaxResults = 3
    )

    $SovereignRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
    $AgentReachExe = Join-Path $env:USERPROFILE ".agent-reach-venv/Scripts/agent-reach.exe"
    
    if (-not (Test-Path $AgentReachExe)) {
        Write-SovereignLog -Level "WARN" -Step "OMNISEARCH" -Message "AgentReach not installed. Falling back to simple curl."
        # Fallback to pure curl via Jina Reader if AgentReach isn't installed
        $JinaURL = "https://s.jina.ai/" + [uri]::EscapeDataString($Query)
        try {
            $Result = curl.exe -s $JinaURL
            return $Result
        } catch {
            return $null
        }
    }

    try {
        Write-SovereignLog -Level "INFO" -Step "OMNISEARCH" -Message "Executing OmniSearch [$Mode]: $Query"
        
        $Result = ""
        switch ($Mode) {
            "Web" {
                # Exa web search via AgentReach
                $Result = & $AgentReachExe run "exa search `"$Query`" --num $MaxResults" 2>&1 | Out-String
            }
            "Code" {
                # Exa code search
                $Result = & $AgentReachExe run "exa search code `"$Query`" --num $MaxResults" 2>&1 | Out-String
            }
            "GitHub" {
                # GitHub CLI native lookup
                $Result = gh search repos $Query --limit $MaxResults | Out-String
            }
        }
        
        Write-SovereignLog -Level "INFO" -Step "OMNISEARCH" -Message "OmniSearch returned $(($Result.Length)) bytes of intelligence."
        return $Result
    } catch {
        Write-SovereignLog -Level "ERROR" -Step "OMNISEARCH" -Message "OmniSearch failed: $_"
        return $null
    }
}
