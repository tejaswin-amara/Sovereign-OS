Set-StrictMode -Version Latest

function Get-JavaDependencies {
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
    
    # 1. Maven Scan (pom.xml) recursively
    $PomXmlPaths = Get-ManifestFiles -Path $ResolvedWorkspace -Filter "pom.xml" -Exclusions $ExcludedDirs
    foreach ($PomXml in $PomXmlPaths) {
        if (Test-Path -LiteralPath $PomXml) {
            $PomContent = Get-Content -LiteralPath $PomXml -Raw -ErrorAction SilentlyContinue
            if ($PomContent) {
                # Trim UTF-8 BOM if present
                $PomContent = $PomContent.Trim([char]0xFEFF)
                # Strip XML comments first
                $CleanContent = $PomContent -replace '(?s)<!--.*?-->', ''
                # Case-insensitive matching
                $DepBlocks = [regex]::Matches($CleanContent, '(?s)(?i)<dependency>(.*?)</dependency>')
                foreach ($block in $DepBlocks) {
                    $art = $null
                    $grp = $null
                    if ($block.Value -match '(?i)<artifactId>([^<]+)</artifactId>') {
                        $art = $Matches[1].Trim()
                        $DetectedDeps += $art
                    }
                    if ($block.Value -match '(?i)<groupId>([^<]+)</groupId>') {
                        $grp = $Matches[1].Trim()
                    }
                    if ($grp -and $art) {
                        $DetectedDeps += $art
                        $DetectedDeps += "$($grp):$($art)"
                    }
                }
            }
        }
    }
    
    # 2. Gradle Scan (build.gradle / build.gradle.kts) recursively
    $GradleFiles = [System.Collections.Generic.List[string]]::new()
    $Files1 = Get-ManifestFiles -Path $ResolvedWorkspace -Filter "build.gradle" -Exclusions $ExcludedDirs
    if ($null -ne $Files1) {
        foreach ($f in $Files1) { [void]$GradleFiles.Add($f) }
    }
    $Files2 = Get-ManifestFiles -Path $ResolvedWorkspace -Filter "build.gradle.kts" -Exclusions $ExcludedDirs
    if ($null -ne $Files2) {
        foreach ($f in $Files2) { [void]$GradleFiles.Add($f) }
    }
    
    foreach ($GradlePath in $GradleFiles) {
        if (Test-Path -LiteralPath $GradlePath) {
            $GradleContent = Get-Content -LiteralPath $GradlePath -Raw -ErrorAction SilentlyContinue
            if ($GradleContent) {
                # Trim UTF-8 BOM if present
                $GradleContent = $GradleContent.Trim([char]0xFEFF)
                # Read line-by-line to handle platform/BOM and named-arguments accurately
                $Lines = $GradleContent -split '\r?\n'
                foreach ($line in $Lines) {
                    # Skip commented out lines
                    if ($line -match '^\s*//') {
                        continue
                    }
                    # Check if line contains a dependency declaration configuration
                    if ($line -match '(?:implementation|api|testImplementation|runtimeOnly|compileOnly)') {
                        # 1. Named arguments format: e.g. group: 'org.springframework', name: 'spring-core'
                        # or group = "org.springframework", name = "spring-core"
                        $hasGroup = $line -match 'group\s*[:=]\s*[''"](?<grp>[a-zA-Z0-9._-]+)[''"]'
                        $grpVal = if ($hasGroup) { $Matches['grp'] } else { $null }
                        
                        $hasName = $line -match 'name\s*[:=]\s*[''"](?<art>[a-zA-Z0-9._-]+)[''"]'
                        $artVal = if ($hasName) { $Matches['art'] } else { $null }
                        
                        if ($grpVal -and $artVal) {
                            $DetectedDeps += $artVal
                            $DetectedDeps += "$($grpVal):$($artVal)"
                            continue
                        }
                        
                        # 2. Standard string format, supporting optional platform()
                        $isMatch = $line -match '(?:implementation|api|testImplementation|runtimeOnly|compileOnly)\s*\(?\s*(?:platform\s*\(?\s*)?[''"](?<dep>[a-zA-Z0-9._-]+):(?<artifact>[a-zA-Z0-9._-]+)(?::[^''"]*)?[''"]'
                        if ($isMatch) {
                            $dep = $Matches['dep']
                            $art = $Matches['artifact']
                            if ($dep -and $art) {
                                $DetectedDeps += $art
                                $DetectedDeps += "$($dep):$($art)"
                            }
                        }
                    }
                }
            }
        }
    }
    
    return ($DetectedDeps | Select-Object -Unique)
}
