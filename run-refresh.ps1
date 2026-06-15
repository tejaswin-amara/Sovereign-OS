# run-refresh.ps1 - Parallel Library Sync & Initialization Runner (v13.2.0-CloudNative)
# Purpose: Fetches and pulls all git skill repositories in parallel, then runs the controller pipeline.

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Write-Host "[INIT]    Syncing git skill repositories in parallel..." -ForegroundColor Cyan

$Dirs = Get-ChildItem -Path "D:\Skills" -Directory | Where-Object { 
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
        
        $PullOutput = git -C $repoPath pull --ff-only 2>&1
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

Write-Host "[SYNC]    Refresh complete. Synced: $UpdatedCount, Failed: $FailedCount" -ForegroundColor Cyan

Write-Host "[EXEC]    Running Sovereign Master Controller..." -ForegroundColor Cyan
pwsh -NoProfile -ExecutionPolicy Bypass -File "D:\Skills\sovereign.ps1" -ProjectPath "D:\Skills"
if ($LASTEXITCODE -ne 0) { throw "sovereign.ps1 failed with exit code $LASTEXITCODE" }
pwsh -NoProfile -ExecutionPolicy Bypass -File "D:\Skills\sovereign-check.ps1" -ProjectPath "D:\Skills"
if ($LASTEXITCODE -ne 0) { throw "sovereign-check.ps1 failed with exit code $LASTEXITCODE" }

Write-Host "[DONE]    Sovereign v13.2.0-CloudNative Online." -ForegroundColor Cyan
