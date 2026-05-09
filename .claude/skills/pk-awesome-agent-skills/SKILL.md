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

Use this package as a reference catalog of candidate agent skills from Kingkillery repos.

- `README.md`: categorized + per-repo listing with direct links to every `SKILL.md`.
- `skills-flat.json`: parseable list of all skills.
- `catalog.json`: flattened index with URL/path metadata.
- `scripts/Update-PKAwesomeAgentSkills.ps1`: refresh snapshots from your local `$HOME\.codex\kingkillery-agent-skill-repos.json`.

