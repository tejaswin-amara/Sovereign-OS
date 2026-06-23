# Helpers.Tests.ps1 - Sovereign Helpers Unit Test Suite
# Designed for Pester 5
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Describe "Sovereign Helpers Unit Tests" {
    BeforeAll {
        $script:SovereignRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        Import-Module "$script:SovereignRoot/agent-bootstrap/scripts/helpers.psm1" -Force
        
        # Setup a temporary workspace directory for file I/O tests
        $script:TestWorkspace = Join-Path $PSScriptRoot "helpers_test_workspace"
        if (Test-Path $script:TestWorkspace) {
            Remove-Item $script:TestWorkspace -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        }
        New-Item -Path $script:TestWorkspace -ItemType Directory -Force | Out-Null
    }

    AfterAll {
        # Cleanup temporary workspace
        if (Test-Path $script:TestWorkspace) {
            Remove-Item $script:TestWorkspace -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }

    Context "Validation Helper (Validation.ps1)" {
        It "Should return true when string matches pattern" {
            Assert-SovereignPattern -InputString "v14.0.0-CloudNative" -Pattern '^v\d+\.\d+\.\d+' | Should -Be $true
        }

        It "Should -Throw PATTERN_MISMATCH when string does not match pattern" {
            { Assert-SovereignPattern -InputString "invalid-version" -Pattern '^v\d+\.\d+\.\d+' } | Should -Throw "*PATTERN_MISMATCH*"
        }
    }

    Context "IO Helper (IO.ps1)" {
        BeforeEach {
            $script:SourceFile = Join-Path $script:TestWorkspace "source.txt"
            $script:DestFile = Join-Path $script:TestWorkspace "destination.txt"
            [System.IO.File]::WriteAllText($script:SourceFile, "Source Content")
            if (Test-Path $script:DestFile) { Remove-Item $script:DestFile -Force }
        }

        It "Should successfully move source to destination when destination does not exist" {
            Invoke-AtomicMove -Source $script:SourceFile -Destination $script:DestFile
            (Test-Path $script:SourceFile) | Should -Be $false
            (Test-Path $script:DestFile) | Should -Be $true
            (Get-Content $script:DestFile) | Should -Be "Source Content"
        }

        It "Should overwrite destination and clean backup when destination exists" {
            [System.IO.File]::WriteAllText($script:DestFile, "Old Content")
            Invoke-AtomicMove -Source $script:SourceFile -Destination $script:DestFile
            (Test-Path $script:SourceFile) | Should -Be $false
            (Test-Path $script:DestFile) | Should -Be $true
            (Test-Path "$script:DestFile.bak") | Should -Be $false
            (Get-Content $script:DestFile) | Should -Be "Source Content"
        }

        It "Should restore backup and throw error if move operation fails" {
            [System.IO.File]::WriteAllText($script:DestFile, "Old Content")
            # We mock Move-Item inside the 'helpers' module context.
            Mock Move-Item { throw "Simulated Move Error" } -ModuleName helpers -ParameterFilter { $Path -eq $script:SourceFile }
            
            { Invoke-AtomicMove -Source $script:SourceFile -Destination $script:DestFile } | Should -Throw "*ATOMIC_MOVE_FAIL*"
            
            # Destination should still contain original "Old Content"
            (Test-Path $script:DestFile) | Should -Be $true
            (Get-Content $script:DestFile) | Should -Be "Old Content"
        }
    }

    Context "Configuration Helper (Configuration.ps1)" {
        BeforeEach {
            $script:MockConfigPath = Join-Path $script:TestWorkspace "sovereign.config.json"
            $script:MockHashPath = Join-Path $script:TestWorkspace ".config.sha256"
            
            if (Test-Path $script:MockConfigPath) { Remove-Item $script:MockConfigPath -Force }
            if (Test-Path $script:MockHashPath) { Remove-Item $script:MockHashPath -Force }
        }

        It "Should save content atomically" {
            $Content = "{ `"test`": 123 }"
            Save-AtomicContent -Path $script:MockConfigPath -Content $Content
            (Test-Path $script:MockConfigPath) | Should -Be $true
            (Get-Content $script:MockConfigPath) | Should -Be $Content
        }

        It "Should resolve dotted key paths correctly in config" {
            $ConfigData = @{
                governance = @{
                    module_cap = 32
                    skills_count = 10
                }
                version = "14.0.0"
            } | ConvertTo-Json
            [System.IO.File]::WriteAllText($script:MockConfigPath, $ConfigData)
            
            { Assert-SovereignConfigIntegrity -ConfigPath $script:MockConfigPath -HashPath $script:MockHashPath } | Should -Not -Be -Throw
            (Test-Path $script:MockHashPath) | Should -Be $true
        }

        It "Should -Throw CONFIG_INTEGRITY_VIOLATION when config does not match hash" {
            $ConfigData1 = "{ `"version`": `"1.0.0`" }"
            $ConfigData2 = "{ `"version`": `"2.0.0`" }"
            
            # Initial seal
            [System.IO.File]::WriteAllText($script:MockConfigPath, $ConfigData1)
            Update-SovereignChecksum -ConfigPath $script:MockConfigPath -HashPath $script:MockHashPath | Out-Null
            
            # Tamper the config
            [System.IO.File]::WriteAllText($script:MockConfigPath, $ConfigData2)
            
            { Assert-SovereignConfigIntegrity -ConfigPath $script:MockConfigPath -HashPath $script:MockHashPath } | Should -Throw "*CONFIG_INTEGRITY_VIOLATION*"
        }
    }

    Context "Logging Helper (Logging.ps1)" {
        BeforeEach {
            $script:LogDir = Join-Path $script:TestWorkspace "LOGS"
            if (Test-Path $script:LogDir) { Remove-Item $script:LogDir -Recurse -Force }
            
            # Reset the global batch queue
            $global:SovereignLogBatch.Clear()
        }

        It "Should sanitize sensitive paths in log messages" {
            Set-SovereignLogContext -LogDir $script:LogDir -RunId "TEST-RUN" -CorrId "TEST-CORR"
            
            $TestMessage = "Error occurred in C:/Skills/some-file.ps1 for user home C:/Users/Home and drive D:\Temp"
            
            Write-SovereignLog -Level "INFO" -Step "TEST_SAN" -Message $TestMessage
            
            # Force flush
            & (Get-Module helpers) { Flush-SovereignLogs }
            
            $LogFile = Join-Path $script:LogDir "sovereign-audit.jsonl"
            (Test-Path $LogFile) | Should -Be $true
            
            $LoggedEntry = Get-Content $LogFile | ConvertFrom-Json
            $LoggedEntry.message | Should -Not -Be -Match "C:/Skills"
            $LoggedEntry.message | Should -Not -Be -Match "C:/Users/Home"
            $LoggedEntry.message | Should -Not -Be -Match "D:\\Temp"
            $LoggedEntry.message | Should -Match "<SkillsRoot>"
            $LoggedEntry.message | Should -Match "<UserHome>"
            $LoggedEntry.message | Should -Match "<DrivePath>"
        }

        It "Should queue logs in memory and flush when threshold is reached" {
            Set-SovereignLogContext -LogDir $script:LogDir -RunId "TEST-RUN" -CorrId "TEST-CORR"
            
            $global:SovereignLogFlushThreshold = 5
            $LogFile = Join-Path $script:LogDir "sovereign-audit.jsonl"
            
            for ($i = 1; $i -le 4; $i++) {
                Write-SovereignLog -Level "INFO" -Step "BATCH" -Message "Log #$i"
            }
            # Threshold not reached yet, so log file shouldn't exist
            (Test-Path $LogFile) | Should -Be $false
            
            # Write the 5th log to trigger flush
            Write-SovereignLog -Level "INFO" -Step "BATCH" -Message "Log #5"
            (Test-Path $LogFile) | Should -Be $true
            
            $Lines = Get-Content $LogFile
            $Lines.Count | Should -Be 5
        }

        It "Should rotate logs when max size limit is exceeded" {
            # Setup Log directory with a large mock audit file
            New-Item -ItemType Directory -Path $script:LogDir -Force | Out-Null
            $AuditFile = Join-Path $script:LogDir "sovereign-audit.jsonl"
            
            # Create a 2MB file
            $LargeContent = "A" * (2 * 1024 * 1024)
            [System.IO.File]::WriteAllText($AuditFile, $LargeContent)
            
            # Run rotation with max size set to 1MB
            Start-LogRotation -LogDir $script:LogDir -MaxAgeDays 7 -MaxSizeBytes (1 * 1024 * 1024)
            
            # The original audit log Should -Be rotated to sovereign-audit.1.jsonl
            (Test-Path $AuditFile) | Should -Be $false
            (Test-Path (Join-Path $script:LogDir "sovereign-audit.1.jsonl")) | Should -Be $true
        }
    }

    Context "Locking Helper (Locking.ps1)" {
        It "Should acquire and release a system mutex" {
            $LockFile = Join-Path $script:TestWorkspace "mutex.lock"
            
            $Mutex = Start-SovereignLock -LockFile $LockFile -TimeoutSeconds 2
            $Mutex | Should -Not -BeNullOrEmpty
            $Mutex.GetType().Name | Should -Be "Mutex"
            
            # Release mutex
            Stop-SovereignLock -LockFile $LockFile -Mutex $Mutex
            (Test-Path $LockFile) | Should -Be $false
        }

        It "Should timeout if lock is already held" {
            $LockFile = Join-Path $script:TestWorkspace "mutex.lock"
            
            # Start a background job to hold the lock
            $Job = Start-Job -ArgumentList $script:SovereignRoot, $LockFile -ScriptBlock {
                param($root, $lf)
                Import-Module "$root/agent-bootstrap/scripts/helpers.psm1" -Force
                $Mutex = Start-SovereignLock -LockFile $lf -TimeoutSeconds 2
                Start-Sleep -Seconds 3
                Stop-SovereignLock -LockFile $lf -Mutex $Mutex
            }
            
            # Wait for the job to start and acquire the lock
            Start-Sleep -Milliseconds 800
            
            try {
                # Attempting to acquire lock should timeout and throw
                { Start-SovereignLock -LockFile $LockFile -TimeoutSeconds 1 } | Should -Throw -ExceptionType "*LOCK_TIMEOUT*"
            } finally {
                # Cleanup job
                Stop-Job $Job
                Remove-Job $Job
            }
        }
    }

    Context "Modularity Helper (Modularity.ps1)" {
        BeforeEach {
            $script:MockAgentDir = Join-Path $script:TestWorkspace "mock_agent"
            if (Test-Path $script:MockAgentDir) { Remove-Item $script:MockAgentDir -Recurse -Force }
            
            $script:RulesDir = Join-Path $script:MockAgentDir "rules"
            $script:WorkflowsDir = Join-Path $script:MockAgentDir "workflows"
            New-Item -ItemType Directory -Path $script:RulesDir -Force | Out-Null
            New-Item -ItemType Directory -Path $script:WorkflowsDir -Force | Out-Null
        }

        It "Should assert module count passes when under cap" {
            [System.IO.File]::WriteAllText((Join-Path $script:RulesDir "rule1.md"), "Rule 1")
            [System.IO.File]::WriteAllText((Join-Path $script:WorkflowsDir "wf1.md"), "Workflow 1")
            
            $Result = Assert-ModuleCap -AgentDir $script:MockAgentDir -Cap 5
            $Result.Total | Should -Be 2
            $Result.Rules | Should -Be 1
            $Result.Workflows | Should -Be 1
        }

        It "Should -Throw MODULE_CAP_EXCEEDED when over cap" {
            [System.IO.File]::WriteAllText((Join-Path $script:RulesDir "rule1.md"), "Rule 1")
            [System.IO.File]::WriteAllText((Join-Path $script:RulesDir "rule2.md"), "Rule 2")
            [System.IO.File]::WriteAllText((Join-Path $script:WorkflowsDir "wf1.md"), "Workflow 1")
            
            { Assert-ModuleCap -AgentDir $script:MockAgentDir -Cap 2 } | Should -Throw "*MODULE_CAP_EXCEEDED*"
        }

        It "Should return list of files recursively matching filter and ignoring exclusions" {
            $SubFolder = Join-Path $script:MockAgentDir "sub"
            New-Item -ItemType Directory -Path $SubFolder -Force | Out-Null
            
            [System.IO.File]::WriteAllText((Join-Path $script:MockAgentDir "file1.txt"), "A")
            [System.IO.File]::WriteAllText((Join-Path $SubFolder "file2.txt"), "B")
            [System.IO.File]::WriteAllText((Join-Path $script:MockAgentDir "file3.log"), "C")
            
            $Files = @(Get-SovereignManifestFiles -Path $script:MockAgentDir -Filter "*.txt" -Exclusions @("sub"))
            $Files.Count | Should -Be 1
            $Files[0] | Should -Match "file1.txt"
        }
    }
}


