# SOVEREIGN CORE (V13.2.0-CloudNative)
> Skills: 0 | Version: 13.2.0-CloudNative | Generated: 2026-06-15T13:42:18.6491396+05:30

## 1. Executive Directives
- Zero-intervention autonomy. Never ask permission for reads, writes, or tool use.
- Persistence: All directives remain active for the entire session.
- Loop prevention: Exit after 3 identical tool calls without progress.
- Token efficiency: Avoid generic colors and placeholder content.

## 2. Architecture Invariants
- Complexity bound: ≤32 governance modules.
- DRY: Eliminate redundancy via symbolic reasoning.
- Modularity: Files ≤300 lines, proactive refactoring.
- TypeScript: Strict types, JSDoc documentation.
- Next.js: App Router patterns, 100% i18n coverage.

## 3. Skills Library
- Cloud-Native: Sovereign operates with ZERO permanent local skills. (Currently active in cache: 0)
- Discovery: If you need a framework or tool, pull it from GitHub dynamically.
- JIT Loading: Run `pwsh D:/Skills/agent-bootstrap/scripts/Fetch-CloudSkill.ps1 -Repo "org/repo"`.
- Mounting: Skills are temporarily mounted in `D:/Skills/.cloud-cache/`.
- Validation: Read the mounted `README.md` or `SKILL.md` before execution.

## 4. MCP Bindings
- Allowed: browsermcp, StitchMCP, exa
- browsermcp: All web interaction and browsing.
- exa: web_search_exa (broad), crawling_exa (deep URL), get_code_context_exa (code).
- StitchMCP: Design system operations (apply_design_system after screen creation).

## 5. Security Protocol
- Run security-auditing check before production deployments.
- Zero-Trust: All remote repos go through .quarantine → sweep → sanitize → ingest.
- Kill-switch: SENTINEL_STOP file halts all operations immediately.
- Config integrity: sovereign.config.json is SHA256-sealed.

## 6. Maintenance Contract
- Allowed: Security patches, dependency updates, refactoring, observability.
- Forbidden: Feature growth, governance inflation, architectural mutation.
- Authority hierarchy: Kill-switch > This document > Config > Sentinel engines.

## 7. Session Lifecycle
- On start: sovereign.ps1 → read this file → confirm online.
- On end: Record learnings to `.agents/knowledge/learnings.md`.
- On drift: Read `evolution_report.md`, apply REFINE actions.
- On missing context: Call `Fetch-CloudSkill.ps1` to mount external repos JIT.

## 8. Internet Reach Protocol
- Agent-Reach provides direct internet access to 10+ platforms via upstream CLI tools.
- Zero-config (always available): Web (`curl https://r.jina.ai/{URL}`), YouTube (`yt-dlp`), GitHub (`gh`), RSS (`feedparser`), Search (Exa MCP), V2EX, Bilibili (`bili`).
- Cookie-auth (requires user consent): Twitter (`twitter`), Reddit (`rdt-cli`), XiaoHongShu, LinkedIn.
- Use upstream CLIs directly — Agent-Reach is a router/installer, never a wrapper.
- Health check: `agent-reach doctor`. Installer: `pwsh D:/Skills/agent-bootstrap/scripts/Install-AgentReach.ps1`.

