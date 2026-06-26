[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Repo
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$SovereignPath = (Resolve-Path "$PSScriptRoot/../..").Path
Import-Module "$SovereignPath/agent-bootstrap/scripts/helpers.psm1" -Force -DisableNameChecking

# Parse repo input (e.g. "microsoft/SkillOpt" or "https://github.com/microsoft/SkillOpt")
$CleanRepo = $Repo -replace "https://github.com/", ""
if ($CleanRepo -notmatch '^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$') {
    throw "Invalid repo format. Use 'org/repo' or 'https://github.com/org/repo'"
}

$RepoParts = $CleanRepo -split "/"
if ($RepoParts[0] -eq "." -or $RepoParts[0] -eq ".." -or $RepoParts[1] -eq "." -or $RepoParts[1] -eq "..") {
    throw "Invalid repo format. Directory traversal is forbidden."
}
$RepoName = $RepoParts[-1]
$TargetUrl = "https://github.com/$CleanRepo"

$ConfigCache = Get-SovereignConfig -KeyPath "governance.cloud_cache_dir"
$CacheDir = if ($ConfigCache) { $ConfigCache } else { "C:\Skills\.cloud-cache" }
$TargetPath = Join-Path $CacheDir $RepoName

if (-not (Test-Path $CacheDir)) {
    New-Item -Path $CacheDir -ItemType Directory -Force | Out-Null
}

$HashFile = Join-Path $TargetPath ".commit_hash"
$CurrentHash = if (Test-Path $HashFile) { Get-Content $HashFile } else { $null }

try {
    # Check if remote has changed
    $RemoteHead = git ls-remote $TargetUrl HEAD 2>&1 | Select-String -Pattern "^([a-f0-9]+)\s+HEAD"
    $LatestHash = if ($RemoteHead) { $RemoteHead.Matches.Groups[1].Value } else { $null }
} catch {
    $LatestHash = $null
}

if (Test-Path $TargetPath) {
    if ($LatestHash -and $CurrentHash -and $LatestHash -eq $CurrentHash) {
        Write-Host "[CACHE HIT] '$RepoName' is up-to-date at $LatestHash" -ForegroundColor Green
        return
    } else {
        Write-Host "[CACHE STALE] '$RepoName' has updates. Evicting old cache..." -ForegroundColor Yellow
        Remove-Item -Path $TargetPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "[FETCH] Mounting '$RepoName' via JIT Cloud Fetch..." -ForegroundColor Cyan
try {
    # Blobless shallow clone for lightning fast fetching with security config parameters
    $timeoutSeconds = 60
    $proc = Start-Process -FilePath "git" -ArgumentList "clone -c protocol.file.allow=never -c core.hooksPath=/dev/null --filter=blob:none --depth 1 $TargetUrl $TargetPath" -PassThru -NoNewWindow
    if (-not $proc.WaitForExit($timeoutSeconds * 1000)) {
        $proc.Kill()
        throw "Git clone timed out after $timeoutSeconds seconds"
    }
    if ($proc.ExitCode -ne 0) { throw "Git clone failed with exit code $($proc.ExitCode)" }
    
    # Immediately drop the massive .git folder to save context space
    $GitFolder = Join-Path $TargetPath ".git"
    if (Test-Path $GitFolder) {
        Remove-Item -Path $GitFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    if ($LatestHash) {
        Set-Content -Path $HashFile -Value $LatestHash
    }
    
    Write-Host "[SUCCESS] Skill '$RepoName' is ready at: $TargetPath" -ForegroundColor Green
} catch {
    throw "Failed to fetch '$RepoName'. Verify the URL. $_"
}
