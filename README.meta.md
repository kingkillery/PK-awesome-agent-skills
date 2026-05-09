## PK Awesome Agent Skills - Skill Package

This repository is a generated catalog of candidate agent skills sourced from
`$HOME\.codex\kingkillery-agent-skill-repos.json`.

### What's included

- `catalog.json` - flat skill inventory (`{"repo","skill","path","url"}`-style entries)
- `skills-flat.json` - normalized copy with one row per `SKILL.md`
- `README.md` - human-friendly catalog with:
  - repository inventory
  - skills by category
  - skills by repository
  - direct links to every `SKILL.md`
- `scripts/` - helper scripts to refresh generated artifacts

### Regenerate the catalog

```powershell
cd C:\dev\desktop-projects\pk-awesome-agent-skills
.\scripts\Update-PKAwesomeAgentSkills.ps1
```

Default data source is `$HOME\.codex\kingkillery-agent-skill-repos.json`.

### Intended use

- Use this repo as a reference index when wiring agent skill workflows in
  Codex/Claude Code.
- The links go directly to upstream GitHub `SKILL.md` files and are grouped both
  by category and repository for quick navigation.

### Rating pipeline

To keep the catalog improving over time, we now generate usefulness scores and
gap signals for each skill in the catalog:

- `skill-ratings.json` - every skill with score + reasoning + risk flags
- `skill-rating-summary.json` - per-type score summary
- `skill-rankings-by-category.md` - human-readable ranking by category
- `skill-gap-analysis.md` - bottom performers and gap candidates by category

Run locally:

```powershell
.\scripts\Update-PKAwesomeAgentSkills.ps1
.\scripts\Generate-PKAwesomeReadme.ps1
.\scripts\Grade-PKAwesomeSkills.ps1
```

Read the score artifacts to:
- prioritize low-scoring skills
- fix naming/actionability issues in weak areas
- add evidence/references for low-signal skills

### Local neutral reviewer

For any CLI coding agent (Codex, Claude, or any runner), use:

```powershell
pwsh .\scripts\Run-PKAwesomeLocalSkillReview.ps1 -AsJson
```

The default output is a single machine-readable contract:
`local-skill-review-session.json` with:

- overall score distribution
- top skills per type
- gap candidates per type
- recommended next moves

See [Skill rating and gap workflow](skill-rating-and-gap-workflow.md) for the full review model and an iterative improvement loop.
