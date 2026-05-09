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
  $parts = $Category -split "/"
  return ($parts | Select-Object -Last 1)
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
$categoryGroups = $skills | Group-Object category | Sort-Object -Property @{Expression='Count';Descending=$true}, @{Expression='Name';Descending=$false}

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
  $name = Get-CategoryDisplay $cat.Name
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
  $name = Get-CategoryDisplay $cat.Name
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
  $anchor = Get-Anchored $repo.Name
  $null = $sb.AppendLine("### $($repo.Name)")
  $null = $sb.AppendLine("<a id=`"$anchor`"></a>")
  $null = $sb.AppendLine("[Repository home]($url)")
  $items = $repo.Group | Sort-Object path
  foreach ($item in $items) {
    $null = $sb.AppendLine("- [$($item.path)]($($item.link))")
  }
  $null = $sb.AppendLine("")
}

$sb.ToString() | Set-Content -NoNewline -LiteralPath $OutputPath
Write-Host "Generated README: $OutputPath"
