$Mutex = New-Object System.Threading.Mutex($false, "Global\SovereignOSLock")
if ($Mutex.WaitOne(0, $false)) {
    Write-Host "Lock acquired by test script for 10 seconds"
    Start-Sleep -Seconds 10
    $Mutex.ReleaseMutex()
    $Mutex.Dispose()
    Write-Host "Lock released by test script"
} else {
    Write-Host "Could not acquire lock in test script"
}
