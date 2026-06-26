# self-evolve.ps1 - The Sovereign Intelligence Engine (v14.0.0-CloudNative)
# Purpose: Autonomous drift detection, rule refinement, and skill gap analysis.
# Version: 14.0.0-CloudNative

[CmdletBinding()]
param(
    [string]$WorkspacePath = "."
)

Set-StrictMode -Version Latest

$ErrorActionPreference = "Stop"
$SkillsPath = (Resolve-Path "$PSScriptRoot/../..").Path
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
    $Learnings = if (Test-Path $LearningsPath) { Get-Content $LearningsPath -Raw } else { "No previous learnings found." }
    $LearningLines = ([regex]::Matches($Learnings, '\|.*?\|.*?\|.*?\|.*?\|')).Count
    $RecentAhas = if ($LearningLines -gt 1) { $LearningLines - 1 } else { 0 }

    # --- 1. DRIFT DETECTION ---
    $Issues = Test-SovereignDrift -RulesPath $RulesPath -ProjectDomain $Manifest.ProjectDomain

    # --- 2. SKILL GAP ANALYSIS ---
    $HarvestedPath = Join-Path $KnowledgeDir "harvested_skills.md"
    $SkillGaps = Get-SovereignSkillGaps -DetectedTags $Manifest.DetectedTags -HarvestedPath $HarvestedPath -SkillsPath $SkillsPath

    # --- 3. GENERATE EVOLUTION REPORT ---
    Write-SovereignEvolutionReport -EvolutionReport $EvolutionReport -Version $Version -Manifest $Manifest -RecentAhas $RecentAhas -Issues $Issues -SkillGaps $SkillGaps -Learnings $Learnings -LearningsPath $LearningsPath -RulesPath $RulesPath -WorkspacePath $WorkspacePath -SkillsPath $SkillsPath

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
