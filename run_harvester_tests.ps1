# C:\Skills\run_harvester_tests.ps1
# Empirical test runner for skill-harvester and its parsers.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Load the helpers module
Import-Module "$PSScriptRoot/agent-bootstrap/scripts/helpers.psm1" -Force -DisableNameChecking

# Mock Write-SovereignLog to prevent missing function errors and capture logs
$script:LogWarnings = [System.Collections.Generic.List[string]]::new()
function Write-SovereignLog {
    param(
        [string]$Level,
        [string]$Step,
        [string]$Message
    )
    $log = "[$Level] [$Step] $Message"
    Write-Host $log -ForegroundColor Yellow
    if ($Level -eq "WARN" -or $Level -eq "ERROR") {
        $script:LogWarnings.Add($log)
    }
}

# Load the parsers
$HarvesterDir = "C:\Skills\agent-bootstrap\scripts\harvesters"
$Parsers = @("NodeParser.ps1", "PythonParser.ps1", "RustParser.ps1", "GoParser.ps1", "JavaParser.ps1", "DotNetParser.ps1")

foreach ($Parser in $Parsers) {
    $ParserPath = Join-Path $HarvesterDir $Parser
    if (Test-Path -LiteralPath $ParserPath) {
        Write-Host "Loading parser: $ParserPath" -ForegroundColor Cyan
        . $ParserPath
    } else {
        Write-Error "Parser file not found: $ParserPath"
    }
}

# Test workspace path
$FixtureRoot = "C:\Skills\harvester_test_fixtures"

# Dot-source the helpers containing Setup-Fixtures and Assert functions
. "$PSScriptRoot/agent-bootstrap/tests/HarvesterTestHelpers.ps1"

# Run the tests
$Results = [System.Collections.Generic.List[PSCustomObject]]::new()

