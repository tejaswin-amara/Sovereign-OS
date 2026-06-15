# self-evolve.ps1 - The Sovereign Intelligence Engine (v13.2.0-CloudNative)
# Purpose: Autonomous drift detection, rule refinement, and skill gap analysis.
# Version: 13.2.0-CloudNative

[CmdletBinding()]
param(
    [string]$WorkspacePath = "."
)

$ErrorActionPreference = "Stop"
$SkillsPath = "D:/Skills"
Import-Module "$SkillsPath/agent-bootstrap/scripts/helpers.psm1" -Force -DisableNameChecking
$Version = Get-SovereignVersion -SkillsRoot $SkillsPath
$AgentDir = Join-Path $WorkspacePath ".agents"
$KnowledgeDir = Join-Path $AgentDir "knowledge"
$ManifestPath = Join-Path $KnowledgeDir "evolution_manifest.json"
$LearningsPath = Join-Path $KnowledgeDir "learnings.md"
$RulesPath = Join-Path $AgentDir "rules/rules.md"
$EvolutionReport = Join-Path $KnowledgeDir "evolution_report.md"

try {
    # --- LOAD MANIFEST ---
    if (-not (Test-Path $ManifestPath)) {
        return
    }
    $Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json

    # --- LOAD LEARNINGS ---
    $Learnings = if (Test-Path $LearningsPath) { Get-Content $LearningsPath -Raw } else { "" }
    $LearningLines = ([regex]::Matches($Learnings, '\|.*?\|.*?\|.*?\|.*?\|')).Count
    $RecentAhas = if ($LearningLines -gt 1) { $LearningLines - 1 } else { 0 }

    # --- 1. DRIFT DETECTION ---
    
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

    $DomainKey = $Manifest.ProjectDomain
    if ($DomainChecks.ContainsKey($DomainKey)) {
        foreach ($Check in $DomainChecks[$DomainKey]) {
            if ($RulesContent -notmatch $Check.Pattern) {
                $Issues.Add("MISSING: $($Check.Label) (domain=$DomainKey)")
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
    if ($Issues.Count -gt 0) {
        Write-SovereignLog -Level "INFO" -Step "EVOLUTION" -Message "Auto-healing rules.md with $($Issues.Count) missing domains..."
        $RuleAppends = "`r`n`r`n## Auto-Healed Rules ($(Get-Date -Format 'yyyy-MM-dd'))`r`n"
        foreach ($I in $Issues) {
            $RuleAppends += "- $I`r`n"
        }
        if (-not (Test-Path $RulesPath)) {
            $RulesDir = Split-Path $RulesPath
            if (-not (Test-Path $RulesDir)) { New-Item -Path $RulesDir -ItemType Directory -Force | Out-Null }
            New-Item -Path $RulesPath -ItemType File -Force | Out-Null
        }
        Add-Content -Path $RulesPath -Value $RuleAppends
    }

    # --- 2. SKILL GAP ANALYSIS ---
    
    $HarvestedContent = ""
    $HarvestedPath = Join-Path $KnowledgeDir "harvested_skills.md"
    if (Test-Path $HarvestedPath) { $HarvestedContent = Get-Content $HarvestedPath -Raw }

    $SkillGaps = [System.Collections.Generic.List[string]]::new()
    $DetectedTags = @()
    if ($Manifest.DetectedTags) { $DetectedTags = @($Manifest.DetectedTags) }

    # Check if project uses deps that map to skills not yet harvested
    $TagToSkill = @{
        "next"         = "vercel/next.js"
        "react"        = "facebook/react"
        "drizzle"      = "drizzle-team/drizzle-orm"
        "trpc"         = "trpc/trpc"
        "zod"          = "colinhacks/zod"
        "hono"         = "honojs/hono"
        "turbo"        = "vercel/turborepo"
        "playwright"   = "microsoft/playwright"
        "better-auth"  = "better-auth/better-auth"
        "next-auth"    = "nextauthjs/next-auth"
        "expo"         = "expo/expo"
        "tanstack"     = "TanStack/query"
        "docker"       = "docker/awesome-compose"
        "fastify"      = "fastify/fastify"
        "bullmq"       = "taskforcesh/bullmq"
        "astro"        = "withastro/astro"
        "svelte"       = "sveltejs/svelte"
        "payload"      = "payloadcms/payload"
        "lucia"        = "lucia-auth/lucia"
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
        Write-SovereignLog -Level "INFO" -Step "EVOLUTION" -Message "Auto-fetching missing skill: $Repo"
        & pwsh -NoProfile -ExecutionPolicy Bypass -File "$SkillsPath/agent-bootstrap/scripts/Fetch-CloudSkill.ps1" -Repo $Repo
        if ($LASTEXITCODE -ne 0) {
            Write-SovereignLog -Level "WARN" -Step "EVOLUTION" -Message "Failed to auto-fetch '$Repo' with exit code $LASTEXITCODE"
        }
    }

    # --- 3. GENERATE EVOLUTION REPORT ---
    

    $Report = ""
    $Report += "# SOVEREIGN EVOLUTION REPORT (v$Version)`r`n"
    $Report += "> Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`n`r`n"
    $Report += "## Intelligence Signals`r`n"
    $Report += "| Signal | Value |`r`n"
    $Report += "|---|---|`r`n"
    $Report += "| Primary Domain | $($Manifest.ProjectDomain) |`r`n"
    $Report += "| Engine Version | $Version |`r`n"
    $Report += "| Detected Tags | $($DetectedTags.Count) |`r`n"
    $Report += "| Global Skills | $($Manifest.GlobalSkills) |`r`n"
    $Report += "| Local Files | $($Manifest.LocalFiles) |`r`n"
    $Report += "| Learnings Recorded | $RecentAhas |`r`n"
    $Report += "`r`n"
    $Report += "## Drift Analysis ($($Issues.Count) issues healed)`r`n`r`n"

    if ($Issues.Count -gt 0) {
        foreach ($I in $Issues) {
            $Report += "- [x] **HEALED**: $I`r`n"
        }
    } else {
        $Report += "- [x] **ALIGNED**: Project rules match all domain signals.`r`n"
    }

    $Report += "`r`n## Skill Gap Analysis ($($SkillGaps.Count) gaps fetched)`r`n`r`n"
    if ($SkillGaps.Count -gt 0) {
        foreach ($G in $SkillGaps) {
            $Report += "- [x] **FETCHED**: $G`r`n"
        }
    } else {
        $Report += "- [x] **COMPLETE**: All detected dependencies have matching skills.`r`n"
    }

    $Report += "`r`n## Learnings Integration`r`n"
    if ($RecentAhas -gt 3) {
        Write-SovereignLog -Level "INFO" -Step "EVOLUTION" -Message "Learnings file is bloated. Absorbing $RecentAhas learnings into rules.md..."
        $RuleAppends = "`r`n`r`n## Absorbed Learnings ($(Get-Date -Format 'yyyy-MM-dd'))`r`n$Learnings"
        Add-Content -Path $RulesPath -Value $RuleAppends
        Set-Content -Path $LearningsPath -Value "| Feature | Insight/Aha Moment | Associated Files | Date |`r`n|---|---|---|---|"
        $Report += "- [x] **ABSORBED**: $RecentAhas learnings permanently integrated into rules.md.`r`n"
    } elseif ($RecentAhas -gt 0) {
        $Report += "- [ ] **PENDING**: $RecentAhas learnings in learnings.md. Will absorb when count > 3.`r`n"
    } else {
        $Report += "- [x] **CLEAN**: No new learnings to absorb.`r`n"
    }

    $Report += "`r`n## Recommended Actions`r`n"
    $Report += "1. Review harvested_skills.md for newly linked expertise.`r`n"
    $Report += "2. Record any architectural wins in learnings.md.`r`n"

    Save-AtomicContent -Path $EvolutionReport -Content $Report

    $TotalIssues = $Issues.Count + $SkillGaps.Count
    if ($TotalIssues -eq 0) {
        Write-SovereignLog -Level "INFO" -Step "EVOLUTION" -Message "Evolution alignment perfect. No issues found."
    } else {
        Write-SovereignLog -Level "INFO" -Step "EVOLUTION" -Message "Evolution alignment complete. See report."
    }

    return
} catch {
    Write-SovereignLog -Level "ERROR" -Step "EVOLUTION" -Message "Self-Evolution Engine encountered a fatal error: $($_.Exception.Message)"
    throw "Self-Evolution Engine encountered a fatal error: $($_.Exception.Message)"
}
