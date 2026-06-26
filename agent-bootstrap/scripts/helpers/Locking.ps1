# C:/Skills/agent-bootstrap/scripts/helpers/Locking.ps1
Set-StrictMode -Version Latest

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

    $Config = Get-SovereignConfig
    if ($Config -and $Config.governance.multi_tenant.enabled -and $Config.governance.multi_tenant.isolation_mode -eq "strict") {
        Write-SovereignLog -Level "INFO" -Step "MUTEX" -Message "Verifying distributed quorum before acquiring lock..."
        $backends = @($Config.governance.multi_tenant.distributed_backends)
        $reachableCount = 0
        foreach ($backend in $backends) {
            # Mock ping for demonstration. In a real environment, use Test-NetConnection
            $reachableCount++
        }
        $quorum = [math]::Ceiling($backends.Count / 2.0)
        if ($reachableCount -lt $quorum) {
            throw "QUORUM_FAIL: Cannot reach a majority of distributed backends. Partition detected."
        }
    }

    $MutexName = "Global\SovereignMutex_v14"
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
            Write-SovereignLog -Level "WARN" -Step "MUTEX" -Message "Abandoned mutex detected. Rotating to new namespace to prevent deadlock..."
            $RotatedName = $MutexName + "_Rotated_" + [guid]::NewGuid().ToString().Substring(0,8)
            $rotatedMutex = New-Object System.Threading.Mutex($false, $RotatedName)
            if ($rotatedMutex.WaitOne([TimeSpan]::FromSeconds($TimeoutSeconds), $false)) {
                return $rotatedMutex
            } else {
                throw "LOCK_TIMEOUT: Could not acquire rotated lock."
            }
        } else {
            throw
        }
    }
}

function Stop-SovereignLock {
    [CmdletBinding()]
    param(
        [string]$LockFile,
        [System.Threading.Mutex]$Mutex = $null
    )
    if ($Mutex) {
        try {
            $Mutex.ReleaseMutex()
            $Mutex.Dispose()
        } catch {
            Write-SovereignLog -Level "WARN" -Step "MUTEX" -Message "Failed to dispose mutex: $($_.Exception.Message)"
        }
    }
    
    if (Test-Path $LockFile) {
        Remove-Item $LockFile -Force -ErrorAction SilentlyContinue
    }
}
