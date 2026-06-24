<#
.SYNOPSIS
Sovereign OS Universal Setup Script
.DESCRIPTION
This script prepares a fresh environment for Sovereign OS. It verifies PowerShell 7+, triggers the Agent-Reach installation, and runs an initial diagnostic sweep.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Information -InformationAction Continue "🔱 SOVEREIGN OS - INITIALIZATION SEQUENCE 🔱" -ForegroundColor Cyan
Write-Information -InformationAction Continue "============================================="

# 1. Verify PowerShell Version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Information -InformationAction Continue "[ERROR] Sovereign OS requires PowerShell 7+. You are running $($PSVersionTable.PSVersion)." -ForegroundColor Red
    Write-Information -InformationAction Continue "Please install PowerShell 7: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows"
    exit 1
}
Write-Information -InformationAction Continue "[OK] PowerShell 7+ detected." -ForegroundColor Green

# 2. Install Agent-Reach
Write-Information -InformationAction Continue "`n[1/3] Initializing Agent-Reach Protocol..." -ForegroundColor Yellow
try {
    pwsh -ExecutionPolicy Bypass -File "agent-bootstrap/scripts/Install-AgentReach.ps1"
    Write-Information -InformationAction Continue "[OK] Agent-Reach installed successfully." -ForegroundColor Green
} catch {
    Write-Information -InformationAction Continue "[WARNING] Agent-Reach installation encountered issues. Continuing setup... $_" -ForegroundColor Yellow
}

# 3. Verify Configurations
Write-Information -InformationAction Continue "`n[2/3] Verifying Sovereign Core Configurations..." -ForegroundColor Yellow
if (-not (Test-Path "sovereign.config.json")) {
    Write-Information -InformationAction Continue "[ERROR] Missing sovereign.config.json. Ensure you cloned the entire repository." -ForegroundColor Red
    exit 1
}
Write-Information -InformationAction Continue "[OK] Core configurations present." -ForegroundColor Green

# 4. Run Enterprise Sweep
Write-Information -InformationAction Continue "`n[3/3] Running Sovereign Enterprise Diagnostic Sweep..." -ForegroundColor Yellow
pwsh -ExecutionPolicy Bypass -File "sovereign-check.ps1"

Write-Information -InformationAction Continue "`n============================================="
Write-Information -InformationAction Continue "✅ SOVEREIGN OS INSTALLED AND VERIFIED!" -ForegroundColor Green
Write-Information -InformationAction Continue "Run the master pipeline to boot the system:"
Write-Information -InformationAction Continue "pwsh -ExecutionPolicy Bypass -File `"sovereign.ps1`"" -ForegroundColor Cyan
