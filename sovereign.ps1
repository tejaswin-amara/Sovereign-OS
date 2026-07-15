# sovereign.ps1 - The Sovereign Master Controller (v15.0.2-Pure)
# Purpose: Single-file orchestrator. Zero external script dependencies.

[CmdletBinding()]
param(
    [string]$ProjectPath = ".",
    [switch]$UpdateLibrary = $false
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$SovereignRoot = $PSScriptRoot
$LockFile = "$SovereignRoot/.sovereign.lock"
$LogDir = "$SovereignRoot/LOGS"

if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }
$RunID = [guid]::NewGuid().ToString().Substring(0,8)

function Write-Log {
    param([string]$Level, [string]$Step, [string]$Message)
    $Timestamp = Get-Date -Format "HH:mm:ss"
    $Line = "[$Timestamp] [$Level] [$Step] $Message"
    Write-Host $Line
    Add-Content -Path "$LogDir/sovereign-$([datetime]::Now.ToString('yyyyMMdd')).log" -Value $Line
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
    Write-Log "ERROR" "INIT" "Config missing."
    exit 1
}
$Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

# 2. VERSION CHECK
$Version = Get-Content "$SovereignRoot/VERSION" -Raw
$Version = $Version.Trim()
if ($Config.version -ne $Version) {
    Write-Log "WARN" "INIT" "Version drift. Config has $($Config.version), aligning to $Version."
}

# 3. MUTEX LOCK
$MutexName = "Global\SovereignOSLock"
$Mutex = New-Object System.Threading.Mutex($false, $MutexName)
if (-not $Mutex.WaitOne(5000, $false)) {
    Write-Log "ERROR" "MUTEX" "Could not acquire OS lock. Another instance is running."
    exit 1
}

try {
    $ExecutionStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Log "INFO" "MUTEX" "OS-Level Lock Acquired."

    # 4. SKILL COUNT
    $DynamicCount = (Get-ChildItem -Path "$SovereignRoot/skills" -Directory).Count
    Write-Log "INFO" "INIT" "Dynamic skill count: $DynamicCount"
    
    if ($Config.governance.skills_count -ne $DynamicCount) {
        $Config.governance.skills_count = $DynamicCount
        Save-Atomic -Path $ConfigPath -Content ($Config | ConvertTo-Json -Depth 10)
    }

    # 5. GENERATE CORE MD
    $TemplatePath = "$SovereignRoot/SOVEREIGN_CORE.template.md"
    $CoreOutputPath = "$SovereignRoot/SOVEREIGN_CORE.md"
    if (Test-Path $TemplatePath) {
        $TemplateContent = Get-Content $TemplatePath -Raw
        $Timestamp = Get-Date -Format "o"
        $CoreContent = $TemplateContent -replace '\{\{SKILL_COUNT\}\}', $DynamicCount -replace '\{\{VERSION\}\}', $Version -replace '\{\{TIMESTAMP\}\}', $Timestamp
        Save-Atomic -Path $CoreOutputPath -Content $CoreContent
        Write-Log "INFO" "CORE_GEN" "Generated SOVEREIGN_CORE.md"
    }

    # 6. GC CLOUD CACHE
    $CloudCacheDir = "$SovereignRoot/.cloud-cache"
    if (Test-Path $CloudCacheDir) {
        Remove-Item -Path $CloudCacheDir -Recurse -Force -ErrorAction SilentlyContinue
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
