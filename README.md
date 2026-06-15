# Sovereign OS (v13.2.0-CloudNative) 🔱
> **The Ultimate, Zero-Drift, Cloud-Native Agent OS.**

Sovereign OS is a radically decoupled, zero-intervention governance framework for autonomous AI Agents. It transforms any standard directory into a deeply governed, perfectly synchronized intelligence hub, completely eliminating context drift, architecture decay, and manual skill integration.

## 🚀 The Cloud-Native Paradigm
Sovereign v13.2.0 entirely eliminates local bloat. It leverages a revolutionary **JIT (Just-In-Time) Cloud Fetching** architecture to instantly mount external repositories into an ephemeral `.cloud-cache`. 

Rather than maintaining static local knowledge bases, Sovereign allows agents to instantly pull the most advanced open-source tools—from web automation to RAG pipelines—directly from GitHub on-the-fly.

### The Ultimate Agent Stack (Natively Integrated)
Sovereign OS is designed to orchestrate the absolute pinnacle of current AI technology:
- **Web Exploration**: `browser-use`, `skyvern`, `crawlee`, `firecrawl`, `jina-ai/reader`
- **Orchestration**: `langchain-ai/langgraph`, `crewAIInc/crewAI`
- **Memory & Sandboxing**: `mem0ai/mem0`, `e2b-dev/E2B`
- **Coding & RAG**: `Aider-AI/aider`, `run-llama/llama_index`
- **Universal APIs**: Anthropic MCP Servers, `BerriAI/litellm`

## ⚙️ Architecture & Governance

### 1. Sovereign Command (The Universal Trigger)
The entire OS operates via a single unified command (`sovereign.ps1`). Executing this command triggers a 6-phase pipeline:
1. **OS-Level Mutex Lock**: Secures the environment for atomic writes.
2. **Integrity & Config Verification**: Cryptographically validates core files against SHA256 checksums.
3. **Skill Harvesting**: Analyzes local files and intelligently maps project requirements to cloud skills.
4. **Self-Evolution Engine**: Analyzes agent drift, absorbs session learnings, and auto-fetches missing tools.
5. **AST Security Sweep**: Scans all active scripts to guarantee 0 vulnerabilities before operation.
6. **Ephemeral GC**: Prunes the cloud-cache and purges memory leaks.

### 2. Zero-Trust Execution
Sovereign operates entirely headless. Every script, module, and rule is rigorously governed by the `sovereign.config.json` module caps. The engine implements strict PowerShell typing (`Set-StrictMode -Version Latest`) and robust error handling to prevent silent failures.

### 3. Agent-Reach Protocol
Agents have unhindered, protocol-level access to the internet. The Agent-Reach sub-engine provides standardized CLI tools allowing agents to natively parse YouTube, read any webpage via Jina, and utilize the Exa semantic search MCP seamlessly.

## 🚀 Quick Start
To initialize the Sovereign OS environment on a target project:
```powershell
pwsh -ExecutionPolicy Bypass -File "D:/Skills/sovereign.ps1" -ProjectPath "$PWD"
```

To fetch a cloud tool directly into the agent cache:
```powershell
pwsh D:/Skills/agent-bootstrap/scripts/Fetch-CloudSkill.ps1 -Repo "browser-use/browser-use"
```

## 🛡️ License
Sovereign OS is released under the **MIT License**. It is built for the open-source community to push the boundaries of what autonomous agent architectures can achieve.
