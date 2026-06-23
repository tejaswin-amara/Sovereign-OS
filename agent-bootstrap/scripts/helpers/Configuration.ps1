# C:/Skills/agent-bootstrap/scripts/helpers/Configuration.ps1

function Get-SovereignConfig {
    [CmdletBinding()]
    param([string]$KeyPath)
    
    $SovereignRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
    $ConfigPath = "$SovereignRoot/sovereign.config.json"
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
        [string]$ConfigPath = "",
        [string]$HashPath = ""
    )

    $SovereignRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
    if ([string]::IsNullOrWhiteSpace($ConfigPath)) { $ConfigPath = "$SovereignRoot/sovereign.config.json" }
    if ([string]::IsNullOrWhiteSpace($HashPath)) { $HashPath = "$SovereignRoot/agent-bootstrap/.config.sha256" }

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
        
        # DPAPI Encrypt
        Add-Type -AssemblyName System.Security
        $HashStringBytes = [System.Text.Encoding]::UTF8.GetBytes($CurrentHash)
        $EncryptedBytes = [System.Security.Cryptography.ProtectedData]::Protect($HashStringBytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
        $EncryptedBase64 = [Convert]::ToBase64String($EncryptedBytes)

        [System.IO.File]::WriteAllText($HashPath, $EncryptedBase64)
        Set-ItemProperty -Path $HashPath -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
        return $true
    }

    $EncryptedBase64 = (Get-Content $HashPath -First 1).Trim()
    
    # DPAPI Decrypt
    try {
        Add-Type -AssemblyName System.Security
        $EncryptedBytes = [Convert]::FromBase64String($EncryptedBase64)
        $DecryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($EncryptedBytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
        $MasterHash = [System.Text.Encoding]::UTF8.GetString($DecryptedBytes).ToLower()
    } catch {
        # Fallback to plaintext if DPAPI fails (backwards compatibility for the first run)
        $MasterHash = $EncryptedBase64.ToLower()
    }

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
