# C:/Skills/agent-bootstrap/scripts/helpers/Validation.ps1
Set-StrictMode -Version Latest

function Assert-SovereignPattern {
    [CmdletBinding()]
    param([string]$InputString, [string]$Pattern)
    if ($InputString -notmatch $Pattern) {
        throw "PATTERN_MISMATCH: '$InputString' does not match required pattern '$Pattern'"
    }
    return $true
}
