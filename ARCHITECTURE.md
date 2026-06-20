# Sovereign OS - Technical Architecture

Sovereign OS (`v14.0.0-CloudNative`) represents a paradigm shift in autonomous agent governance. Instead of treating the agent as a disparate script, Sovereign acts as a true Operating System that manages state, enforces security, and dynamically loads memory and dependencies into a Zero-Drift environment.

## The 7-Phase Sovereign Pipeline

When `pwsh -File "sovereign.ps1"` is executed, it guarantees the safety and evolution of the environment through 7 absolute phases:

### Phase 1: The Mutex Lock
Sovereign operates on an atomic scale. It acquires an OS-level lock using strict lease-time file streams. If another agent or process attempts to mutate the state while the master controller is running, they are queued or rejected, absolutely preventing race conditions and corrupted rule sets.

### Phase 2: Configuration Integrity & Core Generation
The system verifies the SHA-256 signature of `sovereign.config.json`, computes dynamic skill counts, and reconstructs the `SOVEREIGN_CORE.md` file from immutable templates. This is the **Single Source of Truth** for the current session.

### Phase 3: Skill Harvesting
The deep harvester scans project manifests (package.json, pyproject.toml, Cargo.toml, go.mod, pom.xml, *.csproj) using language-specific parsers, maps detected dependencies to cloud skill repos, and generates `harvested_skills.md`.

### Phase 4: Self-Evolution & Drift Analysis
The environment runs a drift-analysis against `.agents/knowledge/evolution_report.md`. If the user has introduced new technologies (e.g., React, Next.js), the Evolution engine detects the drift and automatically invokes JIT Cloud Fetching to mount the required skills. It also absorbs session learnings and runs Ponytail debt sweeps.

### Phase 5: AST Security Sweep
Before any workflow is executed, `security-sweep.ps1` runs a full Abstract Syntax Tree (AST) scan of the workspace. It checks for:
- Dangerous `Invoke-Expression` / `iex` usage.
- `eval()` and `new Function()` in JS/TS.
- Shell spawn via `exec/execSync`.
- Unwhitelisted third-party package imports.
If a vulnerability is found, the OS halts immediately.

### Phase 6: JIT Cloud-Native Skill Fetching (Optional)
Sovereign OS holds **zero** monolithic skills locally. Instead, the OS dynamically fetches open-source repositories from GitHub directly into an ephemeral `.cloud-cache`.
- **Command:** `pwsh agent-bootstrap/scripts/Fetch-CloudSkill.ps1 -Repo "org/repo"`
- **Why?** It ensures that agents always interact with the most up-to-date versions of tools without bogging down the OS repo with millions of lines of external code.

### Phase 7: Ephemeral Garbage Collection & Reach Check
To prevent context inflation and memory leaks, Sovereign OS purges all unpinned and untracked `.cloud-cache` artifacts, restoring the OS to a pristine baseline state. It then verifies Agent-Reach internet channel health.

---

## Agent-Reach Protocol

To grant agents universal, non-brittle access to the internet, Sovereign OS uses the **Agent-Reach** protocol. It acts as an upstream CLI router:
- Instead of using slow, local scraping scripts, it bridges native binaries like `gh` (GitHub), `yt-dlp` (YouTube), `jcode` (browser automation), and `r.jina.ai` (Web text streaming). 
- Run `agent-reach doctor` to verify channel health.
