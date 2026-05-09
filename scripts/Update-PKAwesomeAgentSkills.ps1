param(
    [string]$SourceIndex = "$HOME\.codex\kingkillery-agent-skill-repos.json",
    [string]$OutputDir = "$PSScriptRoot\.."
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SourceIndex)) {
  throw "Source index not found: $SourceIndex"
}

if (-not (Test-Path -LiteralPath $OutputDir)) {
  throw "Output directory not found: $OutputDir"
}

$source = Get-Content -Raw -LiteralPath $SourceIndex | ConvertFrom-Json

$repoRows = New-Object System.Collections.Generic.List[object]
$flatRows = New-Object System.Collections.Generic.List[object]

foreach ($repo in $source.repos) {
  $skillRows = $repo.skill_paths
  $skillCount = 0

  foreach ($skill in $skillRows) {
    $fullPath = ($skill.path -replace '^/', '')
    $repoName = [uri]::EscapeUriString($repo.repo)
    $rawUrl = $repo.url.TrimEnd('/')
    $url = if ($fullPath -match "^https?://") {
      $fullPath
    } else {
      "$rawUrl/blob/main/$fullPath"
    }

    $category = if ($fullPath -match "^skills/([^/]+)/") { $Matches[1] } elseif ($fullPath -match "^.agents/skills/([^/]+)/") { $Matches[1] } else { "uncategorized" }
    $repoRows.Add([pscustomobject]@{
      repo = $repo.repo
      name = ($fullPath -replace '.*/')
      path = $fullPath
      category = $category
      url = $url
    })
    $skillCount++
  }

  if ($skillCount -eq 0) {
    $flatRows.Add([pscustomobject]@{
      repo = $repo.repo
      skill = "<none>"
      path = ""
      category = "uncategorized"
      url = $repo.url
    })
  }
}

$catalogPath = Join-Path $OutputDir "catalog.json"
$skillsFlatPath = Join-Path $OutputDir "skills-flat.json"

$repoRows | ConvertTo-Json -Depth 10 | Set-Content -NoNewline -Path $catalogPath
$flatRows | ConvertTo-Json -Depth 10 | Set-Content -NoNewline -Path $skillsFlatPath

Write-Host "Wrote:"
Write-Host " - $catalogPath"
Write-Host " - $skillsFlatPath"
Write-Host "Tip: rebuild README.md with your preferred static generator if needed."

