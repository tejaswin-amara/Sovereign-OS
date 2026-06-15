# sovereign-check.ps1 - Enterprise Audit Tool (v13.2.0-CloudNative)
# Purpose: Deep integrity scanning of governance, complexity cap, and skill-sync states.
# Each check is isolated — one failure does not crash others.

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ProjectPath = ".",

    [switch]$Heal = $false
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$SovereignRoot = $PSScriptRoot
$FailureCount = 0

# Import shared module
Import-Module "$SovereignRoot/agent-bootstrap/scripts/helpers.psm1" -Force -DisableNameChecking

$RunID = [guid]::NewGuid().ToString().Substring(0,8)
Set-SovereignLogContext -LogDir "$SovereignRoot/LOGS" -RunId $RunID -CorrId $RunID

# Resolve project path
$ResolvedProject = (Resolve-Path $ProjectPath -ErrorAction SilentlyContinue).Path
if (-not $ResolvedProject) { $ResolvedProject = $ProjectPath }

# Dynamic version
$Version = "13.2.0-CloudNative"
try {
    $Version = Get-SovereignVersion -SkillsRoot $SovereignRoot
} catch {
    Write-SovereignLog -Level "WARN" -Step "VERSION" -Message "Could not read VERSION file: $_"
    $FailureCount++
}

$Config = Get-SovereignConfig

# -------------------------------------------------------------------------
# 1. Check Master Controller
# -------------------------------------------------------------------------
try {
    $sovScript = "$SovereignRoot/sovereign.ps1"
    if (Test-Path $sovScript) {
        $header = Get-Content $sovScript -Head 1
        if ($header -match 'v13\.\d+\.\d+') {
            Write-SovereignLog -Level "INFO" -Step "CTRL" -Message "Controller version aligned: $($Matches[0])"
        } else {
            Write-SovereignLog -Level "WARN" -Step "CTRL" -Message "Controller version unknown"
            $FailureCount++
        }
    } else {
        Write-SovereignLog -Level "ERROR" -Step "CTRL" -Message "sovereign.ps1 missing"
        $FailureCount++
    }
} catch {
    Write-SovereignLog -Level "ERROR" -Step "CTRL" -Message "Controller check failed: $_"
    $FailureCount++
}

# -------------------------------------------------------------------------
# 2. Check SOVEREIGN_CORE.md Exists
# -------------------------------------------------------------------------
try {
    $corePath = "$SovereignRoot/SOVEREIGN_CORE.md"
    if (Test-Path $corePath) {
        $coreContent = Get-Content $corePath -Raw
        if ($coreContent -match 'SOVEREIGN CORE') {
            Write-SovereignLog -Level "INFO" -Step "CORE" -Message "SOVEREIGN_CORE.md present and valid"
        } else {
            Write-SovereignLog -Level "WARN" -Step "CORE" -Message "SOVEREIGN_CORE.md exists but content unexpected"
        }
    } else {
        Write-SovereignLog -Level "WARN" -Step "CORE" -Message "SOVEREIGN_CORE.md not found. Run sovereign.ps1 to generate."
        $FailureCount++
    }
} catch {
    Write-SovereignLog -Level "ERROR" -Step "CORE" -Message "Core check failed: $_"
    $FailureCount++
}

# -------------------------------------------------------------------------
# 3. Check Module Cap Compliance
# -------------------------------------------------------------------------
try {
    $rulesDir = "$ResolvedProject/.agents/rules"
    $wfDir = "$ResolvedProject/.agents/workflows"

    if ((Test-Path $rulesDir) -and (Test-Path $wfDir)) {
        $ruleCount = @(Get-ChildItem "$rulesDir" -Filter "*.md" -ErrorAction SilentlyContinue).Count
        $wfCount = @(Get-ChildItem "$wfDir" -Filter "*.md" -ErrorAction SilentlyContinue).Count
        $totalModules = $ruleCount + $wfCount
        $moduleCapConfig = Get-SovereignConfig -KeyPath "governance.module_cap"
        $moduleCap = if ($moduleCapConfig) { [int]$moduleCapConfig } else { 32 }

        if ($totalModules -le $moduleCap) {
            Write-SovereignLog -Level "INFO" -Step "MODCAP" -Message "Module count OK: $totalModules/$moduleCap ($ruleCount rules + $wfCount workflows)"
        } else {
            Write-SovereignLog -Level "ERROR" -Step "MODCAP" -Message "Module cap EXCEEDED: $totalModules/$moduleCap"
            $FailureCount++
        }
    } else {
        Write-SovereignLog -Level "INFO" -Step "MODCAP" -Message "No .agents dir found (standalone context)"
    }
} catch {
    Write-SovereignLog -Level "ERROR" -Step "MODCAP" -Message "Module cap check failed: $_"
    $FailureCount++
}