try {
    Setup-Fixtures

    Write-Host "`n=== STARTING PARSER EMPIRICAL TESTS ===`n" -ForegroundColor Cyan

    # --- Test Case 1: Empty Folder ---
    $script:LogWarnings.Clear()
    $deps = Get-NodeDependencies -ResolvedWorkspace (Join-Path $FixtureRoot "empty_dir")
    Assert-Empty $deps "NodeParser on empty folder"

    $deps = Get-PythonDependencies -ResolvedWorkspace (Join-Path $FixtureRoot "empty_dir")
    Assert-Empty $deps "PythonParser on empty folder"

    $deps = Get-RustDependencies -ResolvedWorkspace (Join-Path $FixtureRoot "empty_dir")
    Assert-Empty $deps "RustParser on empty folder"

    $deps = Get-GoDependencies -ResolvedWorkspace (Join-Path $FixtureRoot "empty_dir")
    Assert-Empty $deps "GoParser on empty folder"

    $deps = Get-JavaDependencies -ResolvedWorkspace (Join-Path $FixtureRoot "empty_dir")
    Assert-Empty $deps "JavaParser on empty folder"

    $deps = Get-DotNetDependencies -ResolvedWorkspace (Join-Path $FixtureRoot "empty_dir")
    Assert-Empty $deps "DotNetParser on empty folder"

    # --- Test Case 2: Deep Folders ---
    $deps = Get-NodeDependencies -ResolvedWorkspace (Join-Path $FixtureRoot "deep_dir")
    Assert-Contains -Collection $deps -Item "express" -TestName "NodeParser on deep folder recursion"

    # --- Test Case 3: Folder with Special Characters in Name ---
    $deps = Get-RustDependencies -ResolvedWorkspace (Join-Path $FixtureRoot "dir[with]brackets")
    Assert-Contains -Collection $deps -Item "serde" -TestName "RustParser on folder with brackets 'dir[with]brackets'"

    $deps = Get-PythonDependencies -ResolvedWorkspace (Join-Path $FixtureRoot "dir with spaces")
    Assert-Contains -Collection $deps -Item "flask" -TestName "PythonParser on folder with spaces 'dir with spaces'"

    $deps = Get-GoDependencies -ResolvedWorkspace (Join-Path $FixtureRoot "dir#with#hashes")
    Assert-Contains -Collection $deps -Item "github.com/gin-gonic/gin" -TestName "GoParser on folder with hashes (full path)"
    Assert-Contains -Collection $deps -Item "gin" -TestName "GoParser on folder with hashes (short name)"

    # --- Test Case 4: Invalid Manifest Files (Robustness) ---
    $script:LogWarnings.Clear()
    $invalidDir = Join-Path $FixtureRoot "invalid_manifests"
    
    # Node should fail to parse invalid json but log a warning and not crash
    # ponytail: Removed unused $deps assignment in C:\Skills\run_harvester_tests.ps1 at line 271 to reduce technical debt
    Assert-Throws-No-Error {
        Get-NodeDependencies -ResolvedWorkspace $invalidDir
    } "NodeParser does not crash on invalid package.json"
    if ($script:LogWarnings.Count -gt 0) {
        Write-Host "  [INFO] NodeParser logged expected warnings: $script:LogWarnings" -ForegroundColor Gray
    }

    # Python parsing of invalid requirements.txt or pyproject.toml
    Assert-Throws-No-Error {
        $deps = Get-PythonDependencies -ResolvedWorkspace $invalidDir
        Write-Host "  [INFO] PythonParser invalid_manifests deps: $($deps -join ', ')" -ForegroundColor Gray
    } "PythonParser does not crash on invalid pyproject.toml and requirements.txt"

    # --- Test Case 5: Maven/Gradle Mixes ---
    $deps = Get-JavaDependencies -ResolvedWorkspace (Join-Path $FixtureRoot "mix_dir")
    Assert-Contains -Collection $deps -Item "junit" -TestName "JavaParser Maven dependency in mixed folder"
    Assert-Contains -Collection $deps -Item "junit:junit" -TestName "JavaParser Maven G:A dependency in mixed folder"
    Assert-Contains -Collection $deps -Item "spring-core" -TestName "JavaParser Gradle dependency in mixed folder"
    Assert-Contains -Collection $deps -Item "org.springframework:spring-core" -TestName "JavaParser Gradle G:A dependency in mixed folder"
    Assert-Contains -Collection $deps -Item "mockito-core" -TestName "JavaParser Gradle dependency without version"
    Assert-Contains -Collection $deps -Item "org.mockito:mockito-core" -TestName "JavaParser Gradle G:A dependency without version"

    # --- Test Case 6: Reparse Point (Symlink/Junction) Recursion ---
    # In junction_dir we have sub_dir/test.csproj and self_loop (junction pointing to junction_dir)
    # If the parser handles junctions correctly, it will parse sub_dir/test.csproj but NOT get stuck in self_loop.
    # Let's verify DotNetParser.
    $juncDir = Join-Path $FixtureRoot "junction_dir"
    
    $task = Start-Job -ScriptBlock {
        param($juncDir, $HarvesterDir)
        # Load helpers module in the job scope
        $SovereignRoot = (Resolve-Path -LiteralPath "$HarvesterDir/../../..").Path
        Import-Module "$SovereignRoot/agent-bootstrap/scripts/helpers.psm1" -Force -DisableNameChecking
        # Load DotNetParser in the job scope
        . (Join-Path $HarvesterDir "DotNetParser.ps1")
        # Define mock log
        function Write-SovereignLog { param($Level, $Step, $Message) }
        $start = [DateTime]::UtcNow
        $deps = Get-DotNetDependencies -ResolvedWorkspace $juncDir
        $duration = ([DateTime]::UtcNow - $start).TotalSeconds
        return [PSCustomObject]@{ Deps = $deps; Duration = $duration }
    } -ArgumentList $juncDir, $HarvesterDir

    Write-Host "Waiting for DotNetParser on junction directory (loop protection check)..."
    # Wait for job using Wait-Job. $completed will be the job if it finishes within 5 seconds.
    $completed = Wait-Job $task -Timeout 5
    if ($null -eq $completed) {
        Write-Host "  [FAIL] DotNetParser got stuck in infinite junction recursion!" -ForegroundColor Red
        $Results.Add([PSCustomObject]@{ Test = "Junction recursion safety"; Result = "FAIL"; Details = "Parser timed out (stuck in junction loop)" })
        Stop-Job $task -ErrorAction SilentlyContinue | Out-Null
    } else {
        $jobResult = Receive-Job $task
        Write-Host "  [PASS] DotNetParser finished in $($jobResult.Duration) seconds without infinite recursion." -ForegroundColor Green
        Assert-Contains -Collection $jobResult.Deps -Item "Newtonsoft.Json" -TestName "DotNetParser on junction_dir finds csproj in sub_dir"
    }

    # Clean up junction link first before deleting the root
    $junctionLink = Join-Path $FixtureRoot "junction_dir\self_loop"
    if (Test-Path -LiteralPath $junctionLink) {
        Write-Host "Removing directory junction link: $junctionLink"
        $isWin = if (Get-Variable -Name "IsWindows" -ValueOnly -ErrorAction SilentlyContinue) { $true } elseif ($env:OS -eq "Windows_NT") { $true } else { $false }
        if ($isWin) {
            cmd.exe /c rmdir "$junctionLink"
        } else {
            Remove-Item -LiteralPath $junctionLink -Force
        }
    }

} catch {
    Write-Host "CRITICAL TEST FAILURE: $_" -ForegroundColor Red
} finally {
    # Clean up test fixtures
    Write-Host "Cleaning up test fixtures..." -ForegroundColor Gray
    if (Test-Path -LiteralPath $FixtureRoot) {
        Remove-Item -LiteralPath $FixtureRoot -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

# Generate markdown report in Results
$ReportFile = Join-Path $PSScriptRoot "test_report.md"
$Report = "# Harvester Parsers Test Report`n`n"
$Report += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
$Report += "| Test Name | Result | Details |`n"
$Report += "|---|---|---|`n"
foreach ($r in $Results) {
    $Report += "| $($r.Test) | **$($r.Result)** | $($r.Details) |`n"
}
Set-Content -Path $ReportFile -Value $Report
Write-Host "`nTest report written to: $ReportFile" -ForegroundColor Green
