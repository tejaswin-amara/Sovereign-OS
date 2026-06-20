# generate-log-report.ps1 - Integrated Observability Generator (v13.2.0-CloudNative)
# Purpose: Parses sovereign-audit.jsonl to generate a structured, human-readable markdown log report.

[CmdletBinding()]
param(
    [string]$ProjectPath = "."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SovereignRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$LogDir = "$SovereignRoot/LOGS"
$AuditLogFile = "$LogDir/sovereign-audit.jsonl"
$ReportFile = "$LogDir/sovereign_log_report.md"

if (-not (Test-Path $AuditLogFile)) {
    Write-Host "Audit log file not found at $AuditLogFile"
    exit 0
}

# Read all lines from jsonl
$Lines = Get-Content $AuditLogFile -ErrorAction SilentlyContinue
if (-not $Lines) {
    Write-Host "Audit log is empty."
    exit 0
}

# Convert each line from JSON
$Entries = @()
foreach ($Line in $Lines) {
    if ([string]::IsNullOrWhiteSpace($Line)) { continue }
    try {
        $Entry = $Line | ConvertFrom-Json
        $Entries += $Entry
    } catch {}
}

if ($Entries.Count -eq 0) {
    Write-Host "No valid log entries found."
    exit 0
}

# Get latest run_id
$LatestRunId = $Entries[-1].run_id
$RunEntries = @($Entries | Where-Object { $_.run_id -eq $LatestRunId })

$Timestamp = $RunEntries[0].timestamp
$Errors = @($RunEntries | Where-Object { $_.level -eq "ERROR" })
$Warnings = @($RunEntries | Where-Object { $_.level -eq "WARN" })

$ReportMD = @"
# Sovereign Run Execution Report (Run ID: $LatestRunId)
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## 1. Execution Summary
- **Start Time**: $Timestamp
- **Run ID**: "$LatestRunId"
- **Correlation ID**: "$($RunEntries[0].correlation_id)"
- **Total Steps Logged**: $(@($RunEntries).Count)
- **Errors**: $(@($Errors).Count)
- **Warnings**: $(@($Warnings).Count)
- **Status**: $(if (@($Errors).Count -gt 0) { "❌ FAILED" } else { "✅ SUCCESS" })

"@

if (@($Errors).Count -gt 0) {
    $ReportMD += "`n## ❌ Errors`n"
    foreach ($Err in $Errors) {
        $ReportMD += "- **[$($Err.step)]**: $($Err.message)`n"
    }
}

if (@($Warnings).Count -gt 0) {
    $ReportMD += "`n## ⚠️ Warnings`n"
    foreach ($Warn in $Warnings) {
        $ReportMD += "- **[$($Warn.step)]**: $($Warn.message)`n"
    }
}

$ReportMD += "`n## 📋 Full Execution Flow`n"
$ReportMD += "| Timestamp | Level | Step | Message |`n"
$ReportMD += "| :--- | :--- | :--- | :--- |`n"
foreach ($Entry in $RunEntries) {
    $CleanMsg = $Entry.message -replace '\|', '\\|'
    $ReportMD += "| $($Entry.timestamp) | $($Entry.level) | $($Entry.step) | $CleanMsg |`n"
}

# Save report in LOGS
[System.IO.File]::WriteAllText($ReportFile, $ReportMD)

# If ProjectPath has .agents/knowledge, copy it there
$ProjKnowledge = Join-Path $ProjectPath ".agents/knowledge"
if (Test-Path $ProjKnowledge) {
    [System.IO.File]::WriteAllText((Join-Path $ProjKnowledge "sovereign_log_report.md"), $ReportMD)
}

Write-Host "Integrated Log Report generated at $ReportFile"
