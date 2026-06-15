# Sovereign OS - Technical Architecture

Sovereign OS (`v13.2.0-CloudNative`) represents a paradigm shift in autonomous agent governance. Instead of treating the agent as a disparate script, Sovereign acts as a true Operating System that manages state, enforces security, and dynamically loads memory and dependencies into a Zero-Drift environment.

## The 6-Phase Sovereign Pipeline

When `pwsh -File "sovereign.ps1"` is executed, it guarantees the safety and evolution of the environment through 6 absolute phases:

### Phase 1: The Mutex Lock
Sovereign operates on an atomic scale. It acquires an OS-level lock using strict lease-time file streams. If another agent or process attempts to mutate the state while the master controller is running, they are queued or rejected, absolutely preventing race conditions and corrupted rule sets.

### Phase 2: Configuration Integrity
The system verifies the SHA-256 signature of `sovereign.config.json` and reconstructs the `SOVEREIGN_CORE.md` file from immutable templates. This is the **Single Source of Truth** for the current session.

### Phase 3: JIT Cloud-Native Skill Fetching
Sovereign OS holds **zero** monolithic skills locally. Instead, the OS dynamically fetches open-source repositories from GitHub directly into an ephemeral `.cloud-cache`.
- **Command:** `pwsh agent-bootstrap/scripts/Fetch-CloudSkill.ps1 -Repo "org/repo"`
- **Why?** It ensures that agents always interact with the most up-to-date versions of tools without bogging down the OS repo with millions of lines of external code.

### Phase 4: AST Security Sweep
Before any workflow is executed, `security-sweep.ps1` runs a full Abstract Syntax Tree (AST) scan of the workspace. It checks for:
- Missing `-ErrorAction` flags.
- Suppressed `catch` blocks.
- Execution Policy vulnerabilities.
- Unsafe `Invoke-Expression` use.
If a vulnerability is found, the OS halts immediately.

### Phase 5: Self-Evolution
The environment runs a drift-analysis against `.agents/knowledge/evolution_report.md`. If the user has introduced new technologies (e.g., React, Next.js), the Evolution engine detects the drift and automatically invokes Phase 3 to fetch the required skills.

### Phase 6: Ephemeral Garbage Collection
To prevent context inflation and memory leaks, Sovereign OS purges all unpinned and untracked `.cloud-cache` artifacts, restoring the OS to a pristine baseline state.

---

## Agent-Reach Protocol

To grant agents universal, non-brittle access to the internet, Sovereign OS uses the **Agent-Reach** protocol. It acts as an upstream CLI router:
- Instead of using slow, local scraping scripts, it bridges native binaries like `gh` (GitHub), `yt-dlp` (YouTube), and `r.jina.ai` (Web text streaming). 
- Run `agent-reach doctor` to verify channel health.
