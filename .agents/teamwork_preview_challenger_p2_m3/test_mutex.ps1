# Test 1: Holding lock for 2s (less than 5s timeout) -> sovereign.ps1 should wait and succeed
Write-Host "--- TEST 1: Lock held for 2 seconds (Timeout is 5s) ---"
$job = Start-Job -ScriptBlock {
    $createdNew = $false
    $m = [System.Threading.Mutex]::new($true, "Global\SovereignOSLock", [ref]$createdNew)
    if (-not $createdNew) {
        [void]$m.WaitOne()
    }
    Start-Sleep -Seconds 2
    $m.ReleaseMutex()
    $m.Dispose()
}
Start-Sleep -Milliseconds 500
$sw = [System.Diagnostics.Stopwatch]::StartNew()
& C:\Skills\sovereign.ps1
$exit1 = $LASTEXITCODE
$sw.Stop()
Write-Host "Test 1 Exit Code: $exit1, Elapsed: $($sw.ElapsedMilliseconds) ms"
Wait-Job $job | Out-Null
Receive-Job $job | Out-Null
Remove-Job $job

# Test 2: Holding lock for 6s (greater than 5s timeout) -> sovereign.ps1 should fail with lock timeout
Write-Host "`n--- TEST 2: Lock held for 6 seconds (Timeout is 5s) ---"
$job2 = Start-Job -ScriptBlock {
    $createdNew = $false
    $m = [System.Threading.Mutex]::new($true, "Global\SovereignOSLock", [ref]$createdNew)
    if (-not $createdNew) {
        [void]$m.WaitOne()
    }
    Start-Sleep -Seconds 6
    $m.ReleaseMutex()
    $m.Dispose()
}
Start-Sleep -Milliseconds 500
$sw2 = [System.Diagnostics.Stopwatch]::StartNew()
try {
    & C:\Skills\sovereign.ps1
    $exit2 = $LASTEXITCODE
} catch {
    $exit2 = 1
}
$sw2.Stop()
Write-Host "Test 2 Exit Code: $exit2, Elapsed: $($sw2.ElapsedMilliseconds) ms"
Wait-Job $job2 | Out-Null
Receive-Job $job2 | Out-Null
Remove-Job $job2

if ($exit1 -eq 0 -and $exit2 -eq 1) {
    Write-Host "`n>>> MUTEX EMPIRICAL VERIFICATION PASSED <<<"
} else {
    Write-Host "`n>>> MUTEX EMPIRICAL VERIFICATION FAILED <<<"
    exit 1
}
