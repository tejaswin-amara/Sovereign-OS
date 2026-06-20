Set-StrictMode -Version Latest

function Get-PythonDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedWorkspace
    )
    
    $ExcludedDirs = @(".git", "node_modules", ".agents", ".quarantine", "LOGS", "templates", "servers")
    
    $DetectedDeps = @()
    
    # 1. Parse requirements.txt files
    $ReqTxtPaths = Get-SovereignManifestFiles -Path $ResolvedWorkspace -Filter "requirements.txt" -Exclusions $ExcludedDirs
    foreach ($ReqPath in $ReqTxtPaths) {
        if (Test-Path -LiteralPath $ReqPath) {
            $Lines = Get-Content -LiteralPath $ReqPath -ErrorAction SilentlyContinue
            if ($Lines) {
                foreach ($line in $Lines) {
                    $trimmedLine = $line.Trim()
                    if ($trimmedLine -and -not $trimmedLine.StartsWith("#") -and -not $trimmedLine.StartsWith("-r")) {
                        # Handle editable prefix
                        $lineWithoutE = $trimmedLine
                        $isEditable = $false
                        if ($trimmedLine -match '^-(?:e|-editable)\s+(.*)$') {
                            $lineWithoutE = $Matches[1].Trim()
                            $isEditable = $true
                        }

                        # Filter out editable local installs
                        if ($isEditable) {
                            $isLocalPath = $lineWithoutE -match '^(\.|\/|\\|~)' -or ($lineWithoutE -notmatch '://' -and $lineWithoutE -notmatch '@' -and $lineWithoutE -notmatch '^(git\+|git:|https?:|local:|ssh:)')
                            if ($isLocalPath) {
                                continue
                            }
                        }

                        # Extract name from egg parameter if present, otherwise clean and parse normally
                        if ($lineWithoutE -match '#egg=(?<egg>[a-zA-Z0-9._-]+)') {
                            $DetectedDeps += $Matches['egg'].Trim()
                        } else {
                            $cleanLine = ($lineWithoutE -split '#')[0].Trim()
                            $cleanLine = ($cleanLine -split ';')[0].Trim()
                            if ($cleanLine) {
                                if ($cleanLine -match '^(?:git\+|git:|https?:|local:|ssh:).*?/(?<egg>[a-zA-Z0-9._-]+)(?:\.git)?(?:@[\w.-]+)?$') {
                                    $DetectedDeps += $Matches['egg'].Trim()
                                } else {
                                    $pkg = ($cleanLine -split '[=<>!~]')[0].Trim()
                                    if ($pkg) {
                                        $DetectedDeps += $pkg
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    # 2. Parse pyproject.toml files
    $PyProjectPaths = Get-SovereignManifestFiles -Path $ResolvedWorkspace -Filter "pyproject.toml" -Exclusions $ExcludedDirs
    foreach ($TomlPath in $PyProjectPaths) {
        if (Test-Path -LiteralPath $TomlPath) {
            $TomlContent = Get-Content -LiteralPath $TomlPath -Raw -ErrorAction SilentlyContinue
            if ($TomlContent) {
                # Trim UTF-8 BOM if present
                $TomlContent = $TomlContent.Trim([char]0xFEFF)
                $Lines = $TomlContent -split '\r?\n'
                
                $InDeps = $false
                $InOptionalDeps = $false
                $InPep621Deps = $false
                $InBraces = $false
                $ExcludeKeys = @("version", "git", "branch", "rev", "optional", "extras", "python", "path", "tag", "markers", "ref", "develop")
                
                foreach ($line in $Lines) {
                    $trimmed = $line.Trim()
                    if ($trimmed -eq "" -or $trimmed.StartsWith("#")) {
                        continue
                    }
                    
                    # Section headers
                    if ($trimmed -match '^\[project\.optional-dependencies\]') {
                        $InOptionalDeps = $true
                        $InDeps = $false
                        $InPep621Deps = $false
                        $InBraces = $false
                        continue
                    }
                    if ($trimmed -match '^\[project\.dependencies\]' -or 
                        $trimmed -match '^\[tool\.poetry\..*dependencies\]') {
                        $InDeps = $true
                        $InOptionalDeps = $false
                        $InPep621Deps = $false
                        $InBraces = $false
                        continue
                    }
                    if ($trimmed -match '^\[.*\]') {
                        $InDeps = $false
                        $InOptionalDeps = $false
                        $InPep621Deps = $false
                        $InBraces = $false
                        continue
                    }
                    
                    # Single-line PEP 621 array check
                    if (($trimmed -match '^dependencies\s*=\s*\[(?<content>[^\]]*)\]') -or 
                        ($InOptionalDeps -and $trimmed -match '^[a-zA-Z0-9._-]+\s*=\s*\[(?<content>[^\]]*)\]')) {
                        $content = $Matches['content']
                        $matches = [regex]::Matches($content, '["''](?<dep>[a-zA-Z0-9._-]+)(?:[^"'']*)["'']')
                        foreach ($m in $matches) {
                            $depName = $m.Groups['dep'].Value.Trim()
                            if ($depName -notin $ExcludeKeys) {
                                $DetectedDeps += $depName
                            }
                        }
                        continue
                    }
                    
                    # Multiline array start
                    if ($trimmed -match '^dependencies\s*=\s*\[') {
                        $InPep621Deps = $true
                        $InDeps = $false
                        $InOptionalDeps = $false
                        continue
                    }
                    if ($InOptionalDeps -and $trimmed -match '^[a-zA-Z0-9._-]+\s*=\s*\[') {
                        $InPep621Deps = $true
                        continue
                    }
                    
                    # Multiline array end
                    if ($InPep621Deps -and $trimmed -eq ']') {
                        $InPep621Deps = $false
                        continue
                    }
                    
                    # Parse inside multiline array
                    if ($InPep621Deps) {
                        if ($trimmed -match '^["''](?<dep>[a-zA-Z0-9._-]+)(?:[^"'']*)["'']') {
                            $depName = $Matches['dep'].Trim()
                            if ($depName -notin $ExcludeKeys) {
                                $DetectedDeps += $depName
                            }
                        }
                        continue
                    }
                    
                    # Trace braces for multiline table attribute pollution
                    if ($trimmed -match '\{' -and $trimmed -notmatch '\}') {
                        $InBraces = $true
                    }
                    
                    # Parse standard table dependencies (e.g. poetry style)
                    if ($InDeps -and -not $InBraces) {
                        if ($trimmed -match '^(?<dep>[a-zA-Z0-9._-]+)\s*=') {
                            $depName = $Matches['dep'].Trim()
                            if ($depName -notin $ExcludeKeys) {
                                $DetectedDeps += $depName
                            }
                        }
                    }
                    
                    # Exit braces if closing brace is encountered
                    if ($trimmed -match '\}') {
                        $InBraces = $false
                    }
                }
            }
        }
    }
    
    return ($DetectedDeps | Select-Object -Unique)
}
