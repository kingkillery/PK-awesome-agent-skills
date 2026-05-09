---
name: pk-awesome-agent-skills-reviewer
tags:
  - local-evaluator
  - skill-quality
  - score
summary: Run a local, deterministic skill rating pass and return review artifacts.
examples:
  - score all skills and export machine-readable review session
  - get category gap candidates for improvement planning
  - produce neutral scoring evidence for any CLI agent runbook
---

This is a local, neutral review skill for PK Awesome Agent Skills.

Use this when an agent or maintainer wants objective scoring outside of the
agent's own judgment.

Execution:

```powershell
.\pk-awesome-review.cmd -AsJson
```

Or via npm CLI:

```powershell
npm exec -- pk-awesome-review -AsJson
```

Useful args:

- `-TopN` adjust how many top entries to keep per type.
- `-GapBottomPercent` adjust what percentage counts as a gap set.
- `-OutputDir` set output folder for generated artifacts.
- `-SkipRegrade` assume existing artifacts are already current.

CLI output contract:

- `local-skill-review-session.json` is the default machine-readable artifact.
- Includes:
  - `type_summaries`
  - `top_by_type`
  - `gap_by_type`
  - `recommended_next_moves`
