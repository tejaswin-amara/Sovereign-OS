param(
    [Parameter(Mandatory=$true)]
    [string]$AgentId,

    [Parameter(Mandatory=$true)]
    [int]$PromptTokens,

    [Parameter(Mandatory=$true)]
    [int]$CompletionTokens,

    [Parameter(Mandatory=$true)]
    [decimal]$EstimatedCost
)

Set-StrictMode -Version Latest

$LogsDir = "C:\Skills\LOGS"
if (-Not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir | Out-Null
}

$DbPath = Join-Path $LogsDir "telemetry.db"

# Initialize DB if it doesn't exist
$InitSql = @"
CREATE TABLE IF NOT EXISTS token_usage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    agent_id TEXT NOT NULL,
    prompt_tokens INTEGER NOT NULL,
    completion_tokens INTEGER NOT NULL,
    estimated_cost REAL NOT NULL
);
"@

if (Get-Command sqlite3 -ErrorAction SilentlyContinue) {
    $InitSql | sqlite3 $DbPath
    $InsertSql | sqlite3 $DbPath
    Write-Information "Telemetry logged successfully to SQLite ($DbPath)" -InformationAction Continue
} else {
    $CsvPath = Join-Path $LogsDir "telemetry.csv"
    if (-Not (Test-Path $CsvPath)) {
        "timestamp,agent_id,prompt_tokens,completion_tokens,estimated_cost" | Out-File $CsvPath -Encoding utf8
    }
    $Date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$Date,$AgentId,$PromptTokens,$CompletionTokens,$EstimatedCost" | Out-File $CsvPath -Append -Encoding utf8
    Write-Information "Telemetry logged successfully to CSV Fallback ($CsvPath)" -InformationAction Continue
}
