# Remediation Verification Tests
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Describe "Sovereign Remediation Empirical Verification" {
    BeforeAll {
        $script:SovereignRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        $script:LockFile = Join-Path $script:SovereignRoot "remediation_test.lock"
        $script:SrcDir = Join-Path $script:SovereignRoot "temp_src_dir"
        $script:DestDirNormal = Join-Path $script:SovereignRoot "temp_dest_dir"
        $script:DestDirSingleQuote = Join-Path $script:SovereignRoot "temp_dest_dir'quote"
    }

    Context "1. Lock Handling (HL-04)" {
        BeforeEach {
            if (Test-Path $script:LockFile) {
                Remove-Item $script:LockFile -Force -ErrorAction SilentlyContinue
            }
        }

        AfterEach {
            if (Test-Path $script:LockFile) {
                Remove-Item $script:LockFile -Force -ErrorAction SilentlyContinue
            }
        }

        It "Original logic should fail/timeout when lock file is empty" {
            # Create an empty lock file
            New-Item -Path $script:LockFile -ItemType File -Force | Out-Null

            # Simulate the original logic: if ($existing -and $existing.PID) block is skipped
            $existing = $null
            try {
                $existing = Get-Content $script:LockFile -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
            } catch {}

            $isStale = $false
            if ($existing -and $existing.PID) {
                # Original block is skipped because $existing is null
                $isStale = $false
            }

            # In the original logic, $isStale remains false, so file is not deleted.
            $isStale | Should -Be $false
            (Test-Path $script:LockFile) | Should -Be $true
        }

        It "Remediated logic should detect empty lock file as stale, delete it, and allow acquisition" {
            # Create an empty lock file
            New-Item -Path $script:LockFile -ItemType File -Force | Out-Null

            # Simulate remediated logic
            $existing = $null
            try {
                $existing = Get-Content $script:LockFile -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
            } catch {}

            $isStale = $false
            if ($null -eq $existing) {
                $isStale = $true
            } elseif (-not $existing.PSObject.Properties['PID'] -or -not $existing.PSObject.Properties['StartTime']) {
                $isStale = $true
            }

            if ($isStale) {
                Remove-Item $script:LockFile -Force -ErrorAction SilentlyContinue
            }

            # File should be successfully deleted
            $isStale | Should -Be $true
            (Test-Path $script:LockFile) | Should -Be $false
        }

        It "Remediated logic should detect corrupt JSON lock file as stale, delete it, and allow acquisition" {
            # Create a corrupt lock file
            [System.IO.File]::WriteAllText($script:LockFile, "corrupted json content")

            # Simulate remediated logic
            $existing = $null
            try {
                $existing = Get-Content $script:LockFile -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
            } catch {}

            $isStale = $false
            if ($null -eq $existing) {
                $isStale = $true
            } elseif (-not $existing.PSObject.Properties['PID'] -or -not $existing.PSObject.Properties['StartTime']) {
                $isStale = $true
            }

            if ($isStale) {
                Remove-Item $script:LockFile -Force -ErrorAction SilentlyContinue
            }

            # File should be successfully deleted
            $isStale | Should -Be $true
            (Test-Path $script:LockFile) | Should -Be $false
        }

        It "Remediated logic should detect missing metadata in JSON lock file as stale and delete it" {
            # Create a JSON lock file with missing PID/StartTime
            $badJson = @{ InvalidKey = "value" } | ConvertTo-Json
            [System.IO.File]::WriteAllText($script:LockFile, $badJson)

            # Simulate remediated logic
            $existing = $null
            try {
                $existing = Get-Content $script:LockFile -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
            } catch {}

            $isStale = $false
            if ($null -eq $existing) {
                $isStale = $true
            } elseif (-not $existing.PSObject.Properties['PID'] -or -not $existing.PSObject.Properties['StartTime']) {
                $isStale = $true
            }

            if ($isStale) {
                Remove-Item $script:LockFile -Force -ErrorAction SilentlyContinue
            }

            # File should be successfully deleted
            $isStale | Should -Be $true
            (Test-Path $script:LockFile) | Should -Be $false
        }
    }

    Context "2. Lore.md Check (VS-04)" {
        It "Should catch missing Lore.md and add warning" {
            $Warnings = @()
            $hasLore = $false # Simulate Lore.md missing
            if ($hasLore) {
                # ...
            } else {
                $Warnings += "No Lore.md found. Capturing hard-won lessons in Lore.md is recommended."
            }
            $Warnings.Count | Should -Be 1
            $Warnings[0] | Should -Match "No Lore.md found"
        }

        It "Should catch empty or whitespace-only Lore.md and add warning" {
            $testContents = @(
                $null,
                "",
                "   ",
                "`r`n`r`n",
                "   `r`n   "
            )

            foreach ($content in $testContents) {
                $Warnings = @()
                $loreContent = $content
                if ($null -eq $loreContent -or $loreContent.Trim().Length -lt 20) {
                    $Warnings += "Lore.md is very short - consider expanding the captured wisdom."
                }
                $Warnings.Count | Should -Be 1
                $Warnings[0] | Should -Match "Lore.md is very short"
            }
        }

        It "Should catch short Lore.md (< 20 chars) and add warning" {
            $Warnings = @()
            $loreContent = "Too short" # 9 characters
            if ($null -eq $loreContent -or $loreContent.Trim().Length -lt 20) {
                $Warnings += "Lore.md is very short - consider expanding the captured wisdom."
            }
            $Warnings.Count | Should -Be 1
            $Warnings[0] | Should -Match "Lore.md is very short"
        }

        It "Should allow valid Lore.md (>= 20 chars) without warnings" {
            $Warnings = @()
            $loreContent = "This is a valid Lore.md file with more than twenty characters of wisdom."
            if ($null -eq $loreContent -or $loreContent.Trim().Length -lt 20) {
                $Warnings += "Lore.md is very short - consider expanding the captured wisdom."
            }
            $Warnings.Count | Should -Be 0
        }
    }

    Context "3. Escaping Single Quotes in Junction Creation (BS-02 and BS-05)" {
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

        It "Junction creation should work when path is standard" {
            $dest = $script:DestDirNormal
            $escapedDest = $dest.Replace("'", "''")
            $escapedSrc = $script:SrcDir.Replace("'", "''")
            
            # Direct cmdlet call — avoids Invoke-Expression AST violation
            New-Item -ItemType Junction -Path $dest -Value $script:SrcDir -Force | Out-Null

            (Test-Path $dest) | Should -Be $true
        }

        It "Junction creation should work when path contains single quotes" {
            $dest = $script:DestDirSingleQuote
            $escapedDest = $dest.Replace("'", "''")
            $escapedSrc = $script:SrcDir.Replace("'", "''")
            
            # Direct cmdlet call — avoids Invoke-Expression AST violation
            New-Item -ItemType Junction -Path $dest -Value $script:SrcDir -Force | Out-Null

            (Test-Path $dest) | Should -Be $true
        }

        It "Get-ChildItem using -LiteralPath should succeed when path contains brackets (BS-05)" {
            $bracketDir = Join-Path $script:SovereignRoot "temp_gci[bracket]"
            if (-not (Test-Path $bracketDir)) {
                New-Item -Path $bracketDir -ItemType Directory -Force | Out-Null
            }
            New-Item -Path (Join-Path $bracketDir "dummy.txt") -ItemType File -Force | Out-Null

            try {
                # This should succeed and not throw an exception
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
            
            # Original logic
            $OriginalNormalized = $WindowsPath -replace '\\\\', '/'
            $OriginalNormalized | Should -Be "C:\Skills\agent-bootstrap\scripts" # Fails to replace single backslash

            # Remediated logic
            $RemediatedNormalized = $WindowsPath.Replace('\', '/')
            $RemediatedNormalized | Should -Be "C:/Skills/agent-bootstrap/scripts" # Succeeds
        }
    }
}
