# C:/Skills/agent-bootstrap/scripts/helpers/Checksum.ps1

function Update-SovereignChecksum {
    [CmdletBinding()]
    param(
        [string]$ConfigPath = "C:/Skills/sovereign.config.json",
        [string]$HashPath = "C:/Skills/agent-bootstrap/.config.sha256"
    )
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
    [System.IO.File]::WriteAllText($HashPath, $CurrentHash)
    Set-ItemProperty -Path $HashPath -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
    Write-SovereignLog -Level "INFO" -Step "INTEGRITY" -Message "Checksum sealed successfully: $CurrentHash"
    return $CurrentHash
}
