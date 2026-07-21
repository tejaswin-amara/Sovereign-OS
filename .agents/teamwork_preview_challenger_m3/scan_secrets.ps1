# scan_secrets.ps1 - Scan for hardcoded secrets/tokens
param (
    [string]$Root = "C:\Skills"
)

$patterns = @(
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

$files = Get-ChildItem -Path $Root -Recurse -Include *.ps1,*.go,*.json,*.md,*.yml,*.yaml | Where-Object { $_.FullName -notmatch '\\\.git\\' }
$found = @()

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    foreach ($pat in $patterns) {
        $matches = [regex]::Matches($content, $pat)
        foreach ($m in $matches) {
            $val = $m.Value
            # Exclude known dummy test fixtures/examples
            if ($val -notmatch 'abcdefghijklmnopqrst' -and $val -notmatch 'sk-ant-\.\.\.' -and $val -notmatch 'sk-your_key_here') {
                $found += [PSCustomObject]@{
                    File = $file.FullName.Replace("$Root\", "")
                    Pattern = $pat
                    Match = $val
                }
            }
        }
    }
}

if ($found.Count -eq 0) {
    Write-Output "RESULT: NO_HARDCODED_SECRETS_FOUND"
} else {
    Write-Output "RESULT: HARDCODED_SECRETS_DETECTED ($($found.Count) matches)"
    $found | Format-Table -AutoSize
}
