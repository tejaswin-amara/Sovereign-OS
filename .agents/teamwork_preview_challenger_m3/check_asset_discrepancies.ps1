# check_asset_discrepancies.ps1 - Audit Asset Registry alignment
param (
    [string]$Root = "C:\Skills"
)

Write-Output "=== 1. SUBMODULE ALIGNMENT (sovereign.config.json vs .gitmodules vs actual filesystem) ==="

$config = Get-Content (Join-Path $Root "sovereign.config.json") -Raw | ConvertFrom-Json
$configSubmodules = $config.submodules.psobject.properties.Name

$gitmodulesContent = Get-Content (Join-Path $Root ".gitmodules") -Raw
$gitmodulePaths = [regex]::Matches($gitmodulesContent, 'path = (.*)') | ForEach-Object { $_.Groups[1].Value.Trim() }

Write-Output ("Submodules in sovereign.config.json ({0}): {1}" -f $configSubmodules.Count, ($configSubmodules -join ", "))
Write-Output ("Submodules in .gitmodules ({0}): {1}" -f $gitmodulePaths.Count, ($gitmodulePaths -join ", "))

# Check for submodules in root that are NOT in sovereign.config.json
foreach ($gp in $gitmodulePaths) {
    $foundInConfig = $false
    foreach ($cs in $configSubmodules) {
        if ($config.submodules.$cs.path -eq $gp) {
            $foundInConfig = $true
            break
        }
    }
    if (-not $foundInConfig) {
        Write-Output ("DISCREPANCY: Submodule '{0}' is in .gitmodules but NOT in sovereign.config.json!" -f $gp)
    }
}

Write-Output "`n=== 2. CHECK IF ANY ASSET FROM ASSET_REGISTRY.MD IS STABLE/ILLEGALLY VENDORED AS SUBMODULE ==="
$assetRegistryContent = Get-Content (Join-Path $Root "ASSET_REGISTRY.md") -Raw
$assetNames = @("checkout", "goreleaser", "trivy", "gosec", "golangci-lint", "cobra", "viper", "zap", "zerolog", "langchaingo", "open-agent-framework-go", "shadcn-ui", "tailwindcss")

foreach ($asset in $assetNames) {
    foreach ($gp in $gitmodulePaths) {
        if ($gp -like "*$asset*") {
            Write-Output ("VIOLATION: Asset '{0}' from ASSET_REGISTRY.md is added as a Git Submodule at '{1}'!" -f $asset, $gp)
        }
    }
}

Write-Output "`n=== 3. CHECK FOR UNREGISTERED SUBMODULES OR DIRECTORIES IN modules/ AND skills/ ==="
$moduleDirs = Get-ChildItem (Join-Path $Root "modules") -Directory | ForEach-Object { "modules/$($_.Name)" }
$skillDirs = Get-ChildItem (Join-Path $Root "skills") -Directory | Where-Object { $_.Name -ne ".agents" } | ForEach-Object { "skills/$($_.Name)" }

$actualDirs = $moduleDirs + $skillDirs
foreach ($ad in $actualDirs) {
    if ($gitmodulePaths -notcontains $ad) {
        Write-Output ("DISCREPANCY: Directory '{0}' exists on disk but is NOT registered in .gitmodules!" -f $ad)
    }
}

Write-Output "`n=== 4. ASSET INTEGRATION LOGGING CHECK IN AUDIT_LEDGER.MD ==="
$auditLedgerContent = Get-Content (Join-Path $Root "AUDIT_LEDGER.md") -Raw
Write-Output "Checking AUDIT_LEDGER.md Section 3 (Dynamic Asset Registry):"
if ($auditLedgerContent -match "Dynamic Asset Registry") {
    Write-Output "Found 'Dynamic Asset Registry' section in AUDIT_LEDGER.md."
} else {
    Write-Output "MISSING: 'Dynamic Asset Registry' section not found in AUDIT_LEDGER.md."
}
