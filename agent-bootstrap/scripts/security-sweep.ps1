# security-sweep.ps1 - Autonomous AST and Security Validation Workflow (v14.0.0-CloudNative)
# Purpose: Pre-commit/Pre-execution parsing to block dynamic code execution and vulnerability leakage.
# Location: C:/Skills/agent-bootstrap/scripts/security-sweep.ps1

[CmdletBinding()]
param(
    [string]$ProjectPath = "C:/Skills",
    [bool]$BlockOnError = $true
)

Set-StrictMode -Version Latest

# Core imports
$SovereignRoot = (Resolve-Path "$PSScriptRoot/../..").Path
Import-Module "$SovereignRoot/agent-bootstrap/scripts/helpers.psm1" -Force -DisableNameChecking
$Version = Get-SovereignVersion -SkillsRoot $SovereignRoot
$Config = Get-SovereignConfig

Write-SovereignLog -Level "INFO" -Step "SECURITY_SWEEP" -Message "Initializing AST & Code Security Scan v$Version..."

$Violations = [System.Collections.Generic.List[string]]::new()
$Files = [System.Collections.Generic.List[string]]::new()

# Performance Optimization: Early pruning of huge directories to avoid traversing hundreds of thousands of files.
$ExcludeDirs = [System.Collections.Generic.List[string]]::new()
@('node_modules', '.git', 'dist', '.next', 'build', '.agents', 'LOGS', 'templates', 'G0DM0D3', '.archive-v1.0', 'skills', '.agent-reach-venv', '.venv', '__pycache__') | ForEach-Object { $ExcludeDirs.Add($_) }

if ($ProjectPath -ieq "C:/Skills" -or $ProjectPath -ieq "C:\Skills") {
    try {
        $AllSubDirs = Get-ChildItem -Path "C:\Skills" -Directory | Select-Object -ExpandProperty Name
        foreach ($DirName in $AllSubDirs) {
            if ($DirName -ne "agent-bootstrap" -and $DirName -ne ".agents" -and -not $ExcludeDirs.Contains($DirName)) {
                $ExcludeDirs.Add($DirName)
            }
        }
    } catch {
        Write-SovereignLog -Level "WARN" -Step "SECURITY_SWEEP" -Message "Failed to build exclusion list: $_"
    }
}

function Get-TargetFiles {
    param([string]$CurrentPath)
    try {
        $Dirs = [System.IO.Directory]::EnumerateDirectories($CurrentPath)
        foreach ($Dir in $Dirs) {
            $DirName = [System.IO.Path]::GetFileName($Dir)
            if (-not $ExcludeDirs.Contains($DirName) -and $DirName -notmatch "^\.") {
                # Prevent infinite loop on junctions/symlinks
                $DirInfo = [System.IO.DirectoryInfo]::new($Dir)
                if (-not $DirInfo.LinkTarget) {
                    Get-TargetFiles -CurrentPath $Dir
                }
            }
        }
        $FoundFiles = [System.IO.Directory]::EnumerateFiles($CurrentPath)
        foreach ($File in $FoundFiles) {
            $Ext = [System.IO.Path]::GetExtension($File).ToLower()
            if ($Ext -in @(".ps1", ".psm1", ".js", ".ts", ".tsx", ".jsx")) {
                $Files.Add($File)
            }
        }
    } catch {
        Write-SovereignLog -Level "WARN" -Step "SECURITY_SWEEP" -Message "Access denied or missing path at $($CurrentPath): $_"
    }
}

Write-SovereignLog -Level "INFO" -Step "SECURITY_SWEEP" -Message "Pruning directory tree and collecting files in $ProjectPath..."
Get-TargetFiles -CurrentPath $ProjectPath
Write-SovereignLog -Level "INFO" -Step "SECURITY_SWEEP" -Message "Found $($Files.Count) scripts to scan."

