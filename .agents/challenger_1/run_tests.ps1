$ErrorActionPreference = "Stop"
$TargetScript = "C:\Skills\sovereign.ps1"
$ConfigPath = "C:\Skills\sovereign.config.json"
$ReportDir = "C:\Skills\.agents\challenger_1"

Write-Host "=================== TEST 1: Baseline Execution ==================="
$p1 = Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$TargetScript`"" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$ReportDir\test1_stdout.txt" -RedirectStandardError "$ReportDir\test1_stderr.txt"
$t1_exit = $p1.ExitCode
$t1_stdout = Get-Content "$ReportDir\test1_stdout.txt" -Raw
$t1_stderr = Get-Content "$ReportDir\test1_stderr.txt" -Raw
Write-Host "Test 1 Exit Code: $t1_exit"
Write-Host "Test 1 Stdout:`n$t1_stdout"
if ($t1_stderr) { Write-Host "Test 1 Stderr:`n$t1_stderr" }

Write-Host "=================== TEST 2: Mutex Lock Collision ==================="
$lockerScript = "$ReportDir\hold_mutex.ps1"
$lockerCode = @'
try {
    $mutex = New-Object System.Threading.Mutex($false, "Global\SovereignOSLock")
    if ($mutex.WaitOne(5000, $false)) {
        Write-Host "MUTEX_HELD"
        Start-Sleep -Seconds 12
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    } else {
        Write-Host "MUTEX_FAILED_TO_ACQUIRE"
    }
} catch {
    Write-Host "MUTEX_ERROR: $_"
}
'@
Set-Content -Path $lockerScript -Value $lockerCode -Encoding UTF8

$locker = Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$lockerScript`"" -NoNewWindow -PassThru -RedirectStandardOutput "$ReportDir\locker_stdout.txt" -RedirectStandardError "$ReportDir\locker_stderr.txt"

# Give locker process time to launch and acquire mutex
Start-Sleep -Milliseconds 1500

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$p2 = Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$TargetScript`"" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$ReportDir\test2_stdout.txt" -RedirectStandardError "$ReportDir\test2_stderr.txt"
$sw.Stop()

$t2_exit = $p2.ExitCode
$t2_duration = $sw.ElapsedMilliseconds
$t2_stdout = Get-Content "$ReportDir\test2_stdout.txt" -Raw
$t2_stderr = Get-Content "$ReportDir\test2_stderr.txt" -Raw
$locker_stdout = Get-Content "$ReportDir\locker_stdout.txt" -Raw
$locker_stderr = Get-Content "$ReportDir\locker_stderr.txt" -Raw

Write-Host "Locker Stdout: $locker_stdout"
if ($locker_stderr) { Write-Host "Locker Stderr: $locker_stderr" }
Write-Host "Test 2 Exit Code: $t2_exit"
Write-Host "Test 2 Duration: ${t2_duration} ms"
Write-Host "Test 2 Stdout:`n$t2_stdout"
if ($t2_stderr) { Write-Host "Test 2 Stderr:`n$t2_stderr" }

if (-not $locker.HasExited) {
    Stop-Process -Id $locker.Id -Force
}

Write-Host "=================== TEST 3: Dynamic Config Auto-Update ==================="
$configJson = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$origSkillsCount = $configJson.governance.skills_count

# Mutate skills_count to an incorrect value 999
$configJson.governance.skills_count = 999
$configJson | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath -Encoding UTF8
Write-Host "Config mutated skills_count to 999."

$p3 = Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$TargetScript`"" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$ReportDir\test3_stdout.txt" -RedirectStandardError "$ReportDir\test3_stderr.txt"
$t3_exit = $p3.ExitCode
$t3_stdout = Get-Content "$ReportDir\test3_stdout.txt" -Raw
$t3_stderr = Get-Content "$ReportDir\test3_stderr.txt" -Raw

$updatedConfig = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$updatedSkillsCount = $updatedConfig.governance.skills_count

Write-Host "Test 3 Exit Code: $t3_exit"
Write-Host "Test 3 Stdout:`n$t3_stdout"
if ($t3_stderr) { Write-Host "Test 3 Stderr:`n$t3_stderr" }
Write-Host "Updated skills_count in sovereign.config.json: $updatedSkillsCount"

Write-Host "=================== SUMMARY RESULTS ==================="
Write-Host "TEST 1 PASS: $($t1_exit -eq 0 -and $t1_stdout -match 'Dynamic skill count: 2, Module count: 4')"
Write-Host "TEST 2 PASS: $($t2_exit -eq 1 -and $t2_duration -ge 4500 -and $t2_stdout -match 'Could not acquire OS lock')"
Write-Host "TEST 3 PASS: $($t3_exit -eq 0 -and $updatedSkillsCount -eq 2)"
