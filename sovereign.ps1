# sovereign.ps1 - The Sovereign Master Controller (v18.0.0-Rulebook)
# Purpose: Single-file orchestrator. Zero unearned complexity.

[CmdletBinding()]
param(
    [string]$ProjectPath = ".",
    [switch]$UpdateLibrary = $false,
    [string]$Command = "",
    [string[]]$CommandArgs = @()
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
$Version = (Get-Content (Join-Path $SovereignRoot "VERSION") -Raw).Trim()

function Invoke-Audit {
    Write-Host "- Config exists: $(Test-Path $ConfigPath)"
    $SkillsDir = Join-Path $SovereignRoot "skills"
    $ModulesDir = Join-Path $SovereignRoot "modules"
    Write-Host "- Skills dir exists: $(Test-Path $SkillsDir)"
    Write-Host "- Modules dir exists: $(Test-Path $ModulesDir)"
    Write-Host "- Version: $Version"
    Write-Host "- Last 5 log lines:"
    $LogFiles = Get-ChildItem -Path $LogDir -Filter "sovereign-*.log" | Sort-Object LastWriteTime -Descending
    if ($LogFiles) {
        Get-Content $LogFiles[0].FullName -Tail 5 | ForEach-Object { Write-Host "  * $_" }
    }
}

function Invoke-Status {
    $SkillsDir = Join-Path $SovereignRoot "skills"
    $ModulesDir = Join-Path $SovereignRoot "modules"
    $Results = @()
    
    if (Test-Path $ModulesDir) {
        Get-ChildItem -Path $ModulesDir -Directory | ForEach-Object {
            $Path = $_.FullName
            $Health = if ((Test-Path "$Path/go.mod") -or (Test-Path "$Path/package.json") -or (Test-Path "$Path/SKILL.md") -or (Test-Path "$Path/pyproject.toml") -or (Test-Path "$Path/server.json") -or (Get-ChildItem -Path $Path -Filter "Makefile*" -ErrorAction SilentlyContinue | Select-Object -First 1)) { "Healthy" } else { "Missing Manifest" }
            $Results += [pscustomobject][ordered]@{ Name = $_.Name; Type = "Module"; Path = $Path; Health = $Health }
        }
    }
    if (Test-Path $SkillsDir) {
        Get-ChildItem -Path $SkillsDir -Directory | ForEach-Object {
            $Path = $_.FullName
            $Health = if ((Test-Path "$Path/go.mod") -or (Test-Path "$Path/package.json") -or (Test-Path "$Path/SKILL.md") -or (Test-Path "$Path/pyproject.toml") -or (Test-Path "$Path/server.json") -or (Get-ChildItem -Path $Path -Filter "Makefile*" -ErrorAction SilentlyContinue | Select-Object -First 1)) { "Healthy" } else { "Missing Manifest" }
            $Results += [pscustomobject][ordered]@{ Name = $_.Name; Type = "Skill"; Path = $Path; Health = $Health }
        }
    }
    $Results | Format-Table
}

function Invoke-Logs {
    $N = if ($CommandArgs.Count -gt 0 -and [int]::TryParse($CommandArgs[0], [ref]0)) { [int]$CommandArgs[0] } else { 20 }
    $LogFiles = Get-ChildItem -Path $LogDir -Filter "sovereign-*.log" | Sort-Object LastWriteTime -Descending
    if ($LogFiles) {
        Get-Content $LogFiles[0].FullName -Tail $N | Write-Host
    } else {
        Write-Host "No logs found."
    }
}

function Invoke-Config {
    $Config | ConvertTo-Json -Depth 10 | Write-Host
}

function Invoke-Summary {
    $LastLogTime = "N/A"
    $LogFiles = Get-ChildItem -Path $LogDir -Filter "sovereign-*.log" | Sort-Object LastWriteTime -Descending
    if ($LogFiles) { $LastLogTime = $LogFiles[0].LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss") }
    $ModCount = if ($null -ne $Config.governance.modules_count) { $Config.governance.modules_count } else { 0 }
    $SkillCount = if ($null -ne $Config.governance.skills_count) { $Config.governance.skills_count } else { 0 }
    Write-Host "Sovereign $Version | Modules: $ModCount | Skills: $SkillCount | Last Log: $LastLogTime"
}

function Invoke-Help {
    $HelpData = @(
        [pscustomobject][ordered]@{ Command = "audit"; Description = "Checks core directories and displays last 5 log lines" }
        [pscustomobject][ordered]@{ Command = "status"; Description = "Checks health of all skills and modules" }
        [pscustomobject][ordered]@{ Command = "logs [N]"; Description = "Tail last N (default 20) lines from the newest log file" }
        [pscustomobject][ordered]@{ Command = "config"; Description = "Displays sovereign.config.json" }
        [pscustomobject][ordered]@{ Command = "summary"; Description = "One-line summary of system state" }
        [pscustomobject][ordered]@{ Command = "run"; Description = "Run standard orchestration (acquires mutex)" }
        [pscustomobject][ordered]@{ Command = "help"; Description = "Shows this list" }
    )
    $HelpData | Format-Table
    Write-Host "Agent Commands (handled by AI agent, not this script): build, test, fix, scan, deploy, docs, workflow, step, halt, rule, format"
}

function Invoke-RunOrchestration {
    # 2. MUTEX LOCK (Platform-aware namespace: Global\ on Windows, un-prefixed on non-Windows)
    $IsWindowsOS = if (Test-Path variable:IsWindows) { $IsWindows } else { ($env:OS -like "*Windows*") -or ([Environment]::OSVersion.Platform -eq "Win32NT") }
    $MutexName = if ($IsWindowsOS) { "Global\SovereignOSLock" } else { "SovereignOSLock" }
    $script:Mutex = New-Object System.Threading.Mutex($false, $MutexName)
    $script:MutexAcquired = $false

    try {
        try {
            $script:MutexAcquired = $script:Mutex.WaitOne($Config.governance.lock_timeout_seconds * 1000, $false)
        } catch {
            $script:MutexAcquired = $false
        }

        if (-not $script:MutexAcquired) {
            Write-Log "ERROR" "MUTEX" "Could not acquire OS lock. Another instance is running."
            exit 1
        }

        $script:ExecutionStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
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
        if ($script:Mutex) {
            if ($script:MutexAcquired) {
                $script:Mutex.ReleaseMutex()
                Write-Log "INFO" "MUTEX" "Lock released."
            }
            $script:Mutex.Dispose()
        }
        if ($null -ne $script:ExecutionStopwatch) {
            $script:ExecutionStopwatch.Stop()
            Write-Log "INFO" "TELEMETRY" "Execution finished in $($script:ExecutionStopwatch.ElapsedMilliseconds) ms."
        }
    }
}

if ($Command -eq "" -or $Command -eq "run") {
    Invoke-RunOrchestration
} else {
    switch ($Command) {
        "audit"   { Invoke-Audit }
        "status"  { Invoke-Status }
        "logs"    { Invoke-Logs }
        "config"  { Invoke-Config }
        "summary" { Invoke-Summary }
        "help"    { Invoke-Help }
        default   { Write-Host "Unknown command: $Command"; Invoke-Help; exit 1 }
    }
}
exit 0
