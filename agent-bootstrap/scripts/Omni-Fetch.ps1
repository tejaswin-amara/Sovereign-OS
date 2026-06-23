# Omni-Fetch.ps1 - The Sovereign Apex Mass Acquisition Engine
# Purpose: Proactively downloads ALL mapped intelligence repositories simultaneously into .cloud-cache
# Architecture: Runspace Parallelism using Fetch-CloudSkill.ps1

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$SovereignPath = (Resolve-Path "$PSScriptRoot/../..").Path
Import-Module "$SovereignPath/agent-bootstrap/scripts/helpers.psm1" -Force -DisableNameChecking

$Config = Get-SovereignConfig
if (-not $Config.dep_to_skill_map) {
    throw "dep_to_skill_map is missing from sovereign.config.json"
}

$ReposToFetch = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

# Extract unique github repos
foreach ($Prop in $Config.dep_to_skill_map.PSObject.Properties) {
    $RepoPath = $Prop.Value
    if ($RepoPath -match '^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$') {
        [void]$ReposToFetch.Add($RepoPath)
    }
}

Write-SovereignLog -Level "INFO" -Step "OMNI-FETCH" -Message "Initiating Sovereign Apex Acquisition. Target: $($ReposToFetch.Count) Repositories."
Write-Host "=========================================" -ForegroundColor Magenta
Write-Host " SOVEREIGN APEX ENGINE - MASS ACQUISITION" -ForegroundColor Magenta
Write-Host "=========================================" -ForegroundColor Magenta

# Limit parallelism to avoid ratelimiting or thrashing CPU too hard
$ThrottleLimit = 8 

$Results = $ReposToFetch | ForEach-Object -Parallel {
    $Repo = $_
    $SovereignPath = $using:SovereignPath
    $FetchScript = "$SovereignPath/agent-bootstrap/scripts/Fetch-CloudSkill.ps1"
    
    try {
        & $FetchScript -Repo $Repo
        return @{ Repo = $Repo; Status = "SUCCESS" }
    } catch {
        return @{ Repo = $Repo; Status = "FAILED"; Error = $_.Exception.Message }
    }
} -ThrottleLimit $ThrottleLimit

$SuccessCount = ($Results | Where-Object { $_.Status -eq "SUCCESS" }).Count
$FailedCount = ($Results | Where-Object { $_.Status -eq "FAILED" }).Count

Write-SovereignLog -Level "INFO" -Step "OMNI-FETCH" -Message "Omni-Fetch Complete. SUCCESS: $SuccessCount, FAILED: $FailedCount"

if ($FailedCount -gt 0) {
    Write-Host "`n[!] The following repositories failed to fetch:" -ForegroundColor Yellow
    $Results | Where-Object { $_.Status -eq "FAILED" } | ForEach-Object {
        Write-Host "  - $($_.Repo) ($($_.Error))" -ForegroundColor Red
    }
}

Write-Host "`nOmni-Fetch Acquisition complete. $SuccessCount repos cached." -ForegroundColor Green
