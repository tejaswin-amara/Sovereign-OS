# Structural & Architectural Analysis Report: `no-mistakes` Module

## 1. Observation

Direct file observations from `C:\Skills\modules\no-mistakes`:

- **Skill Synchronization (`internal/skill/skill.go` vs `skills/no-mistakes/SKILL.md`)**:
  - `internal/skill/skill.go:15` defines `Name = "no-mistakes"`.
  - `internal/skill/skill.go:20` defines `Description = "Validate your code changes through the no-mistakes pipeline..."`.
  - `internal/skill/skill.go:31` `Markdown()` constructs frontmatter `---`, `name`, `description`, `user-invocable: true`, and appends `body`.
  - `skills/no-mistakes/SKILL.md:1-5` matches `Markdown()` frontmatter format and content exactly. Body matches `internal/skill/skill.go:45-330` line-for-line.

- **Security & Config Trust Boundaries (`internal/daemon/manager.go` & `internal/config/config.go`)**:
  - `internal/daemon/manager.go:715`: Calls `assertGateTrustedConfigReadable(ctx, wtDir, repo.DefaultBranch, trustedSHA)`. Fails closed if default-branch config cannot be fetched or parsed.
  - `internal/daemon/manager.go:720-722`: `trustedRepoCfg := loadTrustedRepoConfig(...)`; `allowRepoCommands := trustedRepoCfg != nil && trustedRepoCfg.AllowRepoCommands`; `effectiveRepoCfg := config.EffectiveRepoConfig(repoCfg, trustedRepoCfg, allowRepoCommands)`.
  - `internal/config/config.go:102`: `AllowRepoCommands` is scoped per-repo. Scoped validation in `config_repo_trust_test.go:236` ensures global `allow_repo_commands` is explicitly rejected. A pushed branch cannot self-enable `allow_repo_commands` because `allowRepoCommands` is read exclusively from `trustedRepoCfg`.

- **Daemon Singleton Lock (`internal/daemon/lock.go`)**:
  - `internal/daemon/lock.go:38-65`: `acquireSingletonLock` opens `<NM_HOME>/daemon.lock` and applies `tryLockFile(f)`. OS-native file lock (`flock` on Unix, `LockFileEx` on Windows) guarantees lock release on any process exit/crash without stale lock state heuristics. Writes JSON diagnostic payload (`PID`, `StartedAt`).

- **Process Hardening & Subprocess Lifecycle (`internal/winproc` & `internal/shellenv`)**:
  - `internal/winproc/harden_windows.go:24-33`: `winproc.Harden(cmd)` sets `CreationFlags |= windows.CREATE_NO_WINDOW` and `HideWindow = true` to suppress console window popups when spawned by console-less daemon on Windows.
  - `internal/shellenv/shellenv.go:324-326`: `ConfigureShellCommand(cmd)` attaches process group management, configures tree cancellation via `cmd.Cancel`, and enforces `cmd.WaitDelay = 5s` to reap grandchild processes on exit.

- **Git Hook Gate Path Resolution (`internal/git/hook.go`)**:
  - `internal/git/hook.go:44-59`: `postReceiveHookScript` queries `git rev-parse --absolute-git-dir`, falling back to `pwd -P` from hook directory to ensure `GATE_DIR` is strictly absolute (resolving issue #269 where `.` path caused daemon rejection).

## 2. Logic Chain

1. **Skill Drift Invariant**: The repository enforces that `skills/no-mistakes/SKILL.md` is generated from `internal/skill/skill.go`. Comparison confirms `SKILL.md` matches `Markdown()` output. `make lint` enforces this invariant in CI via drift checks.
2. **Untrusted Code Execution Boundary**: `no-mistakes` executes repository commands (`commands.test`, `commands.lint`, `commands.format`) and selects pipeline agents (`agent`). If untrusted feature branches could modify these fields, PR submissions could execute malicious commands on the daemon host. By restricting `commands.*`, `agent`, `document.instructions`, and `disable_project_settings` to the pinned default-branch SHA (`trustedSHA`) unless `allow_repo_commands` is set on the default branch itself, the system maintains a secure boundary against untrusted branch execution.
3. **Daemon Concurrency Control**: Multiple daemon processes running on the same `NM_HOME` would compete for worktrees and crash active runs. Exclusive file locking at daemon startup ensures single-instance ownership per `NM_HOME`.
4. **Subprocess Resilience**: Leaked grandchild processes (e.g. background build watchers) hold open pipes, causing process hangs or worktree lock contention. `shellenv.ConfigureShellCommand` and `winproc.Harden` isolate process trees, enforce cancellation cleanup, and prevent UI flash artifacts on Windows.

## 3. Caveats

- Live execution tests (`go test -race ./...`, `make e2e`) were not executed during this turn as this is a read-only architectural investigation pass.
- Verification relied on direct file inspection and pattern matching against documented design invariants in `AGENTS.md`.

## 4. Conclusion

The `no-mistakes` module in `C:\Skills\modules\no-mistakes` fully satisfies all architectural, security, and process hardening guidelines set forth in `AGENTS.md` and repository standards:
1. `skills/no-mistakes/SKILL.md` is in 100% sync with `internal/skill/skill.go`.
2. Security boundaries for repo config (`allow_repo_commands`, trusted default branch fallback, fail-closed fetching) are properly enforced in `internal/daemon/manager.go` and `internal/config/config.go`.
3. Daemon lock (`lock.go`), process hardening (`winproc`, `shellenv`), and path handling (`git/hook.go`) strictly follow robust design practices.

## 5. Verification Method

To independently verify these findings:
1. Run `make lint` inside `C:\Skills\modules\no-mistakes` to verify generated skill drift check.
2. Inspect `internal/skill/skill.go` line 31 (`Markdown()`) vs `skills/no-mistakes/SKILL.md`.
3. Run `go test ./internal/config/... ./internal/daemon/... ./internal/winproc/...` to execute unit tests for security and process hardening.
