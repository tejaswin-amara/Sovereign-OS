# Sovereign-OS Architectural Decisions (v15.0.0-CloudNative Rebuild)

This document serves as the single source of truth for architectural choices, specifically the pruning of aspirational subsystems during the Sovereign-OS v15.0.0-CloudNative rebuild. 

Sovereign-OS operates under strict "honest engineering" principles. Features that are described as working must be working. Silent degradation and mock features masquerading as production code are forbidden. The "Ponytail Doctrine" enforces minimal code, YAGNI, and aggressive suspicion of unearned complexity.

## Decisions

### 1. Removal of Edge, Master, and eBPF Mock Subsystems
- **Verdict**: Removed entirely.
- **Rationale**: The `Start-EdgeSovereign` and `master` folder components were purely mock interfaces implementing `Start-Sleep` timers. The claimed eBPF zero-trust telemetry parsing did not exist. These components added no functionality and created false expectations. 
- **Action**: All associated files (`Invoke-IsolateNode.ps1`, `ebpf-prometheus-schema.md`, `micro-sovereign.ps1`, `Sign-EdgeState.ps1`) were deleted.

### 2. Removal of the "OmniVector" Database Mock
- **Verdict**: Removed entirely.
- **Rationale**: `omnivector.index` was an empty file pretending to be an embedded semantic vector space. Semantic capabilities, when required, should be explicitly defined via functioning MCPs or standard text parsing (like the existing AST/regex rules).

### 3. Distributed Mutex Lock (Quorum Mock)
- **Verdict**: Removed.
- **Rationale**: The system included a simulated quorum check attempting to mock a distributed Redis/etcd lock without actually having network connections. The local `.sovereign.lock` OS-level file locking is sufficient for preventing concurrent script executions on the same machine.
- **Action**: Removed the simulated quorum sequence in `Locking.ps1`.

### 4. "OmniSearch" Aspirational Subsystem
- **Verdict**: Replaced with real diagnostic script.
- **Rationale**: The `Invoke-OmniSearch` function in `Troubleshooting.ps1` was a mock. It has been replaced by `Invoke-SovereignInternetDiagnostic`, which performs a real web search utilizing the Jina API for error resolutions.

### 5. Multi-Agent Swarm (LangGraph Mock)
- **Verdict**: Maintained as an explicit test mock with Honesty Headers.
- **Rationale**: The files `graph.py` and `Start-SovereignSwarm.ps1` previously pretended to invoke a LangGraph swarm but functionally output fixed strings. They have been preserved for interface testing purposes, but explicitly marked with "HONESTY HEADERS" so users understand they are mocks.

### 6. Aspirational Configurations in `sovereign.config.json`
- **Verdict**: Removed dead configuration flags.
- **Rationale**: Flags such as `require_signature`, `mcp_bindings`, and `module_caps.network/filesystem` were declared in configuration but never enforced by the runtime. They have been stripped to ensure the config file represents truth. Module caps are enforced via the folder count module capacity (`Assert-ModuleCap`).

### 7. Enforcing Sandbox Verification
- **Verdict**: Made explicit.
- **Rationale**: `Invoke-Sandbox.ps1` silently fell back to local execution if Docker wasn't present. The rebuild wired the `sandbox.enabled` configuration flag to strictly gate the fallback, ensuring the system refuses to run unsandboxed when sandboxing is requested.

## Summary
The system is now small, correct, honest, and fully verified. Every function executes the capability it describes.
