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

    # ponytail: distributed quorum check removed — was a mock that unconditionally reported success.
    # Ceiling: if real multi-node locking is needed, implement with actual Test-NetConnection.

    $ParentDir = Split-Path $LockFile -Parent
    if (!(Test-Path $ParentDir)) {
        New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
    }

    $Timeout = [TimeSpan]::FromSeconds($TimeoutSeconds)
    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    while ($Stopwatch.Elapsed -lt $Timeout -or $TimeoutSeconds -eq 0) {
        try {
            $FileStream = [System.IO.File]::Open($LockFile, 'OpenOrCreate', 'ReadWrite', 'None')
            return $FileStream
        } catch {
            if ($TimeoutSeconds -eq 0) {
                throw "LOCK_TIMEOUT: Sovereign lock could not be acquired immediately."
            }
            Start-Sleep -Milliseconds 200
        }
    }
    
    throw "LOCK_TIMEOUT: Sovereign lock could not be acquired within $TimeoutSeconds seconds."
}

function Stop-SovereignLock {
    [CmdletBinding()]
    param(
        [string]$LockFile,
        $Mutex = $null
    )
    if ($Mutex -is [System.IO.FileStream]) {
        try {
            $Mutex.Close()
            $Mutex.Dispose()
        } catch {
            Write-SovereignLog -Level "WARN" -Step "MUTEX" -Message "Failed to dispose lock: $($_.Exception.Message)"
        }
    }
    
    if (Test-Path $LockFile) {
        Remove-Item $LockFile -Force -ErrorAction SilentlyContinue
    }
}
