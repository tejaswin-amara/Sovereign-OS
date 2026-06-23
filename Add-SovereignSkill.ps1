param(
    [Parameter(Mandatory=$true)]
    [string]$Repo,

    [Parameter(Mandatory=$true)]
    [string]$PackageName
)

$ConfigFile = "C:\Skills\sovereign.config.json"

if (-Not (Test-Path $ConfigFile)) {
    Write-Error "Config file not found: $ConfigFile"
    exit 1
}

$Config = Get-Content $ConfigFile -Raw | ConvertFrom-Json -Depth 10

if ($Config.dep_to_skill_map.$PackageName) {
    Write-Warning "Package '$PackageName' already maps to '$($Config.dep_to_skill_map.$PackageName)'. Updating to '$Repo'."
}

$Config.dep_to_skill_map | Add-Member -MemberType NoteProperty -Name $PackageName -Value $Repo -Force

# Convert back to JSON and format nicely
$JsonOutput = ConvertTo-Json $Config -Depth 10
$JsonOutput = $JsonOutput -replace '\\u003e', '>'

Set-Content -Path $ConfigFile -Value $JsonOutput

Write-Host "Successfully injected '$PackageName' -> '$Repo' into sovereign.config.json"

# Trigger checksum update if it exists
if (Test-Path "C:\Skills\agent-bootstrap\scripts\update-checksum.ps1") {
    pwsh -File "C:\Skills\agent-bootstrap\scripts\update-checksum.ps1"
}
