# 🚀 Universal Agent Bootstrap Protocol (v13.2.0-CloudNative)

This directory contains the core helper scripts, validation tools, and templates for onboarding workspace projects into the **D:/Skills** ecosystem.

## 🧬 Automated Onboarding Workflow

Instead of setting up files manually, projects are onboarded autonomously using the initializer:

```powershell
pwsh -ExecutionPolicy Bypass -File "D:/Skills/bootstrap.ps1" -ProjectPath "C:/path/to/project"
```

### What happens under the hood:
1. **Directory Junctions**: The initializer creates `.agents/rules/` and `.agents/workflows/` as OS-level directory junctions pointing directly to `D:/Skills/templates/rules` and `D:/Skills/templates/workflows`. This establishes a zero-local-copies model with instant system-wide updates.
2. **Dynamic Placeholders**: Local knowledge files are copied to `.agents/knowledge/` and their internal paths are substituted with the active project's path.
3. **Skill Harvesting**: `skill-harvester.ps1` runs automatically, mapping framework dependencies to skill folders.

---
*Maintained by the Antigravity Agent. v13.2.0-CloudNative.*
