<#
.SYNOPSIS
	Assembles the deployable addon folder and CurseForge zip into <repo>\build\.

.DESCRIPTION
	Copies <repo>\ExecuteRange\ (the addon source) into
	<repo>\build\ExecuteRange\, leaving out editor/IDE files that must not
	ship (.vscode, *.wowproj, *.wowsln, *.user), replaces the
	@project-version@ placeholder with the version from addon.json, and zips
	the folder as <repo>\build\ExecuteRange-<version>.zip, the layout
	CurseForge expects (the addon folder is the zip's root entry).

	The build folder is git-ignored; it is what deploy.ps1 copies into the game
	and what gets uploaded to CurseForge. The output is recreated from scratch
	on every run.

	The addon name and version come from <repo>\addon.json.

.EXAMPLE
	.\build.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$RepoRoot  = $PSScriptRoot
$BuildRoot = Join-Path $RepoRoot "build"

# addon.json is the single place for the addon name and version
# (deploy.ps1 reads it too for the game folder).
$Addon = Get-Content (Join-Path $RepoRoot "addon.json") -Raw | ConvertFrom-Json
foreach ($key in "name", "version") {
	if (-not $Addon.$key) {
		throw "addon.json is missing '$key'."
	}
}
$AddonName = $Addon.name
$Version   = $Addon.version
if ($Version -notmatch '^\d+\.\d+\.\d+(\S*)$') {
	throw "addon.json version must look like 1.2.3 (optionally with a suffix), got '$Version'."
}

$Source = Join-Path $RepoRoot $AddonName
if (-not (Test-Path (Join-Path $Source "$AddonName.toc"))) {
	throw "Addon source '$Source\$AddonName.toc' is missing."
}

# Development-only files inside the source folder that are not shipped.
$ExcludeDirs  = @(".vscode")
$ExcludeFiles = @("*.wowproj", "*.wowsln", "*.user")

# The .toc (and any other .toc/.lua/.md file) carries the
# @project-version@ placeholder, which is replaced in the build output.
$VersionPlaceholder = "@project-version@"

function Set-BuildVersion([string]$Folder) {
	$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
	foreach ($file in Get-ChildItem $Folder -Recurse -File -Include *.toc, *.lua, *.md) {
		$text = [System.IO.File]::ReadAllText($file.FullName)
		if ($text.Contains($VersionPlaceholder)) {
			[System.IO.File]::WriteAllText($file.FullName, $text.Replace($VersionPlaceholder, $Version), $utf8NoBom)
		}
	}
}

# Zips a folder so that the folder itself is the single root entry, with
# forward-slash entry names (Compress-Archive writes backslashes on some
# PowerShell versions, which CurseForge and non-Windows unzips choke on).
function New-AddonZip([string]$Folder, [string]$Zip) {
	Add-Type -AssemblyName System.IO.Compression
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	if (Test-Path $Zip) {
		Remove-Item $Zip -Force
	}
	$root = (Split-Path $Folder -Leaf)
	$archive = [System.IO.Compression.ZipFile]::Open($Zip, [System.IO.Compression.ZipArchiveMode]::Create)
	try {
		foreach ($file in Get-ChildItem $Folder -Recurse -File) {
			$relative = $file.FullName.Substring($Folder.Length).TrimStart('\', '/').Replace('\', '/')
			[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
				$archive, $file.FullName, "$root/$relative",
				[System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
		}
	} finally {
		$archive.Dispose()
	}
}

$output = Join-Path $BuildRoot $AddonName

if (Test-Path $output) {
	Remove-Item $output -Recurse -Force
}
New-Item -ItemType Directory -Force $output | Out-Null

# /E copies the tree including empty sub-folders; /XD and /XF drop the
# development-only files listed above.
$robocopyArgs = @($Source, $output, "/E", "/NJH", "/NJS", "/NDL", "/NFL", "/NP", "/R:2", "/W:1", "/XD") + $ExcludeDirs + @("/XF") + $ExcludeFiles
& robocopy @robocopyArgs
$code = $LASTEXITCODE

# Robocopy exit codes below 8 mean success (bits 1/2/4 = copied/extra/mismatched).
if ($code -ge 8) {
	throw "robocopy failed with exit code $code while copying the addon source"
}
Set-BuildVersion $output

$count = (Get-ChildItem $output -Recurse -File).Count
Write-Host "Built $AddonName $Version -> $output ($count files)"

# CurseForge upload: a zip whose root is the addon folder itself
# (ExecuteRange/ExecuteRange.toc, ...). Old zips of other versions are
# removed so the folder holds exactly one.
Get-ChildItem $BuildRoot -File -Filter "$AddonName-*.zip" | Remove-Item -Force
$zip = Join-Path $BuildRoot "$AddonName-$Version.zip"
New-AddonZip -Folder $output -Zip $zip
Write-Host "Zipped -> $zip"

exit 0
