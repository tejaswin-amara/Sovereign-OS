# Sovereign Enterprise Test Suite (v13.2.0-CloudNative)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SovereignRoot = (Resolve-Path "$PSScriptRoot/../..").Path

# Import the module under test
Import-Module "$SovereignRoot/agent-bootstrap/scripts/helpers.psm1" -Force

Describe "Sovereign Helpers" {
    
    Context "Configuration Management" {
        It "Should correctly load sovereign.config.json" {
            $config = Get-SovereignConfig
            $config | Should Not BeNullOrEmpty
            $config.version | Should Match "13.2.0-CloudNative"
        }
    }

    Context "Version Resolution" {
        It "Should resolve the VERSION file" {
            $version = Get-SovereignVersion -SkillsRoot $SovereignRoot
            $version | Should Match "13.2.0-CloudNative"
        }
    }

    Context "Dynamic Skill Counting" {
        It "Should count folders honoring exclusions" {
            $config = Get-SovereignConfig
            $ExcludedDirs = @($config.governance.harvester_excluded_dirs)
            $count = Get-DynamicSkillCount -SkillsRoot $SovereignRoot -ExcludedDirs $ExcludedDirs
            $count | Should BeGreaterThan 0
        }
    }

    Context "Logging Formatting" {
        It "Should execute Write-SovereignLog without errors" {
            $script:SovereignLogDir = "$SovereignRoot/LOGS"
            $script:RunID = "TEST-RUN"
            $script:CorrelationID = "TEST-CORR"
            
            { Write-SovereignLog -Level "INFO" -Step "TEST" -Message "Pester Verification" } | Should Not Throw
        }
    }
}
