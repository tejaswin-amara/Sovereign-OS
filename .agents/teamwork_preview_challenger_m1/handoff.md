# Empirical Test Report & Handoff — Sovereign-OS V16 Controller

**Agent**: Challenger M1 (critic, specialist)  
**Date**: 2026-07-21  
**Working Directory**: `C:\Skills\.agents\teamwork_preview_challenger_m1\`  
**Target Files**: `C:\Skills\sovereign.ps1`, `C:\Skills\sovereign.config.json`, `C:\Skills\modules`  

---

## 1. Observation

### 1.1 Baseline Execution of `sovereign.ps1`
Command executed:
```powershell
powershell.exe -ExecutionPolicy Bypass -File C:\Skills\sovereign.ps1
```
- **Exit Code**: `0`
- **Stdout**:
```
[08:37:02] [INFO] [MUTEX] OS-Level Lock Acquired.
[08:37:02] [INFO] [INIT] Dynamic skill count: 2, Module count: 4
[08:37:02] [INFO] [COMPLETE] ALL PHASES PASSED
[08:37:02] [INFO] [MUTEX] Lock released.
[08:37:02] [INFO] [TELEMETRY] Execution finished in 116 ms.
```
- **Stderr**: *(empty)*

---

### 1.2 Mutex Lock Empirical Contention & Concurrency Testing (`test_mutex.ps1`)

**Test 2.1: Mutex Contention Timeout (Blocker holding lock for 7s)**
- Blocker background process acquired `"Global\SovereignOSLock"` and slept for 7s.
- `sovereign.ps1` invoked concurrently (config `lock_timeout_seconds` = 5s).
- **Exit Code**: `1`
- **Duration**: `7132 ms` (WaitOne 5000 ms timeout + startup overhead)
- **Stdout**:
```
[08:37:21] [ERROR] [MUTEX] Could not acquire OS lock. Another instance is running.
```

**Test 2.2: Mutex Handover (Blocker holding lock for 2s)**
- Blocker background process acquired `"Global\SovereignOSLock"` and slept for 2s.
- `sovereign.ps1` invoked 500ms after blocker started.
- **Exit Code**: `0`
- **Duration**: `4049 ms` (Waited ~1.5s for blocker release, acquired lock, executed cleanly).
- **Stdout**:
```
[08:37:26] [INFO] [MUTEX] OS-Level Lock Acquired.
[08:37:26] [INFO] [INIT] Dynamic skill count: 2, Module count: 4
[08:37:26] [INFO] [COMPLETE] ALL PHASES PASSED
[08:37:26] [INFO] [MUTEX] Lock released.
[08:37:26] [INFO] [TELEMETRY] Execution finished in 206 ms.
```

**Test 2.3: Simultaneous Parallel Invocations (2 Concurrent Jobs)**
- Launched 2 background jobs running `sovereign.ps1` simultaneously.
- **Result**: Both completed cleanly with exit code `0`. Execution synchronized via OS Mutex without deadlock or state corruption.

---

### 1.3 Dynamic Module Count Empirical Validation (`test_module_count.ps1`)

**Test 3.1: Baseline Count**
- Disk contents of `C:\Skills\modules` (4 directories): `codebase-memory-mcp`, `no-mistakes`, `sovereign-cli`, `sovereign-ui`.
- `sovereign.ps1` log output: `Dynamic skill count: 2, Module count: 4`.
- **Result**: PASS (Reported 4 matches disk count 4).

**Test 3.2: Dynamic Addition of Subdirectory**
- Created `C:\Skills\modules\_temp_test_module_m1`.
- `sovereign.ps1` log output: `Dynamic skill count: 2, Module count: 5`.
- **Result**: PASS (Dynamic module detection confirmed). Cleaned up temp directory.

**Test 3.3: Exclusion of Non-Directory Files**
- Created `C:\Skills\modules\_temp_file.txt`.
- `sovereign.ps1` log output: `Dynamic skill count: 2, Module count: 4`.
- **Result**: PASS (`Get-ChildItem -Path $ModulesDir -Directory` properly filters out non-directory files). Cleaned up temp file.

---

### 1.4 Config Parsing Normal & Edge Conditions (`test_config_parsing.ps1`)

Tested `sovereign.ps1` across 7 config conditions:

| Scenario | Config State | Exit Code | Stdout / Stderr Excerpt | Result |
|---|---|---|---|---|
| **4.1** | Valid Config Baseline | `0` | `[INFO] [COMPLETE] ALL PHASES PASSED` | PASS |
| **4.2** | Missing `sovereign.config.json` | `1` | Stdout: `[ERROR] [INIT] Config missing at C:\Skills/sovereign.config.json.`<br>Stderr: `The variable '$LogDir' cannot be retrieved because it has not been set.` | PASS (Exits non-zero) |
| **4.3** | Malformed JSON Syntax | `1` | Stderr: `ConvertFrom-Json : Invalid object passed in...` | PASS (Exits non-zero) |
| **4.4** | Empty JSON `{}` | `1` | Stderr: `The property 'paths' cannot be found on this object.` | PASS (Exits non-zero) |
| **4.5** | Missing `paths` Section | `1` | Stderr: `The property 'paths' cannot be found on this object.` | PASS (Exits non-zero) |
| **4.6** | Missing `governance` Section | `1` | Stderr: `The property 'governance' cannot be found on this object.` | PASS (Exits non-zero) |
| **4.7** | Missing `governance.lock_timeout_seconds` | `1` | Stderr: `The property 'lock_timeout_seconds' cannot be found on this object.` | PASS (Exits non-zero) |

---

## 2. Logic Chain

1. **Observation**: Execution of `sovereign.ps1` under valid conditions completes with Exit Code `0` and outputs log lines confirming mutex lock acquisition, dynamic skill/module counting, phase completion, lock release, and telemetry execution timing.
2. **Observation**: Mutex contention tests demonstrate that `New-Object System.Threading.Mutex($false, "Global\SovereignOSLock")` correctly blocks concurrent executions beyond `lock_timeout_seconds` (5s), yielding Exit Code `1` and logging `[ERROR] [MUTEX] Could not acquire OS lock. Another instance is running.` Handover within timeout allows queued process to resume and complete cleanly.
3. **Observation**: `sovereign.ps1` calculates `$DynamicModuleCount` using `@(Get-ChildItem -Path $ModulesDir -Directory).Count`, correctly matching actual subdirectories (4 baseline, 5 on addition, 4 when non-directory file is present).
4. **Observation**: `sovereign.ps1` fails with Exit Code `1` for all invalid or missing configuration files.
5. **Deduction**: In invalid config scenarios, error handling is currently split: missing file is caught at line 34, while malformed/missing fields trigger PowerShell StrictMode terminating exceptions prior to entering the `try/catch` block (line 51). In all cases, execution halts safely with exit code 1.

---

## 3. Caveats

- **Uninitialized `$LogDir` in Line 19**: In `Write-Log`, `$LogDir` is evaluated (`if ($LogDir)`). When `Write-Log` is called on line 34 (Config missing error), `$LogDir` has not yet been assigned (line 40). Under `Set-StrictMode -Version Latest`, checking an uninitialized variable emits a StrictMode warning on stderr before exiting.
- **Config Persistence**: `sovereign.ps1` updates `$Config.governance.skills_count` in `sovereign.config.json` when dynamic skill count changes, but does not persist dynamic module count to config (as no `modules_count` schema field exists).

---

## 4. Conclusion

- **Overall Status**: **PASSED ALL EMPIRICAL TESTS**.
- `sovereign.ps1` functions correctly as single-file orchestrator.
- Mutex lock `"Global\SovereignOSLock"` provides reliable OS-level mutual exclusion across process boundaries.
- Module directory counting is accurate and resilient to non-directory artifacts.
- Invalid config conditions reliably abort execution with Exit Code 1.

---

## 5. Verification Method

To re-verify independently, run the following test scripts from `C:\Skills`:

1. Baseline Execution:
   `powershell.exe -ExecutionPolicy Bypass -File C:\Skills\sovereign.ps1`
2. Mutex Contention Harness:
   `powershell.exe -ExecutionPolicy Bypass -File C:\Skills\.agents\teamwork_preview_challenger_m1\test_mutex.ps1`
3. Dynamic Module Count Test:
   `powershell.exe -ExecutionPolicy Bypass -File C:\Skills\.agents\teamwork_preview_challenger_m1\test_module_count.ps1`
4. Config Parsing Edge Case Harness:
   `powershell.exe -ExecutionPolicy Bypass -File C:\Skills\.agents\teamwork_preview_challenger_m1\test_config_parsing.ps1`

---

## Adversarial Review / Stress Test Summary

**Overall Risk Assessment**: LOW

### Challenges & Minor Findings

1. **[Low] Uninitialized `$LogDir` in `Write-Log` during early config failure**
   - **Scenario**: When `sovereign.config.json` is missing, `Write-Log` is called at line 34 before `$LogDir` is set at line 40.
   - **Blast Radius**: Exits with code 1 as intended, but emits `The variable '$LogDir' cannot be retrieved because it has not been set` to Stderr under StrictMode.
   - **Suggested Defense**: Initialize `$LogDir = $null` or move `try/catch` block to wrap initial config reading.

2. **[Low] Config parsing outside `try/catch` block**
   - **Scenario**: Malformed JSON or missing schema properties cause terminating PowerShell exceptions outside the explicit `try/catch` block.
   - **Blast Radius**: Exits with code 1 as intended, but bypasses `Write-Log "ERROR" "EXEC" ...` formatting.
   - **Suggested Defense**: Move lines 31-50 inside the `try` block.
