# Sovereign-OS V18 — CLI & Orchestration Reference

## Overview

Sovereign-OS provides a streamlined command interface governed by the orchestrator:
1. **PowerShell Orchestrator** (`sovereign.ps1`)
2. **Batch Wrapper** (`sovereign.cmd`)
3. **Sovereign CLI** (`sovereign-cli`)

---

## 1. PowerShell Orchestrator & Batch Wrapper

### Syntax
```powershell
.\sovereign.ps1 [-Command <cmd>] [-CommandArgs <args>]
```
Shorthand via `sovereign.cmd`:
```cmd
sovereign <command> [args]
```

### System Commands (Handled Natively)
- `sovereign audit`: System diagnostic
- `sovereign status`: Module/skill health table
- `sovereign logs [n]`: Tail log files
- `sovereign config`: Display config
- `sovereign summary`: One-line system summary
- `sovereign run`: Full orchestration pass
- `sovereign help`: List commands

### Agent Commands (Handled by AI per Rulebook §2)
These commands trigger specific agent workflows:
- `/build [target]`: Build module(s)
- `/test [target]`: Run tests
- `/fix <target>`: Auto-fix issues
- `/scan`: Security sweep
- `/deploy`: Push changes + verify CI
- `/docs`: Regenerate documentation
- `/workflow <name>`: Start named workflow
- `/step`: Execute next workflow step

### Control Commands
- `@halt`: Pause all proactive work. Await explicit next instruction
- `@rule <text>`: Adopt constraint for session
- `@format <type>`: Set output format
- `@reset`: Clear session rules

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
