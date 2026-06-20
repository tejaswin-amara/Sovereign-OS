# C:\Skills\run_harvester_tests.ps1
# Empirical test runner for skill-harvester and its parsers.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Load the helpers module
Import-Module "C:/Skills/agent-bootstrap/scripts/helpers.psm1" -Force -DisableNameChecking

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

# Setup fixture directories
function Setup-Fixtures {
    Write-Host "Setting up test fixtures at $FixtureRoot..." -ForegroundColor Green
    if (Test-Path -LiteralPath $FixtureRoot) {
        # Force delete existing
        Remove-Item -LiteralPath $FixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -Path $FixtureRoot -ItemType Directory -Force | Out-Null

    # Case 1: Empty Folder
    New-Item -Path (Join-Path $FixtureRoot "empty_dir") -ItemType Directory -Force | Out-Null

    # Case 2: Deep Folders
    $deepPath = Join-Path $FixtureRoot "deep_dir"
    for ($i = 1; $i -le 20; $i++) {
        $deepPath = Join-Path $deepPath $i
    }
    New-Item -Path $deepPath -ItemType Directory -Force | Out-Null
    # Add a package.json at the deepest level
    $pkgJsonContent = @{
        dependencies = @{
            express = "^4.17.1"
        }
    } | ConvertTo-Json
    Set-Content -LiteralPath (Join-Path $deepPath "package.json") -Value $pkgJsonContent

    # Case 3: Folder with Special Characters in Name
    $specBrackets = Join-Path $FixtureRoot "dir[with]brackets"
    $specSpaces = Join-Path $FixtureRoot "dir with spaces"
    $specHashes = Join-Path $FixtureRoot "dir#with#hashes"
    $specQuotes = Join-Path $FixtureRoot "dir'with'quotes"
    New-Item -Path $specBrackets -ItemType Directory -Force | Out-Null
    New-Item -Path $specSpaces -ItemType Directory -Force | Out-Null
    New-Item -Path $specHashes -ItemType Directory -Force | Out-Null
    New-Item -Path $specQuotes -ItemType Directory -Force | Out-Null

    # Put a Cargo.toml with serde inside brackets folder
    $cargoContent = @"
[dependencies]
serde = "1.0"
"@
    Set-Content -LiteralPath (Join-Path $specBrackets "Cargo.toml") -Value $cargoContent

    # Put a requirements.txt with flask inside spaces folder
    $reqContent = "flask>=2.0.0"
    Set-Content -LiteralPath (Join-Path $specSpaces "requirements.txt") -Value $reqContent

    # Put a go.mod inside hashes folder
    $goModContent = @"
module test

go 1.16

require (
	github.com/gin-gonic/gin v1.7.0
)
"@
    Set-Content -LiteralPath (Join-Path $specHashes "go.mod") -Value $goModContent

    # Case 4: Invalid Manifest Files (Robustness)
    $invalidDir = Join-Path $FixtureRoot "invalid_manifests"
    New-Item -Path $invalidDir -ItemType Directory -Force | Out-Null
    # Invalid package.json (invalid JSON syntax)
    Set-Content -LiteralPath (Join-Path $invalidDir "package.json") -Value "{ invalid json: yes "
    # Invalid requirements.txt (empty or weird content)
    Set-Content -LiteralPath (Join-Path $invalidDir "requirements.txt") -Value "-r non_existent.txt`n-e .`ngit+https://github.com/psf/requests.git"
    # Invalid pyproject.toml (invalid TOML syntax but matching some patterns)
    $invalidPyProj = @"
[project.dependencies]
invalid_pkg = 
broken syntax
"@
    Set-Content -LiteralPath (Join-Path $invalidDir "pyproject.toml") -Value $invalidPyProj

    # Case 5: Maven/Gradle Mixes
    $mixDir = Join-Path $FixtureRoot "mix_dir"
    New-Item -Path $mixDir -ItemType Directory -Force | Out-Null
    # pom.xml
    $pomContent = @"
<project>
  <dependencies>
    <dependency>
      <groupId>junit</groupId>
      <artifactId>junit</artifactId>
      <version>4.12</version>
    </dependency>
  </dependencies>
</project>
"@
    Set-Content -LiteralPath (Join-Path $mixDir "pom.xml") -Value $pomContent
    # build.gradle
    $gradleContent = @"
dependencies {
    implementation 'org.springframework:spring-core:5.3.9'
    testImplementation "org.mockito:mockito-core"
}
"@
    Set-Content -LiteralPath (Join-Path $mixDir "build.gradle") -Value $gradleContent

    # Case 6: Reparse Point (Symlink/Junction) Recursion
    $junctionDir = Join-Path $FixtureRoot "junction_dir"
    New-Item -Path $junctionDir -ItemType Directory -Force | Out-Null
    $subDir = Join-Path $junctionDir "sub_dir"
    New-Item -Path $subDir -ItemType Directory -Force | Out-Null
    
    # Put a csproj inside sub_dir
    $csprojContent = @"
<Project Sdk="Microsoft.NET.Sdk">
  <ItemGroup>
    <PackageReference Include="Newtonsoft.Json" Version="13.0.1" />
  </ItemGroup>
</Project>
"@
    Set-Content -LiteralPath (Join-Path $subDir "test.csproj") -Value $csprojContent

    # Create a junction inside junction_dir pointing to itself (infinite recursion test)
    $junctionLink = Join-Path $junctionDir "self_loop"
    Write-Host "Creating directory junction from $junctionLink to $junctionDir"
    # Call cmd.exe to run mklink
    $cmdOutput = cmd.exe /c mklink /j "$junctionLink" "$junctionDir" 2>&1
    Write-Host "mklink output: $cmdOutput"
}

# Run the tests
$Results = [System.Collections.Generic.List[PSCustomObject]]::new()

function Assert-Contains {
    param(
        [System.Collections.IEnumerable]$Collection,
        [string]$Item,
        [string]$TestName
    )
    $found = $false
    if ($Collection) {
        foreach ($c in $Collection) {
            if ($c -eq $Item) { $found = $true; break }
        }
    }
    if ($found) {
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
        $Results.Add([PSCustomObject]@{ Test = $TestName; Result = "PASS"; Details = "Found expected dependency: $Item" })
    } else {
        Write-Host "  [FAIL] $TestName" -ForegroundColor Red
        Write-Host "         Collection: $($Collection -join ', ')" -ForegroundColor DarkRed
        $Results.Add([PSCustomObject]@{ Test = $TestName; Result = "FAIL"; Details = "Expected dependency '$Item' not found. Got: $($Collection -join ', ')" })
    }
}

function Assert-Empty {
    param(
        [System.Collections.IEnumerable]$Collection,
        [string]$TestName
    )
    $count = 0
    if ($Collection) {
        $count = @($Collection).Count
    }
    if ($count -eq 0) {
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
        $Results.Add([PSCustomObject]@{ Test = $TestName; Result = "PASS"; Details = "Collection is empty, as expected" })
    } else {
        Write-Host "  [FAIL] $TestName" -ForegroundColor Red
        Write-Host "         Got: $($Collection -join ', ')" -ForegroundColor DarkRed
        $Results.Add([PSCustomObject]@{ Test = $TestName; Result = "FAIL"; Details = "Expected empty collection, got $count items: $($Collection -join ', ')" })
    }
}

function Assert-Throws-No-Error {
    param(
        [scriptblock]$Action,
        [string]$TestName
    )
    try {
        & $Action
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
        $Results.Add([PSCustomObject]@{ Test = $TestName; Result = "PASS"; Details = "Executed without error" })
    } catch {
        Write-Host "  [FAIL] $TestName" -ForegroundColor Red
        Write-Host "         Error: $_" -ForegroundColor DarkRed
        $Results.Add([PSCustomObject]@{ Test = $TestName; Result = "FAIL"; Details = "Expected no error, but caught: $_" })
    }
}

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
    Assert-Contains $deps "express" "NodeParser on deep folder recursion"

    # --- Test Case 3: Folder with Special Characters in Name ---
    $deps = Get-RustDependencies -ResolvedWorkspace (Join-Path $FixtureRoot "dir[with]brackets")
    Assert-Contains $deps "serde" "RustParser on folder with brackets 'dir[with]brackets'"

    $deps = Get-PythonDependencies -ResolvedWorkspace (Join-Path $FixtureRoot "dir with spaces")
    Assert-Contains $deps "flask" "PythonParser on folder with spaces 'dir with spaces'"

    $deps = Get-GoDependencies -ResolvedWorkspace (Join-Path $FixtureRoot "dir#with#hashes")
    Assert-Contains $deps "github.com/gin-gonic/gin" "GoParser on folder with hashes (full path)"
    Assert-Contains $deps "gin" "GoParser on folder with hashes (short name)"

    # --- Test Case 4: Invalid Manifest Files (Robustness) ---
    $script:LogWarnings.Clear()
    $invalidDir = Join-Path $FixtureRoot "invalid_manifests"
    
    # Node should fail to parse invalid json but log a warning and not crash
    Assert-Throws-No-Error {
        $deps = Get-NodeDependencies -ResolvedWorkspace $invalidDir
    } "NodeParser does not crash on invalid package.json"
    if ($script:LogWarnings.Count -gt 0) {
        Write-Host "  [INFO] NodeParser logged expected warnings: $script:LogWarnings" -ForegroundColor Gray
    }

    # Python parsing of invalid requirements.txt or pyproject.toml
    Assert-Throws-No-Error {
        $deps = Get-PythonDependencies -ResolvedWorkspace $invalidDir
        # Let's see what it extracted from requirements.txt
        # "-r non_existent.txt`n-e .`ngit+https://github.com/psf/requests.git"
        # Since it splits on #, ;, it should fall back. Let's see:
        # `-e .` is not skipped because it doesn't match egg, url, or requirement.txt splits.
        # Let's inspect $deps.
        Write-Host "  [INFO] PythonParser invalid_manifests deps: $($deps -join ', ')" -ForegroundColor Gray
    } "PythonParser does not crash on invalid pyproject.toml and requirements.txt"

    # --- Test Case 5: Maven/Gradle Mixes ---
    $deps = Get-JavaDependencies -ResolvedWorkspace (Join-Path $FixtureRoot "mix_dir")
    Assert-Contains $deps "junit" "JavaParser Maven dependency in mixed folder"
    Assert-Contains $deps "junit:junit" "JavaParser Maven G:A dependency in mixed folder"
    Assert-Contains $deps "spring-core" "JavaParser Gradle dependency in mixed folder"
    Assert-Contains $deps "org.springframework:spring-core" "JavaParser Gradle G:A dependency in mixed folder"
    Assert-Contains $deps "mockito-core" "JavaParser Gradle dependency without version"
    Assert-Contains $deps "org.mockito:mockito-core" "JavaParser Gradle G:A dependency without version"

    # --- Test Case 6: Reparse Point (Symlink/Junction) Recursion ---
    # In junction_dir we have sub_dir/test.csproj and self_loop (junction pointing to junction_dir)
    # If the parser handles junctions correctly, it will parse sub_dir/test.csproj but NOT get stuck in self_loop.
    # Let's verify DotNetParser.
    $juncDir = Join-Path $FixtureRoot "junction_dir"
    
    $timeoutMiliseconds = 5000
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
    $completed = Wait-Job $task -Timeout 5
    if ($null -eq $completed) {
        Write-Host "  [FAIL] DotNetParser got stuck in infinite junction recursion!" -ForegroundColor Red
        $Results.Add([PSCustomObject]@{ Test = "Junction recursion safety"; Result = "FAIL"; Details = "Parser timed out (stuck in junction loop)" })
        Stop-Job $task -ErrorAction SilentlyContinue | Out-Null
    } else {
        $jobResult = Receive-Job $task
        Write-Host "  [PASS] DotNetParser finished in $($jobResult.Duration) seconds without infinite recursion." -ForegroundColor Green
        Assert-Contains $jobResult.Deps "Newtonsoft.Json" "DotNetParser on junction_dir finds csproj in sub_dir"
    }

    # Clean up junction link first before deleting the root
    $junctionLink = Join-Path $FixtureRoot "junction_dir\self_loop"
    if (Test-Path -LiteralPath $junctionLink) {
        Write-Host "Removing directory junction link: $junctionLink"
        # On Windows, to remove a directory junction without removing the target content, we can use cmd.exe rmdir
        cmd.exe /c rmdir "$junctionLink"
    }

} catch {
    Write-Host "CRITICAL TEST FAILURE: $_" -ForegroundColor Red
} finally {
    # Clean up test fixtures
    Write-Host "Cleaning up test fixtures..." -ForegroundColor Gray
    if (Test-Path -LiteralPath $FixtureRoot) {
        Remove-Item -LiteralPath $FixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
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
