# Sovereign-OS V16 Phase 2 Deep Audit Plan

## Architecture & Scope
Sovereign-OS V16 is a modular local operating system with dynamic PowerShell discovery (`sovereign.ps1`), configuration validation (`sovereign.config.json`), Go CLI (`modules/sovereign-cli`), Next.js/Shadcn UI (`modules/sovereign-ui`), asset registry (`ASSET_REGISTRY.md`), audit ledger (`AUDIT_LEDGER.md`), and mistakes ledger (`MISTAKES_LEDGER.md`).

## Milestones

| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | R1: Sovereign-CLI Audit | Verify `modules/sovereign-cli/cmd/root.go` for Cobra, Viper, Zap usage & `go.mod` structure | None | DONE (Report: `.agents/explorer_m1/handoff.md`) |
| 2 | R2: Sovereign-UI Audit | Verify `modules/sovereign-ui/src/app/page.tsx` App Router, `components.json` Shadcn/Tailwind, `package.json` vs `ASSET_REGISTRY.md` | None | DONE (Report: `.agents/explorer_m2/handoff.md` - Defects Found) |
| 3 | R3: Core Integrity & Execution | Execute `sovereign.ps1`, verify dynamic skill/module discovery, Mutex lock acquisition, `sovereign.config.json` match | None | DONE (Report: `.agents/worker_m3/handoff.md`) |
| 4 | R4: Zero Ghost Assets Audit | Repo-wide audit for ghost assets (unregistered dependencies, unused code/modules, drift between codebase and `ASSET_REGISTRY.md` / `AUDIT_LEDGER.md`) | M1, M2, M3 | DONE (Report: `.agents/explorer_m4/handoff.md` - Defects Found) |
| 5 | Synthesis & Final Report | Synthesize all worker/reviewer findings, perform Forensic Audit, write final Phase 2 report, notify parent/sentinel | M1, M2, M3, M4 | DONE (Report: `.agents/auditor_final/handoff.md` - Final Verdict: CLEAN) |

## Interface Contracts & Invariants
- `sovereign.ps1` must dynamically discover skills and modules and match `sovereign.config.json`.
- `cmd/root.go` must import and use `github.com/spf13/cobra`, `github.com/spf13/viper`, and `go.uber.org/zap`.
- `modules/sovereign-ui` must be a valid Next.js App Router project with Shadcn/Tailwind configuration and dependencies registered in `ASSET_REGISTRY.md`.
- Zero ghost assets across the repository — all external assets/dependencies must be logged in `ASSET_REGISTRY.md` and `AUDIT_LEDGER.md`.

## Code Layout
- `sovereign.ps1`: Core PowerShell launcher and dynamic discovery script
- `sovereign.config.json`: Core system configuration file
- `modules/sovereign-cli`: Go CLI module (`cmd/root.go`, `go.mod`, etc.)
- `modules/sovereign-ui`: Next.js frontend module (`src/app/page.tsx`, `components.json`, `package.json`, etc.)
- `ASSET_REGISTRY.md`: Registry of external tools, dependencies, and packages
- `AUDIT_LEDGER.md`: Ledger of verified capabilities and system audits
- `MISTAKES_LEDGER.md`: Ledger of process failures and historical mistakes
