# AUDIT_LEDGER.md — Sovereign-OS Rebuild Ground Truth

**Created:** 2026-07-07 (Phase 0 of the Rebuild)
**Baseline:** `main` @ commit `7d8788e` (61 commits)
**Test baseline:** 40 `It` blocks across 4 files, all passing. CI runs only `Helpers.Tests.ps1`.
**Diagnostic baseline:** `sovereign-check.ps1` → 0 failures (harvest stale warning only).

> **Methodology:** Every row below was verified by reading the live source at `C:/Skills` on 2026-07-07, not from the audit document. Where the audit document and the live source disagree, the live source wins and the discrepancy is noted.

---

## Capability Status Matrix

| # | Capability | Status | File(s) | Verified Evidence | Disposition |
|---|-----------|--------|---------|-------------------|-------------|
| C01 | Master 7-phase pipeline | ✅ REAL | `sovereign.ps1` | 302 lines, all phases execute | Keep as-is |
| C02 | Cross-process file locking | ✅ REAL | `Locking.ps1` | FileStream exclusive lock, unit-tested incl. concurrency | Keep (D8: preserve) |
| C03 | JSON-lines audit logging + rotation | ✅ REAL | `Logging.ps1` | Batched writer, age/size rotation, unit-tested | Fix: D10 cross-platform |
| C04 | Log path sanitization | 🟡 PARTIAL | `Logging.ps1`, `OmniSearch.ps1`, `Troubleshooting.ps1` | Sanitization works for `Write-SovereignLog` but `Invoke-OmniSearch` (catch block) bypasses it | Fix: wire sanitized version |
| C05 | Config integrity checksum | 🟡 PARTIAL | `Checksum.ps1`, `Configuration.ps1` | Write-side has cross-platform guard; read-side does NOT | Fix: D4, D5 |
| C06 | Dependency harvesting (6 langs) | ✅ REAL | `skill-harvester.ps1`, `harvesters/*.ps1` | Genuine parsing, unit-tested with realistic fixtures | Keep (D15: remove dead param) |
| C07 | Skill-gap auto-fetch | ✅ REAL | `Evolution.ps1` | Real cross-reference + real Fetch-CloudSkill calls | Fix: D7 merge dep maps |
| C08 | JIT cloud skill fetching | ✅ REAL | `Fetch-CloudSkill.ps1` | Hardened git clone with `-c protocol.file.allow=never` | Keep as-is (D8: preserve) |
| C09 | AST-based PowerShell security scan | ✅ REAL | `security-sweep.ps1` | Genuine `System.Management.Automation.Language.Parser` | Keep as-is (D8: preserve) |
| C10 | JS/TS security scan | 🟡 PARTIAL | `security-sweep.ps1` | Regex-based (not AST), WARN-only on unwhitelisted imports | Keep (honest in docs) |
| C11 | Self-evolution / drift detection | ✅ REAL | `Evolution.ps1` | Real keyword matching + auto-append to rules.md | Keep as-is |
| C12 | Turbovec semantic indexing | 🟡 PARTIAL | `Evolution.ps1` | Real invocation of external tool, contingent on JIT-fetch | Keep (honest in docs) |
| C13 | Docker container definitions | ✅ REAL (infra) | `Dockerfile`, `docker-compose.yml` | Buildable; Ollama wired but never called | Fix: document honestly |
| C14 | E2B sandbox | 🟠 SILENT DEGRADE | `Invoke-E2BSandbox.ps1` | Falls back to unsandboxed exec() silently | Fix: wire sandbox.enabled |
| C15 | LangGraph swarm | 🟡 STUB BODIES | `graph.py`, `Start-SovereignSwarm.ps1` | Real StateGraph, stub node bodies | Fix: add honest header |
| C16 | Pre-commit ponytail hook | 🟠 STUB | `pre-commit-ponytail.ps1` | Filename-pattern regex only | Keep (honest in docs) |
| C17 | Jules integration | ❌ DELETED | `Install-JulesCLI.ps1`, `Invoke-JulesSession.ps1`, `Start-JulesWebhookListener.ps1`, `Wait-JulesSession.ps1` | Deleted in v15 sterilization | Keep deleted |
| C18 | NTFS junction sharing | ✅ REAL (Win) / 🟡 DEGRADED (other) | `bootstrap.ps1` | Junction on Windows, static copy on Linux | Fix: add symlink path |
| C19 | Vendored Ponytail skills | ✅ REAL | `skills/ponytail*/SKILL.md` | Unmodified upstream, MIT | Keep as-is |
| C20 | Winget dependency update | ✅ REAL (Win) | `sovereign.ps1` Phase 6.5 | Graceful WARN on non-Windows | Keep as-is |

### Capabilities Confirmed Deleted Since Audit

| # | Capability | Audit Status | Current Status | Evidence |
|---|-----------|-------------|---------------|----------|
| X01 | Algorand blockchain audit trail | 🟠 MOCKED | ❌ DELETED | `edge/` dir no longer exists |
| X02 | ZK-SNARK attestation | ⚪ DOC-ONLY | ❌ DELETED | `zk-payload-schema.md` gone |
| X03 | eBPF/XDP firewall | ⚪ DOC-ONLY | ❌ DELETED | `ebpf-prometheus-schema.md` gone |
| X04 | Threat isolation protocol | 🟠 3/4 MOCKED | ❌ DELETED | `master/` dir no longer exists |
| X05 | Micro-sovereign WASM edge | 🟠 DESCRIPTIVE | ❌ DELETED | `edge/micro-sovereign.ps1` gone |
| X06 | Async sandbox | 🟠 MOCKED | ❌ DELETED | `Invoke-AsyncSandbox.ps1` gone |
| X07 | Async data ingestion | 🟠 MOCKED | ❌ DELETED | `Receive-AsyncData.ps1` gone |
| X08 | SQLite telemetry | 🟡 BROKEN | ❌ DELETED | `Log-SovereignTelemetry.ps1` gone; ponytail comment in sovereign.ps1:296 |

