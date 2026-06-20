# update-checksum.ps1 - Utility wrapper to sign sovereign.config.json (v14.0.0-CloudNative)

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ConfigPath = "$PSScriptRoot/../../sovereign.config.json"
$HashPath = "$PSScriptRoot/../.config.sha256"

if (-not (Test-Path $ConfigPath)) {
    throw "sovereign.config.json missing at $ConfigPath"
}

Import-Module "$PSScriptRoot/helpers.psm1" -Force -DisableNameChecking
$CurrentHash = Update-SovereignChecksum -ConfigPath $ConfigPath -HashPath $HashPath
Write-Host "Updated checksum to: $CurrentHash" -ForegroundColor Green
return
