# Sovereign-OS — Agent Rulebook v18

*Load this as system prompt, project instructions, or equivalent in any agent operating this repository.*
*Communication: concise, structured, zero fluff. Tables > lists > prose. Code > descriptions.*

---

## §1 Identity

**Sovereign-OS** is a hyper-minimalist meta-framework governing autonomous AI coding agents.
- **Root**: `C:\Skills` | **Version**: `VERSION` file | **Config**: `sovereign.config.json`
- **Doctrine**: Ponytail — deletion before addition, zero unearned complexity, concrete current utility only.
- **Golden Rule**: When in doubt, do less. Fewer lines = fewer mistakes.

---

## §2 Command Reference

Execute immediately when requested by the user without requiring redundant confirmation.

### Slash Commands — Actions

| Command | Effect | Execution |
|:---|:---|:---|
| `/audit` | Full system diagnostic | Run `sovereign audit` or inspect version, module health, config state, lock status |
| `/status` | Health table of modules & skills | Inspect `modules/*` and `skills/*` for manifests (`go.mod`, `package.json`, `SKILL.md`) |
| `/build [target]` | Build module(s) | `go build ./...` for Go, `npm run build` for Node. Default: all |
| `/test [target]` | Run tests | `go test ./...` for Go, `npm test` for Node. Default: all |
| `/fix <target>` | Auto-fix issues | Diagnose, fix, verify. Max 3 iterations. Log in AUDIT_LEDGER |
| `/scan` | Security sweep | Run security audit (GoSec, Trivy, secret scanner) |
| `/deploy` | Push changes & verify CI | Git add, commit, push via `no-mistakes` proxy gate |
| `/docs` | Regenerate documentation | Update `docs/` files to match current state |
| `/logs [n]` | Tail last n log lines | Read `LOGS/sovereign-YYYYMMDD.log` (default n=20) |
| `/config` | Show live config | Display formatted `sovereign.config.json` |
| `/summary` | Session summary | Version, module/skill counts, active status (one paragraph max) |
| `/workflow <name>` | Start workflow | Set workflow context (`onboard`, `release`, `security-audit`, `refactor`) |
| `/step` | Execute workflow step | Run next action in active workflow |
| `/help` | List commands | Display command reference |
| `/version` | Show version | Read and display `VERSION` |
| `/run` | Run orchestrator | Execute `sovereign.ps1` full orchestration pass |

### At Commands — Context & Control

| Command | Effect |
|:---|:---|
| `@module <name>` | Focus on named module in `modules/` |
| `@skill <name>` | Invoke named skill from `skills/<name>/SKILL.md` |
| `@tool <server> <tool>` | Call specific MCP tool from registered servers |
| `@config` | Open `sovereign.config.json` for review/edit |
| `@ledger` | Open `AUDIT_LEDGER.md` for review/append |
| `@mistakes` | Open `MISTAKES_LEDGER.md` (check before complex tasks) |
| `@registry` | Open `ASSET_REGISTRY.md` for approved tools |
| `@rule <text>` | Enforce constraint for active session |
| `@format <type>` | Set output format: `json`, `table`, `list`, `diff`, `minimal` |
| `@halt` | Pause proactive work, await explicit instructions |
| `@reset` | Clear session rules and format overrides |

---

## §3 Resource Map

### Modules — `C:\Skills\modules\`

| Module | Stack | Purpose | Build | Test |
|:---|:---|:---|:---|:---|
| `sovereign-cli` | Go / Cobra / Viper | CLI control & state queries | `go build ./...` | `go test ./...` |
| `sovereign-ui` | Next.js 14 / TS / Tailwind | Web telemetry dashboard | `npm run build` | `npm test` |
| `no-mistakes` | Go (v1.72.0) | PR gating & verification pipeline | `go build ./...` | `go test ./...` |
| `codebase-memory-mcp` | Go/C Binary (v0.10.8) | Semantic code search & graph | Native binary | N/A |
| `sovereign-security` | Go | Secret scanner & security audit | `go build ./...` | `go test ./...` |
| `sovereign-memory` | Go | Key-value execution store | `go build ./...` | `go test ./...` |
| `sovereign-adapt` | Go | Policy & remediation engine | `go build ./...` | `go test ./...` |

### Skills — `C:\Skills\skills\`

| Skill | Purpose | Trigger |
|:---|:---|:---|
| `ponytail` | Minimal-code philosophy enforcement | Any coding task, or user mentions "ponytail" / "be lazy" |
| `agent-reach` | Internet research & multi-platform routing | Web research, platforms, or URL queries |

### MCP Tool Priority

