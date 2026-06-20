# C:/Skills/agent-bootstrap/scripts/helpers/Version.ps1

function Get-SovereignVersion {
    [CmdletBinding()]
    param([string]$SkillsRoot = "C:/Skills")
    $VersionFile = Join-Path $SkillsRoot "VERSION"
    if (Test-Path $VersionFile) {
        return (Get-Content $VersionFile -First 1).Trim()
    }
    throw "VERSION_MISSING: Cannot find $VersionFile"
}

function Test-SovereignIntegrity {
    [CmdletBinding()]
    param([string]$RootPath = "$PSScriptRoot/../../..")

    Write-SovereignLog -Level "INFO" -Step "INTEGRITY_CHECK" -Message "Scanning for orphaned backup files..."

    $ScanPaths = @(
        [PSCustomObject]@{ Path = $RootPath; Recurse = $false }
        [PSCustomObject]@{ Path = "$RootPath/agent-bootstrap"; Recurse = $true }
    )

    $BakFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    $TmpFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

    foreach ($Item in $ScanPaths) {
        if (Test-Path $Item.Path) {
            $Baks = Get-ChildItem $Item.Path -Filter "*.bak" -Recurse:$Item.Recurse -ErrorAction SilentlyContinue
            if ($Baks) { foreach ($b in $Baks) { $BakFiles.Add($b) } }
            $Tmps = Get-ChildItem $Item.Path -Filter "*.tmp" -Recurse:$Item.Recurse -ErrorAction SilentlyContinue
            if ($Tmps) { foreach ($t in $Tmps) { $TmpFiles.Add($t) } }
        }
    }

    foreach ($file in $BakFiles) {
        $live = $file.FullName -replace '\.bak$', ''
        if (-not (Test-Path $live) -or (Get-Item $live).Length -eq 0) {
            Write-SovereignLog -Level "INFO" -Step "RESTORE" -Message "Restoring $live from backup $($file.Name)"
            Move-Item $file.FullName $live -Force
        }
    }

    foreach ($file in $TmpFiles) {
        Write-SovereignLog -Level "INFO" -Step "CLEANUP" -Message "Removing stale temp file: $($file.Name)"
        Remove-Item $file.FullName -Force
    }

    Write-SovereignLog -Level "INFO" -Step "INTEGRITY_CHECK" -Message "Complete. System is clean."
}
