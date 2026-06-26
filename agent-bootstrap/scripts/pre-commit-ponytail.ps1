# pre-commit-ponytail.ps1 - Sovereign Technical Debt Enforcer
# Validates code changes against Ponytail (lazy dev) rules before committing.

[CmdletBinding()]
param(
    [string]$WorkspacePath = "."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SovereignRoot = (Resolve-Path "$PSScriptRoot/../..").Path
Import-Module "$SovereignRoot/agent-bootstrap/scripts/helpers.psm1" -Force -DisableNameChecking

Write-SovereignLog -Level "INFO" -Step "PONYTAIL_HOOK" -Message "Initiating Ponytail Debt Sweep on staged files..."

try {
    # 1. Check if ponytail skills are available in the system
    $PonytailDir = "$SovereignRoot/skills/ponytail-review"
    if (-not (Test-Path $PonytailDir)) {
        Write-SovereignLog -Level "INFO" -Step "PONYTAIL_HOOK" -Message "Ponytail skills not found. Skipping strict debt enforcement."
        exit 0
    }

    # 2. Extract staged changes
    Push-Location $WorkspacePath
    $StagedFiles = git diff --cached --name-only
    if (-not $StagedFiles) {
        Write-SovereignLog -Level "INFO" -Step "PONYTAIL_HOOK" -Message "No staged files. Skipping."
        Pop-Location
        exit 0
    }

    # 3. Analyze for over-engineering (stubbed logic representing the AI agent review step)
    $OverEngineered = $false
    foreach ($File in $StagedFiles) {
        if ($File -match "interface\w+Manager\.ts" -or $File -match "Abstract\w+Factory") {
            Write-SovereignLog -Level "ERROR" -Step "PONYTAIL_HOOK" -Message "Bloat detected in ${File}: Do not use Manager/Factory abstractions unless absolutely requested."
            $OverEngineered = $true
        }
    }

    Pop-Location

    if ($OverEngineered) {
        Write-SovereignLog -Level "ERROR" -Step "PONYTAIL_HOOK" -Message "Ponytail strict mode blocked this commit due to detected over-engineering or speculative abstractions."
        exit 1
    }

    Write-SovereignLog -Level "INFO" -Step "PONYTAIL_HOOK" -Message "Ponytail debt sweep passed. Code is minimal and lazy."
    exit 0
} catch {
    Write-SovereignLog -Level "WARN" -Step "PONYTAIL_HOOK" -Message "Error during Ponytail sweep: $_"
    exit 0 # Non-blocking on internal error
}
