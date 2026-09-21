<#
.SYNOPSIS
	Deploys the addon into the World of Warcraft AddOns folder.

.DESCRIPTION
	Runs build.ps1 (ExecuteRange\ assembled into <repo>\build\ExecuteRange\)
	and mirrors that build output into
	<WoW>\<gameDir>\Interface\AddOns\ExecuteRange\, where gameDir comes from
	addon.json (_retail_).

	The WoW install location (the folder that contains _retail_, _classic_, ...)
	is asked for on the first run and stored in deploy.config.json next to this
	script. That file is git-ignored because it is machine specific.

.PARAMETER Reset
	Forget the stored WoW location and ask for it again.

.EXAMPLE
	.\deploy.ps1
	.\deploy.ps1 -Reset
#>
[CmdletBinding()]
param(
	[switch]$Reset
)

$ErrorActionPreference = "Stop"

$RepoRoot    = $PSScriptRoot
$ConfigPath  = Join-Path $RepoRoot "deploy.config.json"
$BuildScript = Join-Path $RepoRoot "build.ps1"

# Addon name and the game sub-folder it deploys to ("gameDir") come from addon.json.
$Addon = Get-Content (Join-Path $RepoRoot "addon.json") -Raw | ConvertFrom-Json
foreach ($key in "name", "gameDir") {
	if (-not $Addon.$key) {
		throw "addon.json is missing '$key'."
	}
}
$AddonName = $Addon.name
$GameDir   = $Addon.gameDir

# --- WoW location -----------------------------------------------------------

function Read-WowPath {
	while ($true) {
		$path = Read-Host "Path to your World of Warcraft install (the folder containing $GameDir, e.g. D:\Games\World of Warcraft)"
		$path = $path.Trim().Trim('"')
		if (-not $path) { continue }
		if (-not (Test-Path $path)) {
			Write-Warning "'$path' does not exist."
			continue
		}
		# Accept the game folder itself too and step up to the install root.
		if ((Split-Path $path -Leaf) -eq $GameDir) {
			$path = Split-Path $path -Parent
		}
		return (Resolve-Path $path).Path
	}
}

$config = $null
if (-not $Reset -and (Test-Path $ConfigPath)) {
	try {
		$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
	} catch {
		Write-Warning "deploy.config.json is unreadable; asking for the path again."
	}
}

if (-not $config -or -not $config.wowPath -or -not (Test-Path $config.wowPath)) {
	if ($config -and $config.wowPath) {
		Write-Warning "Stored WoW location '$($config.wowPath)' no longer exists."
	}
	$wowPath = Read-WowPath
	$config = [pscustomobject]@{ wowPath = $wowPath }
	$config | ConvertTo-Json | Set-Content $ConfigPath -Encoding UTF8
	Write-Host "Stored WoW location in $ConfigPath"
}

$WowPath = $config.wowPath

$gameFolder = Join-Path $WowPath $GameDir
if (-not (Test-Path $gameFolder)) {
	throw "Game folder '$gameFolder' does not exist in the WoW install. Run with -Reset to change the location."
}
$target = Join-Path $gameFolder "Interface\AddOns\$AddonName"

# --- Build + deploy ---------------------------------------------------------

$buildOutput = Join-Path $RepoRoot "build\$AddonName"

& $BuildScript
if ($LASTEXITCODE -ne 0 -or -not (Test-Path (Join-Path $buildOutput "$AddonName.toc"))) {
	throw "build.ps1 did not produce '$buildOutput'."
}

Write-Host "Deploying $buildOutput -> $target"
New-Item -ItemType Directory -Force (Split-Path $target -Parent) | Out-Null

# /MIR keeps the target an exact copy of the build output (removes deleted files).
$robocopyArgs = @($buildOutput, $target, "/MIR", "/NJH", "/NJS", "/NDL", "/NP", "/R:2", "/W:1")
& robocopy @robocopyArgs
$code = $LASTEXITCODE

# Robocopy exit codes below 8 mean success (bits 1/2/4 = copied/extra/mismatched).
if ($code -ge 8) {
	throw "robocopy failed with exit code $code while deploying $AddonName"
}

Write-Host "Done. Type /reload in game to pick up the changes."

exit 0
