# C:/Skills/agent-bootstrap/scripts/helpers/Locking.ps1

function Start-SovereignLock {
    [CmdletBinding()]
    param(
        [string]$LockFile = "$PSScriptRoot/../../../.sovereign.lock",
        [int]$TimeoutSeconds = 0
    )

    if ($TimeoutSeconds -le 0) {
        $ConfigTimeout = Get-SovereignConfig -KeyPath "governance.lock_timeout_seconds"
        $TimeoutSeconds = if ($ConfigTimeout) { [int]$ConfigTimeout } else { 30 }
    }

    $MutexName = "Global\SovereignMutex"
    $mutex = New-Object System.Threading.Mutex($false, $MutexName)

    try {
        if ($mutex.WaitOne([TimeSpan]::FromSeconds($TimeoutSeconds), $false)) {
            # Mutex acquired
            return $mutex
        } else {
            throw "LOCK_TIMEOUT: Sovereign lock could not be acquired within $TimeoutSeconds seconds."
        }
    } catch {
        if ($_.Exception.GetType().Name -eq "AbandonedMutexException") {
            # The mutex was abandoned by another process that exited without releasing it
            Write-SovereignLog -Level "WARN" -Step "MUTEX" -Message "Recovered abandoned mutex."
            return $mutex
        } else {
            throw
        }
    }
}

function Stop-SovereignLock {
    [CmdletBinding()]
    param(
        [string]$LockFile,
        [System.Threading.Mutex]$Mutex = $null,
        [System.IO.FileStream]$LockStream = $null # Kept for backwards compatibility
    )
    if ($Mutex) {
        try {
            $Mutex.ReleaseMutex()
            $Mutex.Dispose()
        } catch {
            Write-SovereignLog -Level "WARN" -Step "MUTEX" -Message "Failed to dispose mutex: $($_.Exception.Message)"
        }
    } elseif ($LockStream) {
        try {
            $LockStream.Dispose()
        } catch {
            Write-SovereignLog -Level "WARN" -Step "MUTEX" -Message "Failed to dispose legacy lock stream: $($_.Exception.Message)"
        }
    }
    
    if (Test-Path $LockFile) {
        Remove-Item $LockFile -Force -ErrorAction SilentlyContinue
    }
}
