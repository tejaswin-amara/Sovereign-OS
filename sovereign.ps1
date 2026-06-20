# sovereign.ps1 - The Sovereign Master Controller (v14.0.0-CloudNative)
# Purpose: Unified Orchestrator with OS-level Locking, Phase-Gated Execution, and State Reconciliation.
# Location: D:/Skills/sovereign.ps1

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Position = 0)]
    [string]$ProjectPath = ".",

    [switch]$UpdateLibrary = $false,

    [Parameter(Mandatory=$false)]
    [string]$FetchURL
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$SovereignRoot = $PSScriptRoot
$LockFile = "$SovereignRoot/.sovereign.lock"
$LogDir = "$SovereignRoot/LOGS"


# -------------------------------------------------------------------------
# 1. SETUP ENVIRONMENT
# -------------------------------------------------------------------------
if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }

# 2. IMPORT SHARED MODULE
Import-Module "$SovereignRoot/agent-bootstrap/scripts/helpers.psm1" -Force -DisableNameChecking

# 3. CONFIGURE LOGGING CONTEXT
$RunID = [guid]::NewGuid().ToString().Substring(0,8)
$CorrelationID = [guid]::NewGuid().ToString().Substring(0,8)
Set-SovereignLogContext -LogDir $LogDir -RunId $RunID -CorrId $CorrelationID

# Log Rotation (retention policy from config)
Start-LogRotation -LogDir $LogDir

# -------------------------------------------------------------------------
# 4. READ VERSION & CONFIG (Single source of truth)
# -------------------------------------------------------------------------
$Version = Get-SovereignVersion -SkillsRoot $SovereignRoot
$Config = Get-SovereignConfig
if (-not $Config) {
    Write-SovereignLog -Level "ERROR" -Step "VALIDATION" -Message "sovereign.config.json MISSING or CORRUPT. Aborting."
    exit 1
}

$PhaseFailures = @()
if ($Config.version -ne $Version) {
    Write-SovereignLog -Level "WARN" -Step "VALIDATION" -Message "Version drift detected: sovereign.config.json has '$($Config.version)' but VERSION has '$Version'. Aligning system to '$Version'."
    $PhaseFailures += "VERSION_DRIFT"
}

# -------------------------------------------------------------------------
# EXECUTION HEAD
# -------------------------------------------------------------------------
$ResolvedProject = (Resolve-Path $ProjectPath -ErrorAction SilentlyContinue).Path
if (-not $ResolvedProject) { $ResolvedProject = $ProjectPath }

# -------------------------------------------------------------------------
# 5. PRE-FLIGHT INTEGRITY & VALIDATION
# -------------------------------------------------------------------------
Verify-SovereignIntegrity -RootPath $SovereignRoot
Assert-SovereignConfigIntegrity -ConfigPath "$SovereignRoot/sovereign.config.json" -HashPath "$SovereignRoot/agent-bootstrap/.config.sha256"

# Validate required config keys
try {
    $RequiredKeys = @("version", "security_policy", "governance")
    foreach ($Key in $RequiredKeys) {
        if (-not ($Config.PSObject.Properties[$Key])) {
            throw "Missing required config key: $Key"
        }
    }
    Write-SovereignLog -Level "INFO" -Step "VALIDATION" -Message "Config schema validated. Version: $($Config.version)"
} catch {
    Write-SovereignLog -Level "ERROR" -Step "VALIDATION" -Message "Config validation failed: $_. Aborting."
    exit 1
}

# Module Cap Enforcement (Hard Block)
$AgentDir = Join-Path $ResolvedProject ".agents"
if (Test-Path $AgentDir) {
    try {
        Assert-ModuleCap -AgentDir $AgentDir
    } catch {
        Write-SovereignLog -Level "ERROR" -Step "MODULE_CAP" -Message "$($_.Exception.Message)"
        exit 2
    }
}

# -------------------------------------------------------------------------
# 6. PHASE-GATED EXECUTION (Lock INSIDE try, critical phase abort)
# -------------------------------------------------------------------------
$LockStream = $null

