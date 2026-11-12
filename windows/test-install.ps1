#requires -Version 7.0
$ErrorActionPreference = 'Stop'
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-windows-test-' + [guid]::NewGuid())
$testHome = Join-Path $temporary 'home'
$testProfile = Join-Path $testHome 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
$previousGlobalConfig = $env:GIT_CONFIG_GLOBAL
$previousExitCode = $global:LASTEXITCODE
New-Item -ItemType Directory -Path "$testHome\.claude", "$testHome\.codex" -Force | Out-Null
$env:GIT_CONFIG_GLOBAL = Join-Path $temporary 'gitconfig'

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

try {
    Set-Content "$testHome\.claude\settings.json" '{"autoUpdatesChannel":"stable","env":{"KEEP_ME":"yes"}}'
    Set-Content "$testHome\.claude\.credentials.json" 'sentinel-not-a-real-credential'
    Set-Content "$testHome\.codex\config.toml" "model = `"old`"`n[desktop]`nkeep = true`n"
    & "$PSScriptRoot\install.ps1" -HomeDirectory $testHome -ProfilePath $testProfile
    Assert-True ($LASTEXITCODE -eq 0) 'Installer Git commands failed.'
    $settings = Get-Content "$testHome\.claude\settings.json" -Raw | ConvertFrom-Json
    Assert-True ($settings.autoUpdatesChannel -eq 'stable') 'Existing Claude settings changed.'
    Assert-True ($settings.env.KEEP_ME -eq 'yes') 'Existing Claude environment changed.'
    Assert-True (Test-Path $settings.env.CLAUDE_CODE_GIT_BASH_PATH) 'Git Bash path does not exist.'
    Assert-True ((Get-Content "$testHome\.claude\.credentials.json") -eq 'sentinel-not-a-real-credential') 'Credentials changed.'
    $config = Get-Content "$testHome\.codex\config.toml" -Raw
    Assert-True ($config.Contains('[desktop]') -and $config.Contains('keep = true')) 'Windows Codex sections changed.'
    Assert-True (-not $config.Contains('"/Users/') -and -not $config.Contains('"/Applications/')) 'Mac paths entered the Windows config.'
    Assert-True ((Get-FileHash "$testHome\.codex\AGENTS.md").Hash -eq (Get-FileHash "$PSScriptRoot\..\.claude\CLAUDE.md").Hash) 'Codex instructions differ from shared instructions.'
    Assert-True ((git config --global user.email) -eq 'dev@yarden-zamir.com') 'Git identity differs.'
    Assert-True ((git config --global core.autocrlf) -eq 'input') 'Git line endings differ.'
    $fixture = Join-Path $temporary 'project'
    New-Item -ItemType Directory -Path "$fixture\_shared" -Force | Out-Null
    Set-Content "$fixture\_shared\local-settings.txt" 'local fixture'
    git init --bare "$fixture\.bare" | Out-Null
    git --git-dir "$fixture\.bare" worktree add --orphan -b main "$fixture\main" | Out-Null
    git -C "$fixture\main" -c commit.gpgsign=false commit --allow-empty -m fixture | Out-Null
    git -C "$fixture\main" checkout main | Out-Null
    Assert-True (Test-Path "$fixture\main\local-settings.txt") 'Checkout hook did not apply the shared file.'
    $exclude = Get-Content "$fixture\.bare\info\exclude" -Raw
    Assert-True ($exclude.Contains('/local-settings.txt')) 'Shared file exclusion is missing.'
    Assert-True (@(Get-ChildItem "$fixture\main" -Directory | Where-Object Name -Like 'C*').Count -eq 0) 'Hook created a drive path inside the worktree.'
    $before = @(Get-ChildItem $testHome -Recurse -Force | Where-Object Name -Like '*.backup-*').Count
    & "$PSScriptRoot\install.ps1" -HomeDirectory $testHome -ProfilePath $testProfile
    $after = @(Get-ChildItem $testHome -Recurse -Force | Where-Object Name -Like '*.backup-*').Count
    Assert-True ($before -eq $after) 'Unchanged reinstall created new backups.'
    . $testProfile
    Push-Location $PSScriptRoot
    try {
        $global:LASTEXITCODE = 17
        $rendered = prompt
        Assert-True ($rendered.Contains('[main]')) 'Prompt omitted the Git branch.'
        Assert-True ($global:LASTEXITCODE -eq 17) 'Prompt changed LASTEXITCODE.'
    } finally { Pop-Location }
    Write-Host "PASS: settings, credentials, portable config, Git identity, idempotence, and profile. Fixtures: $temporary"
} finally {
    $env:GIT_CONFIG_GLOBAL = $previousGlobalConfig
    $global:LASTEXITCODE = $previousExitCode
}
