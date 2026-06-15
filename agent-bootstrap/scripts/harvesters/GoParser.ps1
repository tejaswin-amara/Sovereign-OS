Set-StrictMode -Version Latest

function Get-GoDependencies {
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
    $GoModPaths = Get-ManifestFiles -Path $ResolvedWorkspace -Filter "go.mod" -Exclusions $ExcludedDirs
    
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
