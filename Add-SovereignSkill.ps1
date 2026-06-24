param(
    [Parameter(Mandatory=$true)]
    [string]$Repo,

    [Parameter(Mandatory=$false)]
    [string]$PackageName
)

Set-StrictMode -Version Latest

if ([string]::IsNullOrEmpty($PackageName)) {
    $CleanRepo = $Repo.TrimEnd('/','\')
    $PackageName = ($CleanRepo -split '[/\\]')[-1]
}

$ConfigFile = "C:\Skills\sovereign.config.json"

if (-Not (Test-Path $ConfigFile)) {
    Write-Error "Config file not found: $ConfigFile"
    exit 1
}

$Config = Get-Content $ConfigFile -Raw | ConvertFrom-Json

# Validate repo format: must be in the format 'owner/repo'
if ($Repo -notmatch '^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$') {
    throw "Invalid repository format: '$Repo'. Must be in 'owner/repo' format."
}

# Validate security policy on PackageName and Repo
if ($Config.security_policy) {
    if ($Config.security_policy.deny_patterns) {
        foreach ($pattern in $Config.security_policy.deny_patterns) {
            if ($Repo -match $pattern) {
                throw "Repository '$Repo' violates security pattern '$pattern'."
            }
            if ($PackageName -match $pattern) {
                throw "PackageName '$PackageName' violates security pattern '$pattern'."
            }
        }
    }
}

if ($Config.dep_to_skill_map.$PackageName) {
    Write-Warning "Package '$PackageName' already maps to '$($Config.dep_to_skill_map.$PackageName)'. Updating to '$Repo'."
}

$Config.dep_to_skill_map | Add-Member -MemberType NoteProperty -Name $PackageName -Value $Repo -Force

# Convert back to JSON and format nicely
$JsonOutput = ConvertTo-Json $Config -Depth 10
$JsonOutput = $JsonOutput -replace '\\u003e', '>'

Set-Content -Path $ConfigFile -Value $JsonOutput -Force

Write-Information "Successfully injected '$PackageName' -> '$Repo' into sovereign.config.json" -InformationAction Continue

# Trigger checksum update if it exists
if (Test-Path "C:\Skills\agent-bootstrap\scripts\update-checksum.ps1") {
    pwsh -NoProfile -File "C:\Skills\agent-bootstrap\scripts\update-checksum.ps1"
}

# Automatically fetch the cloud skill to local cache
$FetchScript = "C:\Skills\agent-bootstrap\scripts\Fetch-CloudSkill.ps1"
if (Test-Path $FetchScript) {
    Write-Information "Auto-fetching dependency '$Repo'..." -InformationAction Continue
    pwsh -NoProfile -File $FetchScript -Repo $Repo
}
