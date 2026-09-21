--dependencies
local ExecuteRange_Console = ExecuteRange_Console;
local ExecuteRange_ButtonsResolver = ExecuteRange_ButtonsResolver;
local ExecuteRange_Constants = ExecuteRange_Constants;
local ExecuteRange_Core = ExecuteRange_Core;
--------------

-- Since 12.0 (Midnight) an enemy's health and the player's cooldowns are "secret values" in combat: the
-- addon can store and pass them around but any comparison or arithmetic on them is a Lua error. The
-- decision "is the target in execute range" is therefore split in two:
--
--   * usable spells (Execute, Kill Shot, Touch of Death, Soul Reaper, Shadowburn): the
--     spell is only castable in execute range, and C_Spell.IsSpellUsable() is never secret, so the addon
--     knows the answer and shows/hides the alert outright.
--   * threshold spells (Shadow Word: Death, Drain Soul, Scorch): the alert is shown whenever an attackable
--     target exists, and its *alpha* is driven by UnitHealthPercent() evaluated through a curve that maps
--     "health <= threshold" to 1 and everything else to 0. The addon never sees the value, the client does.
--
-- The same trick gates the alert on the spell's cooldown (unless "Show On Cooldown" is set). The two
-- gates are nested frames (health gate > cooldown gate) so their alphas multiply.
-- Blizzard's own action-button glow for a spell (SPELL_ACTIVATION_OVERLAY_GLOW_SHOW, also never secret)
-- counts as "in execute range" for both kinds of spell.

-- What is currently displayed
local state = {
	shown = false,          -- the alert (button glows and/or overlay) is displayed
	spellId = nil,          -- the spell it is displayed for
	buttons = {},           -- buttons we put a glow on, keyed by button
	refreshTimer = nil,     -- AceTimer handle re-applying the gate alphas while shown
	lastDecision = nil,     -- last debug-logged decision
};

-- Curves are built once and reused; their points are plain numbers so results are only secret if the
-- evaluated value was.
local healthCurves = {};    -- threshold -> curve, 1 when the health fraction is at/below threshold, else 0
local cooldownCurve;        -- 1 when the remaining cooldown is 0 seconds, else 0

local function GetHealthCurve(threshold)
	local curve = healthCurves[threshold];
	if curve == nil then
		local fraction = threshold / 100;
		curve = C_CurveUtil.CreateCurve();
		curve:SetType(Enum.LuaCurveType.Linear);
		curve:AddPoint(0, 1);
		curve:AddPoint(fraction, 1);
		curve:AddPoint(fraction + 0.0001, 0);
		curve:AddPoint(1, 0);
		healthCurves[threshold] = curve;
	end
	return curve;
end

local function GetCooldownCurve()
	if cooldownCurve == nil then
		cooldownCurve = C_CurveUtil.CreateCurve();
		cooldownCurve:SetType(Enum.LuaCurveType.Linear);
		cooldownCurve:AddPoint(0, 1);
		cooldownCurve:AddPoint(0.05, 0);
		cooldownCurve:AddPoint(86400, 0);
	end
	return cooldownCurve;
end

