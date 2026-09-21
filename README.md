# ExecuteRange - WowAddon
https://www.curseforge.com/wow/addons/execute-range

## General
Displays a button glow and an optional spell alert when the target is within "Execute" range.

## Classes - Spells Supported
* Warrior - Execute
* Hunter - Kill Shot (Marksmanship) / Black Arrow
* Monk - Touch of Death
* Death Knight - Soul Reaper
* Warlock - Shadowburn / Drain Soul
* Priest - Shadow Word: Death
* Mage - Scorch

## Description
Supported spells will glow when the target is below a certain percentage of health and optionally a spell alert will be shown. The spell alert overlay is configurable (texture/location/color etc)

Supports: Bartender4, Dominos, Blizzard Default UI

### Midnight (12.0+) and secret values
Since Midnight an enemy's health and the player's cooldowns are "secret values" that addons cannot compare or do
maths on. ExecuteRange therefore never reads the target's health:

* Spells that are only castable in execute range (Execute, Kill Shot, Touch of Death, Soul Reaper,
  Shadowburn) are detected through the spell's usability, which is not secret.
* Spells that are always castable but stronger below a threshold (Shadow Word: Death, Drain Soul, Scorch) have
  their alert's visibility driven by the game client itself: the target's health percentage is fed through a
  curve into the alert's transparency, so it becomes visible at the threshold without the addon ever seeing
  the value. As a consequence there is no fade-in animation or sound for these spells.
* The "Show On Cooldown" option works the same way, through the spell's cooldown.
* If Blizzard's own action-button glow fires for one of the spells, the alert follows it.

Buttons Blizzard already glows itself are left alone so the glow is never doubled.

Paladin support was dropped in 4.0: since Midnight, Hammer of Wrath is an empowered Judgment during Avenging
Wrath and no longer has an execute condition.
