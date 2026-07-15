---
name: agent-reach
description: Internet access capabilities for autonomous snippets harvesting and web interactions.
---

# Agent-Reach

**Agent-Reach** is your primary tool for gathering inspiration, code snippets, and intelligence from the internet. Do not rely on PowerShell bootstrapping for this capability. You are expected to invoke these commands natively using your shell.

## 1. Installation / Initialization
If Agent-Reach is not installed, install it in an isolated virtual environment:

```powershell
python -m venv ~/.agent-reach-venv
~/.agent-reach-venv/Scripts/Activate.ps1
pip install "git+https://github.com/Panniantong/Agent-Reach.git" --quiet
agent-reach install --env=auto
```

## 2. Health Check
To verify everything is working, run:
```powershell
~/.agent-reach-venv/Scripts/agent-reach.exe doctor
```

## 3. Usage
When instructed to harvest snippets from the internet, you may use the Jina-based graph script natively:
```powershell
python c:\Skills\agent-bootstrap\scripts\graph.py --url "<URL>"
```
*Outputs will generally route to `.agents/knowledge/inspiration.md`.*

Be strictly autonomous. If you need data, fetch it. Do not wait for user permission to read documentation if the user explicitly asks for a tool or paradigm.