try {
    # Lock acquisition INSIDE try block — guarantees finally cleanup
    $LockStream = Start-SovereignLock -LockFile $LockFile -TimeoutSeconds 30
    Write-SovereignLog -Level "INFO" -Step "MUTEX" -Message "OS-Level Lock Acquired."

    # ------------------------------------------------------------------
    # PHASE 1: INIT — Dynamic Skill Count & Config Update [CRITICAL]
    # ------------------------------------------------------------------
    Write-SovereignLog -Level "INFO" -Step "INIT" -Message "Computing dynamic skill count."

    $ExcludedDirs = @()
    if ($Config.governance -and $Config.governance.harvester_excluded_dirs) {
        $ExcludedDirs = @($Config.governance.harvester_excluded_dirs)
    }
    $DynamicCount = Get-DynamicSkillCount -SkillsRoot $SovereignRoot -ExcludedDirs $ExcludedDirs
    Write-SovereignLog -Level "INFO" -Step "INIT" -Message "Dynamic skill count: $DynamicCount"

    if ($UpdateLibrary -and (Test-Path "$SovereignRoot/.git")) {
        Push-Location $SovereignRoot; git pull --quiet; Pop-Location
    }

    # Overwrite config.governance.skills_count with dynamic count and save ONLY if changed
    $ConfigPath = "$SovereignRoot/sovereign.config.json"
    $ConfigRaw = Get-Content $ConfigPath -Raw
    $ConfigObj = $ConfigRaw | ConvertFrom-Json
    if ($ConfigObj.governance.skills_count -ne $DynamicCount) {
        $ConfigObj.governance.skills_count = $DynamicCount
        $ConfigJson = $ConfigObj | ConvertTo-Json -Depth 10
        Save-AtomicContent -Path $ConfigPath -Content $ConfigJson
        Write-SovereignLog -Level "INFO" -Step "INIT" -Message "Config governance.skills_count updated to $DynamicCount."
        # Reseal config checksum after updating skills_count
        Update-SovereignChecksum -ConfigPath $ConfigPath -HashPath "$SovereignRoot/agent-bootstrap/.config.sha256"
    } else {
        Write-SovereignLog -Level "INFO" -Step "INIT" -Message "Config governance.skills_count already up-to-date ($DynamicCount). Skipping disk I/O."
    }

    # ------------------------------------------------------------------
    # PHASE 2: CORE_GEN — Generate SOVEREIGN_CORE.md from template [CRITICAL]
    # ------------------------------------------------------------------
    Write-SovereignLog -Level "INFO" -Step "CORE_GEN" -Message "Generating SOVEREIGN_CORE.md from template."

    $TemplatePath = "$SovereignRoot/SOVEREIGN_CORE.template.md"
    $CoreOutputPath = "$SovereignRoot/SOVEREIGN_CORE.md"
    if (Test-Path $TemplatePath) {
        $TemplateContent = Get-Content $TemplatePath -Raw
        $Timestamp = Get-Date -Format "o"
        $CoreContent = $TemplateContent `
            -replace '\{\{SKILL_COUNT\}\}', $DynamicCount `
            -replace '\{\{VERSION\}\}', $Version `
            -replace '\{\{TIMESTAMP\}\}', $Timestamp
        Save-AtomicContent -Path $CoreOutputPath -Content $CoreContent
        Write-SovereignLog -Level "INFO" -Step "CORE_GEN" -Message "SOVEREIGN_CORE.md generated. Skills: $DynamicCount, Version: $Version"
    } else {
        throw "CRITICAL_PHASE_FAILURE: SOVEREIGN_CORE.template.md not found at $TemplatePath. Aborting pipeline."
    }

    # ------------------------------------------------------------------
    # PHASE 3: HARVEST — Skill Harvester [CRITICAL]
    # ------------------------------------------------------------------
    Write-SovereignLog -Level "INFO" -Step "HARVEST" -Message "Running skill harvester."
    $HarvesterScript = "$SovereignRoot/agent-bootstrap/scripts/skill-harvester.ps1"
    if (Test-Path $HarvesterScript) {
        pwsh -NoProfile -File $HarvesterScript -WorkspacePath $ResolvedProject -SyncLibrary | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "CRITICAL_PHASE_FAILURE: Harvester failed with exit code $LASTEXITCODE. Skill ingestion incomplete. Aborting pipeline."
        }
    }

    # ------------------------------------------------------------------
    # PHASE 4: EVOLVE — Drift Analysis [CRITICAL]
    # ------------------------------------------------------------------
    Write-SovereignLog -Level "INFO" -Step "EVOLUTION" -Message "Running drift analysis."
    $EvolveScript = "$SovereignRoot/agent-bootstrap/scripts/self-evolve.ps1"
    if (Test-Path $EvolveScript) {
        pwsh -NoProfile -File $EvolveScript -WorkspacePath $ResolvedProject
        if ($LASTEXITCODE -ne 0) {
            throw "CRITICAL_PHASE_FAILURE: Evolution engine failed with exit code $LASTEXITCODE. Drift state unknown. Aborting pipeline."
        }
    }

    # ------------------------------------------------------------------
    # PHASE 5: SWEEP — Security Sweep [CRITICAL]
    # ------------------------------------------------------------------
    Write-SovereignLog -Level "INFO" -Step "SECURITY_SWEEP" -Message "Running security sweep."
    $SweepScript = "$SovereignRoot/agent-bootstrap/scripts/security-sweep.ps1"
    if (Test-Path $SweepScript) {
        pwsh -NoProfile -File $SweepScript -ProjectPath $ResolvedProject
        if ($LASTEXITCODE -ne 0) {
            throw "CRITICAL_PHASE_FAILURE: Security sweep failed with exit code $LASTEXITCODE. Dynamic code or AST violations found. Aborting pipeline."
        }
    }

    # ------------------------------------------------------------------
    # PHASE 6 (OPTIONAL): FETCH — Cloud-Native JIT Skill Ingestion [NON-CRITICAL]
    # ------------------------------------------------------------------
    if (-not [string]::IsNullOrWhiteSpace($FetchURL)) {
        Write-SovereignLog -Level "INFO" -Step "FETCH" -Message "Triggering Cloud-Native JIT fetch for: $FetchURL"
        $FetchScript = "$SovereignRoot/agent-bootstrap/scripts/Fetch-CloudSkill.ps1"
        if (Test-Path $FetchScript) {
            # Convert full GitHub URL to org/repo format if needed
            $CleanRepo = $FetchURL -replace "https://github.com/", ""
            pwsh -NoProfile -File $FetchScript -Repo $CleanRepo
            if ($LASTEXITCODE -ne 0) {
                Write-SovereignLog -Level "WARN" -Step "FETCH" -Message "JIT fetch returned non-zero for '$CleanRepo'. Skill may not be available."
                $PhaseFailures += "FETCH_WARN"
            }
        } else {
            Write-SovereignLog -Level "ERROR" -Step "FETCH" -Message "Fetch-CloudSkill.ps1 is missing!"
            $PhaseFailures += "FETCH_MISSING"
        }
    }

    # ------------------------------------------------------------------
    # PHASE 6.5: GC — Cloud Cache Garbage Collection [CRITICAL]
    # ------------------------------------------------------------------
    Write-SovereignLog -Level "INFO" -Step "GC" -Message "Running Garbage Collection on ephemeral .cloud-cache..."
    $CloudCacheDir = "$SovereignRoot\.cloud-cache"
    if (Test-Path $CloudCacheDir) {
        try {
            cmd.exe /c "rmdir /s /q ""$CloudCacheDir"""
            if (-not (Test-Path $CloudCacheDir)) {
                Write-SovereignLog -Level "INFO" -Step "GC" -Message "Cloud cache purged successfully."
            } else {
                Write-SovereignLog -Level "WARN" -Step "GC" -Message "Cloud cache partially purged. Some locked files remain."
            }
        } catch {
            Write-SovereignLog -Level "WARN" -Step "GC" -Message "Failed to purge cloud cache. It may be locked."
            $PhaseFailures += "GC_FAIL"
        }
    }

    # ------------------------------------------------------------------
    # PHASE 7: REACH — Internet Access Health Check [NON-CRITICAL]
    # ------------------------------------------------------------------
    Write-SovereignLog -Level "INFO" -Step "REACH" -Message "Checking Internet Reach status..."
    $AgentReachVenv = Join-Path $env:USERPROFILE ".agent-reach-venv"
    $AgentReachExe = Join-Path $AgentReachVenv "Scripts\agent-reach.exe"
    if (Test-Path $AgentReachExe) {
        try {
            $DoctorOutput = & $AgentReachExe doctor 2>&1 | Out-String
            Write-SovereignLog -Level "INFO" -Step "REACH" -Message "Agent-Reach is installed. Doctor output logged."
        } catch {
            Write-SovereignLog -Level "WARN" -Step "REACH" -Message "agent-reach doctor failed: $($_.Exception.Message)"
            $PhaseFailures += "REACH_DOCTOR_FAIL"
        }
    } else {
        Write-SovereignLog -Level "WARN" -Step "REACH" -Message "Agent-Reach is NOT installed. Run Install-AgentReach.ps1 to enable internet access."
    }

    # ------------------------------------------------------------------
    # FINAL REPORT
    # ------------------------------------------------------------------
    $StatusMsg = if ($PhaseFailures.Count -eq 0) { "ALL PHASES PASSED" } else { "COMPLETED WITH WARNINGS: $($PhaseFailures -join ', ')" }
    Write-SovereignLog -Level "INFO" -Step "COMPLETE" -Message $StatusMsg

} catch {
    Write-SovereignLog -Level "ERROR" -Step "EXECUTION" -Message "Fatal error: $($_.Exception.Message)"
    exit 1
} finally {
    # Guaranteed lock cleanup — LockStream is always released
    if ($LockStream) {
        Stop-SovereignLock -LockFile $LockFile -LockStream $LockStream
        Write-SovereignLog -Level "INFO" -Step "MUTEX" -Message "Lock released."
    }
}

exit 0
