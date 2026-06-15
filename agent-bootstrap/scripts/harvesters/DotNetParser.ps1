Set-StrictMode -Version Latest

function Get-DotNetDependencies {
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
    $CsprojFiles = Get-ManifestFiles -Path $ResolvedWorkspace -Filter "*.csproj" -Exclusions $ExcludedDirs
    
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
