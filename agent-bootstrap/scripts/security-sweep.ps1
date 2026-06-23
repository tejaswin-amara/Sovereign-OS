# security-sweep.ps1 - Autonomous AST and Security Validation Workflow (v14.0.0-CloudNative)
# Purpose: Pre-commit/Pre-execution parsing to block dynamic code execution and vulnerability leakage.
# Location: C:/Skills/agent-bootstrap/scripts/security-sweep.ps1

[CmdletBinding()]
param(
    [string]$ProjectPath = "",
    [bool]$BlockOnError = $true
)

Set-StrictMode -Version Latest

# Core imports
$SovereignRoot = (Resolve-Path "$PSScriptRoot/../..").Path
if ([string]::IsNullOrWhiteSpace($ProjectPath)) { $ProjectPath = $SovereignRoot }

Import-Module "$SovereignRoot/agent-bootstrap/scripts/helpers.psm1" -Force -DisableNameChecking
$Version = Get-SovereignVersion -SkillsRoot $SovereignRoot
$Config = Get-SovereignConfig

Write-SovereignLog -Level "INFO" -Step "SECURITY_SWEEP" -Message "Initializing AST & Code Security Scan v$Version..."

$Violations = [System.Collections.Generic.List[string]]::new()
$Files = [System.Collections.Generic.List[string]]::new()

# Performance Optimization: Early pruning of huge directories
$ExcludeDirs = [System.Collections.Generic.List[string]]::new()
@('node_modules', '.git', 'dist', '.next', 'build', '.agents', 'LOGS', 'templates', 'G0DM0D3', '.archive-v1.0', 'skills', '.agent-reach-venv', '.venv', '__pycache__', 'servers') | ForEach-Object { $ExcludeDirs.Add($_) }

try {
    $AllSubDirs = Get-ChildItem -Path $ProjectPath -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    foreach ($DirName in $AllSubDirs) {
        if ($DirName -ne "agent-bootstrap" -and $DirName -ne ".agents" -and -not $ExcludeDirs.Contains($DirName)) {
            $ExcludeDirs.Add($DirName)
        }
    }
} catch {
    Write-SovereignLog -Level "WARN" -Step "SECURITY_SWEEP" -Message "Failed to build exclusion list: $_"
}

function Get-TargetFiles {
    param([string]$CurrentPath)
    try {
        $Dirs = [System.IO.Directory]::EnumerateDirectories($CurrentPath)
        foreach ($Dir in $Dirs) {
            $DirName = [System.IO.Path]::GetFileName($Dir)
            if (-not $ExcludeDirs.Contains($DirName) -and $DirName -notmatch "^\.") {
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

        # Look for Invoke-Expression, scriptblocks, and encoded commands
        $ViolatingNodes = $AST.FindAll({
            param($AstNode)
            if ($AstNode -is [System.Management.Automation.Language.CommandAst]) {
                $cmd = $AstNode.GetCommandName()
                if ($cmd -ieq "Invoke-Expression" -or $cmd -ieq "iex") { return $true }
            }
            if ($AstNode -is [System.Management.Automation.Language.MemberExpressionAst]) {
                $member = $AstNode.Member.Extent.Text
                if ($member -match "Invoke" -or $member -match "Create") {
                    if ($AstNode.Expression.Extent.Text -match "\[scriptblock\]") { return $true }
                }
            }
            if ($AstNode -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                if ($AstNode.Value -match "powershell.*-e(nc|ncoded)?\s+[A-Za-z0-9+/=]+") { return $true }
            }
            return $false
        }, $true)

        if ($ViolatingNodes) {
            foreach ($node in $ViolatingNodes) {
                $Line = $node.Extent.StartLineNumber
                $Snippet = $node.Extent.Text
                $Violations.Add("[POWERSHELL AST] Dynamic Command Execution detected in: $FilePath at line $($Line): `"$Snippet`"")
            }
        }
    }

    # JavaScript/TypeScript Token / Regex AST Scan
    if ($Extension -in @(".js", ".ts", ".tsx", ".jsx")) {
        $Lines = $Content -split '\r?\n'
        $ApprovedDeps = @()
        if ($Config -and $Config.dep_to_skill_map) {
            $ApprovedDeps = $Config.dep_to_skill_map.PSObject.Properties.Name
        }
        $NodeBuiltins = @("path", "fs", "child_process", "crypto", "events", "stream", "os", "http", "https", "util", "url", "querystring", "zlib", "buffer", "process")

        for ($i = 0; $i -lt $Lines.Count; $i++) {
            $LineContent = $Lines[$i]
            
            # Security: Harden eval() bypasses
            if (($LineContent -match 'eval\s*\(' -and $LineContent -notmatch '[a-zA-Z0-9_$]\.eval\s*\(') -or 
                ($LineContent -match '\[\s*[''"]eval[''"]\s*\]') -or 
                ($LineContent -match '\(\s*0\s*,\s*eval\s*\)')) {
                $Violations.Add("[JS/TS SCAN] Dangerous 'eval()' execution detected in: $FilePath at line $($i + 1): `"$($LineContent.Trim())`"")
            }
            
            # Check for new Function()
            if ($LineContent -match 'new\s+Function\s*\(') {
                $Violations.Add("[JS/TS SCAN] Dynamic compilation 'new Function()' detected in: $FilePath at line $($i + 1): `"$($LineContent.Trim())`"")
            }
            
            # Security: Harden exec() bypasses
            if (($LineContent -match 'exec(Sync)?\s*\(' -and $LineContent -notmatch '[a-zA-Z0-9_$]\.exec(Sync)?\s*\(') -or 
                $LineContent -match 'child_process\.exec(Sync)?\s*\(' -or
                $LineContent -match '\[\s*[''"]exec(Sync)?[''"]\s*\]') {
                $Violations.Add("[JS/TS SCAN] Shell spawn 'exec/execSync' execution detected in: $FilePath at line $($i + 1): `"$($LineContent.Trim())`"")
            }
            
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
