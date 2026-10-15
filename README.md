# ⚡ Sovereign-OS V18 — Rulebook Agent Governance Architecture

![Sovereign OS Banner](https://img.shields.io/badge/Sovereign--OS-V18%20Rulebook-8B5CF6?style=for-the-badge&logo=powershell&logoColor=white)
![Build Status](https://img.shields.io/badge/Mutex_Lock-Acquired-10B981?style=for-the-badge&logo=go&logoColor=white)
![Commands](https://img.shields.io/badge/Commands-16%20Slash%20%2B%2011%20At-06B6D4?style=for-the-badge)
![Doctrine](https://img.shields.io/badge/Doctrine-Ponytail%20Minimalism-06B6D4?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-F59E0B?style=for-the-badge)

> **Sovereign-OS** is a hyper-minimalist meta-framework engineered for governing autonomous AI coding agents with full autonomy. Operating on the **Ponytail Doctrine**, it delivers a comprehensive **Rulebook** with `/` and `@` command systems, OS mutex locking, dynamic asset discovery, and agent autonomy protocols.

---

## 🌐 Documentation & Web Portal

Visit the redesigned GitHub Pages documentation portal:
👉 **[Sovereign-OS Interactive Documentation Hub](https://tejaswin-amara.github.io/Sovereign-OS/docs/index.html)**

### Documentation Navigation
- 🏛️ **[System Architecture](docs/architecture.md)** — OS Mutex locking, topology & state synchronization.
- 📦 **[Submodules Reference](docs/modules.md)** — Specifications for all 7 decoupled submodules.
- ✂️ **[Agent Skills Guide](docs/skills.md)** — Deep dive into `ponytail` minimalism and `agent-reach` research.
- 📐 **[Types Reference](docs/types.md)** — Type definitions across TypeScript, Go, and JSON schemas.
- 💻 **[CLI Reference](docs/cli.md)** — PowerShell orchestrator & CLI command parameters.
- 🔒 **[Security Policy](docs/security.md)** — Zero-trust secret scanner & credential redaction rules.

---

## 🏛️ System Architecture

```mermaid
graph TD
    A[Sovereign Core - c:\Skills] --> B(sovereign.ps1 Orchestrator)
    A --> C(sovereign.config.json)
    
    B --> MTx[OS Mutex: Global\SovereignOSLock]
    
    subgraph Submodules [7 Git Submodules]
        D1(sovereign-cli - Go Cobra)
        D2(sovereign-ui - Next.js App Router)
        D3(no-mistakes - Pipeline Engine)
        D4(codebase-memory-mcp - Knowledge Graph)
        D5(sovereign-security - Secret Scanner)
        D6(sovereign-memory - Key-Value Ledger)
        D7(sovereign-adapt - Policy Engine)
    end
    
    subgraph Skills [2 Standing Skills]
        S1(ponytail - Philosophy)
        S2(agent-reach - Research)
    end

    B --> Submodules
    B --> Skills
```

---

## 📦 Submodules Matrix

| Submodule | Category | Stack | Purpose |
| :--- | :--- | :--- | :--- |
| **[`sovereign-cli`](modules/sovereign-cli)** | CLI | Go (Cobra / Viper / Zap) | Command-line control & system state querying |
| **[`sovereign-ui`](modules/sovereign-ui)** | Frontend | Next.js 14 / TypeScript / Tailwind | Real-time web telemetry & agent status dashboard |
| **[`no-mistakes`](modules/no-mistakes)** | Pipeline | Go | Automated git safety, PR routing & verification gates |
| **[`codebase-memory-mcp`](modules/codebase-memory-mcp)** | Knowledge Graph | C / Node.js MCP | Semantic code search, Cypher graph & path tracing |
| **[`sovereign-security`](modules/sovereign-security)** | Security | Go | Zero-trust secret scanner & static security audit |
| **[`sovereign-memory`](modules/sovereign-memory)** | State | Go | Key-value memory ledger & persistent execution store |
| **[`sovereign-adapt`](modules/sovereign-adapt)** | Policy | Go | Strategy tuning & auto-remediation policy engine |

---

## 🚀 Quickstart

```powershell
# Run full orchestration
sovereign run

# System commands
sovereign audit       # Full diagnostic
sovereign status      # Module/skill health table
sovereign summary     # One-line system state
sovereign logs 10     # Last 10 log lines
sovereign config      # Display config
sovereign help        # List all commands
```

### Agent Commands (in chat)
```
/build              # Build all modules
/test               # Run all tests
/fix <target>       # Auto-fix issues
/scan               # Security sweep
/deploy             # Push + CI
@module sovereign-cli   # Focus on module
@rule "no new deps"     # Add session rule
@format table           # Set output format
```

---

## 📜 The Ponytail Doctrine

1. **Deletion Before Addition**: Unused code is technical debt. Prune dead code, unused dependencies, and speculative fallbacks.
2. **Zero Unearned Complexity**: Only build what is requested and currently useful.
3. **Verifiable System State**: Every capability must be backed by empirical test logs or build output.

---

## ⚖️ License & Governance

Governed by the **Agent Rulebook v18** at `.agents/AGENTS.md`. State certified in `AUDIT_LEDGER.md`.
Distributed under the MIT License.
