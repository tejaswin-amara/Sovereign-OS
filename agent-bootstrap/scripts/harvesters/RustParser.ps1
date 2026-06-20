Set-StrictMode -Version Latest

function Get-RustDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedWorkspace
    )
    
    $ExcludedDirs = @(".git", "node_modules", ".agents", ".quarantine", "LOGS", "templates", "servers")
    
    $DetectedDeps = @()
    $CargoPaths = Get-SovereignManifestFiles -Path $ResolvedWorkspace -Filter "Cargo.toml" -Exclusions $ExcludedDirs
    
    foreach ($CargoToml in $CargoPaths) {
        if (Test-Path -LiteralPath $CargoToml) {
            $InDeps = $false
            $CargoLines = Get-Content -LiteralPath $CargoToml -ErrorAction SilentlyContinue
            if ($CargoLines) {
                foreach ($line in $CargoLines) {
                    $trimmed = $line.Trim()
                    if ($trimmed -match '^\[.*dependencies\.(?<dep>[a-zA-Z0-9_-]+)\]') {
                        $DetectedDeps += $Matches['dep'].Trim()
                        $InDeps = $false
                        continue
                    }
                    if ($trimmed -match '^\[.*dependencies.*\]') {
                        $InDeps = $true
                        continue
                    }
                    if ($trimmed -match '^\[.*\]') {
                        $InDeps = $false
                        continue
                    }
                    if ($InDeps -and ($trimmed -match '^(?<dep>[a-zA-Z0-9_-]+)\s*=')) {
                        $DetectedDeps += $Matches['dep'].Trim()
                    }
                }
            }
        }
    }
    return ($DetectedDeps | Select-Object -Unique)
}
