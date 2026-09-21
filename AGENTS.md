# AGENTS.md

Guidance for AI coding agents working in this repository.

## What this is

ExecuteRange is a World of Warcraft (retail) addon written in Lua on the Ace3 framework. It glows the action-bar button of the player's class "execute" spell (Warrior Execute, Paladin Hammer of Wrath, Hunter Kill Shot, Priest Shadow Word: Death, Warlock Drain Soul/Shadowburn, DK Soul Reaper, Monk Touch of Death, Mage Scorch) when the target is in execute range, and optionally shows a configurable full-screen spell-alert overlay. Supports Bartender4, Dominos and the default Blizzard bars. Published on CurseForge: https://www.curseforge.com/wow/addons/execute-range

## Development workflow

There is no lint or test tooling; the addon is plain Lua/XML loaded by the game client. Two PowerShell scripts at the repo root handle building and deploying:

```
addon.json          addon name, version (x.y.z) and the game folder it deploys to ("gameDir": _retail_)
build.ps1           copies ExecuteRange\ into build\ExecuteRange\ (dropping .vscode, *.wowproj, *.wowsln, *.user),
                    replaces @project-version@ with the version and zips it as build\ExecuteRange-<version>.zip
                    (CurseForge layout: the addon folder is the zip's root entry)
build/              build output (git-ignored); what deploy.ps1 copies into the game and what gets uploaded
deploy.ps1          runs build.ps1 and mirrors build\ExecuteRange\ into <WoW>\_retail_\Interface\AddOns\ExecuteRange\
deploy.config.json  machine-specific WoW install path, asked for on first run (git-ignored, never commit; -Reset to change)
```

- **Edit** files under `ExecuteRange/` only. `build/` and the copy inside the game folder are outputs; never edit them directly and never touch anything else in the game install.
- **Run:** `.\deploy.ps1` (PowerShell), then `/reload` in-game after each change. The addon cannot be tested outside the game client; in-game verification is done by the user.
- **Debug:** `/exrange debug` toggles debug output (`ExecuteRange_Console:Debug`) to chat. `/exrange` opens the settings panel. `ExecuteRange_Console:PrintTalentNodes()` dumps the current talent tree (node/entry/spell IDs) — useful when finding IDs for `HasTalentNode`.
- **Release:** bump `"version"` in `addon.json` (and `## Interface` in `ExecuteRange/ExecuteRange.toc` for a new game patch), run `.uild.ps1` and upload `build\ExecuteRange-<version>.zip` to CurseForge. Never write a literal version into the `.toc` — it contains `## Version: @project-version@`, which `build.ps1` replaces (in `.toc`, `.lua` and `.md` files).
- `ExecuteRange/.vscode/settings.json` lists WoW globals for the Lua language server; add to it when using a new Blizzard global.
- `*.wowproj` / `*.wowsln` are legacy Visual Studio "WoW AddonStudio" project files; the real load order is the `.toc`. They are excluded from the build.
- Root `textures/` (gitignored) holds PNG previews of Blizzard's overlay textures for reference only; it is not shipped.
- Do not commit unless asked. Never commit `deploy.config.json`.

## Architecture

### Load order and globals

`ExecuteRange.toc` defines load order: `embeds.xml` (Ace3 libs) → `Init.lua` → `SpellActivationOverlay` → `Console` → `Constants` → `Settings` → `ButtonsResolver` → `SpellAlertsHandler` → `Core`.

`Init.lua` creates the AceAddon (`ExecuteRange_Core`, with AceConsole/AceEvent/AceTimer mixins) and declares every module as an empty global table (`ExecuteRange_Settings`, `ExecuteRange_ButtonsResolver`, …). Each file then fills in its own table and captures the others as `local` at the top ("dependencies" block). To add a module: declare its global in `Init.lua`, add the file to the `.toc` after everything it depends on.

Only the libs listed in `embeds.xml` are loaded; extra Ace3 libs in `Libs/` (AceHook, AceComm, …) are present but commented out.

### Runtime flow

1. `Core.lua:OnInitialize` — reads player class, creates the AceDB (`ExecuteRangeDB`, profile-scoped), seeds per-class defaults via `Settings:InitializeDb`, migrates pre-8.2 texture paths to file IDs, registers the AceConfig options table and `/exrange`. Unsupported classes get a stub options table and the addon is disabled.
2. `Core.lua:OnEnable` registers `UNIT_HEALTH` (target), `PLAYER_TARGET_CHANGED`, `UNIT_AURA` (player). All three funnel into `SpellAlertsHandler:ShowOrHideFlasher()`.
3. `SpellAlertsHandler:ShowOrHideFlasher` computes target health %, calls `GetExecuteRange()` for a threshold, checks the spell is off cooldown (or `showOnCooldown`), then shows/hides `ActionButton_ShowOverlayGlow` on matching buttons and the spell-alert overlay.

### Execute-range threshold convention

`GetExecuteRange()` returns a health percentage the target must be at or below. Two sentinel values are used heavily: **101** = "always show" (used when `IsUsableSpell()` already encodes the range, e.g. Warrior/Paladin/Hunter/Monk) and **0** = "never show". Classes whose spell is always castable use fixed constants (`*_EXECUTE_RANGE` in `Constants.lua`). Spec/talent-dependent cases (Warlock shards, Mage Searing Touch, Warrior Massacre/Condemn) branch here using `GetSpecializationInfo` and `HasTalentNode(nodeId[, entryId])`.

### Button discovery (`ButtonsResolver.lua`)

`GetAllButtons()` picks a strategy by loaded addon: Bartender4 → `LibActionButton-1.0:GetAllButtons()`; Dominos → `DominosActionButtonN` plus Blizzard bars; otherwise Blizzard bar globals (`ActionButtonN`, `MultiBar*ButtonN`). The result is cached in `ExecuteRange_ButtonsResolver.Buttons` on first use and never refreshed. `GetButtonSpellId` also differs: Bartender buttons expose `:GetSpellId()`, others go through `GetActionInfo(button.action)`. Buttons are matched against `Constants.VALID_SPELLS_IDS`.

### Spell alert overlay

`SpellActivationOverlay.lua/.xml` is a forked copy of Blizzard's `SpellActivationOverlay` (own frame `ExecuteRangeSpellActivationOverlayFrame`), kept because Blizzard's version spammed hide-events since 9.0.1. Overlays are keyed by a fake spell ID: `Constants.OVERLAY_ID` for the live alert and `OVERLAY_PREVIEW_ID` for the settings "Preview" button (raised to `FULLSCREEN_DIALOG` strata, auto-hidden by an AceTimer after 8s).

### Settings model (`Settings.lua`)

Profile shape: `enabled`, `showSpellAlert`, `showOnCooldown`, and `alerts` — a list of `{texture, position, scale, red, green, blue, verticalFlip, horizontalFlip}` with at most one entry per position (`TOP/RIGHT/LEFT/BOTTOM/CENTER`). `GetOptionsTable()` builds one AceConfig group per position dynamically (`textureOptions<POSITION>`). `texture` is a Blizzard file data ID; `Constants.TEXTURE_FILE_IDS` maps the old path names to IDs and `Constants.TEXTURES` maps IDs to display names for the dropdown.

### Adding a spell/class

Touch, in order: `Constants.VALID_SPELLS_IDS` and `VALID_SPELLS_NAMES_PER_CLASS`; the supported-class check in `Core:OnInitialize`; a branch in `SpellAlertsHandler:GetExecuteRange`; a default alert in `Settings:InitializeDb`; the `## Notes` line in the `.toc` and the README list.
