# Evolution.ps1 - Sovereign Evolution Helper Functions (v15.0.0-CloudNative)
# Purpose: Helper functions for autonomous drift detection, report writing, and skill gap analysis.

function Test-SovereignDrift {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RulesPath,
        [Parameter(Mandatory = $true)]
        [string]$ProjectDomain
    )

    $Issues = [System.Collections.Generic.List[string]]::new()
    $RulesContent = if (Test-Path $RulesPath) { Get-Content $RulesPath -Raw } else { "" }

    # Domain-specific rule checks
    $DomainChecks = @{
        "Web" = @(
            @{ Pattern = "Next\.js|App Router|Server Component"; Label = "Next.js/React architecture rules" }
            @{ Pattern = "Tailwind|cn\(\)|design token"; Label = "Tailwind CSS / styling conventions" }
            @{ Pattern = "Zod|schema validation|input validation"; Label = "Zod schema validation rules" }
        )
        "Backend" = @(
            @{ Pattern = "Security|Auth|sanitiz"; Label = "Security and authentication rules" }
            @{ Pattern = "Drizzle|ORM|database|transaction"; Label = "Database/ORM patterns" }
            @{ Pattern = "API|tRPC|endpoint"; Label = "API architecture rules" }
        )
        "Mobile" = @(
            @{ Pattern = "Expo|React Native|mobile"; Label = "Mobile development rules" }
        )
        "AI" = @(
            @{ Pattern = "LLM|prompt|agent|embedding"; Label = "AI/LLM development rules" }
        )
    }

    if ($DomainChecks.ContainsKey($ProjectDomain)) {
        foreach ($Check in $DomainChecks[$ProjectDomain]) {
            if ($RulesContent -notmatch $Check.Pattern) {
                $Issues.Add("MISSING: $($Check.Label) (domain=$ProjectDomain)")
            }
        }
    }

    # Cross-domain checks
    if ($RulesContent -notmatch "TypeScript|strict type") {
        $Issues.Add("Enforce TypeScript strict mode for all new files.")
    }
    if ($RulesContent -notmatch "test|Testing") {
        $Issues.Add("Require comprehensive unit testing strategy.")
    }

    # --- AUTO-HEAL RULES ---
    $UniqueIssues = [System.Collections.Generic.List[string]]::new()
    foreach ($I in $Issues) {
        if ($RulesContent -notmatch [regex]::Escape($I)) {
            $UniqueIssues.Add($I)
        }
    }

    if ($UniqueIssues.Count -gt 0) {
        Write-SovereignLog -Level "INFO" -Step "EVOLUTION" -Message "Auto-healing rules.md with $($UniqueIssues.Count) missing domains..."
        $RuleAppends = "`r`n`r`n## Auto-Healed Rules ($(Get-Date -Format 'yyyy-MM-dd'))`r`n"
        foreach ($I in $UniqueIssues) {
            $RuleAppends += "- $I`r`n"
        }
        if (-not (Test-Path $RulesPath)) {
            $RulesDir = Split-Path $RulesPath
            if (-not (Test-Path $RulesDir)) { New-Item -Path $RulesDir -ItemType Directory -Force | Out-Null }
            New-Item -Path $RulesPath -ItemType File -Force | Out-Null
        }
        Add-Content -Path $RulesPath -Value $RuleAppends
    }

    return ,$Issues
}

function Get-SovereignSkillGaps {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IList]$DetectedTags,
        [Parameter(Mandatory = $true)]
        [string]$HarvestedPath,
        [Parameter(Mandatory = $true)]
        [string]$SkillsPath
    )

    $HarvestedContent = ""
    if (Test-Path $HarvestedPath) { $HarvestedContent = Get-Content $HarvestedPath -Raw }

    $SkillGaps = [System.Collections.Generic.List[string]]::new()

    # Check if project uses deps that map to skills not yet harvested
    # ponytail: single source of truth — read from sovereign.config.json instead of hardcoded duplicate
    $ConfigMap = Get-SovereignConfig -KeyPath "dep_to_skill_map"
    $TagToSkill = @{}
    if ($ConfigMap) {
        foreach ($prop in $ConfigMap.PSObject.Properties) {
            $TagToSkill[$prop.Name] = $prop.Value
        }
    }

    $AutoFetchRepos = @()
    foreach ($Tag in $DetectedTags) {
        $CleanTag = $Tag.ToLower().Trim()
        if ($TagToSkill.ContainsKey($CleanTag)) {
            $ExpectedRepo = $TagToSkill[$CleanTag]
            $RepoName = ($ExpectedRepo -split "/")[-1]
            if ($HarvestedContent -notmatch [regex]::Escape($RepoName)) {
                $SkillGaps.Add("Dependency '$Tag' detected. Auto-fetched '$ExpectedRepo'")
                $AutoFetchRepos += $ExpectedRepo
            }
        }
    }

    # --- AUTO-FETCH MISSING SKILLS ---
    foreach ($Repo in $AutoFetchRepos) {
        Write-SovereignLog -Level "INFO" -Step "EVOLUTION" -Message "Auto-fetching missing skill: $Repo (in-process)"
        try {
            & "$SkillsPath/agent-bootstrap/scripts/Fetch-CloudSkill.ps1" -Repo $Repo
        } catch {
            Write-SovereignLog -Level "WARN" -Step "EVOLUTION" -Message "Failed to auto-fetch '$Repo': $_"
        }
    }

    return ,$SkillGaps
}

