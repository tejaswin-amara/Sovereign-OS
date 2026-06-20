# CLOUD-NATIVE SKILLS (v13.2.0-CloudNative)
1. Read `sovereign.config.json` & `.agents/knowledge/harvested_skills.md`.
2. **Cloud-Native JIT Fetch**: Sovereign no longer relies on static local repositories. When you need a skill, framework, or documentation, dynamically mount it from GitHub using:
   `pwsh C:/Skills/agent-bootstrap/scripts/Fetch-CloudSkill.ps1 -Repo "org/repo"`
   *(Example: `pwsh C:/Skills/agent-bootstrap/scripts/Fetch-CloudSkill.ps1 -Repo "microsoft/SkillOpt"`)*
3. Check `C:\Skills\.cloud-cache\` for actively mounted skills. The cache is automatically garbage-collected on every `/sovereign` run.
4. @using-superpowers: Mount the required skill repository and load its `SKILL.md` or `README.md` before taking action.
5. **Internet Reach**: Agent-Reach gives the agent direct access to the internet.
   - Web: `curl https://r.jina.ai/{URL}` — reads any webpage as clean markdown
   - YouTube: `yt-dlp --write-sub --skip-download {URL}` — extract subtitles
   - GitHub: `gh repo view org/repo`, `gh search repos {query}`
   - Search: Exa MCP semantic search (free, no API key)
   - RSS: `agent-reach` feedparser
   - Health: `agent-reach doctor` to check channel status
   - Install: `pwsh C:/Skills/agent-bootstrap/scripts/Install-AgentReach.ps1`
