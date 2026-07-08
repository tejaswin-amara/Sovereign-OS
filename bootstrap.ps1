# bootstrap.ps1 - Sovereign Project Initializer (v15.0.0-CloudNative)
# Purpose: Onboard any project into the Sovereign ecosystem with atomic template injection and cap enforcement.
# Location: C:/Skills/bootstrap.ps1

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$ProjectPath = "."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$SovereignPath = $PSScriptRoot

# Import shared module
Import-Module "$SovereignPath/agent-bootstrap/scripts/helpers.psm1" -Force -DisableNameChecking

# Setup structured logging
$RunID = [guid]::NewGuid().ToString().Substring(0,8)
Set-SovereignLogContext -LogDir "$SovereignPath/LOGS" -RunId $RunID -CorrId $RunID

try {
    # Resolve & Validate project path
    $ResolvedProject = (Resolve-Path $ProjectPath -ErrorAction SilentlyContinue).Path
    if (-not $ResolvedProject) { $ResolvedProject = $ProjectPath }

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

    # Pre-flight: Module Cap Check (delegates to shared helper)
    Assert-ModuleCap -AgentDir $TemplatesSource

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
        $isWin = if (Get-Variable -Name "IsWindows" -ValueOnly -ErrorAction SilentlyContinue) { $true } elseif ($env:OS -eq "Windows_NT") { $true } else { $false }
        $LinkType = if ($isWin) { "Junction" } else { "SymbolicLink" }
        New-Item -ItemType $LinkType -Path $RulesDir -Value "$TemplatesSource/rules" -ErrorAction Stop | Out-Null
        New-Item -ItemType $LinkType -Path $WorkflowsDir -Value "$TemplatesSource/workflows" -ErrorAction Stop | Out-Null
        Write-SovereignLog -Level "INFO" -Step "JUNCTION" -Message "Directory links ($LinkType) established for rules and workflows."
    } catch {
        Write-SovereignLog -Level "WARN" -Step "JUNCTION" -Message "Automatic junction creation failed. Falling back to simple directory copy..."
        try {
            Copy-Item -Path "$TemplatesSource/rules" -Destination $RulesDir -Recurse -Force
            Copy-Item -Path "$TemplatesSource/workflows" -Destination $WorkflowsDir -Recurse -Force
            Write-SovereignLog -Level "INFO" -Step "JUNCTION" -Message "Fallback directory copy succeeded."
        } catch {
            $ErrorMsg = "Junction creation and fallback directory copy both failed. Details: $_"
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
            } catch { Write-Verbose "Duplicate check failed: $_" }
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
            pwsh -NoProfile -File $HarvesterScript -WorkspacePath $ResolvedProject | Out-Null
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
