param(
  [string]$Owner = "MICONNM",
  [string]$Repo = "jeongsan-bot"
)

$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host ""
  Write-Host "==> $Message"
}

function Get-GitHubToken {
  if ($env:GITHUB_TOKEN) { return $env:GITHUB_TOKEN }
  if ($env:GH_TOKEN) { return $env:GH_TOKEN }
  return $null
}

function Invoke-GitHubApi {
  param(
    [ValidateSet("GET", "POST", "PUT")]
    [string]$Method,
    [string]$Path,
    [object]$Body = $null
  )

  $token = Get-GitHubToken
  if (-not $token) {
    throw "GITHUB_TOKEN or GH_TOKEN is required for REST API deployment."
  }

  $headers = @{
    Authorization          = "Bearer $token"
    Accept                 = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
  }

  $uri = "https://api.github.com$Path"
  if ($null -eq $Body) {
    return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers
  }

  $json = $Body | ConvertTo-Json -Depth 10
  return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -Body $json -ContentType "application/json"
}

if (-not (Test-Path -LiteralPath "index.html")) {
  throw "Run this script from the jeongsan-bot project folder."
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw "git is required."
}

$repoFullName = "$Owner/$Repo"
$hasGh = [bool](Get-Command gh -ErrorAction SilentlyContinue)
$token = Get-GitHubToken

if (-not $hasGh -and -not $token) {
  throw "Install/authenticate GitHub CLI with 'gh auth login', or set GITHUB_TOKEN/GH_TOKEN with repo and Pages permissions."
}

Write-Step "Checking repository $repoFullName"
$repoExists = $true
if ($hasGh) {
  gh repo view $repoFullName *> $null
  if ($LASTEXITCODE -ne 0) { $repoExists = $false }
} else {
  try {
    Invoke-GitHubApi -Method GET -Path "/repos/$repoFullName" *> $null
  } catch {
    $repoExists = $false
  }
}

if (-not $repoExists) {
  Write-Step "Creating public repository $repoFullName"
  if ($hasGh) {
    gh repo create $repoFullName --public --description "Jeongsan Bot validation landing page" --source . --remote origin
  } else {
    Invoke-GitHubApi -Method POST -Path "/user/repos" -Body @{
      name        = $Repo
      private     = $false
      description = "Jeongsan Bot validation landing page"
      auto_init   = $false
    } *> $null
    git remote remove origin 2>$null
    git remote add origin "https://github.com/$repoFullName.git"
  }
} else {
  Write-Step "Repository exists; ensuring origin remote"
  git remote remove origin 2>$null
  git remote add origin "https://github.com/$repoFullName.git"
}

Write-Step "Pushing main branch"
git branch -M main
if ($hasGh) {
  git push -u origin main
} else {
  git -c "http.https://github.com/.extraheader=AUTHORIZATION: bearer $token" push -u origin main
}

Write-Step "Enabling GitHub Pages from main branch root"
$pagesBody = @{
  source = @{
    branch = "main"
    path   = "/"
  }
}

if ($hasGh) {
  $tmp = New-TemporaryFile
  try {
    Set-Content -LiteralPath $tmp -Value ($pagesBody | ConvertTo-Json -Depth 5) -Encoding UTF8
    gh api --method POST "repos/$repoFullName/pages" --input $tmp *> $null
    if ($LASTEXITCODE -ne 0) {
      gh api --method PUT "repos/$repoFullName/pages" --input $tmp *> $null
    }
  } finally {
    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
  }
} else {
  try {
    Invoke-GitHubApi -Method POST -Path "/repos/$repoFullName/pages" -Body $pagesBody *> $null
  } catch {
    Invoke-GitHubApi -Method PUT -Path "/repos/$repoFullName/pages" -Body $pagesBody *> $null
  }
}

$url = "https://$Owner.github.io/$Repo/"
Write-Step "Waiting for Pages URL: $url"
for ($i = 1; $i -le 30; $i++) {
  try {
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
      Write-Host "GitHub Pages is live: $url"
      exit 0
    }
  } catch {
    Start-Sleep -Seconds 10
  }
}

throw "GitHub Pages was enabled, but $url did not return 200 within the wait window."
