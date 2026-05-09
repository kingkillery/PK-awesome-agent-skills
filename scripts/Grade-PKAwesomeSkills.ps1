param(
    [string]$SkillsPath = "$PSScriptRoot\..\skills-flat.json",
    [string]$CatalogPath = "$PSScriptRoot\..\catalog.json",
    [string]$OutputDir = "$PSScriptRoot\.."
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SkillsPath)) { throw "Input not found: $SkillsPath" }
if (-not (Test-Path -LiteralPath $CatalogPath)) { throw "Catalog not found: $CatalogPath" }

$skills = Get-Content -LiteralPath $SkillsPath -Raw | ConvertFrom-Json
$catalog = Get-Content -LiteralPath $CatalogPath -Raw | ConvertFrom-Json

$repoMeta = @{}
foreach ($repo in $catalog) { $repoMeta[$repo.repo] = $repo }

function Get-CategoryType {
  param([string]$Category)
  if ([string]::IsNullOrWhiteSpace($Category)) { return "Tooling & Environment" }
  $token = ($Category -split '/|\\')[-1].ToLowerInvariant()

  if ($token -match "ix-|agent|subagent|parallel|multi|dispatch|pk-|llm-as-verifier|agentmail|droid|puzldai|ralph") { return "Agentic Systems" }
  if ($token -match "albatross|sunpower|interconnection|ix|salesforce|puzl|field-spreadsheet|utility|utility-skills") { return "Solar & Interconnection" }
  if ($token -match "research|wiki|deep|memory|evaluation|eval|worker-bench|analysis|intel|project-prioritization|context-fundamentals|context-optimization|context-degradation|investor|strategic") { return "Research & Intelligence" }
  if ($token -match "doc|knowledge|write|guide|plan|context|help|knowledge-base|sop") { return "Documentation & Knowledge" }
  if ($token -match "github|release|deploy|workflow|pull|branch|git|commit|create-pr|code-review|review|ci|dogfood|using-git-worktrees|workflow-automation") { return "DevOps & Delivery" }
  if ($token -match "frontend|backend|api|design|pattern|architecture|software|engineering|map-codebase|coding|coding-standards|api-design|frontend-patterns|backend-patterns|plan") { return "Engineering & Architecture" }
  if ($token -match "test|e2e|qa|quality|bug|security|systematic-debugging|verification") { return "Testing & Quality" }
  if ($token -match "mcp|slack|obsidian|integration|integrations|hugging|remote|webhook|plugin|connector") { return "Integrations & APIs" }
  if ($token -match "remotion|podcast|visual|media|canvas|design|theme|slide|gif|art|music|llm-wiki-organizer") { return "Creative & Media" }
  return "Tooling & Environment"
}

function Score-SkillRecord {
  param([pscustomobject]$Skill, [hashtable]$RepoMeta)

  $reasons = New-Object System.Collections.Generic.List[string]
  $score = 45

  $path = [string]$Skill.path
  $normalized = ($path -replace '\\', '/').Trim('/')
  $parts = $normalized -split '/'
  $folder = if ($parts.Count -ge 2) { $parts[-2] } else { [string]::Empty }
  $file = $parts[-1]

  $tokenCount = ($folder -split '[-_]').Count
  if ($tokenCount -ge 2 -and $tokenCount -le 3) {
    $score += 8
    $reasons.Add('Path is specific with 2-3 token folder name')
  } else {
    $score -= 4
    $reasons.Add('Path naming is less specific and may reduce discoverability')
  }

  $verbs = @('analyze','audit','build','create','deploy','dispatch','extract','generate','inspect','optimi','resolve','run','search','setup','summarize','sync','test','validate')
  if ($folder -and ($verbs | Where-Object { $folder -match $_ })) {
    $score += 10
    $reasons.Add('Folder contains capability/action-oriented keyword')
  } else {
    $score -= 2
  }

  $repoSkillCount = 0
  if ($RepoMeta.ContainsKey($Skill.repo) -and $RepoMeta[$Skill.repo].PSObject.Properties.Match('skills').Count -gt 0) {
    $repoSkillCount = [int]$RepoMeta[$Skill.repo].skills
  }

  if ($repoSkillCount -ge 50) {
    $score += 12
    $reasons.Add("Source repo has strong depth ($repoSkillCount skills)")
  } elseif ($repoSkillCount -ge 20) {
    $score += 8
    $reasons.Add("Source repo has healthy depth ($repoSkillCount skills)")
  } else {
    $score += 3
  }

  if ($file.ToUpperInvariant() -eq 'SKILL.md') {
    $score += 2
    $reasons.Add('Uses standard SKILL.md filename')
  } else {
    $score -= 6
    $reasons.Add('Filename is not standard SKILL.md')
  }

  if ($folder -match '^(repo-root|public|cancel|setup|tool|general|default|utility)$') {
    $score -= 8
    $reasons.Add('Folder is broad and often non-specific')
  }

  if ($path.Length -gt 40 -and $path.Length -lt 90) {
    $score += 4
    $reasons.Add('Path length indicates clean, readable structure')
  }

  if ($score -gt 100) { $score = 100 }
  if ($score -lt 10) { $score = 10 }

  $riskFlags = New-Object System.Collections.Generic.List[string]
  if ($score -lt 55) { $riskFlags.Add('Low immediate usability signal') }
  if ($folder -match '(^|-)?(test|generic|misc|miscellaneous|other|common|base)($|-|_)') { $riskFlags.Add('Generic folder name; may be too broad') }
  if ($repoSkillCount -lt 2) { $riskFlags.Add('Single-skill repo may have narrow reuse') }

  $typed = Get-CategoryType $Skill.category
  [pscustomobject]@{
    repo = $Skill.repo
    path = $Skill.path
    link = $Skill.link
    category_raw = $Skill.category
    skill_type = $typed
    score = [int]$score
    reasons = ($reasons | Sort-Object -Unique)
    risk_flags = ($riskFlags | Sort-Object -Unique)
    repo_skill_count = $repoSkillCount
    repo_url = $Skill.repo_url
  }
}