-- IsSpellUsable on the base spell, or on the spell currently replacing it (e.g. Massacre's Execute,
-- Dark Ranger's Black Arrow)
local function IsSpellUsable(spellId)
	if C_Spell.IsSpellUsable(spellId) then
		return true;
	end
	local overrideId = C_Spell.GetOverrideSpell(spellId);
	return overrideId ~= spellId and C_Spell.IsSpellUsable(overrideId);
end

-- Blizzard glows the button for this spell itself (procs, and execute range for some spells)
local function IsSpellOverlayed(spellId)
	return C_SpellActivationOverlay.IsSpellOverlayed(spellId);
end

-- Whether the player can cast a threshold spell at all (talent spells and overrides such as Drain Soul
-- replacing Shadow Bolt are not reliably reported by C_SpellBook.IsSpellKnown alone)
local function IsSpellKnown(spellId)
	if C_SpellBook.IsSpellKnownOrInSpellBook and C_SpellBook.IsSpellKnownOrInSpellBook(spellId) then
		return true;
	end
	return IsSpellUsable(spellId);
end

-- Works out what should be displayed for the current target.
--@return nil when nothing should be shown, otherwise a table:
--        spellId   the spell the alert is for
--        buttons   the action buttons carrying one of our spells
--        threshold the health % gating the alert, nil when the spell's usability already decided
function ExecuteRange_SpellAlertsHandler:Evaluate()
	if not UnitExists("target") or UnitIsDeadOrGhost("target") or not UnitCanAttack("player", "target") then
		return nil;
	end

	local buttons = ExecuteRange_ButtonsResolver:GetValidButtons();
	if #buttons == 0 then
		return nil;
	end

	local usableSpellId, thresholdSpellId, threshold;
	for _, button in ipairs(buttons) do
		local spellId = ExecuteRange_ButtonsResolver:GetButtonSpellId(button);
		local spell = ExecuteRange_Constants.SPELLS[spellId];
		if IsSpellOverlayed(spellId) or (spell.threshold == nil and IsSpellUsable(spellId)) then
			usableSpellId = spellId;
		elseif spell.threshold ~= nil and IsSpellKnown(spellId) then
			if threshold == nil or spell.threshold > threshold then
				thresholdSpellId = spellId;
				threshold = spell.threshold;
			end
		end
	end

	if usableSpellId ~= nil then
		return { spellId = usableSpellId, buttons = buttons };
	elseif thresholdSpellId ~= nil then
		return { spellId = thresholdSpellId, buttons = buttons, threshold = threshold };
	end
	return nil;
end

-- Prints everything Evaluate() looks at, without touching secret values. `/exrange status`
function ExecuteRange_SpellAlertsHandler:PrintStatus()
	local print = function(msg) ExecuteRange_Console:Print(msg); end
	print("target: exists=" .. tostring(UnitExists("target")) .. " dead=" .. tostring(UnitIsDeadOrGhost("target")) .. " attackable=" .. tostring(UnitCanAttack("player", "target")));
	print("state: shown=" .. tostring(state.shown) .. " spell=" .. tostring(state.spellId) .. " timer=" .. tostring(state.refreshTimer ~= nil));
	local buttons = ExecuteRange_ButtonsResolver:GetValidButtons();
	print("buttons with our spells: " .. #buttons);
	for _, button in ipairs(buttons) do
		local spellId = ExecuteRange_ButtonsResolver:GetButtonSpellId(button);
		local spell = ExecuteRange_Constants.SPELLS[spellId];
		print("  " .. tostring(button:GetName()) .. " -> " .. spell.name .. " (" .. spellId .. ")"
			.. " threshold=" .. tostring(spell.threshold)
			.. " overlayed=" .. tostring(IsSpellOverlayed(spellId))
			.. " usable=" .. tostring(IsSpellUsable(spellId))
			.. " known=" .. tostring(C_SpellBook.IsSpellKnown(spellId))
			.. " knownOrInBook=" .. tostring(C_SpellBook.IsSpellKnownOrInSpellBook and C_SpellBook.IsSpellKnownOrInSpellBook(spellId))
			.. " override=" .. tostring(C_Spell.GetOverrideSpell(spellId))
			.. " glowing=" .. tostring(state.buttons[button] ~= nil));
	end
	if UnitExists("target") then
		-- secret values can be concatenated but not inspected, so only show them when they are not secret
		local percent = UnitHealthPercent("target", true);
		local gated = UnitHealthPercent("target", true, GetHealthCurve(20));
		if issecretvalue(percent) then
			print("target health: secret (curve result secret=" .. tostring(issecretvalue(gated)) .. ")");
		else
			print("target health: " .. percent .. " curve(20%)=" .. gated);
		end
	end
	local result = ExecuteRange_SpellAlertsHandler:Evaluate();
	print("evaluate: " .. (result and ("show spell=" .. result.spellId .. " threshold=" .. tostring(result.threshold)) or "hide"));
end

--Main function. Shows or hides the glow/spell alert accordingly
function ExecuteRange_SpellAlertsHandler:ShowOrHideFlasher()
	local result = ExecuteRange_SpellAlertsHandler:Evaluate();
	local decision = "hide";
	if result then
		decision = "show for spell " .. result.spellId .. (result.threshold and (" gated at " .. result.threshold .. "%") or "");
	end
	-- the refresh timer re-runs this several times a second, only log changes
	if decision ~= state.lastDecision then
		ExecuteRange_Console:Debug("ShowOrHideFlasher => " .. decision);
		state.lastDecision = decision;
	end
	if result then
		ExecuteRange_SpellAlertsHandler:Show(result);
	else
		ExecuteRange_SpellAlertsHandler:Hide();
	end
end

function ExecuteRange_SpellAlertsHandler:Show(result)
	local firstShow = not state.shown or state.spellId ~= result.spellId;

	-- Button glows. Buttons Blizzard already glows for this spell are left to Blizzard.
	local wanted = {};
	for _, button in ipairs(result.buttons) do
		wanted[button] = true;
		if IsSpellOverlayed(ExecuteRange_ButtonsResolver:GetButtonSpellId(button)) then
			ExecuteRange_SpellAlertsHandler:HideButtonGlow(button);
		else
			ExecuteRange_SpellAlertsHandler:ShowButtonGlow(button);
		end
	end
	for button in pairs(state.buttons) do
		if not wanted[button] then
			ExecuteRange_SpellAlertsHandler:HideButtonGlow(button);
		end
	end

	-- Spell alert overlay. Only played once per alert, not on every health update.
	if ExecuteRange_DB.profile.showSpellAlert and firstShow then
		local playSound = result.threshold == nil and not ExecuteRange_SpellAlertsHandler:IsKnownOnCooldown(result.spellId);
		ExecuteRange_SpellAlertsHandler:ShowSpellAlert(ExecuteRangeSpellActivationOverlayFrame, ExecuteRange_Constants.OVERLAY_ID, playSound);
	end

	state.shown = true;
	state.spellId = result.spellId;
	ExecuteRange_SpellAlertsHandler:UpdateGates(result);

	-- The gate alphas are snapshots, keep them fresh while the alert is up (cooldown running out,
	-- health changing without a UNIT_HEALTH event for us)
	if state.refreshTimer == nil then
		state.refreshTimer = ExecuteRange_Core:ScheduleRepeatingTimer(function()
			ExecuteRange_SpellAlertsHandler:ShowOrHideFlasher();
		end, 0.2);
	end
end

function ExecuteRange_SpellAlertsHandler:Hide()
	if state.refreshTimer ~= nil then
		ExecuteRange_Core:CancelTimer(state.refreshTimer);
		state.refreshTimer = nil;
	end
	if not state.shown then
		return;
	end

	for button in pairs(state.buttons) do
		ExecuteRange_SpellAlertsHandler:HideButtonGlow(button);
	end
	ExecuteRange_SpellAlertsHandler:HideSpellAlert(ExecuteRangeSpellActivationOverlayFrame, ExecuteRange_Constants.OVERLAY_ID);

	state.shown = false;
	state.spellId = nil;
end

-- Applies the "in execute range" and "off cooldown" alphas to the overlay gates and the button glows.
-- Either alpha may be a secret value; SetAlpha accepts those.
function ExecuteRange_SpellAlertsHandler:UpdateGates(result)
	local healthAlpha, cooldownAlpha = 1, 1;

	if result.threshold ~= nil then
		healthAlpha = UnitHealthPercent("target", true, GetHealthCurve(result.threshold));
	end

	if not ExecuteRange_DB.profile.showOnCooldown then
		local ignoreGCD = true;
		local duration = C_Spell.GetSpellCooldownDuration(result.spellId, ignoreGCD);
		if duration ~= nil then
			cooldownAlpha = duration:EvaluateRemainingDuration(GetCooldownCurve());
		end
	end

	ExecuteRangeAlertGateFrame:SetAlpha(healthAlpha);
	ExecuteRangeAlertGateFrame.CooldownGate:SetAlpha(cooldownAlpha);
	for button in pairs(state.buttons) do
		local glow = button.ExecuteRangeGlow;
		glow:SetAlpha(healthAlpha);
		glow.Alert:SetAlpha(cooldownAlpha);
	end
end

-- True only when the cooldown can be inspected (out of combat) and the spell is on cooldown. Used to
-- skip the alert sound; the visual is handled by the cooldown gate either way.
function ExecuteRange_SpellAlertsHandler:IsKnownOnCooldown(spellId)
	if ExecuteRange_DB.profile.showOnCooldown then
		return false;
	end
	local ignoreGCD = true;
	local duration = C_Spell.GetSpellCooldownDuration(spellId, ignoreGCD);
	if duration == nil then
		return false;
	end
	if duration:HasSecretValues() then
		return false;
	end
	return duration:IsActive();
end

-- Button glow: our own copy of Blizzard's proc glow (ActionButtonSpellAlertTemplate) inside a gate frame,
-- so it can be alpha-gated like the overlay and never fights Blizzard's own glow on the same button.
function ExecuteRange_SpellAlertsHandler:GetButtonGlow(button)
	local glow = button.ExecuteRangeGlow;
	if glow == nil then
		glow = CreateFrame("Frame", nil, button);
		glow:SetAllPoints(button);
		local alert = CreateFrame("Frame", nil, glow, "ActionButtonSpellAlertTemplate");
		local width, height = button:GetSize();
		alert:SetSize(width * 1.4, height * 1.4);
		alert:SetPoint("CENTER", glow, "CENTER", 0, 0);
		glow.Alert = alert;
		glow:Hide();
		button.ExecuteRangeGlow = glow;
	end
	return glow;
end

function ExecuteRange_SpellAlertsHandler:ShowButtonGlow(button)
	if state.buttons[button] then
		return;
	end
	local glow = ExecuteRange_SpellAlertsHandler:GetButtonGlow(button);
	glow:Show();
	glow.Alert:Show();
	glow.Alert.ProcStartAnim:Play(); -- the template's mixin chains ProcLoop after it
	state.buttons[button] = true;
end

function ExecuteRange_SpellAlertsHandler:HideButtonGlow(button)
	if not state.buttons[button] then
		return;
	end
	local glow = button.ExecuteRangeGlow;
	glow.Alert.ProcStartAnim:Stop();
	glow.Alert.ProcLoop:Stop();
	glow.Alert:Hide();
	glow:Hide();
	state.buttons[button] = nil;
end

--Shows the profile's spell alert overlays on the given overlay frame
--@param frame ExecuteRangeSpellActivationOverlayFrame or ExecuteRangeSpellActivationOverlayPreviewFrame
--@param id ExecuteRange_Constants.OVERLAY_ID or OVERLAY_PREVIEW_ID
--@param playSound whether to play the spell alert sound
function ExecuteRange_SpellAlertsHandler:ShowSpellAlert(frame, id, playSound)
	frame:ShowAlerts(ExecuteRange_DB.profile.alerts, id, playSound);
end

function ExecuteRange_SpellAlertsHandler:HideSpellAlert(frame, id)
	ExecuteRange_Console:Debug("Hiding spell alert");
	frame:HideOverlays(id);
end
