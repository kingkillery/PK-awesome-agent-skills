# Skill Rating & Gap Improvement Workflow

This repository uses a repeatable pipeline to score skills, explain scores, and
surface gap candidates by skill type.

## 1) Score and categorize

`scripts/Grade-PKAwesomeSkills.ps1` computes:

- per-skill `score` in `10..100`
- `reasons` that explain why it scored that way
- `risk_flags` for remediation focus
- `skill_type` from 10 canonical categories

## 2) Output artifacts

Run:

```powershell
.\scripts\Grade-PKAwesomeSkills.ps1
```

- `skill-ratings.json`: all scores and explanations
- `skill-rating-summary.json`: category totals and averages
- `skill-rankings-by-category.md`: top skills + scoring rationale per category
- `skill-gap-analysis.md`: weakest skills per category, ready for improvements

## 3) Neutral local reviewer for agents

CLI agents should call:

```powershell
pwsh .\scripts\Run-PKAwesomeLocalSkillReview.ps1 -AsJson -TopN 20 -GapBottomPercent 10
```

This is the neutral scoring entrypoint for local agent workflows:

- Deterministic: same inputs produce same ranking
- Parseable: emit JSON session payload for automation
- Fast: optional `-SkipRegrade` for already refreshed artifacts

Output:

- `local-skill-review-session.json` includes:
  - `type_summaries`
  - `top_by_type`
  - `gap_by_type`
  - `recommended_next_moves`

## 4) CI/CD scoring loop

GitHub Actions workflow `.github/workflows/skill-rating-pipeline.yml` runs:

- refresh catalog (`Update-PKAwesomeAgentSkills.ps1`)
- rebuild README (`Generate-PKAwesomeReadme.ps1`)
- re-grade (`Grade-PKAwesomeSkills.ps1`)
- local agent review packaging (`Run-PKAwesomeLocalSkillReview.ps1`)

It uploads report artifacts and commits them on `master` when they change.

## 5) Use as ranking signal

Use this as the improvement order:

1. Sort by lowest score in `skill-gap-analysis.md`
2. Fix low-priority gaps first:
   - unclear naming
   - non-standard path/file conventions
   - weak discoverability tokens
3. Re-run grader and compare:
   - score delta per skill
   - category average shifts in `skill-rating-summary.json`

## 6) PR hygiene

- Keep `scripts/Grade-PKAwesomeSkills.ps1` as the single source of truth for scoring.
- If scoring semantics change, update both grading logic and docs together.
- Commit generated artifacts with source changes so review has complete context.
