# run_m3_audit_suite.ps1 - Master Verification Harness for Challenger M3
param (
    [string]$ProjectRoot = "C:\Skills"
)

$ErrorActionPreference = "Continue"

Write-Output "===================================================="
Write-Output "SOVEREIGN-OS V16 PONYTAIL AUDIT VERIFIER (M3)"
Write-Output "Execution Timestamp: $(Get-Date -Format 'o')"
Write-Output "===================================================="

# 1. SECRET SCAN
Write-Output "`n[CHECK 1] SCANNING FOR HARDCODED SECRETS AND TOKENS..."
$secretPatterns = @(
    'ghp_[a-zA-Z0-9]{36}',
    'gho_[a-zA-Z0-9]{36}',
    'github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}',
    'sk-[a-zA-Z0-9]{32,}',
    'sk-ant-[a-zA-Z0-9\-_]{32,}',
    'AKIA[0-9A-Z]{16}',
    'AIza[0-9A-Za-z-_]{35}',
    '-----BEGIN [A-Z ]*PRIVATE KEY-----',
    'xox[baprs]-[0-9a-zA-Z]{10,}'
)

$scanFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Include *.ps1,*.go,*.json,*.md,*.yml,*.yaml | Where-Object { $_.FullName -notmatch '\\\.git\\' }
$secretFindings = @()

foreach ($file in $scanFiles) {
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    foreach ($pat in $secretPatterns) {
        $matches = [regex]::Matches($content, $pat)
        foreach ($m in $matches) {
            $val = $m.Value
            $relPath = $file.FullName.Replace("$ProjectRoot\", "")
            $isTestFixture = ($relPath -match 'test' -or $val -match 'abcdef' -or $val -match 'sk-ant-\.\.\.' -or $val -match 'sk-your_key_here')
            $secretFindings += [PSCustomObject]@{
                File = $relPath
                Pattern = $pat
                Match = $val
                Classification = if ($isTestFixture) { "TEST_FIXTURE_REDACTION_TEST" } else { "ACTIVE_HARDCODED_SECRET" }
            }
        }
    }
}

Write-Output ("Total Secret Pattern Matches: {0}" -f $secretFindings.Count)
$secretFindings | Format-Table -AutoSize

# 2. BLOAT & UNTRACKED BINARY SCAN
Write-Output "`n[CHECK 2] SCANNING FOR UNTRACKED, IGNORED, OR LARGE BINARY BLOAT..."

$gitUntracked = git -C $ProjectRoot ls-files --others --exclude-standard
Write-Output ("Untracked Files (excluding .agents metadata): {0}" -f ($gitUntracked | Where-Object { $_ -notmatch '^\.agents' }).Count)
$gitUntracked | Where-Object { $_ -notmatch '^\.agents' } | ForEach-Object { Write-Output "  - $_" }

$gitIgnored = git -C $ProjectRoot ls-files --others --ignored --exclude-standard
Write-Output ("Ignored Files: {0}" -f $gitIgnored.Count)
$gitIgnored | ForEach-Object { Write-Output "  - $_" }

$largeFiles = Get-ChildItem -Path $ProjectRoot -Recurse -File | Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.Length -gt 500000 }
Write-Output ("Large Files (> 500 KB): {0}" -f $largeFiles.Count)
$largeFiles | Select-Object @{N="Path";E={$_.FullName.Replace("$ProjectRoot\", "")}}, @{N="Size_MB";E={[math]::Round($_.Length/1MB, 2)}} | Format-Table -AutoSize

# 3. ASSET REGISTRY DISCREPANCY SCAN
Write-Output "`n[CHECK 3] AUDITING ASSET REGISTRY & SUBMODULE ALIGNMENT..."

$configJson = Get-Content (Join-Path $ProjectRoot "sovereign.config.json") -Raw | ConvertFrom-Json
$configSubmodules = $configJson.submodules.psobject.properties.Name

$gitmodulesContent = Get-Content (Join-Path $ProjectRoot ".gitmodules") -Raw
$gitmodulePaths = [regex]::Matches($gitmodulesContent, 'path = (.*)') | ForEach-Object { $_.Groups[1].Value.Trim() }

Write-Output "Config submodules: $($configSubmodules -join ', ')"
Write-Output "Gitmodules paths:  $($gitmodulePaths -join ', ')"

$diskModules = Get-ChildItem (Join-Path $ProjectRoot "modules") -Directory | ForEach-Object { "modules/$($_.Name)" }
$diskSkills = Get-ChildItem (Join-Path $ProjectRoot "skills") -Directory | Where-Object { $_.Name -ne ".agents" } | ForEach-Object { "skills/$($_.Name)" }

$allDiskDirs = $diskModules + $diskSkills
$unregisteredDirs = @()
foreach ($d in $allDiskDirs) {
    if ($gitmodulePaths -notcontains $d) {
        $unregisteredDirs += $d
    }
}
Write-Output ("Unregistered Disk Module/Skill Directories ({0}):" -f $unregisteredDirs.Count)
$unregisteredDirs | ForEach-Object { Write-Output "  [DISCREPANCY] Unregistered directory in Git: $_" }

# 4. AUDIT LEDGER LOGGING VERIFICATION
Write-Output "`n[CHECK 4] VERIFYING RUNTIME ASSET INTEGRATION LOGGING IN AUDIT_LEDGER.MD..."

$cliGoMod = Join-Path $ProjectRoot "modules\sovereign-cli\go.mod"
$uiPackageJson = Join-Path $ProjectRoot "modules\sovereign-ui\package.json"
$auditLedger = Join-Path $ProjectRoot "AUDIT_LEDGER.md"

$cliDeps = @()
if (Test-Path $cliGoMod) {
    $cliContent = Get-Content $cliGoMod -Raw
    $cliDeps = [regex]::Matches($cliContent, 'github\.com/([^\s]+)|go\.uber\.org/([^\s]+)') | ForEach-Object { $_.Value }
}

$uiDeps = @()
if (Test-Path $uiPackageJson) {
    $uiContent = Get-Content $uiPackageJson -Raw
    $uiDeps = @("tailwindcss", "lucide-react", "next", "react") | Where-Object { $uiContent -match $_ }
}

$auditLedgerText = Get-Content $auditLedger -Raw

Write-Output "Integrated dependencies in modules/sovereign-cli:"
$cliDeps | ForEach-Object { Write-Output "  - $_" }

Write-Output "Integrated dependencies in modules/sovereign-ui:"
$uiDeps | ForEach-Object { Write-Output "  - $_" }

Write-Output "`nVerifying if these dependencies are logged in AUDIT_LEDGER.md:"
$missingLogs = @()
foreach ($dep in ($cliDeps + $uiDeps)) {
    if ($auditLedgerText -match [regex]::Escape($dep)) {
        Write-Output "  [LOGGED] $dep"
    } else {
        Write-Output "  [UNLOGGED / MISSING] $dep"
        $missingLogs += $dep
    }
}

if ($missingLogs.Count -gt 0) {
    Write-Output "`nVERIFICATION RESULT: AUDIT_LEDGER.md is INCOMPLETE/UNLOGGED ($($missingLogs.Count) integrated assets missing from ledger)."
} else {
    Write-Output "`nVERIFICATION RESULT: AUDIT_LEDGER.md is FULLY LOGGED."
}

Write-Output "`n===================================================="
Write-Output "AUDIT SUITE COMPLETE"
Write-Output "===================================================="
