# Sovereign-OS V17 — Submodules Reference

Sovereign-OS V17 features **7 core submodules**, each decoupled and isolated as a Git submodule under `modules/`.

---

## Submodule Directory Layout

| Module | Category | Primary Tech | Path | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `sovereign-cli` | CLI | Go (Cobra, Viper, Zap) | `modules/sovereign-cli` | Command-line interface and daemon manager |
| `sovereign-ui` | Frontend | Next.js (App Router, Tailwind, Shadcn) | `modules/sovereign-ui` | Web dashboard & real-time telemetry monitoring |
| `no-mistakes` | Pipeline | Go (Pipeline, SCM, Agent) | `modules/no-mistakes` | Automated pipeline gate enforcement & git safety |
| `codebase-memory-mcp` | Knowledge Graph | C / Node.js MCP | `modules/codebase-memory-mcp` | Semantic codebase search, Cypher graph, and path tracing |
| `sovereign-security` | Security | Go | `modules/sovereign-security` | Zero-trust secret scanner & static vulnerability audit |
| `sovereign-memory` | State | Go | `modules/sovereign-memory` | Key-value memory ledger backing agent state |
| `sovereign-adapt` | Strategy | Go | `modules/sovereign-adapt` | Strategy tuning and auto-remediation policy engine |

---

## Detailed Specifications

### 1. `sovereign-cli`
- **Entrypoint**: `cmd/root.go`
- **Commands**: `agent`, `status`, `config`, `run`
- **Configuration**: Uses Viper to read `sovereign.config.json`

### 2. `sovereign-ui`
- **Framework**: Next.js 14+ (App Router)
- **Components**: `StatusDashboard.tsx`, `AgentTable.tsx`
- **API Routes**: `/api/status`

### 3. `no-mistakes`
- **Entrypoint**: `cmd/no-mistakes/main.go`
- **Sub-packages**: `internal/cli`, `internal/daemon`, `internal/pipeline`, `internal/agent`, `internal/git`
- **Invariants**: Strict adherence to `AGENTS.md` rules (OS lock, non-destructive rebase, fail-closed security).

### 4. `codebase-memory-mcp`
- **Protocols**: Model Context Protocol (MCP) over stdio.
- **Capabilities**: `index_repository`, `search_graph`, `query_graph`, `trace_path`, `get_code_snippet`.

### 5. `sovereign-security`
- **Capabilities**: Pattern-matching secret scanner covering AWS keys, GitHub PATs, private keys, and custom secrets.

### 6. `sovereign-memory`
- **Capabilities**: In-memory and persistent SQLite/JSON store for agent execution histories and audit records.

### 7. `sovereign-adapt`
- **Capabilities**: Policy engine evaluating execution failures and dynamically adjusting retries, timeouts, and fallback models.
