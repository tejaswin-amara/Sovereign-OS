$LogFile = "C:\Skills\.agents\worker_m3\hold_lock.log"
"Starting hold_lock.ps1" | Out-File $LogFile
try {
    $MutexName = "Global\SovereignOSLock"
    $createdNew = $false
    $Mutex = New-Object System.Threading.Mutex($true, $MutexName, [ref]$createdNew)
    "Mutex created. createdNew=$createdNew" | Out-File $LogFile -Append
    if (-not $createdNew) {
        $acquired = $Mutex.WaitOne(1000)
        "Mutex WaitOne acquired=$acquired" | Out-File $LogFile -Append
    }
    "Holding lock for 7 seconds..." | Out-File $LogFile -Append
    Start-Sleep -Seconds 7
    $Mutex.ReleaseMutex()
    $Mutex.Dispose()
    "Released lock." | Out-File $LogFile -Append
} catch {
    "Error: $_" | Out-File $LogFile -Append
}
