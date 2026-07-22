# Plan: Phase 3 Exhaustive Deep Audit and Remediation

## Objectives
Execute Phase 3 deep audit covering R1 (No-Mistakes invariants), R2 (Global documentation & ledger sync), and R3 (Cross-module architecture, secret scans, sovereign.ps1 lock & execution).

## Milestones & Action Steps

### Milestone 1: No-Mistakes Invariant Audit (R1)
- Dispatch `teamwork_preview_explorer` to inspect `modules/no-mistakes` against `AGENTS.md` invariants:
  1. Daemon lock implementation in `internal/daemon/lock.go` (exclusive lock on `<NM_HOME>/daemon.lock`).
  2. Post-receive hook path resolution in `internal/git/hook.go` (absolute gate path resolution).
  3. Repo Config Trust Boundary in `internal/daemon/manager.go` (trusted default branch, pinned SHA).
  4. Process tree reapers (`shellenv.ConfigureShellCommand`, `winproc.Harden`).
  5. Static analysis check (formatting, lint rules, go vet equivalents).

### Milestone 2: Global Documentation & Ledger Sync Audit (R2)
- Dispatch `teamwork_preview_explorer` to inspect `README.md`, `AUDIT_LEDGER.md`, `MISTAKES_LEDGER.md`, and `ASSET_REGISTRY.md`:
  1. Check for broken links, ghost axioms, phantom features.
  2. Verify Ponytail Doctrine enforcement (no bloat, zero unearned complexity, every line provides verifiable utility).

### Milestone 3: Cross-Module Architectural & Secret Leak Audit (R3)
- Dispatch `teamwork_preview_explorer` to inspect:
  1. `sovereign.config.json` vs `modules/` and `skills/` directories.
  2. Purpose alignment for `sovereign-cli`, `sovereign-ui`, and `codebase-memory-mcp`.
  3. Secret/token leak scan across all files, directories, and git commits.
  4. Empirical execution check for `sovereign.ps1`.

### Milestone 4: Remediation Execution
- Dispatch `teamwork_preview_worker` to remediate any defects identified across M1, M2, M3.

### Milestone 5: Independent Verification & Forensic Audit
- Dispatch Reviewers (`teamwork_preview_reviewer`) to verify changes.
- Dispatch Challengers (`teamwork_preview_challenger`) to stress test `sovereign.ps1` and modules.
- Dispatch Forensic Auditor (`teamwork_preview_auditor`) for final integrity verification and CLEAN verdict.
