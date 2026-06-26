[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$CoreDir = "C:\Skills\core-frameworks"

if (-not (Test-Path $CoreDir)) {
    Write-Host "[ERROR] Core framework directory not found: $CoreDir" -ForegroundColor Red
    exit 1
}

$Repos = Get-ChildItem -Path $CoreDir -Directory

if ($Repos.Count -eq 0) {
    Write-Host "[WARNING] No repositories found in $CoreDir to update." -ForegroundColor Yellow
    exit 0
}

Write-Host "Starting automated sync for $($Repos.Count) repositories..." -ForegroundColor Cyan

foreach ($Repo in $Repos) {
    $RepoName = $Repo.Name
    $RepoPath = $Repo.FullName

    # Verify it is actually a git repository
    if (-not (Test-Path (Join-Path $RepoPath ".git"))) {
        Write-Host "[SKIP] $RepoName is not a git repository." -ForegroundColor Yellow
        continue
    }

    Write-Host "[UPDATE] Synchronizing '$RepoName'..." -ForegroundColor Cyan
    
    try {
        # Using Start-Process to ensure we capture exit codes correctly and handle potential hangs
        $proc = Start-Process -FilePath "git" -ArgumentList "-C `"$RepoPath`" pull --rebase" -PassThru -NoNewWindow -Wait
        
        if ($proc.ExitCode -eq 0) {
            Write-Host "[SUCCESS] $RepoName is fully synced and up-to-date." -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Failed to update '$RepoName'. Exit Code: $($proc.ExitCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "[ERROR] Exception updating '$RepoName': $_" -ForegroundColor Red
    }
}

Write-Host "Sync cycle complete." -ForegroundColor Green
