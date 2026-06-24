# HarvesterTestHelpers.ps1 - Helpers for Harvester Parser Empirical Tests
# Purpose: Fixture setup and assertion functions for harvester tests.

function Setup-Fixtures {
    Write-Host "Setting up test fixtures at $FixtureRoot..." -ForegroundColor Green
    if (Test-Path -LiteralPath $FixtureRoot) {
        # Force delete existing
        Remove-Item -LiteralPath $FixtureRoot -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
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
    Write-Information -InformationAction Continue "Creating directory junction from $junctionLink to $junctionDir"
    # Call cmd.exe to run mklink
    $cmdOutput = cmd.exe /c mklink /j "$junctionLink" "$junctionDir" 2>&1
    Write-Information -InformationAction Continue "mklink output: $cmdOutput"
}

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
