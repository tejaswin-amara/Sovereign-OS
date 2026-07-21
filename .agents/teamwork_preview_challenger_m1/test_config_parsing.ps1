# test_config_parsing.ps1 - Empirical Config Parsing Edge-Case Testing (Refined)

$SovereignRoot = "C:\Skills"
$ScriptPath = Join-Path $SovereignRoot "sovereign.ps1"
$ConfigPath = Join-Path $SovereignRoot "sovereign.config.json"
$ConfigBackup = Join-Path $SovereignRoot "sovereign.config.json.bak_test"

Copy-Item -Path $ConfigPath -Destination $ConfigBackup -Force

function Run-ConfigTest {
    param(
        [string]$TestName,
        [scriptblock]$SetupBlock,
        [bool]$ExpectSuccess
    )

    Write-Host "`n=================================================="
    Write-Host "TEST: $TestName"
    Write-Host "=================================================="

    try {
        & $SetupBlock

        $Proc = Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$ScriptPath`"" -NoNewWindow -PassThru -Wait -RedirectStandardOutput "$SovereignRoot\.agents\teamwork_preview_challenger_m1\temp_stdout.log" -RedirectStandardError "$SovereignRoot\.agents\teamwork_preview_challenger_m1\temp_stderr.log"

        $Stdout = (Get-Content "$SovereignRoot\.agents\teamwork_preview_challenger_m1\temp_stdout.log" -Raw -ErrorAction SilentlyContinue)
        $Stderr = (Get-Content "$SovereignRoot\.agents\teamwork_preview_challenger_m1\temp_stderr.log" -Raw -ErrorAction SilentlyContinue)

        Write-Host "Exit Code: $($Proc.ExitCode)"
        if ($Stdout) { Write-Host "Stdout:`n$Stdout".Trim() }
        if ($Stderr) { Write-Host "Stderr:`n$Stderr".Trim() }

        if ($ExpectSuccess) {
            if ($Proc.ExitCode -eq 0) {
                Write-Host "RESULT: PASS (Successfully executed with exit code 0)"
            } else {
                Write-Host "RESULT: FAIL (Expected exit code 0, got $($Proc.ExitCode))"
            }
        } else {
            if ($Proc.ExitCode -eq 1) {
                Write-Host "RESULT: PASS (Failed safely with non-zero exit code 1 as expected)"
            } else {
                Write-Host "RESULT: FAIL (Expected exit code 1 on bad config, got $($Proc.ExitCode))"
            }
        }
    } finally {
        Copy-Item -Path $ConfigBackup -Destination $ConfigPath -Force
        Remove-Item -Path "$SovereignRoot\.agents\teamwork_preview_challenger_m1\temp_stdout.log" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$SovereignRoot\.agents\teamwork_preview_challenger_m1\temp_stderr.log" -Force -ErrorAction SilentlyContinue
    }
}

try {
    Run-ConfigTest -TestName "4.1 Valid Config Baseline" -SetupBlock {
        Copy-Item -Path $ConfigBackup -Destination $ConfigPath -Force
    } -ExpectSuccess $true

    Run-ConfigTest -TestName "4.2 Missing sovereign.config.json" -SetupBlock {
        Remove-Item -Path $ConfigPath -Force
    } -ExpectSuccess $false

    Run-ConfigTest -TestName "4.3 Malformed JSON Syntax" -SetupBlock {
        Set-Content -Path $ConfigPath -Value "{ `"version`": `"16.0.0-Scratch`", invalid_json_syntax: "
    } -ExpectSuccess $false

    Run-ConfigTest -TestName "4.4 Empty JSON Object {}" -SetupBlock {
        Set-Content -Path $ConfigPath -Value "{}"
    } -ExpectSuccess $false

    Run-ConfigTest -TestName "4.5 Missing 'paths' Section" -SetupBlock {
        $Original = Get-Content $ConfigBackup -Raw | ConvertFrom-Json
        $Original.PSObject.Properties.Remove('paths')
        Set-Content -Path $ConfigPath -Value ($Original | ConvertTo-Json -Depth 10)
    } -ExpectSuccess $false

    Run-ConfigTest -TestName "4.6 Missing 'governance' Section" -SetupBlock {
        $Original = Get-Content $ConfigBackup -Raw | ConvertFrom-Json
        $Original.PSObject.Properties.Remove('governance')
        Set-Content -Path $ConfigPath -Value ($Original | ConvertTo-Json -Depth 10)
    } -ExpectSuccess $false

    Run-ConfigTest -TestName "4.7 Missing 'governance.lock_timeout_seconds'" -SetupBlock {
        $Original = Get-Content $ConfigBackup -Raw | ConvertFrom-Json
        $Original.governance.PSObject.Properties.Remove('lock_timeout_seconds')
        Set-Content -Path $ConfigPath -Value ($Original | ConvertTo-Json -Depth 10)
    } -ExpectSuccess $false

} finally {
    if (Test-Path $ConfigBackup) {
        Copy-Item -Path $ConfigBackup -Destination $ConfigPath -Force
        Remove-Item -Path $ConfigBackup -Force
        Write-Host "`nRestored pristine config and cleaned up backup file."
    }
}
