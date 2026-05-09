## PK Awesome Agent Skills — Skill Package

This repository is a generated catalog of candidate agent skills sourced from
`$HOME\.codex\kingkillery-agent-skill-repos.json`.

### What’s included

- `catalog.json` — flat skill inventory (`{"repo","skill","path","url"}`-style entries)
- `skills-flat.json` — normalized copy with one row per `SKILL.md`
- `README.md` — human-friendly catalog with:
  - repository inventory
  - skills by category
  - skills by repository
  - direct links to every `SKILL.md`
- `scripts/` — helper scripts to refresh the generated artifacts

### Regenerate the catalog

```powershell
cd C:\dev\desktop-projects\pk-awesome-agent-skills
.\scripts\Update-PKAwesomeAgentSkills.ps1
```

Default data source is `$HOME\.codex\kingkillery-agent-skill-repos.json`.

### Intended use

Use this repo as a reference index when wiring agent skill workflows in Codex/Claude Code.
The links go directly to upstream GitHub `SKILL.md` files and are grouped both by
category and repository for quick navigation.

