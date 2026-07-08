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
| 3 | Milestone 3: Code Size & Technical Debt Refactoring | Refactor files > 300 lines (self-evolve.ps1, run_harvester_tests.ps1), clean up dead code, de-duplicate DPAPI, and add cross-platform fallback. | M2 | DONE |
| 4 | Milestone 4: Architectural Consolidation & Honesty Verification | Remove mock features (eBPF, ZK-SNARKs, Algorand ledgers) and ensure all described features are fully working. | M3 | DONE |
| 5 | Milestone 5: Exhaustive Unit Test Coverage | Write exhaustive Pester unit tests targeting every internal function in helpers to achieve 100% coverage. | M4 | DONE |
| 6 | Milestone 6: ScriptAnalyzer Zero Warnings/Errors | Resolve all warnings/errors from Invoke-ScriptAnalyzer repository-wide. | M5 | PLANNED |

## Interface Contracts
- **Config CLI**: `Add-SovereignSkill.ps1` must safely append mappings to `sovereign.config.json` with `-PackageName` being optional.
- **Locking Helper**: `Locking.ps1` must provide robust mutex locks using modern .NET FileStream.
- **Checksum / Config**: Checksum calculation and DPAPI sealing must be centralized in `Checksum.ps1` and used by `Configuration.ps1`.
