# D:/Skills/agent-bootstrap/scripts/helpers/IO.ps1

function Invoke-AtomicMove {
    [CmdletBinding()]
    param([string]$Source, [string]$Destination)

    if (-not (Test-Path $Source)) {
        Write-SovereignLog -Level "ERROR" -Step "ATOMIC_MOVE" -Message "Source does not exist: $Source"
        throw "SOURCE_MISSING: $Source"
    }

    if (Test-Path $Destination) {
        $backup = "$Destination.bak"
        Move-Item $Destination $backup -Force
    }

    try {
        Move-Item $Source $Destination -Force
        if (Test-Path "$Destination.bak") { Remove-Item "$Destination.bak" -Force }
    } catch {
        if (Test-Path "$Destination.bak") { Move-Item "$Destination.bak" $Destination -Force }
        throw "ATOMIC_MOVE_FAIL: $($_.Exception.Message)"
    }
}
