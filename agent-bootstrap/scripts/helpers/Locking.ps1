# D:/Skills/agent-bootstrap/scripts/helpers/Locking.ps1

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

    $StartTime = Get-Date
    $BackoffMS = 100
    $MaxBackoffMS = 2000

    while ($true) {
        try {
            $fs = [System.IO.File]::Open(
                $LockFile,
                [System.IO.FileMode]::CreateNew,
                [System.IO.FileAccess]::Write,
                [System.IO.FileShare]::None
            )
            $pid_info = @{
                PID = $PID
                ProcessName = (Get-Process -Id $PID).ProcessName
                StartTime = (Get-Date -Format "o")
            } | ConvertTo-Json
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($pid_info)
            $fs.Write($bytes, 0, $bytes.Length)
            $fs.Flush()
            return $fs
        }
        catch [System.IO.IOException] {
            $existing = $null
            try {
                $existing = Get-Content $LockFile -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
            } catch {
                # Lock file may be held exclusively — cannot read
            }

            $isStale = $false
            if ($null -eq $existing) {
                $isStale = $true
                Write-SovereignLog -Level "WARN" -Step "MUTEX" -Message "Lock file is empty or corrupt. Auto-clearing."
            } elseif (-not $existing.PSObject.Properties['PID'] -or -not $existing.PSObject.Properties['StartTime']) {
                $isStale = $true
                Write-SovereignLog -Level "WARN" -Step "MUTEX" -Message "Lock file metadata is missing or invalid. Auto-clearing."
            } else {
                try {
                    $proc = Get-Process -Id $existing.PID -ErrorAction SilentlyContinue
                    if (-not $proc) {
                        $isStale = $true
                    } elseif ($existing.ProcessName -and $proc.ProcessName -ne $existing.ProcessName) {
                        $isStale = $true
                        Write-SovereignLog -Level "WARN" -Step "MUTEX" -Message "PID $($existing.PID) reused by '$($proc.ProcessName)' (expected '$($existing.ProcessName)'). Treating as stale."
                    }
                } catch {
                    $isStale = $true
                }

                $LeaseTimeoutSec = 600
                $ConfigLease = Get-SovereignConfig -KeyPath "governance.lock_lease_timeout_seconds"
                if ($ConfigLease) { $LeaseTimeoutSec = [int]$ConfigLease }

                if ($existing.StartTime) {
                    try {
                        $LockTime = [DateTime]::Parse($existing.StartTime, [System.Globalization.CultureInfo]::InvariantCulture)
                        $Elapsed = (Get-Date) - $LockTime
                        if ($Elapsed.TotalSeconds -gt $LeaseTimeoutSec) {
                            $isStale = $true
                            Write-SovereignLog -Level "WARN" -Step "MUTEX" -Message "Lock lease expired. Elapsed: $($Elapsed.TotalSeconds)s (Limit: $($LeaseTimeoutSec)s). Auto-clearing stale lock."
                        }
                    } catch {
                        $isStale = $true
                        Write-SovereignLog -Level "WARN" -Step "MUTEX" -Message "Lock StartTime '$($existing.StartTime)' is unparsable. Auto-clearing suspicious lock."
                    }
                }
            }

            if ($isStale) {
                Remove-Item $LockFile -Force -ErrorAction SilentlyContinue
                # Recursive call removed to prevent stack overflow
                continue
            }

            $ElapsedSeconds = ((Get-Date) - $StartTime).TotalSeconds
            if ($ElapsedSeconds -gt $TimeoutSeconds) {
                $holderPID = if ($existing -and $existing.PSObject.Properties['PID']) { $existing.PID } else { "unknown" }
                throw "LOCK_TIMEOUT: Sovereign lock held by PID $holderPID for over $TimeoutSeconds seconds."
            }

            $SleepMS = [Math]::Min($BackoffMS, $MaxBackoffMS)
            Start-Sleep -Milliseconds $SleepMS
            $BackoffMS = $BackoffMS * 2
        }
    }
}

function Stop-SovereignLock {
    [CmdletBinding()]
    param(
        [string]$LockFile,
        [System.IO.FileStream]$LockStream = $null
    )
    if ($LockStream) {
        try {
            $LockStream.Dispose()
        } catch {
            Write-SovereignLog -Level "WARN" -Step "MUTEX" -Message "Failed to dispose lock stream: $($_.Exception.Message)"
        }
    }
    if (Test-Path $LockFile) {
        Remove-Item $LockFile -Force -ErrorAction SilentlyContinue
    }
}
