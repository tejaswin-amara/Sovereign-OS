## Describe the changes
A clear and concise description of what the PR accomplishes and why it's necessary.

## Sovereign Architecture Verification
- [ ] I have read the `CONTRIBUTING.md` guidelines.
- [ ] I have run `pwsh -ExecutionPolicy Bypass -File "sovereign-check.ps1"` and received **0 vulnerabilities**.
- [ ] I have run the Pester suite (`Invoke-Pester -Path "agent-bootstrap/tests"`) and achieved **23/23 Passes**.
- [ ] My code adheres to `Set-StrictMode -Version Latest`.

## Type of change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Cloud-Native Skill Addition (Adding a new JIT framework)
