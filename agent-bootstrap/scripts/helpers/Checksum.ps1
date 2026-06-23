# C:/Skills/agent-bootstrap/scripts/helpers/Checksum.ps1

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
    
    $FileBytes = [System.IO.File]::ReadAllBytes($ConfigPath)
    $Sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $HashBytes = $Sha256.ComputeHash($FileBytes)
    } finally {
        $Sha256.Dispose()
    }
    
    $CurrentHash = [System.BitConverter]::ToString($HashBytes).Replace("-", "").ToLower()
    
    # SECURITY: Use DPAPI to encrypt the hash so it cannot be tampered with by other users/processes easily
    Add-Type -AssemblyName System.Security
    $HashStringBytes = [System.Text.Encoding]::UTF8.GetBytes($CurrentHash)
    $EncryptedBytes = [System.Security.Cryptography.ProtectedData]::Protect($HashStringBytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    $EncryptedBase64 = [Convert]::ToBase64String($EncryptedBytes)

    [System.IO.File]::WriteAllText($HashPath, $EncryptedBase64)
    Set-ItemProperty -Path $HashPath -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
    Write-SovereignLog -Level "INFO" -Step "INTEGRITY" -Message "Checksum sealed successfully with DPAPI."
    return $CurrentHash
}
