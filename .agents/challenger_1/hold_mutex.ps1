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
