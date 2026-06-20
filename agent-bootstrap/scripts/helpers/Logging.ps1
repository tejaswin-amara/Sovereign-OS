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

function Set-SovereignLogContext {
    [CmdletBinding()]
    param([string]$LogDir, [string]$RunId, [string]$CorrId)
    if ($LogDir) { $script:SovereignLogDir = $LogDir }
    if ($RunId) { $script:RunID = $RunId }
    if ($CorrId) { $script:CorrelationID = $CorrId }
}

function Write-SovereignLog {
    [CmdletBinding()]
    param([string]$Level, [string]$Step, [string]$Message)
    
    # Ensure log directory exists
    if (-not (Test-Path $script:SovereignLogDir)) { 
        New-Item -Path $script:SovereignLogDir -ItemType Directory -Force | Out-Null 
    }
    
    # Sanitize sensitive absolute paths in messages
    $SanitizedMessage = $Message
    if ($SanitizedMessage) {
        $SkillsRootPath = $PSScriptRoot.Replace("\", "/").Replace("/agent-bootstrap/scripts/helpers", "")
        $SkillsRootEscaped = [regex]::Escape($SkillsRootPath)
        $UserHomeEscaped = [regex]::Escape($env:USERPROFILE.Replace("\", "/"))
        
        $TempMsg = $SanitizedMessage.Replace("\", "/")
        $TempMsg = [regex]::Replace($TempMsg, "(?i)$SkillsRootEscaped", "<SkillsRoot>")
        $TempMsg = [regex]::Replace($TempMsg, "(?i)$UserHomeEscaped", "<UserHome>")
        $TempMsg = [regex]::Replace($TempMsg, "(?i)[a-zA-Z]:/", "<Drive>/")
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
    $LogEntry | Out-File -FilePath "$($script:SovereignLogDir)/sovereign-audit.jsonl" -Append -Encoding UTF8
    
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

    # Delete older log files based on retention policy
    $LimitDate = (Get-Date).AddDays(-$MaxAgeDays)
    Get-ChildItem $LogDir -Filter "*.jsonl" -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $LimitDate } |
    ForEach-Object {
        Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
    }

    # Atomic rolling log rotation for active audit log
    $AuditLog = Join-Path $LogDir "sovereign-audit.jsonl"
    if (Test-Path $AuditLog) {
        $File = Get-Item $AuditLog
        if ($File.Length -gt $MaxSizeBytes) {
            # Shift existing rotated logs (keep up to 5 history files: .1 to .5)
            for ($i = 4; $i -ge 1; $i--) {
                $OldLog = Join-Path $LogDir "sovereign-audit.$i.jsonl"
                $NewLog = Join-Path $LogDir "sovereign-audit.$($i+1).jsonl"
                if (Test-Path $OldLog) {
                    Move-Item $OldLog $NewLog -Force -ErrorAction SilentlyContinue
                }
            }
            # Move active log to .1
            $RotatedLog = Join-Path $LogDir "sovereign-audit.1.jsonl"
            Move-Item $AuditLog $RotatedLog -Force -ErrorAction SilentlyContinue
        }
    }
}
