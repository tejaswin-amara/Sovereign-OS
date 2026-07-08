$files = @(
    "C:/Skills/agent-bootstrap/scripts/skill-harvester.ps1"
    "C:/Skills/sovereign.ps1"
    "C:/Skills/bootstrap.ps1"
    "C:/Skills/agent-bootstrap/scripts/helpers.psm1"
)
$allOk = $true
foreach ($f in $files) {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$tokens, [ref]$errors)
    if ($errors.Count -gt 0) {
        Write-Host "FAIL: $f"
        $errors | ForEach-Object { Write-Host "  $_" }
        $allOk = $false
    } else {
        Write-Host "OK: $f"
    }
}
if ($allOk) { Write-Host "`nAll files parse clean." }
