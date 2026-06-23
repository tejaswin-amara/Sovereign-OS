<div align="center">

# 🔱 Sovereign OS
**The Ultimate, Zero-Drift, Cloud-Native Agent Operating System.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![PowerShell 7+](https://img.shields.io/badge/PowerShell-7%2B-blueviolet.svg)](https://microsoft.com/PowerShell)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

Sovereign OS is a radically decoupled, zero-intervention governance framework for autonomous AI Agents. It transforms any standard directory into a deeply governed, perfectly synchronized intelligence hub, completely eliminating context drift, architecture decay, and manual skill integration.

</div>

---

## 🚀 The Apex Engine & Cloud-Native Paradigm

Sovereign `v14.0.0-CloudNative` entirely eliminates local bloat. It leverages a revolutionary **JIT (Just-In-Time) Cloud Fetching** architecture to instantly mount external repositories into an ephemeral `.cloud-cache`. 

Rather than maintaining static local knowledge bases, Sovereign allows agents to instantly pull the most advanced open-source tools—from web automation to RAG pipelines—directly from GitHub on-the-fly. 

The new **Apex Engine** introduces an Omni-Fetch layer capable of parallel-acquiring over **86+ state-of-the-art frameworks**, immediately indexing them via **Turbovec Semantic Vectoring** to create a massive, hyper-intelligent knowledge base. It natively integrates the **Ponytail (Lazy Senior Dev) Mode** inside the Self-Evolution engine to aggressively prune technical debt and block over-engineered architectures.

---

## 🤖 Universal Cross-Platform AI Compatibility

Sovereign OS isn't just a local script. It natively binds to the world's most powerful AI agents and IDEs, forcing them to obey OS governance rules the second they enter the workspace. Out of the box, Sovereign OS seamlessly injects its `SOVEREIGN_CORE.md` master directive into:

- 🔶 **Claude Desktop**: Natively hooks via `claude_desktop_config.json`
- 🧠 **Manus Autonomous Agent**: Governed via `.manus.yaml`
- 💻 **Cursor IDE**: Bound via `.cursorrules`
- 🏄‍♂️ **Windsurf IDE**: Bound via `.windsurfrules`
- 🧩 **Cline / RooCode**: Bound via `.clinerules`
- ⌨️ **Aider CLI**: Governed via `.aider.conf.yml`
- ✈️ **GitHub Copilot**: Governed via `.github/copilot-instructions.md`

Any AI system running in a Sovereign repository will instantly query the Turbovec Semantic Index instead of hallucinating logic, and it will aggressively use JIT Cloud Fetching instead of installing unnecessary local NPM/PIP packages.

---

## 🌐 The Ultimate Agent Stack (Natively Indexed)
Sovereign OS is designed to orchestrate the absolute pinnacle of current AI technology. The Apex Engine continuously indexes the following frameworks into your agent's memory:
- 🕵️ **Web Exploration**: `browser-use`, `skyvern`, `crawlee`, `firecrawl`, `jina-ai/reader`
- 🧠 **Orchestration**: `langchain-ai/langgraph`, `crewAIInc/crewAI`, `stanfordnlp/dspy`, `microsoft/graphrag`
- 💾 **Memory & Sandboxing**: `mem0ai/mem0`, `e2b-dev/E2B`
- 💻 **Coding & RAG**: `Aider-AI/aider`, `run-llama/llama_index`, `pydantic/pydantic-ai`
- 🔌 **Universal APIs**: Anthropic MCP Servers, `BerriAI/litellm`

---

---

## ⚙️ Architecture & Governance

### 1. Sovereign Command (The Universal Trigger)
The entire OS operates via a single unified command (`sovereign.ps1`). Executing this command triggers a 7-phase pipeline:
1. 🔒 **OS-Level Mutex Lock**: Secures the environment for atomic writes.
2. 🛡️ **Integrity & Config Verification**: Cryptographically validates core files against SHA256 checksums.
3. 📦 **Skill Harvesting**: Analyzes local files and intelligently maps project requirements to cloud skills.
4. 🧬 **Self-Evolution Engine**: Analyzes agent drift, absorbs session learnings, auto-fetches missing tools, compiles the Turbovec index, and executes Ponytail sweeps.
5. 🔍 **AST Security Sweep**: Scans all active scripts to guarantee 0 vulnerabilities before operation.
6. ☁️ **JIT Cloud-Native Skill Fetching**: Dynamically fetches tools directly from GitHub into the ephemeral `.cloud-cache`.
7. 🗑️ **Blazing Ephemeral GC**: Natively prunes the `.cloud-cache` instantly via OS hooks, avoiding memory leaks.

### 2. Zero-Trust Execution & Sandboxing
Sovereign operates entirely headless. Every script, module, and rule is rigorously governed by the `sovereign.config.json` module caps. The engine implements strict PowerShell typing (`Set-StrictMode -Version Latest`) and robust error handling to prevent silent failures. 
- **E2B Cloud Environment:** Native sandboxing explicitly integrated into `omni_harvester` for secure, isolated arbitrary code execution.

### 3. Agent-Reach Protocol & Swarm Orchestration
- **Agent-Reach Protocol:** Agents have unhindered, protocol-level access to the internet using standardized CLI tools allowing them to natively parse YouTube, read any webpage via Jina, and utilize the Exa semantic search MCP seamlessly.
- **Multi-Agent Swarm:** The OS orchestrates massive multi-agent parallel execution via `Start-SovereignSwarm.ps1`, integrating LangGraph and CrewAI directly into the Sovereign ecosystem.

### 4. Advanced Tooling & Telemetry
- **Dynamic Config Updaters:** Natively append new skills to the schema without breaking JSON structure using `Add-SovereignSkill.ps1`.
- **SQLite Telemetry Logging:** Real-time token usage and API cost tracking is funneled directly into `LOGS/telemetry.db` via `Log-SovereignTelemetry.ps1`.
- **CI/CD & Containerization:** Sovereign ships with a highly optimized, Ubuntu-based `Dockerfile` and automated `ci.yml` GitHub Actions pipeline. Every commit executes the `.git/hooks/pre-commit` passing the internal `Invoke-Pester` suite.

---

## ⚡ Quick Start

### 1. Frictionless Onboarding
To install the required Agent-Reach environments and verify your system, simply run:
```powershell
pwsh -ExecutionPolicy Bypass -File "./setup.ps1"
```

### 2. Boot the OS
To initialize the Sovereign OS environment on a target project:
```powershell
pwsh -ExecutionPolicy Bypass -File "./sovereign.ps1" -ProjectPath "$PWD"
```

### 3. Fetch a Cloud Tool
To fetch a tool directly into the agent cache on the fly:
```powershell
pwsh ./agent-bootstrap/scripts/Fetch-CloudSkill.ps1 -Repo "browser-use/browser-use"
```

---

## 🤝 Contributing
We welcome contributions! Before submitting a PR, please read our [Contributing Guidelines](CONTRIBUTING.md) and ensure you have run the exhaustive test suite (`.\test_complete_sovereign.ps1`) and the Pester suite (`Invoke-Pester -Path "agent-bootstrap/tests"`).

## 📄 License
Sovereign OS is released under the [MIT License](LICENSE). It is built for the open-source community to push the boundaries of what autonomous agent architectures can achieve.
