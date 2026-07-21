# Sovereign-OS V16 Master Test & Audit Plan

## Overview
This plan defines the step-by-step verification and forensic audit strategy for Sovereign-OS V16, adhering strictly to Project Pattern, Ponytail Doctrine, and `no-mistakes` invariants.

## Milestone Breakdown

### Milestone 1: Core Controller Verification (R1)
- **Objective**: Verify `sovereign.ps1` execution, mutex lock behavior, `sovereign.config.json` parsing, path resolution, and dynamic module counts.
- **Execution Plan**:
  1. Dispatch Explorer `explorer_m1` to analyze `sovereign.ps1`, `sovereign.config.json`, and related scripts/mutex logic.
  2. Dispatch Challenger `challenger_m1` to execute `sovereign.ps1` in PowerShell, capture output/exit codes, test mutex behavior (concurrent run attempt), and verify dynamic module discovery.
  3. Dispatch Reviewer `reviewer_m1` to verify script output against requirements.

### Milestone 2: `no-mistakes` Invariant Testing (R2)
- **Objective**: Navigate to `modules/no-mistakes`, verify adherence to `AGENTS.md` engineering rules, attempt build/test sequence (`make lint`, `go test -race ./...`, `go build`), or document environment limitations and perform manual structural/architectural audit.
- **Execution Plan**:
  1. Dispatch Explorer `explorer_m2` to inspect `modules/no-mistakes` source tree, `AGENTS.md`, `Makefile`, `internal/skill/skill.go`, `SKILL.md`, and configuration.
  2. Dispatch Challenger `challenger_m2` to execute `make lint`, `go test -race ./...`, `go build -o ./bin/no-mistakes ./cmd/no-mistakes` (or test availability of `go`, `make`, `gcc`), and record exact command outputs.
  3. Dispatch Reviewer `reviewer_m2` to audit codebase architecture, skill sync, config security boundaries, and command results.

### Milestone 3: Ponytail Doctrine & Security Audit (R3)
- **Objective**: Audit `C:\Skills` for bloat/unnecessary dependencies, ghost code, committed API keys/secrets, and verify external assets documented in `ASSET_REGISTRY.md`.
- **Execution Plan**:
  1. Dispatch Explorer `explorer_m3` to scan `C:\Skills` for secret patterns (API keys, tokens), unused/dead files, asset registry compliance, and past mistake patterns in `MISTAKES_LEDGER.md`.
  2. Dispatch Challenger `challenger_m3` to run security/bloat audit scripts/checks across the repository.
  3. Dispatch Reviewer `reviewer_m3` to verify Ponytail Doctrine adherence.

### Milestone 4: Forensic Audit & Sentinel Synthesis (M4)
- **Objective**: Dispatch Forensic Auditor `teamwork_preview_auditor` for integrity verification, aggregate all reports into a unified assessment, update `AUDIT_LEDGER.md` / `progress.md`, and present final results to Sentinel parent agent.

## Schedule & Coordination
- Concurrent subagent dispatches for M1, M2, M3 exploration and execution.
- Heartbeat cron active every 10 minutes.
- Strict liveness check & timer bounds.
