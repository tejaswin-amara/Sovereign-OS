# C:/Skills/agent-bootstrap/scripts/helpers/Logging.ps1

if (-not (Get-Variable -Name "SovereignLogDir" -Scope "Script" -ErrorAction SilentlyContinue)) {
    $script:SovereignLogDir = "$PSScriptRoot/../../../LOGS"
}
if (-not (Get-Variable -Name "RunID" -Scope "Script" -ErrorAction SilentlyContinue)) {
    $script:RunID = [guid]::NewGuid().ToString().Substring(0,8)
}
if (-not (Get-Variable -Name "CorrelationID" -Scope "Script" -ErrorAction SilentlyContinue)) {
    $script:CorrelationID = [guid]::NewGuid().ToString().Substring(0,8)
}

# In-memory batch queue to prevent severe Disk I/O bottlenecks
$global:SovereignLogBatch = [System.Collections.Generic.List[string]]::new()
$global:SovereignLogFlushThreshold = 50

function Set-SovereignLogContext {
    [CmdletBinding()]
    param([string]$LogDir, [string]$RunId, [string]$CorrId)
    if ($LogDir) { $script:SovereignLogDir = $LogDir }
    if ($RunId) { $script:RunID = $RunId }
    if ($CorrId) { $script:CorrelationID = $CorrId }
}

function Flush-SovereignLogs {
    if ($global:SovereignLogBatch.Count -gt 0) {
        if (-not (Test-Path $script:SovereignLogDir)) { 
            New-Item -Path $script:SovereignLogDir -ItemType Directory -Force | Out-Null 
        }
        $LogPath = "$($script:SovereignLogDir)/sovereign-audit.jsonl"
        $BatchedLogs = ($global:SovereignLogBatch -join "`n") + "`n"
        [System.IO.File]::AppendAllText($LogPath, $BatchedLogs, [System.Text.Encoding]::UTF8)
        $global:SovereignLogBatch.Clear()
    }
}

function Write-SovereignLog {
    [CmdletBinding()]
    param([string]$Level, [string]$Step, [string]$Message)
    
    # Sanitize sensitive absolute paths in messages
    $SanitizedMessage = $Message
    if ($SanitizedMessage) {
        $SkillsRootPath = $PSScriptRoot.Replace("\", "/").Replace("/agent-bootstrap/scripts/helpers", "")
        $SkillsRootEscaped = [regex]::Escape($SkillsRootPath)
        $UserHomeEscaped = [regex]::Escape($env:USERPROFILE.Replace("\", "/"))
        
        $TempMsg = $SanitizedMessage.Replace("\", "/")
        $TempMsg = [regex]::Replace($TempMsg, "(?i)$SkillsRootEscaped", "<SkillsRoot>")
        $TempMsg = [regex]::Replace($TempMsg, "(?i)$UserHomeEscaped", "<UserHome>")
        # Fix log corruption: only redact actual windows paths, not SHA256 hashes
        $TempMsg = [regex]::Replace($TempMsg, "(?i)\b[a-z]:[/\\](?:[\w\.\-]+[/\\]?)+", "<DrivePath>")
        $SanitizedMessage = $TempMsg
    }

    $LogEntry = @{
        timestamp = Get-Date -Format "o"
        run_id = $script:RunID
        correlation_id = $script:CorrelationID
        level = $Level
        step = $Step
        message = $SanitizedMessage
    } | ConvertTo-Json -Compress
    
    # Add to batch
    $global:SovereignLogBatch.Add($LogEntry)
    if ($global:SovereignLogBatch.Count -ge $global:SovereignLogFlushThreshold) {
        Flush-SovereignLogs
    }
    
    $TimeStamp = Get-Date -Format "HH:mm:ss"
    $PaddedStep = $Step.PadRight(16).Substring(0, 16)
    $LineText = "[$TimeStamp] $PaddedStep $SanitizedMessage"
    switch ($Level) {
        "ERROR" { [Console]::Error.WriteLine($LineText) }
        "WARN"  { [Console]::Error.WriteLine($LineText) }
        "INFO"  { Write-Host $LineText -ForegroundColor Cyan }
        default { Write-Host $LineText -ForegroundColor DarkGray }
    }
}

function Start-LogRotation {
    [CmdletBinding()]
    param(
        [string]$LogDir = "$PSScriptRoot/../../../LOGS",
        [int]$MaxAgeDays = 0,
        [long]$MaxSizeBytes = 0
    )

    if ($MaxAgeDays -le 0) {
        $ConfigAge = Get-SovereignConfig -KeyPath "governance.log_retention_days"
        $MaxAgeDays = if ($ConfigAge) { [int]$ConfigAge } else { 7 }
    }
    if ($MaxSizeBytes -le 0) {
        $ConfigSizeMB = Get-SovereignConfig -KeyPath "governance.log_max_size_mb"
        $MaxSizeBytes = if ($ConfigSizeMB) { [long]([int]$ConfigSizeMB * 1MB) } else { 10MB }
    }

    $LimitDate = (Get-Date).AddDays(-$MaxAgeDays)
    Get-ChildItem $LogDir -Filter "*.jsonl" -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $LimitDate } |
    ForEach-Object {
        Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
    }

    $AuditLog = Join-Path $LogDir "sovereign-audit.jsonl"
    if (Test-Path $AuditLog) {
        $File = Get-Item $AuditLog
        if ($File.Length -gt $MaxSizeBytes) {
            for ($i = 4; $i -ge 1; $i--) {
                $OldLog = Join-Path $LogDir "sovereign-audit.$i.jsonl"
                $NewLog = Join-Path $LogDir "sovereign-audit.$($i+1).jsonl"
                if (Test-Path $OldLog) {
                    Move-Item $OldLog $NewLog -Force -ErrorAction SilentlyContinue
                }
            }
            $RotatedLog = Join-Path $LogDir "sovereign-audit.1.jsonl"
            Move-Item $AuditLog $RotatedLog -Force -ErrorAction SilentlyContinue
        }
    }
}
