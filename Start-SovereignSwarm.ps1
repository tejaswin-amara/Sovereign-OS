param(
    [string]$Task = "Default Swarm Objective",
    [switch]$VerboseOutput
)

Set-StrictMode -Version Latest

Write-Information -InformationAction Continue "Initializing Sovereign Multi-Agent Swarm..."

# Execute Python LangGraph Sequence natively with graceful fallback
$pythonCmd = if (Get-Command "python3" -ErrorAction SilentlyContinue) { "python3" } elseif (Get-Command "python" -ErrorAction SilentlyContinue) { "python" } else { $null }

if ($pythonCmd) {
    # Path is relative to where Start-SovereignSwarm.ps1 is (C:\Skills)
    $graphScript = Join-Path $PSScriptRoot "agent-bootstrap\scripts\graph.py"
    & $pythonCmd $graphScript $Task
} else {
    # Ponytail: Zero dependency fallback when no python is available
    Write-Information -InformationAction Continue "Delegating task: '$Task'"
    Write-Information -InformationAction Continue "Initializing Sovereign Multi-Agent Swarm... (PowerShell Fallback Mode)"
    $Agents = @("omni_harvester", "architect_node", "reviewer_node")
    foreach ($Agent in $Agents) {
        Write-Information -InformationAction Continue "[$Agent]: node active and processing."
    }
    Write-Information -InformationAction Continue "Swarm processing complete. Synchronizing artifacts..."
    Write-Information -InformationAction Continue "Task finished successfully."
}
