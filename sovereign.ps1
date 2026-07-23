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

$LogDir = $null
$Mutex = $null
$MutexAcquired = $false
$ExecutionStopwatch = $null

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
    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Temp, $Content, $Utf8NoBom)
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

# 2. MUTEX LOCK (Platform-aware namespace: Global\ on Windows, un-prefixed on non-Windows)
$IsWindowsOS = if (Test-Path variable:IsWindows) { $IsWindows } else { ($env:OS -like "*Windows*") -or ([Environment]::OSVersion.Platform -eq "Win32NT") }
$MutexName = if ($IsWindowsOS) { "Global\SovereignOSLock" } else { "SovereignOSLock" }
$Mutex = New-Object System.Threading.Mutex($false, $MutexName)
$MutexAcquired = $false

try {
    try {
        $MutexAcquired = $Mutex.WaitOne($Config.governance.lock_timeout_seconds * 1000, $false)
    } catch {
        $MutexAcquired = $false
    }

    if (-not $MutexAcquired) {
        Write-Log "ERROR" "MUTEX" "Could not acquire OS lock. Another instance is running."
        exit 1
    }

    $ExecutionStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Log "INFO" "MUTEX" "OS-Level Lock Acquired."

    # 3. VERIFY CORE STRUCTURE
    $SkillsDir = Join-Path $SovereignRoot "skills"
    $ModulesDir = Join-Path $SovereignRoot "modules"
    
    if (-not (Test-Path $SkillsDir)) { New-Item -Path $SkillsDir -ItemType Directory | Out-Null }
    if (-not (Test-Path $ModulesDir)) { New-Item -Path $ModulesDir -ItemType Directory | Out-Null }

    # 4. SKILL & MODULE COUNT (Filter to directories containing valid manifests: go.mod, package.json, or SKILL.md)
    $DynamicSkillDirs = Get-ChildItem -Path $SkillsDir -Directory | Where-Object {
        (Test-Path (Join-Path $_.FullName "SKILL.md")) -or
        (Test-Path (Join-Path $_.FullName "package.json")) -or
        (Test-Path (Join-Path $_.FullName "go.mod")) -or
        (Get-ChildItem -Path $_.FullName -Recurse -Include "SKILL.md","package.json","go.mod" -ErrorAction SilentlyContinue | Select-Object -First 1)
    }
    $DynamicSkillCount = @($DynamicSkillDirs).Count

    $DynamicModuleDirs = Get-ChildItem -Path $ModulesDir -Directory | Where-Object {
        (Test-Path (Join-Path $_.FullName "go.mod")) -or
        (Test-Path (Join-Path $_.FullName "package.json")) -or
        (Test-Path (Join-Path $_.FullName "SKILL.md")) -or
        (Get-ChildItem -Path $_.FullName -Recurse -Include "go.mod","package.json","SKILL.md" -ErrorAction SilentlyContinue | Select-Object -First 1)
    }
    $DynamicModuleCount = @($DynamicModuleDirs).Count

    Write-Log "INFO" "INIT" "Dynamic skill count: $DynamicSkillCount, Module count: $DynamicModuleCount"
    
    $SaveNeeded = $false
    if ($Config.governance.skills_count -ne $DynamicSkillCount) {
        $Config.governance.skills_count = $DynamicSkillCount
        $SaveNeeded = $true
    }
    if ($null -ne $Config.governance.modules_count -and $Config.governance.modules_count -ne $DynamicModuleCount) {
        $Config.governance.modules_count = $DynamicModuleCount
        $SaveNeeded = $true
    }
    if ($SaveNeeded) {
        Save-Atomic -Path $ConfigPath -Content ($Config | ConvertTo-Json -Depth 10)
    }

    Write-Log "INFO" "COMPLETE" "ALL PHASES PASSED"

} catch {
    Write-Log "ERROR" "EXEC" "Fatal error: $($_.Exception.Message)"
    exit 1
} finally {
    if ($Mutex) {
        if ($MutexAcquired) {
            $Mutex.ReleaseMutex()
            Write-Log "INFO" "MUTEX" "Lock released."
        }
        $Mutex.Dispose()
    }
    if ($null -ne $ExecutionStopwatch) {
        $ExecutionStopwatch.Stop()
        Write-Log "INFO" "TELEMETRY" "Execution finished in $($ExecutionStopwatch.ElapsedMilliseconds) ms."
    }
}
exit 0
