---
name: jules-agent
description: Delegates complex, background tasks to Jules by Google using the REST API for asynchronous, sandboxed PR generation.
---

# Jules Agent Integration

The `jules-agent` skill allows Sovereign OS to leverage **Jules by Google**, an autonomous AI coding agent, for large-scale or background repository tasks.

## When to use
Use this skill when you need to:
- Dispatch a complex refactoring task that should happen asynchronously.
- Generate a Pull Request for a bug fix or feature using an isolated sandbox.
- Perform repository-wide migrations that don't need immediate interactive feedback.

## How to use
To assign a task to Jules, execute the `Invoke-JulesSession.ps1` script located in `C:\Skills\agent-bootstrap\scripts\`.

```powershell
pwsh -File C:\Skills\agent-bootstrap\scripts\Invoke-JulesSession.ps1 -Prompt "Fix the bug in the login component" -Title "Login Bug Fix" -SourceContext "sources/github/username/repo"
```

### Parameters
- **Prompt**: (Mandatory) The detailed instruction for Jules.
- **Title**: (Optional) A title for the Jules session.
- **SourceContext**: (Optional) The target GitHub repository, typically in the format `sources/github/owner/repo`.

### Best Practices
- **Do not** wait for the task to finish synchronously. Jules runs asynchronously.
- Ensure the API key `JULES_API_KEY` is present in `C:\Skills\.env`.
- Use this strictly for tasks that fit the async/PR generation model.
