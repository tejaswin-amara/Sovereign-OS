[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Repo
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$SovereignPath = "D:/Skills"
Import-Module "$SovereignPath/agent-bootstrap/scripts/helpers.psm1" -Force -DisableNameChecking

# Parse repo input (e.g. "microsoft/SkillOpt" or "https://github.com/microsoft/SkillOpt")
$CleanRepo = $Repo -replace "https://github.com/", ""
if ($CleanRepo -notmatch '^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$') {
    throw "Invalid repo format. Use 'org/repo' or 'https://github.com/org/repo'"
}

$RepoParts = $CleanRepo -split "/"
$RepoName = $RepoParts[-1]
$TargetUrl = "https://github.com/$CleanRepo"

$ConfigCache = Get-SovereignConfig -KeyPath "governance.cloud_cache_dir"
$CacheDir = if ($ConfigCache) { $ConfigCache } else { "D:\Skills\.cloud-cache" }
$TargetPath = Join-Path $CacheDir $RepoName

if (-not (Test-Path $CacheDir)) {
    New-Item -Path $CacheDir -ItemType Directory -Force | Out-Null
}

if (Test-Path $TargetPath) {
    Write-Host "[CACHE HIT] '$RepoName' is already mounted in $TargetPath" -ForegroundColor Green
    return
}

Write-Host "[FETCH] Mounting '$RepoName' via JIT Cloud Fetch..." -ForegroundColor Cyan
try {
    # Blobless shallow clone for lightning fast fetching
    git clone --filter=blob:none --depth 1 $TargetUrl $TargetPath 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Git clone failed with exit code $LASTEXITCODE" }
    
    # Immediately drop the massive .git folder to save context space
    $GitFolder = Join-Path $TargetPath ".git"
    if (Test-Path $GitFolder) {
        Remove-Item -Path $GitFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "[SUCCESS] Skill '$RepoName' is ready at: $TargetPath" -ForegroundColor Green
} catch {
    throw "Failed to fetch '$RepoName'. Verify the URL. $_"
}
