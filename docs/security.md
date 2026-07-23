# Sovereign-OS V17 — Security & Governance Policy

## Zero-Trust Security Discipline

Sovereign-OS strictly enforces a **Zero-Trust Security Boundary** across all submodules, commits, and agent interactions.

---

## Security Invariants

### 1. Secret Isolation & Redaction
- **No Credentials in Repository**: API keys, AWS tokens, GitHub PATs, private keys, or passwords must NEVER be committed.
- **Redaction Pipeline**: The `no-mistakes` engine and `sovereign-security` module run regex redaction pass across all prompts and outputs before logging.

### 2. Workspace Boundary Policy
- Transient work, scratch scripts, and logs are isolated inside `scratch/` or `.agents/`.
- No raw binary files or unvetted scripts are allowed in core directories.

### 3. OS-Level Concurrency Isolation
- All orchestrator operations require explicit acquisition of `Global\SovereignOSLock`.
- Prevents race conditions, state corruption, or stale lock hijacking across parallel agent tasks.

### 4. Pinned SHA Trusted Branch Loading
- Pipeline execution configs (`commands.*` and `agent` directives) are loaded strictly from the trusted default branch at a pinned SHA to prevent untrusted pushed branch privilege escalation.
