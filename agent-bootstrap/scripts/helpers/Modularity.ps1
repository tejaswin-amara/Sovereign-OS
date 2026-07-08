# C:/Skills/agent-bootstrap/scripts/helpers/Modularity.ps1
Set-StrictMode -Version Latest

function Assert-ModuleCap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentDir,
        [Parameter(Mandatory = $false)]
        [int]$Cap = 0
    )

    if ($Cap -le 0) {
        $ConfigCap = Get-SovereignConfig -KeyPath "governance.module_cap"
        $Cap = if ($ConfigCap) { [int]$ConfigCap } else { 32 }
    }

    $RulesCount = 0
    $WorkflowsCount = 0

    $RulesDir = Join-Path $AgentDir "rules"
    $WorkflowsDir = Join-Path $AgentDir "workflows"

    if (Test-Path $RulesDir) {
        $RulesCount = @(Get-ChildItem $RulesDir -Filter "*.md" -ErrorAction SilentlyContinue).Count
    }
    if (Test-Path $WorkflowsDir) {
        $WorkflowsCount = @(Get-ChildItem $WorkflowsDir -Filter "*.md" -ErrorAction SilentlyContinue).Count
    }

    $Total = $RulesCount + $WorkflowsCount

    if ($Total -gt $Cap) {
        $ErrorMsg = "MODULE_CAP_EXCEEDED: $Total modules found ($RulesCount rules + $WorkflowsCount workflows) exceeds hard cap of $Cap. BLOCKING ALL WRITES."
        Write-SovereignLog -Level "ERROR" -Step "MODULE_CAP" -Message $ErrorMsg
        throw $ErrorMsg
    }

    Write-SovereignLog -Level "INFO" -Step "MODULE_CAP" -Message "Module count OK: $Total/$Cap ($RulesCount rules + $WorkflowsCount workflows)"
    return @{ Rules = $RulesCount; Workflows = $WorkflowsCount; Total = $Total; Cap = $Cap }
}

function Get-DynamicSkillCount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SkillsRoot,
        [Parameter(Mandatory=$true)]
        [string[]]$ExcludedDirs
    )
    # ponytail: skills live under $SkillsRoot/skills/. Count subdirs containing SKILL.md.
    $SkillsDir = Join-Path $SkillsRoot "skills"
    if (-not (Test-Path $SkillsDir)) { return 0 }
    $AllDirs = Get-ChildItem -Path $SkillsDir -Directory |
        Where-Object { $_.Name -notmatch '^\.' } |
        Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") }
    return @($AllDirs).Count
}

function Get-SovereignManifestFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Filter,
        [Parameter(Mandatory = $true)]
        [string[]]$Exclusions
    )
    $Files = [System.Collections.Generic.List[string]]::new()
    
    try {
        $Info = [System.IO.DirectoryInfo]::new($Path)
        if ($Info.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
            return $Files
        }
    } catch {
        Write-SovereignLog -Level "WARN" -Step "MODULARITY" -Message "Failed to read directory info for $($Path): $_"
        return $Files
    }
    
    try {
        $Matched = Get-ChildItem -LiteralPath $Path -Filter $Filter -File -ErrorAction SilentlyContinue
        foreach ($f in $Matched) {
            [void]$Files.Add($f.FullName)
        }
    } catch {
        Write-SovereignLog -Level "WARN" -Step "MODULARITY" -Message "Failed to get child items for $($Path): $_"
    }
    
    try {
        $SubDirs = Get-ChildItem -LiteralPath $Path -Directory -ErrorAction SilentlyContinue
        foreach ($dir in $SubDirs) {
            if ($dir.Name -notin $Exclusions -and $dir.Name -notmatch '^\.') {
                $SubFiles = Get-SovereignManifestFiles -Path $dir.FullName -Filter $Filter -Exclusions $Exclusions
                if ($null -ne $SubFiles) {
                    foreach ($file in $SubFiles) {
                        [void]$Files.Add($file)
                    }
                }
            }
        }
    } catch {
        Write-SovereignLog -Level "WARN" -Step "MODULARITY" -Message "Failed to traverse subdirectories for $($Path): $_"
    }
    
    return $Files
}

function Get-FilteredProjectFiles {
    # ponytail: single shared file walker replacing 3 duplicate implementations.
    # Upgrade path: if this becomes a bottleneck, switch to [System.IO.Directory]::EnumerateFiles with parallel processing.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$RootPath,
        [Parameter(Mandatory=$false)]
        [string[]]$Extensions = @(".ps1", ".psm1", ".js", ".ts", ".tsx", ".jsx", ".md", ".py"),
        [Parameter(Mandatory=$false)]
        [string[]]$ExcludeDirs = @()
    )
    
    if (-not $ExcludeDirs -or $ExcludeDirs.Count -eq 0) {
        $ConfigExclude = Get-SovereignConfig -KeyPath "governance.harvester_excluded_dirs"
        $ExcludeDirs = if ($ConfigExclude) { @($ConfigExclude) } else { @(".git", "node_modules", "LOGS") }
    }
    
    $Files = [System.Collections.Generic.List[string]]::new()
    $ExcludeSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$ExcludeDirs, [System.StringComparer]::OrdinalIgnoreCase)
    
    $Walker = {
        param([string]$CurrentPath)
        try {
            foreach ($Dir in [System.IO.Directory]::EnumerateDirectories($CurrentPath)) {
                $DirName = [System.IO.Path]::GetFileName($Dir)
                if (-not $ExcludeSet.Contains($DirName) -and $DirName -notmatch '^\.' ) {
                    $DirInfo = [System.IO.DirectoryInfo]::new($Dir)
                    if (-not $DirInfo.LinkTarget) {
                        & $Walker -CurrentPath $Dir
                    }
                }
            }
            foreach ($File in [System.IO.Directory]::EnumerateFiles($CurrentPath)) {
                $Ext = [System.IO.Path]::GetExtension($File).ToLower()
                if ($Ext -in $Extensions) {
                    $Files.Add($File)
                }
            }
        } catch {}
    }
    & $Walker -CurrentPath $RootPath
    return ,$Files
}
