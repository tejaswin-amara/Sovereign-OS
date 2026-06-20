Set-StrictMode -Version Latest

function Get-DotNetDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedWorkspace
    )
    
    $ExcludedDirs = @(".git", "node_modules", ".agents", ".quarantine", "LOGS", "templates", "servers")
    
    $DetectedDeps = @()
    $CsprojFiles = Get-SovereignManifestFiles -Path $ResolvedWorkspace -Filter "*.csproj" -Exclusions $ExcludedDirs
    
    foreach ($csproj in $CsprojFiles) {
        if (Test-Path -LiteralPath $csproj) {
            $CsprojContent = Get-Content -LiteralPath $csproj -Raw -ErrorAction SilentlyContinue
            if ($CsprojContent) {
                $CleanContent = $CsprojContent -replace '(?s)<!--.*?-->', ''
                $MatchesCsproj = [regex]::Matches($CleanContent, '(?s)(?i)<PackageReference\s+[^>]*?Include\s*=\s*([''"])(?<dep>[a-zA-Z0-9._-]+)\1')
                foreach ($m in $MatchesCsproj) {
                    $DetectedDeps += $m.Groups['dep'].Value
                }
            }
        }
    }
    return ($DetectedDeps | Select-Object -Unique)
}
