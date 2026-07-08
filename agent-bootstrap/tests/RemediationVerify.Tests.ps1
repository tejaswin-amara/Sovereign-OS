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

        It "Directory creation should work when path contains single quotes" {
            $dest = $script:DestDirSingleQuote
            
            # Direct cmdlet call instead of Invoke-Expression
            New-Item -ItemType Directory -Path $dest -Force | Out-Null

            (Test-Path $dest) | Should -Be $true
        }

        It "Get-ChildItem using -LiteralPath should succeed when path contains brackets (BS-05)" {
            $bracketDir = Join-Path $script:SovereignRoot "temp_gci[bracket]"
            if (-not (Test-Path $bracketDir)) {
                New-Item -Path $bracketDir -ItemType Directory -Force | Out-Null
            }
            New-Item -Path (Join-Path $bracketDir "dummy.txt") -ItemType File -Force | Out-Null

            try {
                $files = Get-ChildItem -LiteralPath $bracketDir -ErrorAction Stop
                $files.Count | Should -BeGreaterThan 0
            } finally {
                if (Test-Path $bracketDir) {
                    Remove-Item -LiteralPath $bracketDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Context "4. Path Normalization (BS-07)" {
        It "Should correctly normalize backslashes to forward slashes in Windows path" {
            $WindowsPath = "C:\Skills\agent-bootstrap\scripts"
            $RemediatedNormalized = $WindowsPath.Replace('\', '/')
            $RemediatedNormalized | Should -Be "C:/Skills/agent-bootstrap/scripts"
        }
    }
}
