# SOVEREIGN SKILL HARVESTER v15.0.0-CloudNative (BULLETPROOF - REFACTORED)
# Purpose: Deep Harvester with project analysis, dependency mapping, and skill matching.
# Location: C:/Skills/agent-bootstrap/scripts/skill-harvester.ps1

[CmdletBinding()]
param(
    [string]$WorkspacePath = "."
)

Set-StrictMode -Version Latest

$ErrorActionPreference = "Stop"
$SovereignRoot = (Resolve-Path -LiteralPath "$PSScriptRoot/../..").Path
Import-Module "$SovereignRoot/agent-bootstrap/scripts/helpers.psm1" -Force -DisableNameChecking

# -------------------------------------------------------------------------
# REGISTRY INTAKE
# -------------------------------------------------------------------------
$Config = Get-SovereignConfig
if (-not $Config) {
    throw "sovereign.config.json MISSING or CORRUPT. Harvester aborted."
}

$Version = Get-SovereignVersion -SkillsRoot $SovereignRoot
$Axioms = Get-SovereignConfig -KeyPath "core_axioms"
$DepToTag = Get-SovereignConfig -KeyPath "dep_to_skill_map"
if (-not $DepToTag) { $DepToTag = @{} }

# Resolve workspace
$ResolvedWorkspace = (Resolve-Path -LiteralPath $WorkspacePath -ErrorAction SilentlyContinue).Path
if (-not $ResolvedWorkspace) { $ResolvedWorkspace = $WorkspacePath }

# -------------------------------------------------------------------------
# EXECUTION
# -------------------------------------------------------------------------
Write-Host "- - - SOVEREIGN SKILL HARVESTER v$Version - - -" -ForegroundColor Cyan

# [1/7] Scan Global Library dynamically from filesystem
$ExcludedDirs = Get-SovereignConfig -KeyPath "governance.harvester_excluded_dirs"
if (-not $ExcludedDirs) { 
    $ExcludedDirs = @(".git", ".archive-v1.0", "agent-bootstrap", "LOGS", "G0DM0D3", "GodMode", "goose", "templates", "scratch", ".quarantine", "servers") 
}

$Folders = Get-ChildItem -LiteralPath $SovereignRoot -Directory | 
           Where-Object { $_.Name -notin $ExcludedDirs -and $_.Name -notmatch "^\." -and $_.Name -notmatch "^_" }

$GlobalLibrary = @{}
foreach ($Folder in $Folders) {
    $NormalizedPath = $Folder.FullName -replace '\\', '/'
    $GlobalLibrary[$Folder.Name] = @{ path = $NormalizedPath; tags = "" }
}

# [3/7] Scan Project Manifests dynamically using language-specific parsers
$DetectedDeps = @()
$DetectedTags = @()

$HarvestersPath = Join-Path $SovereignRoot "agent-bootstrap/scripts/harvesters"
if (Test-Path -LiteralPath $HarvestersPath) {
    $HarvesterScripts = Get-ChildItem -LiteralPath $HarvestersPath -Filter "*Parser.ps1"
    
    if ($HarvesterScripts) {
        # Run empirical parsers concurrently using runspaces
        $ParallelDeps = $HarvesterScripts | ForEach-Object -Parallel {
            $ScriptPath = $_.FullName
            $Workspace = $using:ResolvedWorkspace
            try {
                . $ScriptPath
                $ParserFunc = Get-Command -Name "Get-*Dependencies" -CommandType Function -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($ParserFunc) {
                    & $ParserFunc.Name -ResolvedWorkspace $Workspace
                }
            } catch {}
        } -ThrottleLimit ($HarvesterScripts.Count)
        
        if ($ParallelDeps) {
            $DetectedDeps += @($ParallelDeps)
        }
    }
} else {
    Write-SovereignLog -Level "WARN" -Step "HARVEST" -Message "Harvesters directory not found at $HarvestersPath"
}

$DetectedDeps = $DetectedDeps | Select-Object -Unique

