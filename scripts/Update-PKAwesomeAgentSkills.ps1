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

$source = Get-Content -LiteralPath $SourceIndex -Raw | ConvertFrom-Json

$catalogRows = New-Object System.Collections.Generic.List[object]
$flatRows = New-Object System.Collections.Generic.List[object]

foreach ($repo in $source) {
  $rawUrl = $repo.url.TrimEnd("/")
  $repoUrl = $repo.url
  $skillPaths = @()

  if ($repo.PSObject.Properties.Match("skill_paths").Count -gt 0 -and $repo.skill_paths) {
    $skillPaths = $repo.skill_paths
  } else {
    $skillPaths = @()
  }

  $catalogRows.Add([pscustomobject]@{
      repo = $repo.repo
      repo_url = $repoUrl
      skills = $skillPaths.Count
  })

  foreach ($pathValue in $skillPaths) {
    $fullPath = $pathValue -replace "^/",""
    $category = [System.IO.Path]::GetDirectoryName($fullPath).Replace("\\", "/")
    $skillName = [System.IO.Path]::GetFileName($fullPath)
    $link = "$rawUrl/blob/main/$fullPath"

    $flatRows.Add([pscustomobject]@{
      repo = $repo.repo
      repo_url = $repoUrl
      category = $category
      path = $fullPath
      link = $link
      name = $skillName
    })
  }
}

$catalogPath = Join-Path $OutputDir "catalog.json"
$flatPath = Join-Path $OutputDir "skills-flat.json"

$catalogRows | ConvertTo-Json -Depth 10 | Set-Content -NoNewline -Path $catalogPath
$flatRows | ConvertTo-Json -Depth 10 | Set-Content -NoNewline -Path $flatPath

Write-Host "Wrote:"
Write-Host " - $catalogPath"
Write-Host " - $flatPath"
Write-Host "Tip: rebuild README.md with .\scripts\Generate-PKAwesomeReadme.ps1"

