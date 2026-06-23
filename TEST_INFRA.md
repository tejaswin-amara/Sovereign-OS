# Sovereign OS E2E Testing Infrastructure & Schema (v14.0.0-CloudNative)

This document defines the E2E testing framework, native Windows runner commands, test placement conventions, and the 93 test cases mapped across the 8 roadmap features.

---

## 1. Test Architecture & Conventions

### 1.1 Placement
All E2E test files must be placed under:
`C:\Skills\agent-bootstrap\tests\e2e\`

### 1.2 File Naming Convention
`Feature[Number]_[FeatureName].Tests.ps1`
Example: `Feature1_Hook.Tests.ps1`

### 1.3 Native Windows Run Command
To execute the E2E test suite natively on Windows, run the following PowerShell command:
```powershell
pwsh -Command "Invoke-Pester -Path 'C:\Skills\agent-bootstrap\tests\e2e' -Output Detailed"
```

To run a specific tier of tests using Tag filtering:
```powershell
pwsh -Command "Invoke-Pester -Path 'C:\Skills\agent-bootstrap\tests\e2e' -Tag 'Tier1' -Output Detailed"
```

---

## 2. Test Case Schema Definition
Each test case is specified using the following fields:
* **Test ID**: Unique code in the format `TC-[Feature]-[Tier]-[Number]`.
* **Feature**: The target feature (F1 to F8).
* **Title**: A short, clear name for the verification.
* **Pre-conditions**: Required environment state.
* **Test Steps**: Operations executed by the test harness.
* **Expected Result**: Assertion checks and validation points.

---

## 3. Comprehensive List of the 93 Test Cases

### 3.1 Tier 1: Happy Path & Core Functionality (40 Test Cases)

| Test ID | Feature | Title | Pre-conditions | Test Steps | Expected Result |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-01-T1-01** | F1: Hook Repair | Hook Existence | Clean repo status | Inspect `.git/hooks/` folder. | `pre-commit` hook file exists and is executable. |
| **TC-01-T1-02** | F1: Hook Repair | Compliant Commit Run | Compliant staged files | Execute git commit. | Hook runs Pester, passes, and commit succeeds. |
| **TC-01-T1-03** | F1: Hook Repair | Modularity Block Run | Staged script > 300 lines | Execute git commit. | Hook detects file length transgression and blocks commit. |
| **TC-01-T1-04** | F1: Hook Repair | Test Failure Block | Failing Pester test staged | Execute git commit. | Hook detects Pester test failures and blocks commit. |
| **TC-01-T1-05** | F1: Hook Repair | Hook Bypass Flag | Non-compliant files staged | Execute `git commit --no-verify`. | Hook is bypassed; commit successfully records. |
| **TC-02-T1-06** | F2: Test Expansion | Helpers Module Import | `helpers.psm1` on disk | Run `Import-Module helpers.psm1`. | Module loads successfully without errors or warnings. |
| **TC-02-T1-07** | F2: Test Expansion | Write Log Success | LOGS dir exists | Call `Write-SovereignLog -Level INFO -Step TEST -Message 'Msg'`. | Message is appended with correct timestamps to LOGS files. |
| **TC-02-T1-08** | F2: Test Expansion | Load Configuration | `sovereign.config.json` valid | Call `Get-SovereignConfig`. | JSON config structure loads into PSObject correctly. |
| **TC-02-T1-09** | F2: Test Expansion | Parse VERSION File | `VERSION` file exists | Call `Get-SovereignVersion`. | Version matches version string in config and code. |
| **TC-02-T1-10** | F2: Test Expansion | Acquire Mutex Lock | No existing lock | Call `Start-SovereignLock`. | `.sovereign.lock` file is created with active PID. |
| **TC-02-T1-11** | F2: Test Expansion | Release Mutex Lock | Lock file exists | Call `Stop-SovereignLock` with current lock stream. | Lock file is deleted and file stream handle is closed. |
| **TC-02-T1-12** | F2: Test Expansion | Assert Module Cap | Module count compliant | Call `Assert-ModuleCap`. | Command exits successfully because modules <= 32. |
| **TC-03-T1-13** | F3: GHA CI/CD | CI Config Integrity | `ci.yml` exists | Run YAML lint parser on `.github/workflows/ci.yml`. | Config parses as fully compliant GitHub Actions YAML. |
| **TC-03-T1-14** | F3: GHA CI/CD | Trigger Actions PR | PR event context | Verify CI runs on PR triggers. | Actions runner triggers build on pull request events. |
| **TC-03-T1-15** | F3: GHA CI/CD | Run Comprehensive Audit | CI runner active | Run `test_complete_sovereign.ps1`. | Script completes successfully on runner environment. |
| **TC-03-T1-16** | F3: GHA CI/CD | Run Integration Sweep | CI runner active | Run `test_all_repos.ps1`. | Mapped repositories are fetched and validated in CI. |
| **TC-03-T1-17** | F3: GHA CI/CD | Runner Env Setup | Windows runner active | Verify pwsh and Pester modules load on CI runner. | Required modules are loaded dynamically with zero errors. |
| **TC-04-T1-18** | F4: Containerization | Dockerfile Validity | Dockerfile exists | Parse Dockerfile syntax. | Dockerfile structure complies with standard syntax rules. |
| **TC-04-T1-19** | F4: Containerization | Compose File Validity | Compose file exists | Run `docker-compose config`. | Compose file structure validates successfully. |
| **TC-04-T1-20** | F4: Containerization | Docker Image Build | Docker engine running | Execute `docker build -t sovereign-os .`. | Image builds successfully with cached layers. |
| **TC-04-T1-21** | F4: Containerization | Container Run Init | Image built | Run container using compose. | Sovereign environment bootstraps inside sandbox. |
| **TC-04-T1-22** | F4: Containerization | Exec sovereign-check | Container active | Run `sovereign-check.ps1` in container. | Integrity check completes successfully. |
| **TC-05-T1-23** | F5: Config CLI | CLI Script Existence | CLI file on disk | Verify `Add-SovereignSkill.ps1` path. | CLI utility script is in place and executable. |
| **TC-05-T1-24** | F5: Config CLI | Add Unique Skill Mappings | Valid config and repo | Run `Add-SovereignSkill -Repo 'org/repo'`. | Target repository is appended to `dep_to_skill_map`. |
| **TC-05-T1-25** | F5: Config CLI | Skill Mapping Verification | Mappings modified | Inspect `sovereign.config.json` after execution. | Added repository mappings match inputted parameters. |
| **TC-05-T1-26** | F5: Config CLI | Checksum Reseal | CLI completes edit | Verify `agent-bootstrap/.config.sha256` value. | Config hash is recalculated, saved, and sealed. |
| **TC-05-T1-27** | F5: Config CLI | Reject Duplicate Mapped | Mapping exists | Run `Add-SovereignSkill -Repo 'org/repo'` twice. | CLI exits without duplicate key addition. |
| **TC-06-T1-28** | F6: E2B Sandbox | Sandbox Config Parse | Valid config on disk | Load E2B config parameters. | Sandbox execution details are parsed successfully. |
| **TC-06-T1-29** | F6: E2B Sandbox | Sandbox Exec Script | E2B client initialized | Execute basic python script inside E2B sandbox. | Executed script completes and outputs results cleanly. |
| **TC-06-T1-30** | F6: E2B Sandbox | Capture Output Data | Python execution runs | Read execution log outputs from E2B return channel. | Standard output and errors are captured accurately. |
| **TC-06-T1-31** | F6: E2B Sandbox | Sandbox Config Toggle | Config mapping present | Toggle E2B sandbox flag to `true`. | System routes all commands through the E2B wrapper. |
| **TC-07-T1-32** | F7: Telemetry | DB Initialization | Run ID active | Call telemetry logger. | SQLite DB `LOGS/telemetry.db` is initialized on demand. |
| **TC-07-T1-33** | F7: Telemetry | Log LLM Token Count | DB exists | Log input/output token metrics. | Database records token metric counts accurately. |
| **TC-07-T1-34** | F7: Telemetry | Log Tool Execution | DB exists | Log tool duration measurements. | DB logs tool names and execution duration. |
| **TC-07-T1-35** | F7: Telemetry | Log Execution Costs | DB exists | Log LLM API costs. | Cost fields map and save with floating point precision. |
| **TC-07-T1-36** | F7: Telemetry | Table Schema Integrity | SQLite file exists | Query sqlite master schema details. | Schema structure matches designed columns and indexes. |
| **TC-08-T1-37** | F8: Swarm | Swarm Script Check | Swarm file on disk | Verify `Start-SovereignSwarm.ps1` path. | Swarm orchestrator script is present and executable. |
| **TC-08-T1-38** | F8: Swarm | Swarm Parameter Parse | Valid parameters | Launch swarm with config parameters. | Swarm initialization parameters parse without error. |
| **TC-08-T1-39** | F8: Swarm | Sub-Agent Spawn | CrewAI/LangGraph loaded | Start swarm coordinator. | Researcher, Coder, and Reviewer sub-agents launch. |
| **TC-08-T1-40** | F8: Swarm | Task Routing Flow | Sub-agents spawned | Dispatch test task to researcher. | Task passes through sub-agents and completes. |

---

### 3.2 Tier 2: Boundary & Edge Cases (40 Test Cases)

| Test ID | Feature | Title | Pre-conditions | Test Steps | Expected Result |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-01-T2-41** | F1: Hook Repair | Staged Paths with Spaces | Staged file with spaces | Commit changes. | Hook processes path and allows commit successfully. |
| **TC-01-T2-42** | F1: Hook Repair | Staged Paths with Brackets | Staged file with brackets | Commit changes. | Hook handles literal paths and completes check. |
| **TC-01-T2-43** | F1: Hook Repair | Empty Commit Run | Staged index is empty | Commit empty changes. | Hook passes immediately with no files to scan. |
| **TC-01-T2-44** | F1: Hook Repair | Read-Only Hooks Folder | `.git/hooks/` read-only | Attempt git commit. | Hook runs from read-only directory without failures. |
| **TC-01-T2-45** | F1: Hook Repair | Run in Subdirectories | Staged changes in subfolder | Commit changes. | Hook runs relative path sweeps correctly. |
| **TC-02-T2-46** | F2: Test Expansion | Corrupt Configuration | Config contains invalid JSON | Run `Get-SovereignConfig`. | Function catches parser errors and throws. |
| **TC-02-T2-47** | F2: Test Expansion | Missing VERSION File | `VERSION` deleted | Run `Get-SovereignVersion`. | Function throws indicating version file is missing. |
| **TC-02-T2-48** | F2: Test Expansion | Stale Mutex Lock PID Dead | Lock file PID is dead | Run `Start-SovereignLock`. | Lock is auto-cleared and acquired by current PID. |
| **TC-02-T2-49** | F2: Test Expansion | Timezone Shift Mutex | Lock StartTime timezone shift | Run lease timeout validation. | System uses DateTimeOffset to prevent early release. |
| **TC-02-T2-50** | F2: Test Expansion | Read-Only LOGS Directory | LOGS folder write protected | Run `Write-SovereignLog`. | Log writes fall back to stdout without crash. |
| **TC-02-T2-51** | F2: Test Expansion | Module Cap Exactly 32 | Module count = 32 | Run `Assert-ModuleCap`. | Assert passes but logs warnings on reaching cap limit. |
| **TC-02-T2-52** | F2: Test Expansion | Module Cap Exceeds 32 | Module count = 33 | Run `Assert-ModuleCap`. | Assert throws error blocking further executions. |
| **TC-03-T2-53** | F3: GHA CI/CD | Massive File Diffs | PR with 1,000+ files | Trigger CI workflow. | Runner processes diffs without memory overflows. |
| **TC-03-T2-54** | F3: GHA CI/CD | Run Trigger Boundary | Push to non-main branch | Verify CI runner. | Runner triggers branch builds without deploy steps. |
| **TC-03-T2-55** | F3: GHA CI/CD | Cloud Skills Rate Limits | Github token near limits | Run CI integration check. | Runner uses local cloud cache and prints warnings. |
| **TC-03-T2-56** | F3: GHA CI/CD | Catch Sweep Warnings | Lint rules output warnings | Run CI sweep. | Runner logs warnings without failing build gate. |
| **TC-03-T2-57** | F3: GHA CI/CD | Lint Markdown Formats | Modified markdown files | Run markdown linter check. | Markdown structures conform to syntax guidelines. |
| **TC-04-T2-58** | F4: Containerization | Read-Only Host Volume | Volume mount read-only | Start container. | Container starts up and logs output to console. |
| **TC-04-T2-59** | F4: Containerization | Timezone Parity Check | Host has offset timezone | Boot container. | Container timezone aligns to host settings. |
| **TC-04-T2-60** | F4: Containerization | Custom Log Path Env | Env override active | Launch container. | Logs are routed to the custom path. |
| **TC-04-T2-61** | F4: Containerization | Build Cache Invalid | Modified scripts on host | Run docker build. | Cache is invalidated; changes copy to image. |
| **TC-05-T2-62** | F5: Config CLI | Repository Format Validation | Input `invalid_format` repo | Run `Add-SovereignSkill -Repo 'invalid'`. | Command rejects invalid repository format. |
| **TC-05-T2-63** | F5: Config CLI | Rejects Path Traversal | Input `../../repo` | Run `Add-SovereignSkill -Repo '../../repo'`. | Command blocks input and throws validation exception. |
| **TC-05-T2-64** | F5: Config CLI | Read-Only Config Override | Config write-protected | Run `Add-SovereignSkill -Repo 'org/repo'`. | File attributes clear, config writes, and seals. |
| **TC-05-T2-65** | F5: Config CLI | Preserve JSON Format | Custom formatting present | Run CLI skill addition. | Whitespace structure and comments are preserved. |
| **TC-05-T2-66** | F5: Config CLI | Trailing Slashes Input | Input `org/repo/` | Run `Add-SovereignSkill -Repo 'org/repo/'`. | Input normalizes to `org/repo` and maps successfully. |
| **TC-06-T2-67** | F6: E2B Sandbox | Sandbox Env Injections | Custom env settings | Launch sandbox execution. | Env variables exist inside sandbox container. |
| **TC-06-T2-68** | F6: E2B Sandbox | Execution Timeout Enforce | Infinite loop script | Run sandbox execution. | Execution terminates after timeout limit is reached. |
| **TC-06-T2-69** | F6: E2B Sandbox | Offline Mode Network Block | Outbound network calls | Run sandbox execution. | Sandboxed network requests fail as designed. |
| **TC-06-T2-70** | F6: E2B Sandbox | Sandbox Clean Up | Crash simulation | Terminate runner process. | Active sandboxes are destroyed without zombie tasks. |
| **TC-06-T2-71** | F6: E2B Sandbox | Large Code Execution | Script > 10MB | Run sandbox execution. | Sandbox parses and runs script without memory leak. |
| **TC-07-T2-72** | F7: Telemetry | Null Logging Fields | Log call with missing fields | Log metrics details. | DB saves null values without throwing exceptions. |
| **TC-07-T2-73** | F7: Telemetry | SQLite Logs Retention | Logs > 7 days old present | Trigger log pruning check. | Logs older than 7 days delete automatically. |
| **TC-07-T2-74** | F7: Telemetry | SQLite Write Load | Concurrent logging calls | Execute parallel logs. | Transactions execute successfully; no database locks. |
| **TC-07-T2-75** | F7: Telemetry | SQLite Schema Migration | Schema version outdated | Initialize database. | Schema migrates to new layout without data loss. |
| **TC-07-T2-76** | F7: Telemetry | SQLite Database Size | DB size exceeds 10MB | Trigger database check. | DB triggers auto-vacuum and logs rotation. |
| **TC-08-T2-77** | F8: Swarm | Clean Swarm Stop | Swarm executing tasks | Issue stop command. | Sub-agent processes terminate without orphaned tasks. |
| **TC-08-T2-78** | F8: Swarm | Cyclic Dependency Sweep | Task A -> B -> A dependencies | Start swarm execution. | Swarm detects cyclic loop and aborts. |
| **TC-08-T2-79** | F8: Swarm | Maximum Message Cap | Loop logic staged | Execute swarm process. | Swarm limits iterations and terminates after 16 calls. |
| **TC-08-T2-80** | F8: Swarm | JSON Format Serialization | Complex state variables | Run agent task routing. | State is serialized and loaded in JSON without errors. |

---

## 3.3 Tier 3: Fault Injection & Recovery (8 Test Cases)

| Test ID | Feature | Title | Failure Injected | Test Steps | Expected Result |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-05-T3-81** | F5: Config CLI | CLI Write Transaction Rollback | Checksum update / config sealing fails | Trigger `Add-SovereignSkill`. | CLI catches exception, reverts edits, and restores config. |
| **TC-02-T3-82** | F2: Test Expansion | Mutex Lock Retry Backoff | Mutex locked by external task | Run `Start-SovereignLock`. | Locking retries with exponential backoff and succeeds. |
| **TC-06-T3-83** | F6: E2B Sandbox | Sandbox Init Fail Fallback | Sandbox cloud API returns 500 | Initialize execution. | System falls back to secure local mock sandbox execution. |
| **TC-07-T3-84** | F7: Telemetry | Telemetry Write Fallback | SQLite DB locked / write permission denied | Log telemetry record. | Logger falls back to flat-file JSON logs in LOGS directory. |
| **TC-08-T3-85** | F8: Swarm | Sub-Agent Recovery | Researcher agent process crashes | Start swarm execution. | Orchestrator detects crash and restarts sub-agent container. |
| **TC-04-T3-86** | F4: Containerization | Kill Switch Trigger | Create `SENTINEL_STOP` file | Boot container. | Container detects kill-switch, aborts phases, exits with code 1. |
| **TC-03-T3-87** | F3: GHA CI/CD | Git Fetch Error Retry | Network packet drop in git clone | Trigger CI workflow. | CI runner retries fetch operations up to 3 times before failing. |
| **TC-01-T3-88** | F1: Hook Repair | Hook Corruption Recovery | Test files corrupted | Attempt git commit. | Hook aborts commit, reports errors, and runs repair. |

---

## 3.4 Tier 4: Environment, Stress, & Security (5 Test Cases)

| Test ID | Feature | Title | Stress / Threat Injected | Test Steps | Expected Result |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-05-T4-89** | F5: Config CLI | Multi-process Write Stress | 10 parallel processes calling `Add-SovereignSkill` | Run parallel write scripts. | Config updates cleanly; zero JSON corruption or checksum mismatches. |
| **TC-06-T4-90** | F6: E2B Sandbox | Sandbox Isolation Security | Script attempts sandbox escape | Execute escape payload. | Sandbox blocks access to host filesystem/processes. |
| **TC-08-T4-91** | F8: Swarm | Swarm Memory Footprint | 24-hour long task execution | Monitor memory size. | Memory usage remains stable; zero memory leaks in state. |
| **TC-07-T4-92** | F7: Telemetry | SQLite DB Write Stress | 10,000 logs written sequentially | Run stress log script. | Telemetry records save, cost tallies update, and older records prune. |
| **TC-01-T4-93** | F1: Hook Repair | Bypass Hook Lockout | Bypassing pre-commit with manual flags | Stage changes and bypass hooks. | Server/OS check validates integrity during next initialization run. |
