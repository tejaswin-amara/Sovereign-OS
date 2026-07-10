# OmniSearch.ps1 - Autonomous Internet Routing Engine
# Purpose: Dynamically route failed queries or errors directly to the internet (via Exa, Jina, or gh CLI)
# to autonomously fetch solutions.
Set-StrictMode -Version Latest

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
    $VenvSubDir = if ($IsWindows -or $env:OS -eq "Windows_NT") { "Scripts" } else { "bin" }
    $ExeName = if ($IsWindows -or $env:OS -eq "Windows_NT") { "agent-reach.exe" } else { "agent-reach" }
    $UserHome = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($env:HOME) { $env:HOME } else { "" }
    $AgentReachExe = if ($UserHome) { Join-Path $UserHome ".agent-reach-venv/$VenvSubDir/$ExeName" } else { "" }
    
    if (-not (Test-Path $AgentReachExe)) {
        Write-SovereignLog -Level "WARN" -Step "OMNISEARCH" -Message "AgentReach not installed. Falling back to simple curl."
        # Fallback to pure curl via Jina Reader if AgentReach isn't installed
        $JinaURL = "https://s.jina.ai/" + [uri]::EscapeDataString($Query)
        try {
            if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
                $Result = curl.exe -s $JinaURL
            } else {
                $Result = Invoke-RestMethod -Uri $JinaURL -UseBasicParsing
            }
            return $Result
        } catch {
            return $null
        }
    }

    try {
        Write-SovereignLog -Level "INFO" -Step "OMNISEARCH" -Message "Executing OmniSearch [$Mode]: $Query"
        
        $Result = ""
        # ponytail: escape query to prevent command injection via backticks or $()
        $SafeQuery = $Query -replace '[`$]', ''
        switch ($Mode) {
            "Web" {
                $Result = & $AgentReachExe run "exa search `"$SafeQuery`" --num $MaxResults" 2>&1 | Out-String
            }
            "Code" {
                $Result = & $AgentReachExe run "exa search code `"$SafeQuery`" --num $MaxResults" 2>&1 | Out-String
            }
            "GitHub" {
                if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
                    Write-SovereignLog -Level "WARN" -Step "OMNISEARCH" -Message "gh CLI not found. Skipping GitHub search."
                    return $null
                }
                $Result = gh search repos $SafeQuery --limit $MaxResults | Out-String
            }
        }
        
        Write-SovereignLog -Level "INFO" -Step "OMNISEARCH" -Message "OmniSearch returned $(($Result.Length)) bytes of intelligence."
        return $Result
    } catch {
        Write-SovereignLog -Level "ERROR" -Step "OMNISEARCH" -Message "OmniSearch failed: $_"
        return $null
    }
}
