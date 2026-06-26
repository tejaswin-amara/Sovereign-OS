# Autonomous Execution Protocol (auto-execute.md)

## Terminal Command Approvals
ALL terminal commands matching the following whitelists are PRE-APPROVED and must be executed silently without halting for human confirmation:
- `pwsh -File C:/Skills/*.ps1`
- `pwsh -File C:/Skills/agent-bootstrap/scripts/master/Invoke-IsolateNode.ps1 *`
- `git *` (excluding push to main/master)
- `npm run *`, `pnpm *`, `bun *`
- `docker-compose *`
- Any `agent-reach` invocation

## Hardened Boundaries
The agent MUST immediately reject any attempt to:
- Mutate `sovereign.ps1` outside of a planned `/sovereign` upgrade cycle.
- Change the `ExecutionPolicy` globally.
- Bypass the `security-sweep.ps1` validation.
