param(
    [string]$InputPath = "$PSScriptRoot\..\skills-flat.json",
    [string]$OutputPath = "$PSScriptRoot\..\README.md"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $InputPath)) {
  throw "Input file not found: $InputPath"
}

$skills = Get-Content -LiteralPath $InputPath -Raw | ConvertFrom-Json
if (-not $skills) {
  throw "No skill records found in $InputPath"
}

function Get-CategoryDisplay {
  param([string]$Category)
  if ([string]::IsNullOrWhiteSpace($Category)) { return "uncategorized" }
  $norm = $Category -replace "[\\\/]", "/"
  $parts = $norm -split "/"
  return ($parts | Select-Object -Last 1)
}

function Get-CategoryType {
  param([string]$Category)
  if ([string]::IsNullOrWhiteSpace($Category)) { return "Tooling & Environment" }

  $token = Get-CategoryDisplay $Category
  $token = $token.ToLowerInvariant()

  if ($token -match "ix-|agent|subagent|parallel|multi|dispatch|pk-|llm-as-verifier|agent-self-improvement|agentmail|droid|puzldai|ralph") {
    return "Agentic Systems"
  }
  if ($token -match "albatross|sunpower|interconnection|ix|salesforce|puzl|field-spreadsheet|utility-skills|utility") {
    return "Solar & Interconnection"
  }
  if ($token -match "research|wiki|deep|memory|evaluation|eval|worker-bench|analysis|intel|investig|project-prioritization|context-fundamentals|context-optimization|context-degradation|investor|strategic") {
    return "Research & Intelligence"
  }
  if ($token -match "doc|knowledge|write|guide|plan|context|help|knowledge-base|sop|skill-creator|requesting-code-review|executing-plans") {
    return "Documentation & Knowledge"
  }
  if ($token -match "github|github-|release|deploy|workflow|pull|branch|git|commit|create-pr|code-review|review|ci|pr|dogfood|using-git-worktrees|repo-root|workflow-automation") {
    return "DevOps & Delivery"
  }
  if ($token -match "frontend|backend|api|design|pattern|architecture|software|engineering|map-codebase|coding|coding-standards|program|codebase|codebase|setup|plan|tdd-workflow|backend-patterns|frontend-patterns|api-design") {
    return "Engineering & Architecture"
  }
  if ($token -match "test|testing|e2e|qa|quality|bug|security|systematic-debugging|verification") {
    return "Testing & Quality"
  }
  if ($token -match "mcp|slack|obsidian|api|integration|integrations|hugging|remote|webhook|plugin|connector|tool|fabrik|fabric|worktree") {
    return "Integrations & APIs"
  }
  if ($token -match "remotion|podcast|visual|media|canvas|design|theme|slide|gif|art|music|web-artifacts|llm-wiki-organizer") {
    return "Creative & Media"
  }
  if ($token -match "setup|tool|utility|environment|remote|apple|android|mac|terminal|automation|scrcpy|fabric-ssh|service|cli") {
    return "Tooling & Environment"
  }

  return "Tooling & Environment"
}

function Get-Anchored {
  param([string]$Text)
  $anchor = $Text.ToLowerInvariant()
  $anchor = [regex]::Replace($anchor, "[^a-z0-9\\s-]", "")
  $anchor = $anchor.Trim()
  $anchor = $anchor -replace "\\s+", "-"
  return $anchor
}

$totalSkills = $skills.Count
$repoGroups = $skills | Group-Object repo | Sort-Object -Property @{Expression='Count';Descending=$true}, @{Expression='Name';Descending=$false}

$typedSkills = $skills | ForEach-Object {
  $record = $_ | Select-Object *
  $record | Add-Member -NotePropertyName skill_type -NotePropertyValue (Get-CategoryType $_.category) -Force
  $record
}
$categoryGroups = $typedSkills | Group-Object skill_type | Sort-Object -Property @{Expression='Count';Descending=$true}, @{Expression='Name';Descending=$false}

