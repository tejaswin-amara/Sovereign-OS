# run-refresh.ps1 - Parallel Library Sync & Initialization Runner (v15.0.0-CloudNative)
# Purpose: Fetches and pulls all git skill repositories in parallel, then runs the controller pipeline.

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Write-Information "[INIT]    Syncing git skill repositories in parallel..." -InformationAction Continue

$Dirs = Get-ChildItem -Path "C:\Skills" -Directory | Where-Object {
    $_.Name -notmatch "^\." -and $_.Name -ne "agent-bootstrap" -and (Test-Path "$($_.FullName)\.git")
}

$results = $Dirs | ForEach-Object -Parallel {
    $repoName = $_.Name
    $repoPath = $_.FullName
    $isShallow = Test-Path "$repoPath\.git\shallow"

    $ExitCode = 0
    try {
        if ($isShallow) {
            git -C $repoPath fetch --unshallow 2>&1 | Out-Null
        }

        git -C $repoPath pull --ff-only 2>&1 | Out-Null
        $ExitCode = $LASTEXITCODE
    } catch {
        $ExitCode = 1
    }

    [PSCustomObject]@{
        Name = $repoName
        Success = ($ExitCode -eq 0)
    }
} -ThrottleLimit 20

$UpdatedCount = @($results | Where-Object { $_.Success }).Count
$FailedCount = @($results | Where-Object { -not $_.Success }).Count

Write-Information "[SYNC]    Refresh complete. Synced: $UpdatedCount, Failed: $FailedCount" -InformationAction Continue

Write-Information "[EXEC]    Running Sovereign Master Controller..." -InformationAction Continue
pwsh -NoProfile -ExecutionPolicy Bypass -File "C:\Skills\sovereign.ps1" -ProjectPath "C:\Skills"
if ($LASTEXITCODE -ne 0) { throw "sovereign.ps1 failed with exit code $LASTEXITCODE" }
pwsh -NoProfile -ExecutionPolicy Bypass -File "C:\Skills\sovereign-check.ps1" -ProjectPath "C:\Skills"
if ($LASTEXITCODE -ne 0) { throw "sovereign-check.ps1 failed with exit code $LASTEXITCODE" }

Write-Information "[DONE]    Sovereign v15.0.0-CloudNative Online." -InformationAction Continue