foreach ($File in $Files) {
    $FilePath = $File
    $Content = Get-Content -LiteralPath $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $Content) { continue }

    $Extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

    # PowerShell AST Parse (Native Parser)
    if ($Extension -in @(".ps1", ".psm1")) {
        $Errors = $null
        $Tokens = $null
        $AST = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$Tokens, [ref]$Errors)

        # Look for Invoke-Expression (iex) statements in AST
        $IexCalls = $AST.FindAll({
            param($AstNode)
            $AstNode -is [System.Management.Automation.Language.CommandAst] -and
            ($AstNode.GetCommandName() -ieq "Invoke-Expression" -or $AstNode.GetCommandName() -ieq "iex")
        }, $true)

        if ($IexCalls) {
            foreach ($call in $IexCalls) {
                $Line = $call.Extent.StartLineNumber
                $Snippet = $call.Extent.Text
                $Violations.Add("[POWERSHELL AST] Dynamic Command Execution (iex/Invoke-Expression) detected in: $FilePath at line $($Line): `"$Snippet`"")
            }
        }
    }

    # JavaScript/TypeScript Token / Regex AST Scan (v14.0.0-CloudNative: Line-by-line with precise snippets)
    if ($Extension -in @(".js", ".ts", ".tsx", ".jsx")) {
        $Lines = $Content -split '\r?\n'
        $ApprovedDeps = @()
        if ($Config -and $Config.dep_to_skill_map) {
            $ApprovedDeps = $Config.dep_to_skill_map.PSObject.Properties.Name
        }
        $NodeBuiltins = @("path", "fs", "child_process", "crypto", "events", "stream", "os", "http", "https", "util", "url", "querystring", "zlib", "buffer", "process")

        for ($i = 0; $i -lt @($Lines).Count; $i++) {
            $LineContent = $Lines[$i]
            # Check for eval() - must not be preceded by a dot (e.g. redis.eval is safe)
            if ($LineContent -match '(?<![a-zA-Z0-9_$.])eval\s*\(') {
                $Violations.Add("[JS/TS SCAN] Dangerous 'eval()' execution detected in: $FilePath at line $($i + 1): `"$($LineContent.Trim())`"")
            }
            # Check for new Function()
            if ($LineContent -match 'new\s+Function\s*\(') {
                $Violations.Add("[JS/TS SCAN] Dynamic compilation 'new Function()' detected in: $FilePath at line $($i + 1): `"$($LineContent.Trim())`"")
            }
            # Check for child_process exec/execSync - block if called globally/directly or via child_process object
            # Avoid flagging safe pattern matching like regex.exec() or pipeline.exec()
            if ($LineContent -match '(?<![a-zA-Z0-9_$.])exec(Sync)?\s*\(' -or $LineContent -match 'child_process\.exec(Sync)?\s*\(') {
                $Violations.Add("[JS/TS SCAN] Shell spawn 'exec/execSync' execution detected in: $FilePath at line $($i + 1): `"$($LineContent.Trim())`"")
            }
            # v14.0.0-CloudNative: Check for import/require package whitelisting
            if ($LineContent -match 'import\s+.*?\s+from\s+[''"](?<pkg>[a-zA-Z0-9_@./-]+)[''"]' -or $LineContent -match 'require\s*\([''"](?<pkg>[a-zA-Z0-9_@./-]+)[''"]\)') {
                $Pkg = $Matches['pkg']
                $CleanPkg = $Pkg.Split('/')[0]
                if ($Pkg -match '^@') {
                    $CleanPkg = ($Pkg -split '/')[0..1] -join '/'
                }
                
                if ($CleanPkg -notmatch '^\.' -and $CleanPkg -notin $NodeBuiltins -and $CleanPkg -notin $ApprovedDeps) {
                    Write-SovereignLog -Level "WARN" -Step "SECURITY_SWEEP" -Message "Unwhitelisted third-party package dependency '$Pkg' imported in $FilePath at line $($i + 1)."
                }
            }
        }
    }
}

# Process scan results
if ($Violations.Count -gt 0) {
    Write-SovereignLog -Level "ERROR" -Step "SECURITY_SWEEP" -Message "Security Audit FAILED! $($Violations.Count) violation(s) detected:"
    foreach ($Violation in $Violations) {
        Write-SovereignLog -Level "ERROR" -Step "SECURITY_SWEEP" -Message "  -> $Violation"
    }

    if ($BlockOnError) {
        throw "SECURITY_AUDIT_FAIL: Dynamic code execution or AST vulnerability scan failed. Execution blocked."
    }
} else {
    Write-SovereignLog -Level "INFO" -Step "SECURITY_SWEEP" -Message "Security Audit PASSED. 0 vulnerabilities found across $($Files.Count) verified files."
}
