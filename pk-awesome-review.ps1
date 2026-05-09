$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "scripts\\Run-PKAwesomeLocalSkillReview.ps1"
& $scriptPath @args
