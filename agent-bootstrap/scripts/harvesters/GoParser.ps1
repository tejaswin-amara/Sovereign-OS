Set-StrictMode -Version Latest

function Get-GoDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedWorkspace
    )
    
    $ExcludedDirs = @(".git", "node_modules", ".agents", ".quarantine", "LOGS", "templates", "servers")
    
    $DetectedDeps = @()
    $GoModPaths = Get-SovereignManifestFiles -Path $ResolvedWorkspace -Filter "go.mod" -Exclusions $ExcludedDirs
    
    foreach ($GoMod in $GoModPaths) {
        if (Test-Path -LiteralPath $GoMod) {
            $GoLines = Get-Content -LiteralPath $GoMod -ErrorAction SilentlyContinue
            if ($GoLines) {
                $InRequire = $false
                foreach ($line in $GoLines) {
                    $trimmed = $line.Trim()
                    if ($trimmed -match '^require\s*\(') {
                        $InRequire = $true
                        continue
                    }
                    if ($InRequire -and ($trimmed -eq ')')) {
                        $InRequire = $false
                        continue
                    }
                    if ($InRequire -and ($trimmed -match '^(?<dep>[a-zA-Z0-9._/-]+)\s+v[0-9]')) {
                        $FullPath = $Matches['dep'].Trim()
                        $DetectedDeps += $FullPath
                        $DetectedDeps += ($FullPath -split '/')[-1]
                    }
                    if (-not $InRequire -and ($trimmed -match '^require\s+(?<dep>[a-zA-Z0-9._/-]+)\s+v[0-9]')) {
                        $FullPath = $Matches['dep'].Trim()
                        $DetectedDeps += $FullPath
                        $DetectedDeps += ($FullPath -split '/')[-1]
                    }
                }
            }
        }
    }
    return ($DetectedDeps | Select-Object -Unique)
}