---

## Defect Status Matrix

| ID | Defect | Audit Status | Verified Live Status | Target Phase | Fix Plan |
|----|--------|-------------|---------------------|-------------|----------|
| D1 | `Write-Information -ForegroundColor` (41 calls, 3 files) | ❌ Present | ✅ Resolved (Replaced with Write-Host) | Phase 1 | Replace with `Write-Host` |
| D2 | `Log-SovereignTelemetry.ps1` undefined `$InsertSql` | ❌ Present | ✅ Resolved by deletion | — | No action needed |
| D3 | `Install-AgentReach.ps1` placeholder hash | ❌ Present | ✅ Resolved (Graceful fallback added) | Phase 1 | Add exit-code check, conditional success msg |
| D4 | `Configuration.ps1` read-side no cross-platform guard | ❌ Present | ✅ Resolved (Cross-platform DPAPI guard added) | Phase 3 | Add `$IsWindows` guard matching Checksum.ps1 |
| D5 | `.config.sha256` machine-bound | ❌ Present | ✅ Resolved (Removed from tracking) | Phase 3 | Remove from tracking, TOFU-only |
| D6 | `Invoke-OmniSearch` unsanitized error egress | ❌ Present | ✅ Resolved (Wired diagnostic) | Phase 4 | Wire `Invoke-SovereignInternetDiagnostic` |
| D7 | Two unsynced dep→repo maps | ❌ Present (114 vs 41) | ✅ Resolved (Evolution.ps1 merged to config) | Phase 2 | Merge Evolution.ps1's `$TagToSkill` into config |
| D8 | `Invoke-E2BSandbox.ps1` silent fallback | ❌ Present | ✅ Resolved (Wired `sandbox.enabled`, default true. Grep confirmed.) | Phase 4 | Wire `sandbox.enabled`, add `-AllowUnsandboxed` |
| D9 | Template contamination + spreading | ❌ Present | ✅ Resolved (Decontaminated) | Phase 6 | Decontaminate learnings.md and rules.md |
| D10 | `$env:USERPROFILE` crash on Linux | ❌ Present | ✅ Resolved (Cross-repo `grep -rn "\$env:USERPROFILE"` confirms 0 unhandled instances. Files updated with fallback) | Phase 3 | Add `$env:HOME` fallback with null guard |
| D11 | Stale `AGENT_DNA.md` in skills-map-template.md | ❌ Present | ✅ Resolved (Updated reference) | Phase 1 | Update reference |
| D12 | Hard-coded "23/23" test count | ❌ Present | ✅ Resolved (Dynamic checking) | Phase 1 | Replace with dynamic instruction |
| D13 | Dead config flags | ❌ Present | ✅ Resolved (Pruned `multi_tenant`, restored `mcp_bindings` as advisory. Grep confirmed no orphans) | Phase 4 | Delete or wire each one |
| D14 | Orphaned gitlinks under core-frameworks/ | ❌ Present | ✅ Resolved (`git rm --cached` executed on aider, browser-use, crewAI, langgraph, reader) | Phase 2 | Verify and clean |
| D15 | Dead `-SyncLibrary` parameter | ❌ Present | ✅ Resolved (Parameter removed) | Phase 2 | Remove param and call-site args |
| D16 | Inline module-cap reimplementation in bootstrap.ps1 | ❌ Present | ✅ Resolved (Wired to shared helper) | Phase 2 | Call shared `Assert-ModuleCap` |
| D17 | Hard-coded `C:\Skills` paths (50+ locations) | ❌ Present | ✅ Resolved (Normalized and documented) | Accept (deployment-specific per Q3) | Document expectation |
| D18 | `run_e2e_tests.ps1` targets nonexistent dir | ❌ Present | ✅ Resolved (Deleted) | Phase 5 | Repoint or delete |
| D19 | Stale `ROADMAP.md` item 4 | ❌ Present | ✅ Resolved (Rewritten) | Phase 6 | Update/rewrite |
| D20 | CI runs only 1 of 4 test files | ❌ Present | ✅ Resolved (Matrix expanded) | Phase 5 | Expand to all tests + matrix |
| D21 | `skill-harvester.ps1` `-SyncLibrary` passed by callers | ❌ Present | ✅ Resolved (Removed) | Phase 2 | Remove from sovereign.ps1 + bootstrap.ps1 |
| D22 | Mock quorum check in Locking.ps1 | ❌ Present | ✅ Resolved (Removed mock) | Phase 4 | Remove mock |
| D23 | `helpers.psm1` export list incomplete/undocumented | ❌ Present | ✅ Resolved (Documented public API) | Phase 2 | Document public API |

---

## Audit Document Accuracy Notes

The audit document (`Sovereign-OS_Complete_Documentation_for_Qwen3-Coder.md`) was written against a prior snapshot. Key inaccuracies vs. current live source:

1. **File deletions not reflected:** 8 files/directories deleted since audit (edge/, master/, async mocks, telemetry, omnivector.index)
2. **Partial fixes applied:** `Checksum.ps1` already has cross-platform guard (audit says it doesn't on `main`)
3. **New files not covered:** `.env`, `test_report.md` (Jules scripts were deleted)
4. **dep_to_skill_map count:** Audit says 114, current is ~82 (reduced)
5. **Test count:** Audit says 39 `It` blocks, current is 40
6. **audit-improvements branch:** Audit says it exists unmerged; it has been deleted (some fixes cherry-picked)
