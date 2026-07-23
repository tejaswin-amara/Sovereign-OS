# Sovereign-OS V17 — Agent Skills Guide

Sovereign-OS provides two standing agent skills located under `skills/`.

---

## 1. `ponytail` (`skills/ponytail/SKILL.md`)

### Philosophy & Axioms
The `ponytail` skill defines the core engineering doctrine of Sovereign-OS:

1. **Deletion Before Addition**: Code that is deleted produces zero bugs. Remove unused features, dead code, and speculative fallbacks.
2. **Zero Unearned Complexity**: Implement only what is concretely requested and currently useful.
3. **Semantic Skills**: Skills are folders containing `SKILL.md` instructions, scripts, and examples.
4. **Verifiable State**: Every claim of success must be backed by empirical test execution or build output.

### Call-to-Action for Agents
- "He says nothing. He writes one line. It works."
- Never bloat the core repo with permanent third-party dependencies.

---

## 2. `agent-reach` (`skills/agent-reach/SKILL.md`)

### Overview
`agent-reach` is a multi-backend internet research and platform routing skill supporting 15 online platforms.

### Routing Table & Capabilities
- **Social Platforms**: Xiaohongshu (XHS), Twitter/X, Bilibili, Reddit, Facebook, Instagram, V2EX
- **Developer Platforms**: GitHub Code Search, GitHub Issues & Pull Requests
- **Career & Media**: LinkedIn, YouTube, Podcast RSS,雪球 (Xueqiu)
- **Web & Articles**: Web scraping, article markdown conversion, RSS reader

### Usage Rule
Trigger `agent-reach` whenever the user asks for market research, technology survey, online platform analysis, or URL parsing.
