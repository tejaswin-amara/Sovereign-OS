# Harvester Parsers Test Suite
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SovereignRoot = (Resolve-Path "$PSScriptRoot/../..").Path

# Import the main harvester helpers or dot-source the parsers
Describe "Sovereign Harvester Parsers" {
    BeforeAll {
        $script:MockWorkspace = Join-Path $PSScriptRoot "mock_workspace"
        if (Test-Path -LiteralPath $script:MockWorkspace) {
            Remove-Item -LiteralPath $script:MockWorkspace -Recurse -Force -ErrorAction SilentlyContinue
        }
        New-Item -Path $script:MockWorkspace -ItemType Directory -Force | Out-Null
        
        # Load the parsers
        $HarvestersPath = Join-Path $SovereignRoot "agent-bootstrap/scripts/harvesters"
        Get-ChildItem -LiteralPath $HarvestersPath -Filter "*Parser.ps1" | ForEach-Object {
            . $_.FullName
        }
    }

    AfterAll {
        if (Test-Path -LiteralPath $script:MockWorkspace) {
            Remove-Item -LiteralPath $script:MockWorkspace -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }

    Context "Node Parser" {
        It "Should scan package.json files recursively and extract dependencies" {
            $SubFolder = Join-Path $script:MockWorkspace "node_proj"
            New-Item -Path $SubFolder -ItemType Directory -Force | Out-Null
            
            $PkgJsonContent = @{
                dependencies = @{
                    express = "^4.17.1"
                    lodash = "^4.17.21"
                }
                devDependencies = @{
                    jest = "^27.0.0"
                }
            } | ConvertTo-Json
            
            [System.IO.File]::WriteAllText((Join-Path $SubFolder "package.json"), $PkgJsonContent)
            
            $deps = Get-NodeDependencies -ResolvedWorkspace $script:MockWorkspace
            $deps -contains "express" | Should Be $true
            $deps -contains "lodash" | Should Be $true
            $deps -contains "jest" | Should Be $true
        }
    }

    Context "Python Parser" {
        It "Should parse requirements.txt and pyproject.toml including markers and VCS" {
            $SubFolder = Join-Path $script:MockWorkspace "py_proj"
            New-Item -Path $SubFolder -ItemType Directory -Force | Out-Null
            
            $ReqContent = @"
# This is a comment
requests>=2.25.1; python_version > '3.6'
git+https://github.com/psf/requests.git@main
django==3.2.5 # security fix
-r other-requirements.txt
"@
            [System.IO.File]::WriteAllText((Join-Path $SubFolder "requirements.txt"), $ReqContent)
            
            $PyProjContent = @"
[tool.poetry.dependencies]
python = "^3.8"
pytest = "^6.2.2"
numpy = { version = "^1.20" }
"@
            [System.IO.File]::WriteAllText((Join-Path $SubFolder "pyproject.toml"), $PyProjContent)
            
            $deps = Get-PythonDependencies -ResolvedWorkspace $script:MockWorkspace
            $deps -contains "requests" | Should Be $true
            $deps -contains "django" | Should Be $true
            $deps -contains "pytest" | Should Be $true
            $deps -contains "numpy" | Should Be $true
            $deps -contains "python" | Should Be $false
        }

        It "Should parse PEP 621 style dependencies in pyproject.toml" {
            $SubFolder = Join-Path $script:MockWorkspace "py_pep621_proj"
            New-Item -Path $SubFolder -ItemType Directory -Force | Out-Null
            
            $PyProjContent = @"
[project]
name = "pep621_proj"
version = "0.1.0"
dependencies = [
    "requests>=2.25.1",
    "pandas",
    "ruamel.yaml; python_version < '3.8'",
    'numpy>=1.20'
]
"@
            [System.IO.File]::WriteAllText((Join-Path $SubFolder "pyproject.toml"), $PyProjContent)
            
            $deps = Get-PythonDependencies -ResolvedWorkspace $script:MockWorkspace
            $deps -contains "requests" | Should Be $true
            $deps -contains "pandas" | Should Be $true
            $deps -contains "ruamel.yaml" | Should Be $true
            $deps -contains "numpy" | Should Be $true
        }
    }

    Context "Rust Parser" {
        It "Should parse Cargo.toml files table-style and target specific dependencies" {
            $SubFolder = Join-Path $script:MockWorkspace "rust_proj"
            New-Item -Path $SubFolder -ItemType Directory -Force | Out-Null
            
            $CargoContent = @"
[package]
name = "test_rust"
version = "0.1.0"

[dependencies]
serde = "1.0"
tokio = { version = "1.0", features = ["full"] }

[dependencies.rand]
version = "0.8"

[target.'cfg(unix)'.dependencies]
openssl = "0.10"
"@
            [System.IO.File]::WriteAllText((Join-Path $SubFolder "Cargo.toml"), $CargoContent)
            
            $deps = Get-RustDependencies -ResolvedWorkspace $script:MockWorkspace
            $deps -contains "serde" | Should Be $true
            $deps -contains "tokio" | Should Be $true
            $deps -contains "rand" | Should Be $true
            $deps -contains "openssl" | Should Be $true
            $deps -contains "version" | Should Be $false
            $deps -contains "features" | Should Be $false
        }
    }

    Context "Go Parser" {
        It "Should parse go.mod files recursively" {
            $SubFolder = Join-Path $script:MockWorkspace "go_proj"
            New-Item -Path $SubFolder -ItemType Directory -Force | Out-Null
            
            $GoContent = @"
module github.com/test/go_proj

go 1.16

require (
	github.com/gin-gonic/gin v1.7.2
	github.com/sirupsen/logrus v1.8.1
)

require github.com/stretchr/testify v1.7.0
"@
            [System.IO.File]::WriteAllText((Join-Path $SubFolder "go.mod"), $GoContent)
            
            $deps = Get-GoDependencies -ResolvedWorkspace $script:MockWorkspace
            $deps -contains "gin" | Should Be $true
            $deps -contains "logrus" | Should Be $true
            $deps -contains "testify" | Should Be $true
        }
    }

    Context "Java Parser" {
        It "Should parse pom.xml and gradle files recursively" {
            $SubFolder = Join-Path $script:MockWorkspace "java_proj"
            New-Item -Path $SubFolder -ItemType Directory -Force | Out-Null
            
            $PomContent = @"
<project>
    <groupId>com.test</groupId>
    <artifactId>test-app</artifactId>
    <dependencies>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-core</artifactId>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <artifactId>maven-compiler-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
"@
            [System.IO.File]::WriteAllText((Join-Path $SubFolder "pom.xml"), $PomContent)
            
            $GradleContent = @"
dependencies {
    implementation 'org.slf4j:slf4j-api:1.7.30'
    testImplementation "junit:junit"
}
"@
            [System.IO.File]::WriteAllText((Join-Path $SubFolder "build.gradle"), $GradleContent)
            
            $deps = Get-JavaDependencies -ResolvedWorkspace $script:MockWorkspace
            $deps -contains "spring-core" | Should Be $true
            $deps -contains "slf4j-api" | Should Be $true
            $deps -contains "junit" | Should Be $true
            $deps -contains "maven-compiler-plugin" | Should Be $false
            $deps -contains "test-app" | Should Be $false
        }
    }

    Context "DotNet Parser" {
        It "Should parse csproj files and extract PackageReference" {
            $SubFolder = Join-Path $script:MockWorkspace "dotnet_proj"
            New-Item -Path $SubFolder -ItemType Directory -Force | Out-Null
            
            $CsprojContent = @"
<Project Sdk="Microsoft.NET.Sdk">
  <ItemGroup>
    <PackageReference Include="Newtonsoft.Json" Version="13.0.1" />
    <PackageReference Include='Microsoft.Extensions.Logging' Version='5.0.0' />
    <PackageReference Version="3.1.0" Include="System.Text.Json" />
  </ItemGroup>
</Project>
"@
            [System.IO.File]::WriteAllText((Join-Path $SubFolder "dotnet_proj.csproj"), $CsprojContent)
            
            $deps = Get-DotNetDependencies -ResolvedWorkspace $script:MockWorkspace
            $deps -contains "Newtonsoft.Json" | Should Be $true
            $deps -contains "Microsoft.Extensions.Logging" | Should Be $true
            $deps -contains "System.Text.Json" | Should Be $true
        }
    }
}
