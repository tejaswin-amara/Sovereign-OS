# bootstrap.ps1 - Sovereign Project Initializer (v13.2.0-CloudNative)
# Purpose: Onboard any project into the Sovereign ecosystem with atomic template injection and cap enforcement.
# Location: D:/Skills/bootstrap.ps1

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$ProjectPath = "."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$SovereignPath = "D:/Skills"

# Import shared module
Import-Module "$SovereignPath/agent-bootstrap/scripts/helpers.psm1" -Force -DisableNameChecking

# Setup structured logging
$RunID = [guid]::NewGuid().ToString().Substring(0,8)
Set-SovereignLogContext -LogDir "$SovereignPath/LOGS" -RunId $RunID -CorrId $RunID

try {
    # Resolve & Validate project path
    $ResolvedProject = (Resolve-Path $ProjectPath -ErrorAction SilentlyContinue).Path
    if (-not $ResolvedProject) { $ResolvedProject = $ProjectPath }

    $Version = Get-SovereignVersion -SkillsRoot $SovereignPath
    $Config = Get-SovereignConfig
    if (-not $Config) {
        throw "sovereign.config.json MISSING or CORRUPT at $SovereignPath. Cannot bootstrap."
    }

    $AgentDir = Join-Path $ResolvedProject ".agents"
    $WorkflowsDir = Join-Path $AgentDir "workflows"
    $RulesDir = Join-Path $AgentDir "rules"
    $KnowledgeDir = Join-Path $AgentDir "knowledge"
    $TemplatesSource = "$SovereignPath/templates"

    Write-SovereignLog -Level "INFO" -Step "ONBOARD" -Message "Sovereign onboarding started. Project: $ResolvedProject"

    if (-not (Test-Path $TemplatesSource)) {
        throw "Templates directory not found at $TemplatesSource!"
    }

    # Pre-flight: Module Cap Check
    $ModuleCap = if ($Config.governance.module_cap) { [int]$Config.governance.module_cap } else { 32 }
    $NewRulesCount = @(Get-ChildItem -LiteralPath "$TemplatesSource/rules" -Filter "*.md" -ErrorAction SilentlyContinue).Count
    $NewWfCount = @(Get-ChildItem -LiteralPath "$TemplatesSource/workflows" -Filter "*.md" -ErrorAction SilentlyContinue).Count
    $NewTotal = $NewRulesCount + $NewWfCount

    if ($NewTotal -gt $ModuleCap) {
        throw "MODULE_CAP_EXCEEDED: Template injection would create $NewTotal modules ($NewRulesCount rules + $NewWfCount workflows), exceeding hard cap of $ModuleCap. BLOCKING WRITE."
    }
    Write-SovereignLog -Level "INFO" -Step "MODCAP" -Message "Template count OK: $NewTotal/$ModuleCap ($NewRulesCount rules + $NewWfCount workflows)"

    # Step 1: Create directory structure
    Write-SovereignLog -Level "INFO" -Step "DIRS" -Message "Creating local governance structure..."
    if (-not (Test-Path $AgentDir)) {
        New-Item -ItemType Directory -Path $AgentDir -Force | Out-Null
    }
    if (-not (Test-Path $KnowledgeDir)) {
        New-Item -ItemType Directory -Path $KnowledgeDir -Force | Out-Null
    }

    # Step 2: Establish OS-level directory junctions pointing to central templates
    Write-SovereignLog -Level "INFO" -Step "JUNCTION" -Message "Establishing directory junctions..."
    if (Test-Path $RulesDir) {
        Remove-Item $RulesDir -Force -Recurse -ErrorAction SilentlyContinue
    }
    if (Test-Path $WorkflowsDir) {
        Remove-Item $WorkflowsDir -Force -Recurse -ErrorAction SilentlyContinue
    }
    
    try {
        New-Item -ItemType Junction -Path $RulesDir -Value "$TemplatesSource/rules" -ErrorAction Stop | Out-Null
        New-Item -ItemType Junction -Path $WorkflowsDir -Value "$TemplatesSource/workflows" -ErrorAction Stop | Out-Null
        Write-SovereignLog -Level "INFO" -Step "JUNCTION" -Message "Junctions established for rules and workflows."
    } catch {
        Write-SovereignLog -Level "WARN" -Step "JUNCTION" -Message "Automatic junction creation failed. Attempting elevated links recovery..."
        
        $RulesDirEscaped = $RulesDir.Replace("'", "''")
        $TemplatesRulesEscaped = "$TemplatesSource/rules".Replace("'", "''")
        $WfDirEscaped = $WorkflowsDir.Replace("'", "''")
        $TemplatesWfEscaped = "$TemplatesSource/workflows".Replace("'", "''")
        
        $ElevCommand = "New-Item -ItemType Junction -Path '$RulesDirEscaped' -Value '$TemplatesRulesEscaped' -Force; New-Item -ItemType Junction -Path '$WfDirEscaped' -Value '$TemplatesWfEscaped' -Force"
        
        try {
            $Proc = Start-Process pwsh -ArgumentList "-NoProfile -Command `"$ElevCommand`"" -Verb RunAs -PassThru -Wait -WindowStyle Hidden
            if ($Proc.ExitCode -eq 0 -and (Test-Path $RulesDir) -and (Test-Path $WorkflowsDir)) {
                Write-SovereignLog -Level "INFO" -Step "JUNCTION" -Message "Elevated link establishment succeeded."
            } else {
                throw "Elevation script failed with exit code $($Proc.ExitCode)"
            }
        } catch {
            # Elevation failed or user denied UAC, serialize helper action script to project root
            $ActionScriptPath = Join-Path $ResolvedProject "establish-links.ps1"
            $ActionContent = @"
# Run this script as Administrator to establish directory junctions
`$TemplatesSource = "D:/Skills/templates"
`$RulesDir = Join-Path `$PSScriptRoot ".agents/rules"
`$WorkflowsDir = Join-Path `$PSScriptRoot ".agents/workflows"

if (Test-Path `$RulesDir) { Remove-Item `$RulesDir -Force -Recurse -ErrorAction SilentlyContinue }
if (Test-Path `$WorkflowsDir) { Remove-Item `$WorkflowsDir -Force -Recurse -ErrorAction SilentlyContinue }

New-Item -ItemType Junction -Path `$RulesDir -Value "`$TemplatesSource/rules" -Force
New-Item -ItemType Junction -Path `$WorkflowsDir -Value "`$TemplatesSource/workflows" -Force
Write-Host "Directory junctions established successfully!" -ForegroundColor Green
Start-Sleep -Seconds 2
"@
            [System.IO.File]::WriteAllText($ActionScriptPath, $ActionContent)
            
            $ErrorMsg = "Junction creation failed. Run helper script '$ActionScriptPath' as Administrator to complete onboarding."
            Write-SovereignLog -Level "ERROR" -Step "JUNCTION" -Message $ErrorMsg
            throw $ErrorMsg
        }
    }

    # Copy knowledge files (with duplicate backup prevention check)
    Write-SovereignLog -Level "INFO" -Step "INJECT" -Message "Injecting local knowledge files..."
    $KnowledgeTemplates = Get-ChildItem -LiteralPath "$TemplatesSource/knowledge" -File -ErrorAction SilentlyContinue
    $NormalPath = $ResolvedProject.Replace('\', '/')
    $UrlPath = [uri]::EscapeDataString($NormalPath)

    foreach ($KTemp in $KnowledgeTemplates) {
        $DestFile = Join-Path $KnowledgeDir $KTemp.Name
        if (Test-Path $DestFile) {
            $Equal = $false
            try {
                $CurrentContent = Get-Content $DestFile -Raw -ErrorAction SilentlyContinue
                $NewContent = Get-Content $KTemp.FullName -Raw -ErrorAction SilentlyContinue
                $ProcessedNew = $NewContent -replace '__PROJECT_PATH_URL__', $UrlPath -replace '__PROJECT_PATH__', $NormalPath
                if ($CurrentContent -and ($CurrentContent.Trim() -eq $ProcessedNew.Trim() -or $CurrentContent.Trim() -eq $NewContent.Trim())) {
                    $Equal = $true
                }
            } catch {}
            if (-not $Equal) {
                $BackupFile = "$DestFile.bak"
                Copy-Item $DestFile $BackupFile -Force
                Write-SovereignLog -Level "INFO" -Step "BACKUP" -Message "Backed up local $($KTemp.Name)"
            }
        }
        Copy-Item $KTemp.FullName $DestFile -Force
    }

    # Dynamic replacement of path placeholders in all copied files (excluding junctions)
    $FilesToProcess = Get-ChildItem -LiteralPath $AgentDir -Recurse -File | Where-Object {
        ($_.Extension -eq ".md" -or $_.Extension -eq ".json") -and
        $_.FullName -notlike "$RulesDir*" -and
        $_.FullName -notlike "$WorkflowsDir*"
    }

    foreach ($File in $FilesToProcess) {
        try {
            $Content = Get-Content $File.FullName -Raw
            if ($Content -match '__PROJECT_PATH') {
                $Content = $Content -replace '__PROJECT_PATH_URL__', $UrlPath
                $Content = $Content -replace '__PROJECT_PATH__', $NormalPath
                Save-AtomicContent -Path $File.FullName -Content $Content
            }
        } catch {
            Write-SovereignLog -Level "WARN" -Step "PLACEHOLDER" -Message "Failed to process placeholder in $($File.Name): $_"
        }
    }

    # Step 3: Run Skill Harvester (Non-critical)
    Write-SovereignLog -Level "INFO" -Step "HARVEST" -Message "Triggering skill harvester..."
    $HarvesterScript = "$SovereignPath/agent-bootstrap/scripts/skill-harvester.ps1"
    if (Test-Path $HarvesterScript) {
        try {
            pwsh -NoProfile -File $HarvesterScript -WorkspacePath $ResolvedProject -SyncLibrary | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-SovereignLog -Level "WARN" -Step "HARVEST" -Message "Harvester failed with exit code $LASTEXITCODE"
            }
        } catch {
            Write-SovereignLog -Level "WARN" -Step "HARVEST" -Message "Harvester check encountered an exception: $_"
        }
    }

    Write-SovereignLog -Level "INFO" -Step "COMPLETE" -Message "Sovereign onboarding completed successfully for $ResolvedProject"
    exit 0

} catch {
    Write-SovereignLog -Level "ERROR" -Step "BOOTSTRAP" -Message "Bootstrap failed: $_"
    exit 1
}
