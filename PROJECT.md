# Project: Sovereign OS Codebase Optimization and Refactoring

## Architecture
- Language: PowerShell (scripts and modules), JSON (configuration files)
- Code Layout:
  - Coordination/Metadata: `.agents/`
  - Source Scripts: `C:\Skills\`, `C:\Skills\agent-bootstrap\scripts\`
  - Test suites: `C:\Skills\agent-bootstrap\tests\`

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Milestone 1: Pester 5 Alignment & CLI Hang Resolution | Make tests run under Pester 5, resolve Add-SovereignSkill.ps1 mandatory parameter hang, and fix tests. | None | DONE |
| 2 | Milestone 2: Strict Standards & UTF-8 BOM | Apply Set-StrictMode -Version Latest, convert files to UTF-8 with BOM to fix encoding errors. | M1 | DONE |
| 3 | Milestone 3: Code Size & Technical Debt Refactoring | Refactor files > 300 lines (self-evolve.ps1, run_harvester_tests.ps1), clean up dead code, de-duplicate DPAPI, and add curl fallback. | M2 | IN_PROGRESS (8bbe6d9d-d21d-458f-8486-a1d5a48e9f69) |
| 4 | Milestone 4: Exhaustive Unit Test Coverage | Write exhaustive Pester unit tests targeting every internal function in helpers to achieve 100% coverage. | M3 | PLANNED |
| 5 | Milestone 5: ScriptAnalyzer Zero Warnings/Errors | Resolve all warnings/errors from Invoke-ScriptAnalyzer repository-wide. | M4 | PLANNED |
| 6 | Milestone 6: Final Verification & Integrity Audit | Run full test suite, verify clean ScriptAnalyzer and Forensic Auditor runs. | M5 | PLANNED |

## Interface Contracts
- **Config CLI**: `Add-SovereignSkill.ps1` must safely append mappings to `sovereign.config.json` with `-PackageName` being optional.
- **Locking Helper**: `Locking.ps1` must provide robust mutex locks without legacy Stream code.
- **Checksum / Config**: Checksum calculation and DPAPI sealing must be centralized in `Checksum.ps1` and used by `Configuration.ps1`.
