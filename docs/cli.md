# Sovereign-OS V17 — CLI & Orchestration Reference

## Overview

Sovereign-OS provides two primary command interfaces:
1. **PowerShell Orchestrator** (`sovereign.ps1`)
2. **Sovereign CLI** (`sovereign-cli`)

---

## 1. PowerShell Orchestrator (`sovereign.ps1`)

### Syntax
```powershell
.\sovereign.ps1 [-ConfigPath <path>] [-Verbose]
```

### Execution Flow
1. Acquires OS-level Mutex (`Global\SovereignOSLock`).
2. Discovers all subdirectories in `modules/` (7 total) and `skills/` (2 total).
3. Validates build manifests (`go.mod`, `package.json`, `SKILL.md`).
4. Atomically persists configuration to `sovereign.config.json`.
5. Logs execution latency and releases OS Mutex.

---

## 2. Sovereign CLI (`modules/sovereign-cli`)

### Commands

| Command | Arguments | Purpose |
| :--- | :--- | :--- |
| `sovereign status` | `--json` | Returns system health, mutex lock state, and submodule counts |
| `sovereign agent` | `--name <name>` | Manages autonomous agent execution contexts |
| `sovereign config` | `--get <key>` | Query configuration key-value pairs |
| `sovereign verify` | `--deep` | Performs a static and runtime integrity audit |

---

## 3. `no-mistakes` Pipeline CLI (`modules/no-mistakes`)

| Command | Description |
| :--- | :--- |
| `no-mistakes init` | Initializes agent skill bindings & fork URLs |
| `no-mistakes daemon run` | Launches the pipeline daemon |
| `no-mistakes axi status` | Returns live parked agent and pipeline status |
