# D:/Skills/agent-bootstrap/scripts/helpers/Modularity.ps1

function Assert-ModuleCap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentDir,
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
    $AllDirs = Get-ChildItem -Path $SkillsRoot -Directory |
        Where-Object { $_.Name -notmatch '^\.' } |
        Where-Object { $_.Name -notmatch '^_' } |
        Where-Object { $_.Name -notin $ExcludedDirs }
    return @($AllDirs).Count
}
