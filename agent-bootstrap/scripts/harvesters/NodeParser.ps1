Set-StrictMode -Version Latest

function Get-NodeDependencies {
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
    $PkgJsonPaths = Get-ManifestFiles -Path $ResolvedWorkspace -Filter "package.json" -Exclusions $ExcludedDirs
    
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
