# test_all_repos.ps1
# Exhaustively tests every single parameter of the cloud integration framework across all mapped repos.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"
$SovereignRoot = $PSScriptRoot

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " INTEGRATION TEST SWEEP " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Parse config
$ConfigPath = "$SovereignRoot/sovereign.config.json"
if (-not (Test-Path $ConfigPath)) {
    Write-Host "FATAL: Config file missing." -ForegroundColor Red
    exit 1
}

$Config = Get-Content $ConfigPath | ConvertFrom-Json
$Mappings = $Config.dep_to_skill_map

# Get unique GitHub repo slugs
$UniqueRepos = @()
foreach ($Property in $Mappings.psobject.properties) {
    if ($Property.Value -notin $UniqueRepos) {
        $UniqueRepos += $Property.Value
    }
}

Write-Host "Found $($UniqueRepos.Count) unique repositories to test." -ForegroundColor Cyan

# Report generation
$ReportPath = "$SovereignRoot/integration_test_report.md"
"# Sovereign OS Integration Sweep Report`n" | Out-File -FilePath $ReportPath -Encoding utf8
"**Run Date**: $(Get-Date)`n" | Out-File -FilePath $ReportPath -Encoding utf8 -Append
"| Repository | Fetch Status | Validation Status | Parameters/Errors |" | Out-File -FilePath $ReportPath -Encoding utf8 -Append
"| --- | --- | --- | --- |" | Out-File -FilePath $ReportPath -Encoding utf8 -Append

$FailCount = 0
$SuccessCount = 0

foreach ($Repo in $UniqueRepos) {
    Write-Host "`nTesting Repository: $Repo" -ForegroundColor Yellow
    $RepoName = $Repo.Split('/')[-1]
    $CachePath = "$SovereignRoot/.cloud-cache/$RepoName"
    $FetchStatus = "FAIL"
    $ValidateStatus = "FAIL"
    $Details = ""

    # 1. Fetch
    Write-Host "  -> Fetching $Repo..."
    $FetchOutput = & pwsh -ExecutionPolicy Bypass -File "$SovereignRoot/agent-bootstrap/scripts/Fetch-CloudSkill.ps1" -Repo $Repo 2>&1
    
    if (Test-Path $CachePath) {
        $FetchStatus = "PASS"
        Write-Host "  [+] Fetch successful." -ForegroundColor Green
        
        # 2. Validate
        Write-Host "  -> Validating parameters..."
        try {
            $ValidateOutput = & pwsh -ExecutionPolicy Bypass -File "$SovereignRoot/agent-bootstrap/scripts/validate-skill.ps1" -Skill $CachePath 2>&1
            if ($LASTEXITCODE -eq 0 -or $ValidateOutput -match "validated successfully") {
                $ValidateStatus = "PASS"
                Write-Host "  [+] Validation passed." -ForegroundColor Green
                $Warnings = ($ValidateOutput | Where-Object { $_ -match "\[WARN\]" }) -join "; "
                if ($Warnings) {
                    $Details = "Warnings: $Warnings"
                } else {
                    $Details = "All params OK."
                }
            } else {
                $ValidateStatus = "FAIL"
                Write-Host "  [-] Validation failed." -ForegroundColor Red
                $Errors = ($ValidateOutput | Where-Object { $_ -match "\[ERROR\]" -or $_ -match "Exception" }) -join "; "
                $Details = "Errors: $Errors"
            }
        } catch {
            $ValidateStatus = "FAIL"
            Write-Host "  [-] Validation crashed." -ForegroundColor Red
            $Details = "Crash: $_"
        }
    } else {
        Write-Host "  [-] Fetch failed." -ForegroundColor Red
        $Details = "Fetch output: $FetchOutput"
    }

    if ($FetchStatus -eq "PASS" -and $ValidateStatus -eq "PASS") {
        $SuccessCount++
    } else {
        $FailCount++
    }

    "| $Repo | $FetchStatus | $ValidateStatus | $Details |" | Out-File -FilePath $ReportPath -Encoding utf8 -Append
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host " SWEEP COMPLETE. Passes: $SuccessCount, Fails: $FailCount" -ForegroundColor Cyan
Write-Host " Report written to: $ReportPath" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