function Write-SovereignEvolutionReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EvolutionReport,
        [Parameter(Mandatory = $true)]
        [string]$Version,
        [Parameter(Mandatory = $true)]
        $Manifest,
        [Parameter(Mandatory = $true)]
        [int]$RecentAhas,
        [Parameter(Mandatory = $false)]
        $Issues,
        [Parameter(Mandatory = $false)]
        $SkillGaps,
        [Parameter(Mandatory = $true)]
        [string]$Learnings,
        [Parameter(Mandatory = $true)]
        [string]$LearningsPath,
        [Parameter(Mandatory = $true)]
        [string]$RulesPath,
        [Parameter(Mandatory = $true)]
        [string]$WorkspacePath,
        [Parameter(Mandatory = $true)]
        [string]$SkillsPath
    )

    $IssuesCount = if ($Issues) { @($Issues).Count } else { 0 }
    $SkillGapsCount = if ($SkillGaps) { @($SkillGaps).Count } else { 0 }

    $Report = ""
    $Report += "# SOVEREIGN EVOLUTION REPORT (v$Version)`r`n"
    $Report += "> Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`n`r`n"
    $Report += "## Intelligence Signals`r`n"
    $Report += "| Signal | Value |`r`n"
    $Report += "|---|---|`r`n"
    $Report += "| Primary Domain | $($Manifest.ProjectDomain) |`r`n"
    $Report += "| Engine Version | $Version |`r`n"
    $Report += "| Detected Tags | $(if ($Manifest.DetectedTags) { @($Manifest.DetectedTags).Count } else { 0 }) |`r`n"
    $Report += "| Global Skills | $($Manifest.GlobalSkills) |`r`n"
    $Report += "| Local Files | $($Manifest.LocalFiles) |`r`n"
    $Report += "| Learnings Recorded | $RecentAhas |`r`n"
    $Report += "`r`n"
    $Report += "## Drift Analysis ($IssuesCount issues healed)`r`n`r`n"

    if ($IssuesCount -gt 0) {
        foreach ($I in $Issues) {
            $Report += "- [x] **HEALED**: $I`r`n"
        }
    } else {
        $Report += "- [x] **ALIGNED**: Project rules match all domain signals.`r`n"
    }

    $Report += "`r`n## Skill Gap Analysis ($SkillGapsCount gaps fetched)`r`n`r`n"
    if ($SkillGapsCount -gt 0) {
        foreach ($G in $SkillGaps) {
            $Report += "- [x] **FETCHED**: $G`r`n"
        }
    } else {
        $Report += "- [x] **COMPLETE**: All detected dependencies have matching skills.`r`n"
    }

    $Report += "`r`n## Learnings Integration`r`n"
    $RulesContent = if (Test-Path $RulesPath) { Get-Content $RulesPath -Raw } else { "" }
    if ($RecentAhas -gt 0) {
        # Parse and extract only NEW learnings that do not already exist in rules.md
        $NewRows = [System.Collections.Generic.List[string]]::new()
        $Lines = $Learnings -split "`r?\n"
        foreach ($Line in $Lines) {
            $Trimmed = $Line.Trim()
            if ($Trimmed -like "|*" -and $Trimmed -notlike "| Feature |*" -and $Trimmed -notlike "|---|*") {
                # Extract learning description or compare exact row to avoid duplicates
                $CleanRow = $Trimmed -replace '\s+', ' '
                $EscapedRow = [regex]::Escape($CleanRow)
                $NormalizedRules = $RulesContent -replace '\s+', ' '
                if ($NormalizedRules -notmatch $EscapedRow) {
                    $NewRows.Add($Line)
                }
            }
        }

        if ($NewRows.Count -gt 0) {
            Write-SovereignLog -Level "INFO" -Step "EVOLUTION" -Message "Absorbing $($NewRows.Count) new learnings into rules.md..."
            $RuleAppends = "`r`n`r`n## Absorbed Learnings ($(Get-Date -Format 'yyyy-MM-dd'))`r`n"
            $RuleAppends += "| Feature | Insight/Aha Moment | Associated Files | Date |`r`n"
            $RuleAppends += "|---|---|---|---|`r`n"
            foreach ($Row in $NewRows) {
                $RuleAppends += "$Row`r`n"
            }
            Add-Content -Path $RulesPath -Value $RuleAppends
            Set-Content -Path $LearningsPath -Value "| Feature | Insight/Aha Moment | Associated Files | Date |`r`n|---|---|---|---|"
            $Report += "- [x] **ABSORBED**: $($NewRows.Count) new learnings permanently integrated into rules.md.`r`n"
        } else {
            # All learnings in learnings.md are already in rules.md
            Set-Content -Path $LearningsPath -Value "| Feature | Insight/Aha Moment | Associated Files | Date |`r`n|---|---|---|---|"
            $Report += "- [x] **CLEAN**: Learning entries were already absorbed. Resetting table.`r`n"
        }
    } else {
        $Report += "- [x] **CLEAN**: No new learnings to absorb.`r`n"
    }

    # PONYTAIL DEBT SWEEP
    Write-SovereignLog -Level "INFO" -Step "EVOLUTION" -Message "Scanning for Ponytail lazy-dev shortcuts..."
    $ExcludeDirsList = [System.Collections.Generic.List[string]]::new()
    @("node_modules", ".git", ".agents", ".cloud-cache", "LOGS", ".agent-reach-venv", ".venv", "__pycache__", "dist", ".next", "build") | ForEach-Object { $ExcludeDirsList.Add($_) }
    
    $Files = [System.Collections.Generic.List[string]]::new()
    $LocalGetPonytailFiles = {
        param([string]$CurrentPath)
        try {
            $Dirs = [System.IO.Directory]::EnumerateDirectories($CurrentPath)
            foreach ($Dir in $Dirs) {
                $DirName = [System.IO.Path]::GetFileName($Dir)
                if (-not $ExcludeDirsList.Contains($DirName) -and $DirName -notmatch "^\.") {
                    $DirInfo = [System.IO.DirectoryInfo]::new($Dir)
                    if (-not $DirInfo.LinkTarget) {
                        &$LocalGetPonytailFiles -CurrentPath $Dir
                    }
                }
            }
            $FoundFiles = [System.IO.Directory]::EnumerateFiles($CurrentPath)
            foreach ($File in $FoundFiles) {
                $Ext = [System.IO.Path]::GetExtension($File).ToLower()
                if ($Ext -in @(".ps1", ".psm1", ".js", ".ts", ".tsx", ".jsx", ".md", ".py")) {
                    $Files.Add($File)
                }
            }
        } catch {}
    }
    &$LocalGetPonytailFiles -CurrentPath $WorkspacePath
    
    $PonytailMarkers = @()
    if ($Files) {
        $PonytailMarkers = $Files | Select-String -Pattern "(//|#|<!--)?\s*ponytail:" -ErrorAction SilentlyContinue
    }
    
    $Report += "`r`n## ðŸ´ Ponytail Debt Ledger`r`n"
    if ($PonytailMarkers -and $PonytailMarkers.Count -gt 0) {
        $Report += "> **Warning**: The following deliberate shortcuts were injected under lazy senior dev mode.`r`n"
        $Report += "> Do not fix these unless they hit their ceiling. They are documented here to prevent rotting.`r`n`r`n"
        foreach ($m in $PonytailMarkers) {
            $RelPath = $m.Path.Replace($WorkspacePath, "").TrimStart("\/")
            $Report += "- **${RelPath}:$($m.LineNumber)** -> $($m.Line.Trim())`r`n"
        }
    } else {
        $Report += "- No Ponytail shortcuts found in the codebase.`r`n"
    }

    $Report += "`r`n## Recommended Actions`r`n"

    # ponytail: Turbovec semantic indexing removed. It was a phantom feature that fetched and deleted a non-existent repo every run.
    $Report += "1. Review harvested_skills.md for newly linked expertise.`r`n"
    $Report += "2. Record any architectural wins in learnings.md.`r`n"

    Save-AtomicContent -Path $EvolutionReport -Content $Report
}
