# run_e2e_tests.ps1 (v14.0.0-CloudNative)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Invoke-Pester -Path 'C:\Skills\agent-bootstrap\tests\e2e' -Output Detailed