# -------------------------------------------------------------------------
# 4. Check Dynamic Skill Count Consistency
# -------------------------------------------------------------------------
try {
    if ($Config) {
        $ExcludedDirsConfig = Get-SovereignConfig -KeyPath "governance.harvester_excluded_dirs"
        $ExcludedDirs = if ($ExcludedDirsConfig) { @($ExcludedDirsConfig) } else { @() }
        $DynamicCount = Get-DynamicSkillCount -SkillsRoot $SovereignRoot -ExcludedDirs $ExcludedDirs
        $ConfigCount = [int]$Config.governance.skills_count

        if ($ConfigCount -eq 0) {
            Write-SovereignLog -Level "INFO" -Step "COUNT" -Message "Config count is 0 (not yet synced). Dynamic count: $DynamicCount"
        } elseif ($ConfigCount -eq $DynamicCount) {
            Write-SovereignLog -Level "INFO" -Step "COUNT" -Message "Skill count aligned: $DynamicCount"
        } else {
            Write-SovereignLog -Level "WARN" -Step "COUNT" -Message "Count drift: config=$ConfigCount vs filesystem=$DynamicCount"
            if ($Heal) {
                $LockStream = Start-SovereignLock -LockFile "$SovereignRoot/.sovereign.lock"
                try {
                    $Config.governance.skills_count = $DynamicCount
                    $PrettyJson = ConvertTo-Json -InputObject $Config -Depth 100
                    Save-AtomicContent -Path "$SovereignRoot/sovereign.config.json" -Content $PrettyJson
                    Update-SovereignChecksum -ConfigPath "$SovereignRoot/sovereign.config.json" -HashPath "$SovereignRoot/agent-bootstrap/.config.sha256" | Out-Null
                    Write-SovereignLog -Level "INFO" -Step "COUNT" -Message "Healed: count set to $DynamicCount"
                } finally {
                    Stop-SovereignLock -LockFile "$SovereignRoot/.sovereign.lock" -LockStream $LockStream
                }
            }
        }
    }
} catch {
    Write-SovereignLog -Level "ERROR" -Step "COUNT" -Message "Count check failed: $_"
    $FailureCount++
}

# -------------------------------------------------------------------------
# 5. Check Config Version Consistency
# -------------------------------------------------------------------------
try {
    if ($Config) {
        if ($Config.version -eq $Version) {
            Write-SovereignLog -Level "INFO" -Step "CFGVER" -Message "Config version aligned: $Version"
        } else {
            Write-SovereignLog -Level "WARN" -Step "CFGVER" -Message "Version drift: config=$($Config.version) vs VERSION=$Version"
            if ($Heal) {
                $LockStream = Start-SovereignLock -LockFile "$SovereignRoot/.sovereign.lock"
                try {
                    $Config.version = $Version
                    $PrettyJson = ConvertTo-Json -InputObject $Config -Depth 100
                    Save-AtomicContent -Path "$SovereignRoot/sovereign.config.json" -Content $PrettyJson
                    Update-SovereignChecksum -ConfigPath "$SovereignRoot/sovereign.config.json" -HashPath "$SovereignRoot/agent-bootstrap/.config.sha256" | Out-Null
                    Write-SovereignLog -Level "INFO" -Step "CFGVER" -Message "Healed: version set to $Version"
                } finally {
                    Stop-SovereignLock -LockFile "$SovereignRoot/.sovereign.lock" -LockStream $LockStream
                }
            }
        }
    } else {
        Write-SovereignLog -Level "ERROR" -Step "CFGVER" -Message "sovereign.config.json missing or corrupt"
        $FailureCount++
    }
} catch {
    Write-SovereignLog -Level "ERROR" -Step "CFGVER" -Message "Config version check failed: $_"
    $FailureCount++
}

# -------------------------------------------------------------------------
# 6. Check for Legacy Files (should be deleted)
# -------------------------------------------------------------------------
try {
    $LegacyFiles = @("AGENT_DNA.md", "CONTRACT.md", "COMMANDER.md", ".cursorrules", "MANIFEST.json")
    foreach ($LF in $LegacyFiles) {
        if (Test-Path "$SovereignRoot/$LF") {
            Write-SovereignLog -Level "WARN" -Step "LEGACY" -Message "Legacy file still exists: $LF (should be deleted)"
        }
    }
    $LegacyScripts = @("agent-bootstrap/scripts/sync-governance.ps1", "agent-bootstrap/scripts/commander-gen.ps1")
    foreach ($LS in $LegacyScripts) {
        if (Test-Path "$SovereignRoot/$LS") {
            Write-SovereignLog -Level "WARN" -Step "LEGACY" -Message "Legacy script still exists: $LS (should be deleted)"
        }
    }
    Write-SovereignLog -Level "INFO" -Step "LEGACY" -Message "Legacy file check complete"
} catch {
    Write-SovereignLog -Level "ERROR" -Step "LEGACY" -Message "Legacy check failed: $_"
    $FailureCount++
}

# -------------------------------------------------------------------------
# 7. Check Skill Harvesting
# -------------------------------------------------------------------------
try {
    $harvestPath = "$ResolvedProject/.agents/knowledge/harvested_skills.md"
    if (Test-Path $harvestPath) {
        $harvestAge = ((Get-Date) - (Get-Item $harvestPath).LastWriteTime).TotalHours
        if ($harvestAge -gt 24) {
            Write-SovereignLog -Level "WARN" -Step "HARVEST" -Message "Harvest stale (${harvestAge}h old). Run sovereign.ps1 to refresh."
        } else {
            Write-SovereignLog -Level "INFO" -Step "HARVEST" -Message "Harvest fresh (${harvestAge}h old)"
        }
    } else {
        Write-SovereignLog -Level "INFO" -Step "HARVEST" -Message "No harvest file found (standalone context)"
    }
} catch {
    Write-SovereignLog -Level "ERROR" -Step "HARVEST" -Message "Harvest check failed: $_"
    $FailureCount++
}

Write-SovereignLog -Level "INFO" -Step "AUDIT" -Message "Sovereign check complete: $FailureCount failures"
exit $FailureCount