# [4/7] Map dependencies to skill tags
function Get-SkillCustomTags {
    param([string]$SkillDirPath)
    $Tags = [System.Collections.Generic.List[string]]::new()
    $DocFiles = @("SKILL.md", "README.md", "rules.md")
    foreach ($doc in $DocFiles) {
        $FullPath = Join-Path $SkillDirPath $doc
        if (Test-Path -LiteralPath $FullPath) {
            try {
                $Content = Get-Content -LiteralPath $FullPath -Raw -ErrorAction SilentlyContinue
                if ($Content) {
                    if ($Content -match '^---\s*\r?\n([\s\S]*?)\r?\n---') {
                        $FM = $Matches[1]
                        if ($FM -match 'tags:\s*\[?(?<tags>[a-zA-Z0-9_\s,-]+)\]?') {
                            foreach ($t in ($Matches['tags'] -split ',')) {
                                $cleanT = $t.Trim().ToLower()
                                if ($cleanT) { [void]$Tags.Add($cleanT) }
                            }
                        }
                        if ($FM -match 'keywords:\s*\[?(?<kws>[a-zA-Z0-9_\s,-]+)\]?') {
                            foreach ($k in ($Matches['kws'] -split ',')) {
                                $cleanK = $k.Trim().ToLower()
                                if ($cleanK) { [void]$Tags.Add($cleanK) }
                            }
                        }
                    }
                    # Strip code blocks to avoid capturing commented lines inside python/shell code blocks as tags
                    $CleanContent = $Content -replace '(?s)```.*?```', ''
                    $CleanContent = $CleanContent -replace '`.*?`', ''
                    $InlineTags = [regex]::Matches($CleanContent, '(?<!\w)#(?<tag>[a-zA-Z][a-zA-Z0-9_-]{1,29})')
                    foreach ($m in $InlineTags) {
                        $cleanT = $m.Groups['tag'].Value.ToLower()
                        if ($cleanT -notin @("h1", "h2", "h3", "h4", "h5", "h6", "axiom")) {
                            [void]$Tags.Add($cleanT)
                        }
                    }
                }
            } catch {}
        }
    }
    return ($Tags | Select-Object -Unique)
}

$PhysicalFolders = Get-ChildItem -LiteralPath $SovereignRoot -Directory | 
                   Where-Object { $_.Name -notin $ExcludedDirs -and $_.Name -notmatch "^\." }

$DynamicMappings = @{}
foreach ($Folder in $PhysicalFolders) {
    $SkillPath = $Folder.FullName
    $CustomTags = Get-SkillCustomTags -SkillDirPath $SkillPath
    if ($CustomTags) {
        foreach ($t in $CustomTags) {
            $IsAlreadyMapped = $false
            if ($DepToTag -is [System.Collections.IDictionary]) {
                $IsAlreadyMapped = $DepToTag.ContainsKey($t)
            } elseif ($DepToTag -is [PSCustomObject]) {
                $IsAlreadyMapped = $null -ne $DepToTag.PSObject.Properties[$t]
            }
            if (-not $IsAlreadyMapped -and -not $DynamicMappings.ContainsKey($t)) {
                $DynamicMappings[$t] = $Folder.Name
            }
        }
    }
}

$ActiveMappings = @{}
if ($DepToTag -is [System.Collections.IDictionary]) {
    foreach ($Key in $DepToTag.Keys) {
        $ActiveMappings[$Key] = $DepToTag[$Key]
    }
} elseif ($DepToTag -is [PSCustomObject]) {
    foreach ($Prop in $DepToTag.PSObject.Properties) {
        $ActiveMappings[$Prop.Name] = $Prop.Value
    }
}
foreach ($Key in $DynamicMappings.Keys) {
    $ActiveMappings[$Key] = $DynamicMappings[$Key]
}

$MatchedSkills = @{}
foreach ($Dep in $DetectedDeps) {
    $CleanDep = $Dep.ToLower().Trim()
    if ($ActiveMappings.ContainsKey($CleanDep)) {
        $SkillName = $ActiveMappings[$CleanDep]
        if (-not $MatchedSkills.ContainsKey($SkillName)) {
            $MatchedSkills[$SkillName] = @{ dep = $Dep; source = "package.json" }
            $DetectedTags += $CleanDep
        }
    }
}

foreach ($LoreKey in $ActiveMappings.Keys) {
    $LoreSkill = $ActiveMappings[$LoreKey]
    foreach ($Dep in $DetectedDeps) {
        $CleanLoreKey = $LoreKey.ToLower().Trim()
        $CleanDep = $Dep.ToLower().Trim()
        # Word boundaries or specific delimiters (hyphen, underscore, slash)
        $Pattern = "(^|[^a-zA-Z0-9])$([regex]::Escape($CleanLoreKey))([^a-zA-Z0-9]|$)"
        if ($CleanDep -match $Pattern -and -not $MatchedSkills.ContainsKey($LoreSkill)) {
            $MatchedSkills[$LoreSkill] = @{ dep = $Dep; source = "lore_mapping" }
            $DetectedTags += $CleanLoreKey
        }
    }
}

foreach ($Axiom in $Axioms) {
    if ($GlobalLibrary.ContainsKey($Axiom) -and -not $MatchedSkills.ContainsKey($Axiom)) {
        $MatchedSkills[$Axiom] = @{ dep = "core_axiom"; source = "manifest" }
    }
}

