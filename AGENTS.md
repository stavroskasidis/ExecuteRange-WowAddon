# AGENTS.md

Guidance for AI coding agents working in this repository.

## What this is

ExecuteRange is a World of Warcraft (retail) addon written in Lua on the Ace3 framework. It glows the action-bar button of the player's class "execute" spell (Warrior Execute, Paladin Hammer of Wrath, Hunter Kill Shot/Black Arrow, Priest Shadow Word: Death, Warlock Drain Soul/Shadowburn, DK Soul Reaper, Monk Touch of Death, Mage Scorch) when the target is in execute range, and optionally shows a configurable full-screen spell-alert overlay. Supports Bartender4, Dominos and the default Blizzard bars. Published on CurseForge: https://www.curseforge.com/wow/addons/execute-range

Targets the live retail client (Midnight, 12.1). Since 12.0 combat data is subject to **secret values** (see below); every design decision in `SpellAlertsHandler.lua` follows from that.

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
- **Debug:** `/exrange debug` toggles debug output (`ExecuteRange_Console:Debug`) to chat; `/exrange status` prints what `Evaluate()` sees for the current target (buttons, usable/known/overlayed per spell, whether health is secret). `/exrange` opens the settings panel. `ExecuteRange_Console:PrintTalentNodes()` dumps the current talent tree (node/entry/spell IDs).
- **API reference:** Blizzard's generated API docs (`Blizzard_APIDocumentationGenerated` in https://github.com/Gethe/wow-ui-source, branch `live`) are the source of truth for which functions exist and which return secrets (`SecretReturns`, `SecretWhen*`, `SecretArguments`). Check there before using a global; many pre-11.0 globals (`IsUsableSpell`, `GetSpellCooldown`, `GetSpellInfo`, `UnitBuff`, `IsAddOnLoaded`, `ActionButton_ShowOverlayGlow`, `InterfaceOptionsFrame_OpenToCategory`) are gone without compat shims.
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
2. `Core.lua:OnEnable` registers `UNIT_HEALTH` (target), `PLAYER_TARGET_CHANGED`, `SPELL_UPDATE_USABLE`, `SPELL_UPDATE_COOLDOWN` and `SPELL_ACTIVATION_OVERLAY_GLOW_SHOW/HIDE`. All funnel into `SpellAlertsHandler:ShowOrHideFlasher()`, which re-evaluates from scratch; a 0.2s AceTimer repeats it while an alert is up.
3. `SpellAlertsHandler:Evaluate` decides what to show (see below); `Show`/`Hide` apply it to the button glows and the overlay, `UpdateGates` refreshes the alpha gates.

### Secret values and the two detection modes

Since 12.0, `UnitHealth`/`UnitHealthPercent` on an enemy and cooldown data in combat return *secret values*: they can be stored and passed to a few widget APIs, but any comparison/arithmetic in addon code is an immediate Lua error. The addon therefore never inspects the target's health. `Constants.SPELLS` (keyed by spell ID) declares one of two modes per spell:

- **usable** (no `threshold`; Execute, Hammer of Wrath, Kill Shot/Black Arrow, Touch of Death, Soul Reaper, Shadowburn): the spell is only castable in execute range, and `C_Spell.IsSpellUsable()` is never secret, so the addon knows the answer and shows/hides outright (with the fade-in and sound). Spell overrides (Massacre, Black Arrow) are covered via `C_Spell.GetOverrideSpell`.
- **threshold** (`threshold = N`; Shadow Word: Death 20, Drain Soul 20, Scorch 30): the alert is shown (silently) whenever an attackable target exists, and its visibility is a *display* concern: `UnitHealthPercent("target", true, curve)` evaluates a step-like `C_CurveUtil` curve (1 at/below the threshold, else 0) and the result, possibly secret, goes straight into `Frame:SetAlpha`, which accepts secrets from addon code.

`C_SpellActivationOverlay.IsSpellOverlayed(spellId)` (Blizzard's own button glow, never secret) counts as "in range" for either mode, and buttons Blizzard already glows get no addon glow.

The cooldown check (`showOnCooldown` off) uses the same trick: `C_Spell.GetSpellCooldownDuration(id, true):EvaluateRemainingDuration(curve)` gives the alpha. The gates are nested frames so the alphas multiply: `ExecuteRangeAlertGateFrame` (health) > `.CooldownGate` (cooldown) > `ExecuteRangeSpellActivationOverlayFrame`; each button gets the same pair (`button.ExecuteRangeGlow` > `.Alert`, an `ActionButtonSpellAlertTemplate`). Never read alpha/health/cooldown values back and never branch on them; `Duration:HasSecretValues()` is the one safe way to ask "can I look at this".

### Button discovery (`ButtonsResolver.lua`)

`GetAllButtons()` picks a strategy by loaded addon: Bartender4 → `LibActionButton-1.0:GetAllButtons()`; Dominos → `DominosActionButtonN` plus Blizzard bars; otherwise Blizzard bar globals (`ActionButtonN`, `MultiBar*ButtonN`). The result is cached in `ExecuteRange_ButtonsResolver.Buttons` on first use and never refreshed (the first use is delayed 1s after enable so bar addons have built their buttons). `GetButtonSpellId` also differs: Bartender buttons expose `:GetSpellId()`, others go through `GetActionInfo(button.action)` (spells, and macros that cast a spell). Buttons are matched against `Constants.SPELLS`.

### Spell alert overlay

`SpellActivationOverlay.lua/.xml` is a forked copy of Blizzard's `SpellActivationOverlay` (`Blizzard_FrameXML/SpellActivationOverlay.lua`), kept because Blizzard's version spammed hide-events since 9.0.1 and because ours takes string positions plus flips. `ExecuteRange_SpellActivationOverlay` is the mixin of two frames: `ExecuteRangeSpellActivationOverlayFrame` (live alert, under the gate frames) and `ExecuteRangeSpellActivationOverlayPreviewFrame` (settings "Preview": `FULLSCREEN_DIALOG` strata, never gated, auto-hidden by an AceTimer after 8s). Each frame has its own overlay pool. Overlays are keyed by a fake spell ID: `Constants.OVERLAY_ID` / `OVERLAY_PREVIEW_ID`.

### Settings model (`Settings.lua`)

Profile shape: `enabled`, `showSpellAlert`, `showOnCooldown`, and `alerts` — a list of `{texture, position, scale, red, green, blue, verticalFlip, horizontalFlip}` with at most one entry per position (`TOP/RIGHT/LEFT/BOTTOM/CENTER`). `GetOptionsTable()` builds one AceConfig group per position dynamically (`textureOptions<POSITION>`). `texture` is a Blizzard file data ID; `Constants.TEXTURE_FILE_IDS` maps the old path names to IDs and `Constants.TEXTURES` maps IDs to display names for the dropdown.

### Adding a spell/class

Touch, in order: `Constants.SPELLS` (an entry per spell ID; give it a `threshold` only if the spell is castable at any health — check the current tooltip on Wowhead, "Only usable on enemies below X%" means no threshold) and `VALID_SPELLS_NAMES_PER_CLASS`; a default alert in `Settings:InitializeDb` for a new class (`SUPPORTED_CLASSES` is derived from `SPELLS`); the `## Notes` line in the `.toc` and the README list.
