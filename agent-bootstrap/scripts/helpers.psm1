# C:/Skills/agent-bootstrap/scripts/helpers.psm1
Set-StrictMode -Version Latest
# Sovereign Shared Module (v14.0.0-CloudNative)
# Purpose: Atomic operations, structured logging, mutex management, and governance enforcement.

$HelperFiles = @(
    "Logging.ps1"
    "Locking.ps1"
    "Configuration.ps1"
    "Checksum.ps1"
    "Version.ps1"
    "Modularity.ps1"
    "IO.ps1"
    "Validation.ps1"
    "OmniSearch.ps1"
    "Troubleshooting.ps1"
    "Evolution.ps1"
)

foreach ($File in $HelperFiles) {
    . "$PSScriptRoot/helpers/$File"
}

Export-ModuleMember -Function @(
    'Assert-SovereignConfigIntegrity',
    'Get-SovereignConfig',
    'Get-SovereignVersion',
    'Get-DynamicSkillCount',
    'Set-SovereignLogContext',
    'Write-SovereignLog',
    'Start-SovereignLock',
    'Stop-SovereignLock',
    'Test-SovereignDrift',
    'Get-SovereignSkillGaps',
    'Write-SovereignEvolutionReport',
    'Test-SovereignIntegrity',
    'Assert-ModuleCap',
    'Invoke-AtomicMove',
    'Save-AtomicContent',
    'Assert-SovereignPattern',
    'Start-LogRotation',
    'Update-SovereignChecksum',
    'Get-SovereignManifestFiles',
    'Invoke-SovereignInternetDiagnostic',
    'Invoke-OmniSearch'
)
