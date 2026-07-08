# validate-skill.ps1 - C:/Skills Skill Verification Engine (v15.0.0-CloudNative)
# Purpose: Check if a skill directory is well-formed with proper documentation.

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Skill  # Can be a name (e.g., 'zod') or a path (e.g., 'C:/Skills/zod')
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$SovereignRoot = (Resolve-Path "$PSScriptRoot/../..").Path

# Import shared module
Import-Module "$SovereignRoot/agent-bootstrap/scripts/helpers.psm1" -Force -DisableNameChecking

# Resolve the absolute path
if (Test-Path $Skill) {
    $SkillPath = (Resolve-Path $Skill).Path
} else {
    $SkillPath = Join-Path $SovereignRoot $Skill
}

$SkillName = Split-Path $SkillPath -Leaf

if (-not (Test-Path $SkillPath)) {
    Write-SovereignLog -Level "ERROR" -Step "VALIDATE" -Message "Skill path does not exist: $SkillPath"
    throw "Skill path does not exist: $SkillPath"
}

$Errors = [System.Collections.Generic.List[string]]::new()
$Warnings = [System.Collections.Generic.List[string]]::new()

# 1. REQUIRED: README.md or SKILL.md (core documentation)
$hasReadme = Test-Path (Join-Path $SkillPath "README.md")
$hasSkillMd = Test-Path (Join-Path $SkillPath "SKILL.md")
$hasCursorrules = Test-Path (Join-Path $SkillPath ".cursorrules")

if (-not $hasReadme -and -not $hasSkillMd -and -not $hasCursorrules) {
    $Errors.Add("Missing README.md, SKILL.md, or .cursorrules (No identification found)")
}

# 2. Check for rules.md (agent reasoning patterns)
$hasRules = Test-Path (Join-Path $SkillPath "rules.md")
if (-not $hasRules -and -not $hasCursorrules) {
    $Warnings.Add("No rules.md or .cursorrules — agent reasoning patterns may be limited")
}

# 3. Check README.md content quality (if exists)
if ($hasReadme) {
    $readmeContent = Get-Content (Join-Path $SkillPath "README.md") -Raw -ErrorAction SilentlyContinue
    if ($readmeContent) {
        if ($readmeContent.Length -lt 50) {
            $Warnings.Add("README.md is very short ($($readmeContent.Length) chars) — may need enrichment")
        }
        if ($readmeContent -notmatch "^#") {
            $Warnings.Add("README.md has no heading — may be poorly formatted")
        }
    }
}

# 4. Check configuration exclusions
$Config = Get-SovereignConfig
if ($Config) {
    $ExcludedDirs = @($Config.governance.harvester_excluded_dirs)
    if ($SkillName -in $ExcludedDirs) {
        $Warnings.Add("Skill is registered in harvester_excluded_dirs within sovereign.config.json and will be ignored by the controller.")
    }
}

# 5. Check for Lore.md (wisdom persistence)
if (Test-Path (Join-Path $SkillPath "Lore.md")) {
    $Warnings.Add("Lore.md found. Ensure it contains actionable wisdom.")
}

# Output results
if ($Warnings.Count -gt 0) {
    foreach ($W in $Warnings) {
        Write-SovereignLog -Level "WARN" -Step "VALIDATE" -Message $W
    }
}

if ($Errors.Count -gt 0) {
    foreach ($Err in $Errors) {
        Write-SovereignLog -Level "ERROR" -Step "VALIDATE" -Message $Err
    }
    throw "Validation failed with $($Errors.Count) errors."
}

Write-SovereignLog -Level "INFO" -Step "VALIDATE" -Message "Skill '$SkillName' validated successfully."
