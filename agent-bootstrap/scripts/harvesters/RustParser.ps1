Set-StrictMode -Version Latest

function Get-RustDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedWorkspace
    )
    
    $ExcludedDirs = @(".git", "node_modules", ".agents", ".quarantine", "LOGS", "templates", "servers")
    
    function Get-ManifestFiles {
        param(
            [string]$Path,
            [string]$Filter,
            [string[]]$Exclusions
        )
        $Files = [System.Collections.Generic.List[string]]::new()
        
        try {
            $Info = [System.IO.DirectoryInfo]::new($Path)
            if ($Info.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
                return $Files
            }
        } catch {
            return $Files
        }
        
        try {
            $Matched = Get-ChildItem -LiteralPath $Path -Filter $Filter -File -ErrorAction SilentlyContinue
            foreach ($f in $Matched) {
                [void]$Files.Add($f.FullName)
            }
        } catch {}
        
        try {
            $SubDirs = Get-ChildItem -LiteralPath $Path -Directory -ErrorAction SilentlyContinue
            foreach ($dir in $SubDirs) {
                if ($dir.Name -notin $Exclusions -and $dir.Name -notmatch '^\.') {
                    $SubFiles = Get-ManifestFiles -Path $dir.FullName -Filter $Filter -Exclusions $Exclusions
                    if ($null -ne $SubFiles) {
                        foreach ($file in $SubFiles) {
                            [void]$Files.Add($file)
                        }
                    }
                }
            }
        } catch {}
        
        return $Files
    }

    $DetectedDeps = @()
    $CargoPaths = Get-ManifestFiles -Path $ResolvedWorkspace -Filter "Cargo.toml" -Exclusions $ExcludedDirs
    
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
