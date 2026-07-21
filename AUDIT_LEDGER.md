# Sovereign-OS Audit Ledger (V16 Pristine Rebuild)

This ledger strictly documents verified facts about the system state. All past falsified claims have been wiped in the V16 Scratch Rebuild.

## Verifiable Truths

### 1. Architecture
- The system is orchestrated by a 73-line PowerShell script (`sovereign.ps1`).
- The script uses an OS-level Mutex (`Global\SovereignOSLock`) to ensure single-instance execution, replacing the non-existent file lock claimed in prior versions.
- Configuration is centralized in `sovereign.config.json` (Version 16.0.0-Scratch).

### 2. Core Modules & Skills
The repository relies exclusively on Git Submodules for its core capabilities:
- `skills/agent-reach`: Internet research and platform routing.
- `skills/ponytail`: Minimalist engineering philosophy governance.
- `modules/no-mistakes`: PR gating, testing, and linting suite.
- `modules/codebase-memory-mcp`: Knowledge graph construction.

### 3. Dynamic Asset Registry
Instead of statically vendoring external dependencies (CI/CD, Security, Linting, Logging), the system uses an `ASSET_REGISTRY.md` file. Agents (acting on behalf of Sovereign) read this registry and dynamically integrate tools via `agent-reach` only when a task strictly requires them.

### 4. Known Good State
- The leaked GitHub token in `.env` was purged from the working tree. (Action required by user: Revoke on GitHub).
- Dead files (`claude_desktop_config.json`, empty `omni-discovery` skills, orphaned HTML docs) have been permanently deleted.
- The Git index correctly reflects only the V16 pristine files and initialized submodules.

> **Status:** CLEAN. No known falsifications or dead weight exist in this repository.
