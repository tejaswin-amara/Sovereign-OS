# Install-AgentReach.ps1 — Sovereign Internet Reach Installer
# Purpose: Install Agent-Reach runtime and zero-config channels for Sovereign.
# Location: C:/Skills/agent-bootstrap/scripts/Install-AgentReach.ps1

[CmdletBinding()]
param(
    [switch]$Safe = $false,
    [string]$Channels = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$SovereignRoot = (Resolve-Path "$PSScriptRoot/../..").Path

# -------------------------------------------------------------------------
# 1. PREFLIGHT — Check Python availability
# -------------------------------------------------------------------------
Write-Host "[REACH] Agent-Reach Installer starting..." -ForegroundColor Cyan

$PythonCmd = $null
foreach ($Candidate in @("python", "python3", "py")) {
    try {
        $Ver = & $Candidate --version 2>&1
        if ($Ver -match "Python\s+3\.(1[0-9]|[2-9][0-9])") {
            $PythonCmd = $Candidate
            Write-Host "[REACH] Found Python: $Ver ($Candidate)" -ForegroundColor Green
            break
        }
    } catch {}
}

if (-not $PythonCmd) {
    throw "Python 3.10+ is required but not found. Install Python first."
}

# -------------------------------------------------------------------------
# 2. CREATE ISOLATED VENV
# -------------------------------------------------------------------------
$VenvDir = Join-Path $SovereignRoot ".agent-reach-venv"
$VenvActivate = Join-Path $VenvDir "Scripts\Activate.ps1"

if (-not (Test-Path $VenvDir)) {
    Write-Host "[REACH] Creating isolated Python venv at $VenvDir..." -ForegroundColor Cyan
    & $PythonCmd -m venv $VenvDir
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create Python venv."
    }
}

# Activate venv for this session
& $VenvActivate

# -------------------------------------------------------------------------
# 3. INSTALL AGENT-REACH
# -------------------------------------------------------------------------
Write-Host "[REACH] Installing agent-reach from GitHub..." -ForegroundColor Cyan
$PipExe = Join-Path $VenvDir "Scripts\pip.exe"
& $PipExe install "git+https://github.com/Panniantong/Agent-Reach.git" --quiet
if ($LASTEXITCODE -ne 0) {
    throw "pip install failed for agent-reach."
}
Write-Host "[REACH] agent-reach package installed." -ForegroundColor Green

# -------------------------------------------------------------------------
# 4. RUN AGENT-REACH INSTALL
# -------------------------------------------------------------------------
$AgentReachExe = Join-Path $VenvDir "Scripts\agent-reach.exe"
if (-not (Test-Path $AgentReachExe)) {
    $AgentReachExe = "agent-reach"
}

$InstallArgs = @("install", "--env=auto")
if ($Safe) { $InstallArgs += "--safe" }

Write-Host "[REACH] Running: agent-reach $($InstallArgs -join ' ')" -ForegroundColor Cyan
& $AgentReachExe @InstallArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARN] agent-reach install returned non-zero. Check doctor output." -ForegroundColor Yellow
}

# -------------------------------------------------------------------------
# 5. INSTALL OPTIONAL CHANNELS (if specified)
# -------------------------------------------------------------------------
if (-not [string]::IsNullOrWhiteSpace($Channels)) {
    Write-Host "[REACH] Installing optional channels: $Channels" -ForegroundColor Cyan
    & $AgentReachExe install --env=auto "--channels=$Channels"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARN] Optional channel install returned non-zero." -ForegroundColor Yellow
    }
}

# -------------------------------------------------------------------------
# 6. RUN DOCTOR
# -------------------------------------------------------------------------
Write-Host "[REACH] Running health check..." -ForegroundColor Cyan
& $AgentReachExe doctor
$DoctorExit = $LASTEXITCODE

# -------------------------------------------------------------------------
# 7. REPORT
# -------------------------------------------------------------------------
if ($DoctorExit -eq 0) {
    Write-Host "[SUCCESS] Agent-Reach is fully operational." -ForegroundColor Green
} else {
    Write-Host "[WARN] Some channels may need configuration. Run 'agent-reach doctor' for details." -ForegroundColor Yellow
}

Write-Host "[REACH] Installation complete. Venv: $VenvDir" -ForegroundColor Cyan
return