$repoCount = $repoGroups.Count
$generated = (Get-Date).ToString("o")
$source = '$HOME\.codex\kingkillery-agent-skill-repos.json'
$sourceHint = 'C:\Users\prest\.codex\kingkillery-agent-skill-repos.json'
$badgeSkills = $totalSkills
$badgeRepos = $repoCount

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine("# PK Awesome Agent Skills")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("A curated, machine-readable index of agent capabilities from Kingkillery skill repositories, with direct links to every `SKILL.md`.")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("![Skills](https://img.shields.io/badge/skills-$badgeSkills-blue)")
$null = $sb.AppendLine("![Repos](https://img.shields.io/badge/repos-$badgeRepos-green)")
$null = $sb.AppendLine("![Format](https://img.shields.io/badge/format-Markdown%20%2B%20JSON-orange)")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("## At a Glance")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("- Source index: $source")
$null = $sb.AppendLine("- Source path: $sourceHint")
$null = $sb.AppendLine("- Generated: $generated")
$null = $sb.AppendLine("- Total repositories: $repoCount")
$null = $sb.AppendLine("- Total skills: $totalSkills")
$null = $sb.AppendLine('- Refresh with: .\scripts\Update-PKAwesomeAgentSkills.ps1')
$null = $sb.AppendLine('- Rebuild README with: .\scripts\Generate-PKAwesomeReadme.ps1')
$null = $sb.AppendLine("")
$null = $sb.AppendLine("## Files")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("- `README.md`: human-readable directory by category and by repository")
$null = $sb.AppendLine("- `skills-flat.json`: full flat list of links and metadata")
$null = $sb.AppendLine("- `catalog.json`: compressed index by repository")
$null = $sb.AppendLine("- `scripts/Update-PKAwesomeAgentSkills.ps1`: refresh JSON snapshots")
$null = $sb.AppendLine("- `scripts/Generate-PKAwesomeReadme.ps1`: regenerate this file")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("## Quick Search Strategy")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("1. Start in the category index when your ask is capability-based.")
$null = $sb.AppendLine("2. Open one or two `SKILL.md` files through the direct links.")
$null = $sb.AppendLine("3. If needed, follow to the owning repo for broader context.")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("## Category Index")
$null = $sb.AppendLine("")

foreach ($cat in $categoryGroups) {
  $name = $cat.Name
  $anchor = Get-Anchored $name
  $null = $sb.AppendLine("- [$name](#$anchor) - $($cat.Count) skills")
}

$null = $sb.AppendLine("")
$null = $sb.AppendLine("## Repository Index")
$null = $sb.AppendLine("")
foreach ($repo in $repoGroups) {
  $url = ($skills | Where-Object repo -eq $repo.Name | Select-Object -First 1).repo_url
  $null = $sb.AppendLine("- [$($repo.Name)]($url) - $($repo.Count) skills")
}

$null = $sb.AppendLine("")
$null = $sb.AppendLine("## Skills by Category")
$null = $sb.AppendLine("")
foreach ($cat in $categoryGroups) {
  $name = $cat.Name
  $anchor = Get-Anchored $name
  $null = $sb.AppendLine("### $name")
  $null = $sb.AppendLine("<a id=`"$anchor`"></a>")
  $items = $cat.Group | Sort-Object repo, path
  foreach ($item in $items) {
    $skillName = "$($item.repo)/$($item.path)"
    $null = $sb.AppendLine("- [$skillName]($($item.link))")
  }
  $null = $sb.AppendLine("")
}

$null = $sb.AppendLine("## Skills by Repository")
$null = $sb.AppendLine("")
foreach ($repo in $repoGroups) {
  $url = ($skills | Where-Object repo -eq $repo.Name | Select-Object -First 1).repo_url
  $null = $sb.AppendLine("### $($repo.Name)")
  $null = $sb.AppendLine("[Repository home]($url)")
  $items = $repo.Group | Sort-Object path
  foreach ($item in $items) {
    $null = $sb.AppendLine("- [$($item.path)]($($item.link))")
  }
  $null = $sb.AppendLine("")
}

$sb.ToString() | Set-Content -NoNewline -LiteralPath $OutputPath
Write-Host "Generated README: $OutputPath"
