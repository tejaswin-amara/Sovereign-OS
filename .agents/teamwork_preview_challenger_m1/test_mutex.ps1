# test_mutex.ps1 - Empirical Mutex Contention Test Harness for sovereign.ps1

$SovereignRoot = "C:\Skills"
$ScriptPath = Join-Path $SovereignRoot "sovereign.ps1"
$MutexName = "Global\SovereignOSLock"

Write-Host "=================================================="
Write-Host "TEST 2.1: Mutex Contention Timeout (Holding lock for 7s)"
Write-Host "=================================================="

# Launch a background PowerShell process that acquires the mutex and holds it for 7s
$BlockerScript = {
    $m = New-Object System.Threading.Mutex($false, "Global\SovereignOSLock")
    if ($m.WaitOne(5000)) {
        Write-Host "[Blocker] Mutex acquired. Holding for 7 seconds..."
        Start-Sleep -Seconds 7
        $m.ReleaseMutex()
        $m.Dispose()
        Write-Host "[Blocker] Mutex released."
    } else {
        Write-Host "[Blocker] Failed to acquire mutex."
    }
}

$BlockerJob = Start-Job -ScriptBlock $BlockerScript
Start-Sleep -Milliseconds 500  # Give blocker time to grab lock

$SW = [System.Diagnostics.Stopwatch]::StartNew()
$ProcessB = Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$ScriptPath`"" -NoNewWindow -PassThru -Wait
$SW.Stop()

Write-Host "Process B ExitCode: $($ProcessB.ExitCode)"
Write-Host "Process B Duration: $($SW.ElapsedMilliseconds) ms"

Receive-Job -Job $BlockerJob | Out-Null
Remove-Job -Job $BlockerJob -Force

Write-Host "`n=================================================="
Write-Host "TEST 2.2: Mutex Handover (Holding lock for 2s)"
Write-Host "=================================================="

$BlockerScript2 = {
    $m = New-Object System.Threading.Mutex($false, "Global\SovereignOSLock")
    if ($m.WaitOne(5000)) {
        Write-Host "[Blocker2] Mutex acquired. Holding for 2 seconds..."
        Start-Sleep -Seconds 2
        $m.ReleaseMutex()
        $m.Dispose()
        Write-Host "[Blocker2] Mutex released."
    }
}

$BlockerJob2 = Start-Job -ScriptBlock $BlockerScript2
Start-Sleep -Milliseconds 500

$SW2 = [System.Diagnostics.Stopwatch]::StartNew()
$ProcessC = Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$ScriptPath`"" -NoNewWindow -PassThru -Wait
$SW2.Stop()

Write-Host "Process C ExitCode: $($ProcessC.ExitCode)"
Write-Host "Process C Duration: $($SW2.ElapsedMilliseconds) ms"

Receive-Job -Job $BlockerJob2 | Out-Null
Remove-Job -Job $BlockerJob2 -Force

Write-Host "`n=================================================="
Write-Host "TEST 2.3: Simultaneous Parallel Invocations (2 jobs)"
Write-Host "=================================================="

$Job1 = Start-Job -ScriptBlock { powershell.exe -ExecutionPolicy Bypass -File "C:\Skills\sovereign.ps1" }
$Job2 = Start-Job -ScriptBlock { powershell.exe -ExecutionPolicy Bypass -File "C:\Skills\sovereign.ps1" }

Wait-Job $Job1, $Job2 | Out-Null

$Out1 = Receive-Job -Job $Job1
$Out2 = Receive-Job -Job $Job2

Write-Host "Job 1 Output:`n$Out1"
Write-Host "Job 1 State: $($Job1.State)"
Write-Host "Job 2 Output:`n$Out2"
Write-Host "Job 2 State: $($Job2.State)"

Remove-Job $Job1, $Job2 -Force
