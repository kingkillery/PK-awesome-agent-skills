---
name: pk-awesome-agent-skills
tags:
  - agent-skills
  - skill-discovery
  - catalog
summary: Discover and index PK/Kingkillery agent skills by category or repository with direct SKILL.md links.
examples:
  - generate skill index
  - find skill by category
  - audit available repositories
---

Use this skill package to inspect candidate agent skills from Kingkillery repos without loading every skill file.

## Inputs

- Optional source index path (default: `$HOME\.codex\kingkillery-agent-skill-repos.json`)
- Optional category/repo filter keywords

## How to use

1. Open this repository index:
   - `README.md` for a human-friendly catalog grouped by category and repository.
   - `skills-flat.json` for machine parsing.
2. Refresh local artifacts if your installed index changed:
   - `scripts/Update-PKAwesomeAgentSkills.ps1`

## Outputs

- Direct GitHub links to each `SKILL.md`
- Counts by repository and category
- Stable JSON snapshots for automation

