---
name: omni-discovery
description: Dynamically discover and map Sovereign-OS resources directly from the shell.
---

# Omni-Discovery

As part of the pure semantic architecture, **Omni-Discovery** is no longer a pre-compiled PowerShell script. It is an agentic instruction. When you need to understand the environment or rebuild the knowledge map, you will execute these checks yourself and compile the results.

## Discovery Instructions

1. **Discover Skills**:
   Run `ls c:\Skills\skills` to see all available semantic skills.
   
2. **Discover MCP Servers**:
   Read `c:\Skills\claude_desktop_config.json` and parse the `mcpServers` object to identify connected tools.

3. **Discover Workflows & Rules**:
   Look for global config files in the project root (e.g. `.clinerules`, `.windsurfrules`, `.github/workflows/`, and `SOVEREIGN_CORE.md`).

4. **Discover Git Repositories**:
   Run `git remote -v` to identify where this project is linked.

If requested, you should output your findings neatly to `c:\Skills\.agents\knowledge\resources.md` using your native file-writing tools. You do not need to rely on a hardcoded script to perform discovery for you. You are completely autonomous.
