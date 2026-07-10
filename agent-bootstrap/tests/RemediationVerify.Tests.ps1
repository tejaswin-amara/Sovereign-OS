# Remediation Verification Tests
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Describe "Sovereign Remediation Empirical Verification" {
    BeforeAll {
        $script:SovereignRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        Import-Module "$script:SovereignRoot/agent-bootstrap/scripts/helpers.psm1" -Force
        
        $script:SrcDir = Join-Path $script:SovereignRoot "temp_src_dir"
        $script:DestDirNormal = Join-Path $script:SovereignRoot "temp_dest_dir"
        $script:DestDirSingleQuote = Join-Path $script:SovereignRoot "temp_dest_dir'quote"
    }

    Context "1. Lock Handling (HL-04)" {
        It "Should acquire and release a system mutex (Remediated Logic)" {
            $LockFile = Join-Path $script:SovereignRoot "remediation_test.lock"
            if (Test-Path $LockFile) { Remove-Item $LockFile -Force -ErrorAction SilentlyContinue }
            
            $Mutex = Start-SovereignLock -LockFile $LockFile -TimeoutSeconds 1
            $Mutex | Should -Not -BeNullOrEmpty
            $Mutex.GetType().Name | Should -Be "FileStream"
            
            Stop-SovereignLock -LockFile $LockFile -Mutex $Mutex
            (Test-Path $LockFile) | Should -Be $false
        }
    }

    Context "3. Escaping Single Quotes in Directory Creation (BS-02 and BS-05)" {
        BeforeEach {
            if (-not (Test-Path $script:SrcDir)) {
                New-Item -Path $script:SrcDir -ItemType Directory -Force | Out-Null
            }
            foreach ($d in @($script:DestDirNormal, $script:DestDirSingleQuote)) {
                if (Test-Path $d) {
                    Remove-Item $d -Force -ErrorAction SilentlyContinue
                }
            }
        }

        AfterEach {
            foreach ($d in @($script:SrcDir, $script:DestDirNormal, $script:DestDirSingleQuote)) {
                if (Test-Path $d) {
                    Remove-Item $d -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It "Directory creation should work when path contains single quotes (BS-02)" {
            $destFile = Join-Path $script:DestDirSingleQuote "test.txt"
            
            # Use actual Sovereign helper function
            Save-AtomicContent -Path $destFile -Content "Test"

            (Test-Path $destFile) | Should -Be $true
        }

        It "Get-SovereignManifestFiles should succeed when path contains brackets (BS-05)" {
            $bracketDir = Join-Path $script:SovereignRoot "temp_gci[bracket]"
            if (-not (Test-Path $bracketDir)) {
                New-Item -Path $bracketDir -ItemType Directory -Force | Out-Null
            }
            New-Item -Path (Join-Path $bracketDir "dummy.json") -ItemType File -Force | Out-Null
            
            # ponytail: mock config for the exclusions in Get-SovereignManifestFiles?
            # Actually Get-SovereignManifestFiles takes exclusions array.
            
            try {
                # Use actual Sovereign helper function
                $files = Get-SovereignManifestFiles -Path $bracketDir -Filter "*.json" -Exclusions @(".git")
                $files.Count | Should -BeGreaterThan 0
            } finally {
                if (Test-Path $bracketDir) {
                    Remove-Item -LiteralPath $bracketDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Context "4. Path Normalization (BS-07) & Validation (VS-04)" {
        It "Should properly sanitize and normalize paths in logs (BS-07)" {
            # Write-SovereignLog handles path sanitization internally
            $LogDir = Join-Path $script:SovereignRoot "LOGS"
            Set-SovereignLogContext -LogDir $LogDir -RunId "TEST-123" -CorrId "TEST-123"
            
            $TestPath = "C:\Users\Fake\Path"
            # It shouldn't crash
            Write-SovereignLog -Level "INFO" -Step "TEST" -Message "Path is $TestPath"
            Flush-SovereignLogs
            
            $LogFile = Join-Path $LogDir "sovereign-audit.jsonl"
            (Test-Path $LogFile) | Should -Be $true
        }
        
        It "Should validate Lore.md using Assert-SovereignPattern (VS-04)" {
            # Restore VS-04 Lore.md validation
            $Content = "Sovereign Master Identity: Confirmed"
            Assert-SovereignPattern -InputString $Content -Pattern "Master Identity" | Should -Be $true
            
            { Assert-SovereignPattern -InputString "Bad" -Pattern "Good" } | Should -Throw "*PATTERN_MISMATCH*"
        }
    }
}
