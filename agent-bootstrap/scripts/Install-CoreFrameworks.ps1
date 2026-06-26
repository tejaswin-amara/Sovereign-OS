[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$CoreDir = "C:\Skills\core-frameworks"

if (-not (Test-Path $CoreDir)) {
    New-Item -Path $CoreDir -ItemType Directory -Force | Out-Null
    Write-Host "[INIT] Created persistent framework directory: $CoreDir" -ForegroundColor Cyan
}

$CoreRepos = @(
    "https://github.com/langchain-ai/langgraph",
    "https://github.com/crewAIInc/crewAI",
    "https://github.com/browser-use/browser-use",
    "https://github.com/jina-ai/reader",
    "https://github.com/Aider-AI/aider"
)

foreach ($Url in $CoreRepos) {
    $RepoName = ($Url -split "/")[-1]
    $TargetPath = Join-Path $CoreDir $RepoName

    if (Test-Path $TargetPath) {
        Write-Host "[SKIP] $RepoName is already installed in persistent cache." -ForegroundColor Yellow
        continue
    }

    Write-Host "[FETCH] Permanently mounting '$RepoName'..." -ForegroundColor Cyan
    try {
        $proc = Start-Process -FilePath "git" -ArgumentList "clone -c protocol.file.allow=never -c core.hooksPath=/dev/null --filter=blob:none --depth 1 $Url $TargetPath" -PassThru -NoNewWindow
        if (-not $proc.WaitForExit(300000)) {
            $proc.Kill()
            throw "Git clone timed out."
        }
        if ($proc.ExitCode -ne 0) { throw "Git clone failed with exit code $($proc.ExitCode)" }
        
        Write-Host "[SUCCESS] $RepoName permanently secured at: $TargetPath" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to fetch '$RepoName'. $_" -ForegroundColor Red
    }
}
