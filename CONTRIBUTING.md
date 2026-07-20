# Contributing to Sovereign OS

Thank you for your interest in making Sovereign OS the absolute best Cloud-Native Agent environment!

## Adding New Skills
Sovereign operates on a core Ponytail philosophy (minimalism and unearned complexity avoidance). Do **not** submit Pull Requests containing massive third-party library wrappers or complex dependencies. 

If you want to add a new core capability:
1. Ensure the capability can be run without installing third-party frameworks.
2. The logic should be semantic (in a `SKILL.md`) rather than procedural shell scripts.
3. Add the tool to the recommended ultimate stack in `README.md`.

## Verifying Changes
Before submitting a PR, you **must** run the local Sovereign controller to ensure the system starts up correctly and acquires the mutex lock:
```powershell
pwsh -ExecutionPolicy Bypass -File "sovereign.ps1"
```
Ensure it completes with all phases passed.

## Submitting a PR
1. Use the provided Pull Request template.
2. All code must pass PR Gating via the `no-mistakes` module (`git push no-mistakes main`).
3. Your code will be rejected if it introduces context drift or redundant architectures.
