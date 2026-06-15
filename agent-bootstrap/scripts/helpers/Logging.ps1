# D:/Skills/agent-bootstrap/scripts/helpers/Logging.ps1

$script:SovereignLogDir = $null
$script:RunID = $null
$script:CorrelationID = $null

if (-not $script:SovereignLogDir) { $script:SovereignLogDir = "$PSScriptRoot/../../../LOGS" }
if (-not $script:RunID) { $script:RunID = [guid]::NewGuid().ToString().Substring(0,8) }
if (-not $script:CorrelationID) { $script:CorrelationID = [guid]::NewGuid().ToString().Substring(0,8) }

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
    
    $LogEntry = @{
        timestamp = Get-Date -Format "o"
        run_id = $script:RunID
        correlation_id = $script:CorrelationID
        level = $Level
        step = $Step
        message = $Message
    } | ConvertTo-Json -Compress
    $LogEntry | Out-File -FilePath "$($script:SovereignLogDir)/sovereign-audit.jsonl" -Append -Encoding UTF8
    
    $TimeStamp = Get-Date -Format "HH:mm:ss"
    $PaddedStep = $Step.PadRight(8).Substring(0, 8)
    $LineText = "[$TimeStamp] $PaddedStep $Message"
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

    Get-ChildItem $LogDir -Filter "*.jsonl" -ErrorAction SilentlyContinue |
    Where-Object {
        ($_.LastWriteTime -lt (Get-Date).AddDays(-$MaxAgeDays)) -or
        ($_.Length -gt $MaxSizeBytes)
    } |
    ForEach-Object {
        Write-SovereignLog -Level "INFO" -Step "LOG_ROTATION" -Message "Deleting (retention policy): $($_.Name)"
        Remove-Item $_.FullName -Force
    }
}