1. **Code Discovery**: `codebase-memory-mcp` (`search_graph`, `trace_path`, `get_code_snippet`, `query_graph`).
2. **GitHub Operations**: `github-mcp-server` (`search_code`, `get_file_contents`, `list_issues`, `create_pull_request`).
3. **Git Operations**: `git-mcp-server` (`git_status`, `git_diff`, `git_commit`, `git_push`).
4. **Database Operations**: `mcp-toolbox-for-databases` (SQLite, relational queries).
5. **System Execution**: `DesktopCommanderMCP` / `filesystem-mcp` / native shell tools.
6. **Browser Automation**: `playwright-mcp` / `chrome-devtools-mcp`.

---

## §4 Autonomy Protocol

### Execute Without Asking:
- Read any file in the workspace or repository.
- Modify code to fix defects, add requested features, or refactor.
- Run builds, tests, linters, and security checks.
- Create git commits and branches for change isolation.
- Invoke approved MCP tools and skills.
- Update documentation and ledgers (`AUDIT_LEDGER.md`).

### Stop and Confirm:
- Deleting core modules, directories, or skills.
- Adding unapproved external dependencies (must consult `ASSET_REGISTRY.md`).
- Altering security boundaries, credentials, or authentication tokens.
- Breaking API changes in public interfaces.

### Pre-Task Checklist:
1. Check `MISTAKES_LEDGER.md` to prevent past regressions.
2. Confirm approved dependencies in `ASSET_REGISTRY.md`.
3. Verify current state via `/status` or test suites.
4. Execute surgical changes and verify each step.
5. Update `AUDIT_LEDGER.md` with verifiable evidence.

---

## §5 Built-In Workflows

### `/workflow onboard`
1. Clone repository with `--recurse-submodules`.
2. Build all modules (`/build`).
3. Execute test suites (`/test`).
4. Run security audit (`/scan`).
5. Output system health summary (`/status`).

### `/workflow release`
1. Execute full audit (`/audit`).
2. Verify all builds and tests pass cleanly (`/build`, `/test`).
3. Run security check (`/scan`).
4. Bump version in `VERSION` and synchronize `sovereign.config.json`.
5. Append release verification entry to `AUDIT_LEDGER.md`.
6. Commit, tag, and push via `no-mistakes`.

### `/workflow security-audit`
1. Run static security analysis (GoSec, Trivy) across modules.
2. Scan for hardcoded credentials, tokens, and `.env` leaks.
3. Validate `.gitignore` coverage.
4. Output structured table of findings; resolve critical issues.
5. Log verification in `AUDIT_LEDGER.md`.

### `/workflow refactor`
1. Run Ponytail audit to identify dead code, bloat, and unused dependencies.
2. Apply surgical deletions and simplifications (standard library first).
3. Re-run builds and test suites to verify zero functional regression.
4. Record diffs in `AUDIT_LEDGER.md`.

---

## §6 Communication Rules

| Rule | Description |
|:---|:---|
| Zero fluff | Concise, technical, direct responses. |
| Structured | Tables for comparisons, bullet lists for sequences, code blocks for code. |
| Diff-first | Show modifications as unified diffs. |
| Evidence-backed | Always provide concrete test/build output rather than claims. |

---

## §7 Security Rules

1. **No Hardcoded Secrets**: Never commit tokens, credentials, or private keys.
2. **Fail Closed**: Block operations if security or validation gates fail.
3. **Verified Tools Only**: Restrict execution to tools registered in `ASSET_REGISTRY.md`.
4. **Log State Changes**: Record dependency additions and external commands in `AUDIT_LEDGER.md`.

---

## §8 Ponytail Compliance Gates

Every code modification must satisfy:
1. **Necessity**: Does this task need to exist? (YAGNI).
2. **Simplicity**: Can it be expressed with standard library or native features?
3. **Minimality**: Is this the shortest working diff?
4. **Zero Bloat**: No unrequested abstractions, boilerplate, or speculative configurations.

---

## §9 Orchestrator Reference

- **Controller**: `sovereign.ps1` (single-file orchestrator)
- **Wrapper**: `sovereign.cmd`
- **Commands**:
  - `sovereign audit`: System health and configuration validation.
  - `sovereign status`: Module and skill status table.
  - `sovereign run`: Full pass (mutex acquisition, discovery, template sync).
  - `sovereign logs`: Tail execution logs from `LOGS/`.

---

## §10 Workspace Layout

```
C:\Skills\
├── .agents/AGENTS.md          ← This rulebook
├── .github/                   ← CI workflows
├── sovereign.ps1              ← Orchestrator
├── sovereign.cmd              ← Command wrapper
├── sovereign.config.json      ← Master config
├── config.yaml                ← no-mistakes config
├── VERSION                    ← Semver string
├── AUDIT_LEDGER.md            ← Verified system state ledger
├── MISTAKES_LEDGER.md         ← Process failure registry
├── ASSET_REGISTRY.md          ← Approved tools registry
├── README.md                  ← Public documentation
├── docs/                      ← Documentation site
├── LOGS/                      ← Runtime logs
├── modules/                   ← Core Go & TS modules
└── skills/                    ← Semantic agent skills (ponytail, agent-reach)
```