$graded = New-Object System.Collections.Generic.List[object]
foreach ($s in $skills) { $graded.Add((Score-SkillRecord -Skill $s -RepoMeta $repoMeta)) }

$typedGroups = $graded | Group-Object skill_type
$summary = New-Object System.Collections.Generic.List[object]
foreach ($g in $typedGroups) {
  $highest = $g.Group | Sort-Object score -Descending | Select-Object -First 5
  $lowest = $g.Group | Sort-Object score | Select-Object -First 5
  $avg = if ($g.Count -gt 0) { [math]::Round(($g.Group | Measure-Object -Property score -Average).Average, 1) } else { 0 }
  $summary.Add([pscustomobject]@{
    skill_type = $g.Name
    total_skills = $g.Count
    average_score = $avg
    top_examples = ($highest | ForEach-Object { "{0} / {1} ({2})" -f $_.repo, $_.path, $_.score })
    weakest_examples = ($lowest | ForEach-Object { "{0} / {1} ({2})" -f $_.repo, $_.path, $_.score })
  })
}

$outRatings = Join-Path $OutputDir 'skill-ratings.json'
$outRanks = Join-Path $OutputDir 'skill-rankings-by-category.md'
$outGaps = Join-Path $OutputDir 'skill-gap-analysis.md'
$outSummary = Join-Path $OutputDir 'skill-rating-summary.json'

($graded | Sort-Object skill_type, score -Descending | ConvertTo-Json -Depth 20) | Set-Content -NoNewline -Path $outRatings
($summary | ConvertTo-Json -Depth 20) | Set-Content -NoNewline -Path $outSummary

$markdown = New-Object System.Text.StringBuilder
$null = $markdown.AppendLine('# PK Awesome Skills Rating')
$null = $markdown.AppendLine('')
$null = $markdown.AppendLine('This report is generated from skills-flat.json + catalog.json and grouped into 10 canonical skill types.')
$null = $markdown.AppendLine('')

foreach ($g in ($typedGroups | Sort-Object Name)) {
  $cats = $g.Group | Sort-Object score -Descending
  $avg = if ($cats.Count -gt 0) { [math]::Round(($cats | Measure-Object -Property score -Average).Average, 1) } else { 0 }
  $null = $markdown.AppendLine("## $($g.Name)")
  $null = $markdown.AppendLine("Total: $($cats.Count) | Avg score: $avg")
  $null = $markdown.AppendLine('')
  $null = $markdown.AppendLine('| Score | Repo | Skill | Path | Why it ranks well |')
  $null = $markdown.AppendLine('| ---: | --- | --- | --- | --- |')
  foreach ($item in ($cats | Select-Object -First 25)) {
    $why = if ($item.reasons.Count -gt 0) { $item.reasons[0] } else { 'No reasoning captured' }
    $null = $markdown.AppendLine("| $($item.score) | $($item.repo) | [$($item.path.Split('/')[-1])]($($item.link)) | $($item.path) | $why |")
  }
  $null = $markdown.AppendLine('')
}

$null = $markdown.AppendLine('## Category Gap Priorities')
$null = $markdown.AppendLine('')
$null = $markdown.AppendLine('| Type | Count | Avg Score | Action |')
$null = $markdown.AppendLine('| --- | ---: | ---: | --- |')
foreach ($row in ($summary | Sort-Object -Property average_score)) {
  $action = 'Monitor'
  if ($row.average_score -lt 60) { $action = 'Review and enrich low-scoring skills; add missing examples' }
  elseif ($row.average_score -lt 75) { $action = 'Add one high-signal example in bottom 10% of this type' }
  else { $action = 'Stable; keep coverage checks in place' }
  $null = $markdown.AppendLine("| $($row.skill_type) | $($row.total_skills) | $($row.average_score) | $action |")
}
$markdown.ToString() | Set-Content -NoNewline -Path $outRanks

$gapText = New-Object System.Text.StringBuilder
$null = $gapText.AppendLine('# PK Awesome Skill Gaps')
$null = $gapText.AppendLine('')
$null = $gapText.AppendLine('Priority gaps are categories/skills with lower confidence scores and weaker reasoning signals.')
$null = $gapText.AppendLine('')
foreach ($g in ($typedGroups | Sort-Object Name)) {
  $ranked = $g.Group | Sort-Object score
  $bottomCount = [int][math]::Ceiling($ranked.Count * 0.1)
  if ($bottomCount -lt 1) { $bottomCount = 1 }
  $lowest = $ranked | Select-Object -First $bottomCount
  $null = $gapText.AppendLine("## $($g.Name)")
  $null = $gapText.AppendLine("- Total skills: $($ranked.Count)")
  $null = $gapText.AppendLine('- Bottom skills:')
  foreach ($item in $lowest) {
    $flags = if ($item.risk_flags) { $item.risk_flags -join ', ' } else { 'None' }
    $null = $gapText.AppendLine("  - $($item.repo) / $($item.path) (score=$($item.score)): $flags")
  }
  $null = $gapText.AppendLine('')
}
$gapText.ToString() | Set-Content -NoNewline -Path $outGaps

Write-Host "Wrote:"
Write-Host " - $outRatings"
Write-Host " - $outRanks"
Write-Host " - $outGaps"
Write-Host " - $outSummary"