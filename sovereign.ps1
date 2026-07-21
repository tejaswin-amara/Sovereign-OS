# sovereign.ps1 - The Sovereign Master Controller (v16.0.0-Scratch)
# Purpose: Single-file orchestrator. Zero unearned complexity.

[CmdletBinding()]
param(
    [string]$ProjectPath = ".",
    [switch]$UpdateLibrary = $false
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$SovereignRoot = $PSScriptRoot

function Write-Log {
    param([string]$Level, [string]$Step, [string]$Message)
    $Timestamp = Get-Date -Format "HH:mm:ss"
    $Line = "[$Timestamp] [$Level] [$Step] $Message"
    Write-Host $Line
    if ($LogDir) {
        Add-Content -Path "$LogDir/sovereign-$([datetime]::Now.ToString('yyyyMMdd')).log" -Value $Line
    }
}

function Save-Atomic {
    param([string]$Path, [string]$Content)
    $Temp = "$Path.tmp"
    Set-Content -Path $Temp -Value $Content -Encoding UTF8
    Move-Item -Path $Temp -Destination $Path -Force
}

# 1. READ CONFIG
$ConfigPath = "$SovereignRoot/sovereign.config.json"
if (-not (Test-Path $ConfigPath)) {
    Write-Log "ERROR" "INIT" "Config missing at $ConfigPath."
    exit 1
}
$Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

# Initialize LogDir after config read
$LogDir = Join-Path $SovereignRoot $Config.paths.logs_dir
if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }

# 2. MUTEX LOCK
$MutexName = "Global\SovereignOSLock"
$Mutex = New-Object System.Threading.Mutex($false, $MutexName)
if (-not $Mutex.WaitOne($Config.governance.lock_timeout_seconds * 1000, $false)) {
    Write-Log "ERROR" "MUTEX" "Could not acquire OS lock. Another instance is running."
    exit 1
}

try {
    $ExecutionStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Log "INFO" "MUTEX" "OS-Level Lock Acquired."

    # 3. VERIFY CORE STRUCTURE
    $SkillsDir = Join-Path $SovereignRoot "skills"
    $ModulesDir = Join-Path $SovereignRoot "modules"
    
    if (-not (Test-Path $SkillsDir)) { New-Item -Path $SkillsDir -ItemType Directory | Out-Null }
    if (-not (Test-Path $ModulesDir)) { New-Item -Path $ModulesDir -ItemType Directory | Out-Null }

    # 4. SKILL & MODULE COUNT
    $DynamicSkillCount = @(Get-ChildItem -Path $SkillsDir -Directory).Count
    $DynamicModuleCount = @(Get-ChildItem -Path $ModulesDir -Directory).Count
    Write-Log "INFO" "INIT" "Dynamic skill count: $DynamicSkillCount, Module count: $DynamicModuleCount"
    
    if ($Config.governance.skills_count -ne $DynamicSkillCount) {
        $Config.governance.skills_count = $DynamicSkillCount
        Save-Atomic -Path $ConfigPath -Content ($Config | ConvertTo-Json -Depth 10)
    }

    Write-Log "INFO" "COMPLETE" "ALL PHASES PASSED"

} catch {
    Write-Log "ERROR" "EXEC" "Fatal error: $($_.Exception.Message)"
    exit 1
} finally {
    if ($Mutex) {
        $Mutex.ReleaseMutex()
        $Mutex.Dispose()
        Write-Log "INFO" "MUTEX" "Lock released."
    }
    if ($null -ne $ExecutionStopwatch) {
        $ExecutionStopwatch.Stop()
        Write-Log "INFO" "TELEMETRY" "Execution finished in $($ExecutionStopwatch.ElapsedMilliseconds) ms."
    }
}
exit 0
