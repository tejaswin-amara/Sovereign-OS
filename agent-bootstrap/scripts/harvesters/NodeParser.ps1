Set-StrictMode -Version Latest

function Get-NodeDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedWorkspace
    )
    
    $ExcludedDirs = @(".git", "node_modules", ".agents", ".quarantine", "LOGS", "templates", "servers")
    
    $DetectedDeps = @()
    $PkgJsonPaths = Get-SovereignManifestFiles -Path $ResolvedWorkspace -Filter "package.json" -Exclusions $ExcludedDirs
    
    foreach ($PkgPath in $PkgJsonPaths) {
        if (Test-Path -LiteralPath $PkgPath) {
            try {
                $Content = Get-Content -LiteralPath $PkgPath -Raw -ErrorAction SilentlyContinue
                if ($Content) {
                    $Pkg = ConvertFrom-Json $Content -ErrorAction SilentlyContinue
                    if ($Pkg) {
                        if ($Pkg.dependencies) {
                            if ($Pkg.dependencies -is [System.Collections.IDictionary]) {
                                $DetectedDeps += $Pkg.dependencies.Keys
                            } elseif ($Pkg.dependencies -is [PSCustomObject]) {
                                $DetectedDeps += $Pkg.dependencies.PSObject.Properties.Name
                            }
                        }
                        if ($Pkg.devDependencies) {
                            if ($Pkg.devDependencies -is [System.Collections.IDictionary]) {
                                $DetectedDeps += $Pkg.devDependencies.Keys
                            } elseif ($Pkg.devDependencies -is [PSCustomObject]) {
                                $DetectedDeps += $Pkg.devDependencies.PSObject.Properties.Name
                            }
                        }
                    }
                }
            } catch {
                Write-SovereignLog -Level "WARN" -Step "HARVEST" -Message "Failed to parse $($PkgPath): $_"
            }
        }
    }
    return ($DetectedDeps | Select-Object -Unique)
}
