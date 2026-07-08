# Contributing to Sovereign OS

Thank you for your interest in making Sovereign OS the absolute best Cloud-Native Agent environment!

## Adding New Cloud-Native Skills
Sovereign operates on a JIT (Just-In-Time) cloud architecture. Do **not** submit Pull Requests containing massive third-party library wrappers. 
If you want to add a new core capability, follow these steps:
1. Ensure the capability can be fetched dynamically via `Fetch-CloudSkill.ps1`.
2. Add the tool to the recommended ultimate stack in `README.md`.
3. Provide an open-source GitHub repository URL that represents the tool.

## Running Diagnostics (Pester)
Before submitting a PR, you **must** run the local Pester verification suite to ensure the system is completely free of drift:
```powershell
Invoke-Pester -Path "agent-bootstrap/tests"
```
Ensure all tests pass with exactly 0 failures.

## Security Sweeps
We take zero-trust security seriously. Ensure your code does not violate the AST module cap or break the atomic Mutex locks. Run:
```powershell
pwsh -ExecutionPolicy Bypass -File "sovereign-check.ps1"
```
This will perform an AST sweep over the entire framework to ensure 0 vulnerabilities.

## Submitting a PR
1. Use the provided Pull Request template.
2. Ensure you have tested your scripts in a strict PowerShell 7 environment (`Set-StrictMode -Version Latest`).
3. Your code will be rejected if it introduces context drift or redundant architectures.