# [5/7] Verify matched skills exist in the library
$VerifiedSkills = @{}
foreach ($Entry in $MatchedSkills.GetEnumerator()) {
    $SkillName = $Entry.Key
    if ($GlobalLibrary.ContainsKey($SkillName)) {
        $SkillPath = $GlobalLibrary[$SkillName].path
        $VerifiedSkills[$SkillName] = @{
            path = $SkillPath
            dep = $Entry.Value.dep
            source = $Entry.Value.source
            has_rules = Test-Path -LiteralPath (Join-Path $SkillPath "rules.md")
            has_readme = Test-Path -LiteralPath (Join-Path $SkillPath "README.md")
        }
    }
}

# [6/7] Generate harvested_skills.md
$KnowledgeDir = Join-Path $ResolvedWorkspace ".agents/knowledge"
if (-not (Test-Path -LiteralPath $KnowledgeDir)) { 
    New-Item -Path $KnowledgeDir -ItemType Directory -Force | Out-Null 
}

$HarvestOutput = "# Sovereign Harvested Skills (v$Version)`n"
$HarvestOutput += "> Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
$HarvestOutput += "> Workspace: $ResolvedWorkspace`n"
$HarvestOutput += "> Total Dependencies: $(@($DetectedDeps).Count)`n"
$HarvestOutput += "> Matched Skills: $($VerifiedSkills.Count)`n"
$HarvestOutput += "> Global Library: $($GlobalLibrary.Count) skills`n`n"
$HarvestOutput += "## Matched Skills`n`n"
$HarvestOutput += "> Table generation suppressed for token context efficiency.`n"
$HarvestOutput += "> See `.agents/knowledge/harvested_skills.md` or query `$SovereignRoot` directly for details.`n"
$HarvestOutput += "`n## Axiom Cores`n`n"
foreach ($Axiom in $Axioms) {
    $HarvestOutput += "- $Axiom`n"
}
$HarvestOutput += "`n---`n"
$HarvestOutput += "$($GlobalLibrary.Count)-SKILL LIBRARY | $($VerifiedSkills.Count) MATCHED | v$Version`n"

Save-AtomicContent -Path (Join-Path $KnowledgeDir "harvested_skills.md") -Content $HarvestOutput

# [7/7] Update evolution manifest with detected tags
$ProjectDomain = "General"
if ($DetectedDeps -contains "next" -or $DetectedDeps -contains "react") { $ProjectDomain = "Web" }
elseif ($DetectedDeps -contains "expo" -or $DetectedDeps -contains "react-native") { $ProjectDomain = "Mobile" }
elseif ($DetectedDeps -contains "fastify" -or $DetectedDeps -contains "hono" -or $DetectedDeps -contains "express") { $ProjectDomain = "Backend" }

$ExcludeHarvestDirs = @($ExcludedDirs) + @('node_modules', '.agents')
function Get-FastHarvestFileCount {
    param([string]$Path, [int]$Depth = 0)
    if ($Depth -gt 15) { return }
    if ($Path -ieq $SovereignRoot -or $Path -ieq ($SovereignRoot -replace '\\', '/')) {
        $script:LocalFileCount = (Get-ChildItem -LiteralPath $Path -File -ErrorAction SilentlyContinue | Measure-Object).Count
        $script:LocalFileCount += (Get-ChildItem -LiteralPath (Join-Path $Path "agent-bootstrap") -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
        return
    }
    try {
        $script:LocalFileCount += [System.IO.Directory]::GetFiles($Path).Length
        foreach ($Dir in [System.IO.Directory]::GetDirectories($Path)) {
            $DirName = [System.IO.Path]::GetFileName($Dir)
            if ($DirName -notin $ExcludeHarvestDirs -and $DirName -notmatch "^\.") {
                try {
                    if (-not [System.IO.DirectoryInfo]::new($Dir).Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
                        Get-FastHarvestFileCount -Path $Dir -Depth ($Depth + 1)
                    }
                } catch {
                    Write-SovereignLog -Level "WARN" -Step "HARVEST" -Message "Skipping unreadable directory $($Dir): $_"
                }
            }
        }
    } catch {
        Write-SovereignLog -Level "WARN" -Step "HARVEST" -Message "Failed to read directory $($Path): $_"
    }
}
$script:LocalFileCount = 0
Get-FastHarvestFileCount -Path $ResolvedWorkspace

$EvolManifest = @{
    ProjectDomain = $ProjectDomain
    DetectedTags = @($DetectedTags | Select-Object -Unique)
    GlobalSkills = $GlobalLibrary.Count
    MatchedSkills = $VerifiedSkills.Count
    LocalFiles = $script:LocalFileCount
    LastHarvest = Get-Date -Format "o"
    Version = $Version
} | ConvertTo-Json -Depth 3

Save-AtomicContent -Path (Join-Path $KnowledgeDir "evolution_manifest.json") -Content $EvolManifest
return
