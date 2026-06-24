# C:/Skills/agent-bootstrap/scripts/helpers/Checksum.ps1
Set-StrictMode -Version Latest

function Get-SovereignFileHash {
    param([string]$FilePath)
    $FileBytes = [System.IO.File]::ReadAllBytes($FilePath)
    $Sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $HashBytes = $Sha256.ComputeHash($FileBytes)
    } finally {
        $Sha256.Dispose()
    }
    return [System.BitConverter]::ToString($HashBytes).Replace("-", "").ToLower()
}

function Protect-SovereignHash {
    param([string]$Hash)
    Add-Type -AssemblyName System.Security
    $HashStringBytes = [System.Text.Encoding]::UTF8.GetBytes($Hash)
    $EncryptedBytes = [System.Security.Cryptography.ProtectedData]::Protect($HashStringBytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    return [Convert]::ToBase64String($EncryptedBytes)
}

function Update-SovereignChecksum {
    [CmdletBinding()]
    param(
        [string]$ConfigPath = "",
        [string]$HashPath = ""
    )
    
    $SovereignRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
    if ([string]::IsNullOrWhiteSpace($ConfigPath)) { $ConfigPath = "$SovereignRoot/sovereign.config.json" }
    if ([string]::IsNullOrWhiteSpace($HashPath)) { $HashPath = "$SovereignRoot/agent-bootstrap/.config.sha256" }

    if (Test-Path $HashPath) {
        Set-ItemProperty -Path $HashPath -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
    }
    
    $CurrentHash = Get-SovereignFileHash -FilePath $ConfigPath
    $EncryptedBase64 = Protect-SovereignHash -Hash $CurrentHash

    [System.IO.File]::WriteAllText($HashPath, $EncryptedBase64)
    Set-ItemProperty -Path $HashPath -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
    Write-SovereignLog -Level "INFO" -Step "INTEGRITY" -Message "Checksum sealed successfully with DPAPI."
    return $CurrentHash
}
