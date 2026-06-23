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

$InitSql | sqlite3 $DbPath

# Insert telemetry event
$InsertSql = "INSERT INTO token_usage (agent_id, prompt_tokens, completion_tokens, estimated_cost) VALUES ('$AgentId', $PromptTokens, $CompletionTokens, $EstimatedCost);"
$InsertSql | sqlite3 $DbPath

Write-Host "Telemetry logged successfully to $DbPath"
