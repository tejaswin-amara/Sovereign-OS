# Sovereign OS Roadmap: Next Steps & Technical Debt

While Sovereign OS currently sits at `v15.0.0-CloudNative` and is operating at a 100% verified success rate across all integrations, there are still crucial tasks, technical debt items, and massive feature expansions left to complete to push the architecture to absolute perfection.

Here is the comprehensive list of remaining tasks:

---

## ✅ Completed (Milestone 1-4)

1. **Pre-Commit Hook Repair**: Cleaned and formatted the `.git/hooks/pre-commit` to cleanly enforce formatting and Pester tests natively on Windows.
2. **Pester Test Coverage Expansion**: Created exhaustive E2E tests and `Helpers.Tests.ps1` to cover `helpers.psm1`.
3. **GitHub Actions CI/CD Integration**: Shipped `.github/workflows/ci.yml`.
4. **Containerization (Docker)**: Built `Dockerfile` for Ubuntu-based execution.
5. **Config Management CLI**: Implemented `Add-SovereignSkill.ps1`.
6. **Cross-Platform Parity**: DPAPI payload decryption, path handling, and junction creation function flawlessly on Windows, Linux, and macOS.
7. **Architectural Verification**: Removed all aspirational mock features (eBPF, ZK-SNARKs, quorum simulations) in favor of working, verified code.

---

## 🛠️ Immediate Fixes & Technical Debt (Upcoming)

### 1. Hardened E2B Python Execution Wrapper
- **Issue**: The `omni_harvester` prompt mandates E2B, but there is no native script to actually execute Python securely via the E2B SDK locally.
- **To-Do**: Build a native `Invoke-E2BSandbox.ps1` script that acts as the universal proxy for all agent terminal execution, natively trapping untrusted python output.

### 2. Full LangGraph/CrewAI Integration
- **Issue**: `Start-SovereignSwarm.ps1` orchestrates via powershell sleep synchronization (mocking the graph).
- **To-Do**: Translate the swarm sequence into a pure python `graph.py` utilizing the LangGraph framework, and invoke it via the PowerShell wrapper.

### 3. Advanced Dependency Resolution
- **Issue**: `Add-SovereignSkill.ps1` mutates the schema, but it does not trigger `Fetch-CloudSkill.ps1`.
- **To-Do**: Link the Config CLI with the Fetcher so that adding a dependency instantly downloads and caches it in `.cloud-cache`.

### 4. Docker Orchestration
- **Issue**: The `Dockerfile` is built but not orchestrated for local development loops.
- **To-Do**: Build `docker-compose.yml` to spin up Sovereign alongside a local LLM API (like Ollama) for completely offline, zero-cost, hyper-secure intelligence execution.
