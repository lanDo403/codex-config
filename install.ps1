[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Selection,
    [string]$SkillsDir = (Join-Path ([Environment]::GetFolderPath('UserProfile')) '.agents\skills'),
    [string]$CodexDir = $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else {
        Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex'
    }),
    [string]$VaultPath,
    [string]$WikiToolsPath,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$sourceRoot = Join-Path $PSScriptRoot 'skills'

function Show-Usage {
    Write-Host 'Usage: .\install.ps1 <skill-name|all> [-SkillsDir PATH]'
    Write-Host '  [-CodexDir PATH] [-VaultPath PATH] [-WikiToolsPath PATH]'
    Write-Host 'Available skills:'
    Get-ChildItem -LiteralPath $sourceRoot -Directory | ForEach-Object {
        if (Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf) {
            Write-Host "  - $($_.Name)"
        }
    }
}

if ($Help) { Show-Usage; exit 0 }
if (-not $Selection) { Show-Usage; exit 2 }

try {
    $names = @($Selection)
    if ($Selection -eq 'all') {
        $names = @(Get-ChildItem -LiteralPath $sourceRoot -Directory | Where-Object {
            Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf
        } | Select-Object -ExpandProperty Name)
    }
    if ($names.Count -eq 0) { throw "No skills found in: $sourceRoot" }
    foreach ($name in $names) {
        if ($name -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$' -or
            -not (Test-Path -LiteralPath (Join-Path (Join-Path $sourceRoot $name) 'SKILL.md') -PathType Leaf)) {
            throw "Skill not found or invalid name: $name"
        }
    }

    foreach ($configFile in @('AGENTS.md', 'RTK.md')) {
        if (-not (Test-Path -LiteralPath (Join-Path (Join-Path $PSScriptRoot 'codex') $configFile) -PathType Leaf)) {
            throw "Missing global rules: $configFile"
        }
    }
    if ($VaultPath) {
        if (-not (Test-Path -LiteralPath $VaultPath -PathType Container)) { throw 'VaultPath must be an existing directory.' }
        $VaultPath = (Resolve-Path -LiteralPath $VaultPath).ProviderPath
    }
    if ($WikiToolsPath) {
        if (-not (Test-Path -LiteralPath $WikiToolsPath -PathType Container)) { throw 'WikiToolsPath must be an existing directory.' }
        $WikiToolsPath = (Resolve-Path -LiteralPath $WikiToolsPath).ProviderPath
    }
    $targetRoot = [IO.Path]::GetFullPath($SkillsDir)
    New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null
    $targetRoot = (Resolve-Path -LiteralPath $targetRoot).ProviderPath
    if ($targetRoot.TrimEnd('\', '/') -eq $sourceRoot.TrimEnd('\', '/') -or
        $targetRoot.StartsWith("$sourceRoot$([IO.Path]::DirectorySeparatorChar)", [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Installation target must be outside the source skills directory.'
    }
    $configRoot = [IO.Path]::GetFullPath($CodexDir)
    New-Item -ItemType Directory -Path $configRoot -Force | Out-Null
    $configRoot = (Resolve-Path -LiteralPath $configRoot).ProviderPath
    $configSource = Join-Path $PSScriptRoot 'codex'
    if ($configRoot.TrimEnd('\', '/') -eq $configSource.TrimEnd('\', '/') -or
        $configRoot.StartsWith("$configSource$([IO.Path]::DirectorySeparatorChar)", [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Codex directory must be outside the source rules directory.'
    }
    foreach ($configFile in @('AGENTS.md', 'RTK.md')) {
        $configTarget = Join-Path $configRoot $configFile
        $configItem = Get-Item -LiteralPath $configTarget -Force -ErrorAction SilentlyContinue
        if ($null -ne $configItem) {
            if ($configItem.PSIsContainer -or ($configItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                throw "Global rules target must be a regular file: $configTarget"
            }
        }
    }
    $backupRoot = Join-Path (Split-Path -Parent $targetRoot) 'skill-backups'

    foreach ($name in $names) {
        $sourceDir = Join-Path $sourceRoot $name
        $targetDir = [IO.Path]::GetFullPath((Join-Path $targetRoot $name))
        if ((Split-Path -Parent $targetDir) -ne $targetRoot.TrimEnd('\', '/')) {
            throw "Installation target is outside the skills directory: $targetDir"
        }
        if ($null -ne (Get-Item -LiteralPath $targetDir -Force -ErrorAction SilentlyContinue)) {
            $backupName = "$name.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([guid]::NewGuid().ToString('N'))"
            $backupDir = [IO.Path]::GetFullPath((Join-Path $backupRoot $backupName))
            if ((Split-Path -Parent $backupDir) -ne [IO.Path]::GetFullPath($backupRoot)) {
                throw "Backup target is outside the backup directory: $backupDir"
            }
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            Move-Item -LiteralPath $targetDir -Destination (Join-Path $backupDir $name)
            Write-Host "Backed up existing skill to: $backupDir"
        }
        Copy-Item -LiteralPath $sourceDir -Destination $targetDir -Recurse -Force
        Write-Host "Installed $name -> $targetDir"
    }
    $configBackup = $null
    foreach ($configFile in @('AGENTS.md', 'RTK.md')) {
        $configTarget = Join-Path $configRoot $configFile
        if (Test-Path -LiteralPath $configTarget) {
            if (-not $configBackup) {
                $backupName = "install-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([guid]::NewGuid().ToString('N'))"
                $configBackup = Join-Path (Join-Path $configRoot 'config-backups') $backupName
                New-Item -ItemType Directory -Path $configBackup -Force | Out-Null
            }
            Copy-Item -LiteralPath $configTarget -Destination (Join-Path $configBackup $configFile)
        }
    }
    if ($configBackup) { Write-Host "Backed up global rules to: $configBackup" }
    $agentsContent = [IO.File]::ReadAllText((Join-Path $configSource 'AGENTS.md'))
    # Read Unicode labels from the template to keep this script ASCII for PowerShell 5.1.
    $pathPlaceholder = [regex]::Match($agentsContent, '^@(<[^>]+>)/RTK\.md').Groups[1].Value
    $vaultPlaceholder = [regex]::Match($agentsContent, '<[^>\r\n]+ VAULT>').Value
    if (-not $pathPlaceholder -or -not $vaultPlaceholder) { throw 'AGENTS.md path placeholders were not found.' }
    $agentsContent = $agentsContent.Replace("$pathPlaceholder/RTK.md", (Join-Path $configRoot 'RTK.md').Replace('\', '/'))
    if ($VaultPath) { $agentsContent = $agentsContent.Replace($vaultPlaceholder, $VaultPath.Replace('\', '/')) }
    if ($WikiToolsPath) { $agentsContent = $agentsContent.Replace($pathPlaceholder, $WikiToolsPath.Replace('\', '/')) }
    [IO.File]::WriteAllText((Join-Path $configRoot 'AGENTS.md'), $agentsContent, (New-Object Text.UTF8Encoding($false)))
    Copy-Item -LiteralPath (Join-Path $configSource 'RTK.md') -Destination (Join-Path $configRoot 'RTK.md') -Force
    Write-Host "Installed global rules -> $configRoot"
    if (-not $VaultPath -or -not $WikiToolsPath) {
        Write-Host 'Wiki placeholders remain in AGENTS.md. Set -VaultPath and -WikiToolsPath or edit them manually.'
    }
    Write-Host 'Done. Restart Codex if the installed skills do not appear.'
} catch {
    Write-Error -Message $_.Exception.Message -ErrorAction Continue
    exit 1
}
