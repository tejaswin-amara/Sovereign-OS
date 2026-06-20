# C:/Skills/agent-bootstrap/scripts/helpers/Configuration.ps1

function Get-SovereignConfig {
    [CmdletBinding()]
    param([string]$KeyPath)
    
    $ConfigPath = "C:/Skills/sovereign.config.json"
    if (-not (Test-Path $ConfigPath)) {
        return $null
    }
    
    try {
        $Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        if (-not $KeyPath) {
            return $Config
        }
        
        $Parts = $KeyPath.Split('.')
        $Current = $Config
        foreach ($Part in $Parts) {
            if ($Current -and $Current.PSObject.Properties[$Part]) {
                $Current = $Current.$Part
            } else {
                return $null
            }
        }
        return $Current
    } catch {
        return $null
    }
}

function Save-AtomicContent {
    [CmdletBinding()]
    param([string]$Path, [string]$Content)
    
    $ParentDir = Split-Path $Path -Parent
    if ($ParentDir -and -not (Test-Path $ParentDir)) {
        New-Item -Path $ParentDir -ItemType Directory -Force | Out-Null
    }

    $TempPath = "$Path.$([guid]::NewGuid().ToString().Substring(0,8)).tmp"
    [System.IO.File]::WriteAllText($TempPath, $Content, [System.Text.Encoding]::UTF8)
    Invoke-AtomicMove -Source $TempPath -Destination $Path
}

function Assert-SovereignConfigIntegrity {
    [CmdletBinding()]
    param(
        [string]$ConfigPath = "C:/Skills/sovereign.config.json",
        [string]$HashPath = "C:/Skills/agent-bootstrap/.config.sha256"
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "CONFIG_MISSING: sovereign.config.json is missing!"
    }

    $FileBytes = [System.IO.File]::ReadAllBytes($ConfigPath)
    $Sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $HashBytes = $Sha256.ComputeHash($FileBytes)
    } finally {
        $Sha256.Dispose()
    }
    $CurrentHash = [System.BitConverter]::ToString($HashBytes).Replace("-", "").ToLower()

    if (-not (Test-Path $HashPath)) {
        Write-SovereignLog -Level "WARN" -Step "INTEGRITY" -Message "Initializing config checksum at $HashPath"
        [System.IO.File]::WriteAllText($HashPath, $CurrentHash)
        Set-ItemProperty -Path $HashPath -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
        return $true
    }

    $MasterHash = (Get-Content $HashPath -First 1).Trim().ToLower()

    if ($CurrentHash -ne $MasterHash) {
        $ErrorMsg = "CONFIG_INTEGRITY_VIOLATION: The global sovereign.config.json has been modified or tampered with! " +
                    "Expected SHA256: $MasterHash, Actual SHA256: $CurrentHash. " +
                    "Pipeline aborted to prevent unauthorized privilege escalation."
        Write-SovereignLog -Level "ERROR" -Step "INTEGRITY" -Message $ErrorMsg
        throw $ErrorMsg
    }

    Write-SovereignLog -Level "INFO" -Step "INTEGRITY" -Message "Configuration checksum verified: $CurrentHash"
    return $true
}
