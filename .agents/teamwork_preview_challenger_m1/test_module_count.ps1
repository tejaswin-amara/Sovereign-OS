# test_module_count.ps1 - Dynamic Module Count Verification

$SovereignRoot = "C:\Skills"
$ScriptPath = Join-Path $SovereignRoot "sovereign.ps1"
$ModulesDir = Join-Path $SovereignRoot "modules"

Write-Host "=================================================="
Write-Host "TEST 3.1: Module Count Baseline Verification"
Write-Host "=================================================="

$ActualDirs = Get-ChildItem -Path $ModulesDir -Directory
Write-Host "Actual Module Directories on Disk ($($ActualDirs.Count)):"
foreach ($d in $ActualDirs) {
    Write-Host " - $($d.Name)"
}

$Output = powershell.exe -ExecutionPolicy Bypass -File $ScriptPath
Write-Host "`nSovereign.ps1 Output:"
$Output | ForEach-Object { Write-Host "  $_" }

$Match = $Output | Select-String "Module count: (\d+)"
if ($Match) {
    $ReportedCount = [int]$Match.Matches[0].Groups[1].Value
    Write-Host "`nReported Module Count: $ReportedCount"
    if ($ReportedCount -eq $ActualDirs.Count) {
        Write-Host "RESULT: PASS (Reported count $ReportedCount matches disk count $($ActualDirs.Count))"
    } else {
        Write-Host "RESULT: FAIL (Reported count $ReportedCount != disk count $($ActualDirs.Count))"
    }
} else {
    Write-Host "RESULT: FAIL (Could not parse module count from output)"
}

Write-Host "`n=================================================="
Write-Host "TEST 3.2: Dynamic Addition of Module Directory"
Write-Host "=================================================="

$TempModDir = Join-Path $ModulesDir "_temp_test_module_m1"
New-Item -Path $TempModDir -ItemType Directory -Force | Out-Null
Write-Host "Created temporary directory: $TempModDir"

try {
    $ActualDirsTemp = (Get-ChildItem -Path $ModulesDir -Directory).Count
    $OutputTemp = powershell.exe -ExecutionPolicy Bypass -File $ScriptPath
    $MatchTemp = $OutputTemp | Select-String "Module count: (\d+)"
    if ($MatchTemp) {
        $ReportedCountTemp = [int]$MatchTemp.Matches[0].Groups[1].Value
        Write-Host "Reported Module Count with Temp Dir: $ReportedCountTemp (Disk: $ActualDirsTemp)"
        if ($ReportedCountTemp -eq $ActualDirsTemp) {
            Write-Host "RESULT: PASS (Dynamic module detection confirmed)"
        } else {
            Write-Host "RESULT: FAIL (Expected $ActualDirsTemp, got $ReportedCountTemp)"
        }
    }
} finally {
    Remove-Item -Path $TempModDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleaned up temporary directory."
}

Write-Host "`n=================================================="
Write-Host "TEST 3.3: Non-Directory File Exclusion Test"
Write-Host "=================================================="

$TempFile = Join-Path $ModulesDir "_temp_file.txt"
Set-Content -Path $TempFile -Value "Test file, should not count as module"
Write-Host "Created temporary file in modules/: $TempFile"

try {
    $ActualDirsFileTest = (Get-ChildItem -Path $ModulesDir -Directory).Count
    $OutputFileTest = powershell.exe -ExecutionPolicy Bypass -File $ScriptPath
    $MatchFileTest = $OutputFileTest | Select-String "Module count: (\d+)"
    if ($MatchFileTest) {
        $ReportedCountFileTest = [int]$MatchFileTest.Matches[0].Groups[1].Value
        Write-Host "Reported Module Count with extra file: $ReportedCountFileTest (Disk directories: $ActualDirsFileTest)"
        if ($ReportedCountFileTest -eq $ActualDirsFileTest) {
            Write-Host "RESULT: PASS (Files are properly ignored, only directories counted)"
        } else {
            Write-Host "RESULT: FAIL (Files erroneously included in module count)"
        }
    }
} finally {
    Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
    Write-Host "Cleaned up temporary file."
}
