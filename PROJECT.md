# Project: Sovereign OS Infrastructure & Capabilities Upgrade

## Architecture
- **Language**: PowerShell (scripts and modules), JSON (configuration files), YAML, Dockerfile
- **Code Layout**:
  - Coordination/Metadata: `.agents/`
  - Source Scripts: `C:\Skills\`, `C:\Skills\agent-bootstrap\scripts\`
  - Test suites: `C:\Skills\agent-bootstrap\tests\`
  - GitHub Actions: `C:\Skills\.github\workflows\`
  - Containerization: `C:\Skills\Dockerfile`, `C:\Skills\docker-compose.yml`

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Milestone 1: E2E Test Suite | Design and build Tier 1-4 opaque-box test suite, publish TEST_INFRA.md and TEST_READY.md | None | IN_PROGRESS (061838fc-e5a2-46e7-af32-535ac3fae168, 5899f9f3-ee95-45fc-8baa-20bee1b07a25, e48e98a1-50c0-47fe-a840-9bf79994931b) |
| 2 | Milestone 2: Git & Testing Infra | Pre-commit hook repair + Pester unit tests for helpers.psm1 | M1 | PLANNED |
| 3 | Milestone 3: CI/CD & Container | GitHub Actions Workflow + optimized Dockerfile and compose | M1, M2 | PLANNED |
| 4 | Milestone 4: Config CLI & Telemetry | Add-SovereignSkill.ps1 + SQLite Token/Cost Telemetry Logger | M1, M2, M3 | PLANNED |
| 5 | Milestone 5: Security & Swarm | E2B omni_harvester configuration + Start-SovereignSwarm.ps1 | M1, M2, M3, M4 | PLANNED |
| 6 | Milestone 6: E2E Pass & Hardening | Final verification pass of E2E suite + Tier 5 Adversarial Hardening | M1, M2, M3, M4, M5 | PLANNED |

## Interface Contracts
- **Telemetry Logger**: Must export SQLite DB initialization and log operations, logging LLM tokens, execution durations, and cost.
- **Config Management**: CLI `Add-SovereignSkill -Repo <repo>` must add repository key to `sovereign.config.json`'s cloud cache, maintaining valid JSON schemas.
- **Multi-Agent Swarm**: `Start-SovereignSwarm.ps1` must coordinate multiple agents using LangGraph/CrewAI framework patterns.
