param(
    [string]$SkillsPath = "$PSScriptRoot\..\skills-flat.json",
    [string]$CatalogPath = "$PSScriptRoot\..\catalog.json",
    [string]$OutputDir = "$PSScriptRoot\..\",
    [string]$EvaluatorId = "local-neutral-scorer-v1",
    [int]$GapBottomPercent = 10,
    [int]$TopN = 25,
    [switch]$SkipRegrade,
    [switch]$AsJson
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $OutputDir)) {
  throw "OutputDir not found: $OutputDir"
}

if (-not $SkipRegrade) {
  Write-Host "Running deterministic local grader to refresh artifacts..."
  & (Join-Path $PSScriptRoot "Grade-PKAwesomeSkills.ps1") -SkillsPath $SkillsPath -CatalogPath $CatalogPath -OutputDir $OutputDir
}

$ratingsPath = Join-Path $OutputDir "skill-ratings.json"
$summaryPath = Join-Path $OutputDir "skill-rating-summary.json"

if (-not (Test-Path -LiteralPath $ratingsPath)) {
  throw "Missing ratings artifact: $ratingsPath"
}
if (-not (Test-Path -LiteralPath $summaryPath)) {
  throw "Missing summary artifact: $summaryPath"
}

$ratings = Get-Content -LiteralPath $ratingsPath -Raw | ConvertFrom-Json
$summary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json

function Resolve-ActionSuggestion {
  param([psobject]$Item)
  if ($Item.score -ge 80) { return "No immediate action required; monitor if context changes." }
  if ($Item.risk_flags -and ($Item.risk_flags -contains 'Generic folder name; may be too broad')) {
    return "Rename folder to a narrower, action-oriented token (e.g. `analyze-bugs`, `summarize-repo`, `audit-security`)."
  }
  if ($Item.risk_flags -and ($Item.risk_flags -contains 'Single-skill repo may have narrow reuse')) {
    return "Add adjacent skills in this repo to increase reuse signals and improve discoverability."
  }
  if ($Item.path -notmatch 'SKILL\.md$') {
    return "Use canonical `SKILL.md` naming and include objective metadata blocks."
  }
  if ($Item.score -lt 55) {
    return "Improve naming/action verbs and include clearer objective-oriented tokens in the path."
  }
  return "Consider adding explicit examples and clearer path/category separation."
}

$byType = $ratings | Group-Object skill_type

$topByType = New-Object System.Collections.Generic.List[object]
$gapsByType = New-Object System.Collections.Generic.List[object]
$signalCounts = @{}
$weakSignalCount = 0

foreach ($bucket in $byType) {
  $sorted = $bucket.Group | Sort-Object score -Descending
  $bottomCount = [int][math]::Ceiling($sorted.Count * ($GapBottomPercent / 100))
  if ($bottomCount -lt 1) { $bottomCount = 1 }

  $topByType.Add([pscustomobject]@{
    skill_type = $bucket.Name
    total = $bucket.Count
    top = $sorted | Select-Object -First $TopN |
      Select-Object repo, path, score, reasons, @{Name='risk_flags'; Expression={ if ($_.risk_flags -is [array] -and $_.risk_flags.Count -gt 0) { @($_.risk_flags) } else { $null } }}, @{Name='recommendation';Expression={Resolve-ActionSuggestion $_}} 
  })

  $gapsByType.Add([pscustomobject]@{
    skill_type = $bucket.Name
    bottom = ($sorted | Sort-Object score) | Select-Object -First $bottomCount |
      Select-Object repo, path, score, reasons, @{Name='risk_flags'; Expression={ if ($_.risk_flags -is [array] -and $_.risk_flags.Count -gt 0) { @($_.risk_flags) } else { $null } }}, @{Name='recommendation';Expression={Resolve-ActionSuggestion $_}}
  })

  foreach ($item in $sorted) {
    if ($item.score -lt 55) { $weakSignalCount += 1 }
    foreach ($reason in $item.risk_flags) {
      $reasonText = [string]$reason
      if ([string]::IsNullOrWhiteSpace($reasonText)) { continue }
      if (-not $signalCounts.ContainsKey($reasonText)) { $signalCounts[$reasonText] = 0 }
      $signalCounts[$reasonText] += 1
    }
  }
}

$riskSorted = $signalCounts.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
  [pscustomobject]@{ risk_flag = $_.Name; count = $_.Value }
}

$overall = $ratings | Measure-Object -Property score -Average -Minimum -Maximum
$scoreCoverage = @{
  total = $overall.Count
  average = [math]::Round($overall.Average, 1)
  minimum = $overall.Minimum
  maximum = $overall.Maximum
  weak_count = $weakSignalCount
}

$session = [pscustomobject]@{
  protocol = "local-skill-review/v1"
  evaluator_id = $EvaluatorId
  generated_at = (Get-Date).ToString("o")
  source = @{
    skills_path = $SkillsPath
    catalog_path = $CatalogPath
  }
  score_coverage = $scoreCoverage
  type_summaries = $summary
  top_by_type = $topByType
  gap_by_type = $gapsByType
  top_risk_signals = $riskSorted
  recommended_next_moves = @(
    "Start with the smallest `gap_by_type` buckets and re-run reviewer after each improvement.",
    "Treat `weak_count` and risk_signal concentration as your objective quality gates."
  )
}

$sessionPath = Join-Path $OutputDir "local-skill-review-session.json"
$session | ConvertTo-Json -Depth 20 | Set-Content -NoNewline -Path $sessionPath

if ($AsJson) {
  $session | ConvertTo-Json -Depth 20
} else {
  Write-Host "Local skill review complete."
  Write-Host "  scores artifact: $ratingsPath"
  Write-Host "  summary artifact: $summaryPath"
  Write-Host "  session artifact: $sessionPath"
  Write-Host "  average score: $($scoreCoverage.average), weak: $($scoreCoverage.weak_count)"
}
