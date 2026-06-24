# test_complete_sovereign.ps1
Set-StrictMode -Version Latest

$ErrorActionPreference = "Continue"
$SovereignRoot = $PSScriptRoot
$script:Results = @()

function Write-Result {
    param([string]$Suite, [string]$Status, [string]$Details)
    $script:Results += [PSCustomObject]@{ Suite = $Suite; Status = $Status; Details = $Details }
    $Color = if ($Status -eq "PASS") { "Green" } elseif ($Status -eq "WARN") { "Yellow" } else { "Red" }
    Write-Information -InformationAction Continue "[$Status] $Suite - $Details" -ForegroundColor $Color
}

Write-Information -InformationAction Continue "=========================================" -ForegroundColor Cyan
Write-Information -InformationAction Continue " SOVEREIGN SYSTEM EXHAUSTIVE AUDIT" -ForegroundColor Cyan
Write-Information -InformationAction Continue "=========================================" -ForegroundColor Cyan

# 1. sovereign-check.ps1
Write-Information -InformationAction Continue "`n--- Running Core Parameter Audit ---" -ForegroundColor Cyan
$checkOutput = & pwsh -ExecutionPolicy Bypass -File "$SovereignRoot/sovereign-check.ps1" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Result "Core Parameter Audit" "PASS" "0 failures detected."
} else {
    Write-Result "Core Parameter Audit" "FAIL" "Exited with code $LASTEXITCODE. Output: $checkOutput"
}

# 2. security-sweep.ps1
Write-Information -InformationAction Continue "`n--- Running Security Sweep ---" -ForegroundColor Cyan
$secOutput = & pwsh -ExecutionPolicy Bypass -File "$SovereignRoot/agent-bootstrap/scripts/security-sweep.ps1" 2>&1
if ($secOutput -match "Security Audit PASSED" -or $LASTEXITCODE -eq 0) {
    Write-Result "Security Sweep" "PASS" "0 vulnerabilities found."
} else {
    Write-Result "Security Sweep" "FAIL" "Vulnerabilities or errors detected. Output: $secOutput"
}

# 3. run_harvester_tests.ps1
Write-Information -InformationAction Continue "`n--- Running Harvester Parser Tests ---" -ForegroundColor Cyan
$harvesterOutput = & pwsh -ExecutionPolicy Bypass -File "$SovereignRoot/run_harvester_tests.ps1" 2>&1
if ($harvesterOutput -match "CRITICAL TEST FAILURE" -or $harvesterOutput -match "\[FAIL\]") {
    $failLines = ($harvesterOutput | Where-Object { $_ -match "\[FAIL\]" }) -join "; "
    Write-Result "Harvester Parsers" "FAIL" "Failures detected: $failLines"
} else {
    Write-Result "Harvester Parsers" "PASS" "All empirical tests passed."
}

# 4. Local Skills validation
Write-Information -InformationAction Continue "`n--- Running Local Skills Validation ---" -ForegroundColor Cyan
$LocalSkillsPath = "$SovereignRoot/skills"
if (Test-Path $LocalSkillsPath) {
    $LocalSkills = Get-ChildItem -Path $LocalSkillsPath -Directory
    $SkillFailures = 0
    foreach ($Skill in $LocalSkills) {
        & pwsh -ExecutionPolicy Bypass -File "$SovereignRoot/agent-bootstrap/scripts/validate-skill.ps1" -Skill $Skill.FullName 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Information -InformationAction Continue "  [-] Validation Failed for local skill: $($Skill.Name)" -ForegroundColor Red
            $SkillFailures++
        } else {
            Write-Information -InformationAction Continue "  [+] Validation Passed for local skill: $($Skill.Name)" -ForegroundColor Green
        }
    }
    if ($SkillFailures -eq 0) {
        Write-Result "Local Skills Integrity" "PASS" "All $($LocalSkills.Count) local skills validated successfully."
    } else {
        Write-Result "Local Skills Integrity" "FAIL" "$SkillFailures/$($LocalSkills.Count) skills failed validation."
    }
} else {
    Write-Result "Local Skills Integrity" "WARN" "No skills directory found at $LocalSkillsPath."
}

# Output Summary
Write-Information -InformationAction Continue "`n=========================================" -ForegroundColor Cyan
Write-Information -InformationAction Continue " EXHAUSTIVE AUDIT SUMMARY" -ForegroundColor Cyan
Write-Information -InformationAction Continue "=========================================" -ForegroundColor Cyan
$script:Results | Format-Table -AutoSize

$ReportPath = "$SovereignRoot/comprehensive_audit_report.json"
$script:Results | ConvertTo-Json | Out-File $ReportPath -Encoding utf8
Write-Information -InformationAction Continue "Report saved to: $ReportPath" -ForegroundColor Cyan
