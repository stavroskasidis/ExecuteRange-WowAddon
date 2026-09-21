-- Called when the addon is loaded
function ExecuteRange_Core:OnInitialize()
	-- Init DB
	local localizedClass, englishClass = UnitClass("player");
    ExecuteRange_Settings.CurrentClass = englishClass;

	ExecuteRange_DB = LibStub("AceDB-3.0"):New("ExecuteRangeDB");
	ExecuteRange_Settings:InitializeDb(englishClass, ExecuteRange_DB, false);


	for key, alert in pairs(ExecuteRange_DB.profile.alerts) do
		-- backwards compat fix for saved settings before 8.2
		-- https://wow.gamepedia.com/Patch_8.2.0/API_changes

		-- "No files outside of Interface\ can be addressed by file path anymore"

		if type(alert.texture) == "string" then
			-- Convert filepath to id
			alert.texture = ExecuteRange_Constants.TEXTURE_FILE_IDS[alert.texture]
		end
    end

	local options = {};
	local disableOnInit = false;
	if not ExecuteRange_Constants.SUPPORTED_CLASSES[ExecuteRange_Settings.CurrentClass] then
		ExecuteRange_Console:Print("'" .. localizedClass .. "' class is not supported");
		options = ExecuteRange_Settings:GetClassNotSupportedOptionsTable();
		disableOnInit = true;
	else
		ExecuteRange_Settings.CurrentSpell = ExecuteRange_Constants.VALID_SPELLS_NAMES_PER_CLASS[ExecuteRange_Settings.CurrentClass];
		options = ExecuteRange_Settings:GetOptionsTable();
		disableOnInit = not ExecuteRange_DB.profile.enabled;
	end

	LibStub("AceConfig-3.0"):RegisterOptionsTable("ExecuteRange", options);
	ExecuteRange_Core.optionsFrame, ExecuteRange_Core.optionsCategoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ExecuteRange", "Execute Range");
	ExecuteRange_Core:RegisterChatCommand("exrange", "SlashCommandHandler", true);

	if disableOnInit then
		ExecuteRange_Core:Disable();
	end
end

-- Called when the addon is enabled
function ExecuteRange_Core:OnEnable()
	-- Everything funnels into SpellAlertsHandler:ShowOrHideFlasher(), which re-evaluates from scratch.

	--The target's health changed (the payload is the unit token, which is never secret)
	self:RegisterEvent("UNIT_HEALTH");

	--The player's target changed, including when the target is lost
	self:RegisterEvent("PLAYER_TARGET_CHANGED");

	--A spell became usable/unusable or went on/off cooldown (Execute in range, Avenging Wrath for Hammer of Wrath, ...)
	self:RegisterEvent("SPELL_UPDATE_USABLE");
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN");

	--Blizzard's own action-button glow for a spell started/stopped
	self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW");
	self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE");

	--A /reload keeps the target, so evaluate once the action bar addons have built their buttons
	self:ScheduleTimer(function()
		ExecuteRange_SpellAlertsHandler:ShowOrHideFlasher();
	end, 1);
end

-- Called when the addon is disabled
function ExecuteRange_Core:OnDisable()
	ExecuteRange_SpellAlertsHandler:Hide();
end

--UNIT_HEALTH event handler
--@param eventName Placeholder parameter by Ace. The name of the event
--@param arg1 the UnitID that triggered the event. e.x. "target","focus"
function ExecuteRange_Core:UNIT_HEALTH(eventName, arg1)
	if arg1 == "target" then
		ExecuteRange_SpellAlertsHandler:ShowOrHideFlasher();
	end
end

--PLAYER_TARGET_CHANGED event handler
--@param eventName Placeholder parameter by Ace. The name of the event
--@param arg1 The way the target was changed. e.x. Escape, Left click
function ExecuteRange_Core:PLAYER_TARGET_CHANGED(eventName, arg1)
	ExecuteRange_SpellAlertsHandler:ShowOrHideFlasher();
end

function ExecuteRange_Core:SPELL_UPDATE_USABLE(eventName)
	ExecuteRange_SpellAlertsHandler:ShowOrHideFlasher();
end

function ExecuteRange_Core:SPELL_UPDATE_COOLDOWN(eventName)
	ExecuteRange_SpellAlertsHandler:ShowOrHideFlasher();
end

--SPELL_ACTIVATION_OVERLAY_GLOW_SHOW/HIDE event handler
--@param eventName Placeholder parameter by Ace. The name of the event
--@param spellId the spell Blizzard started/stopped glowing
function ExecuteRange_Core:SPELL_ACTIVATION_OVERLAY_GLOW_SHOW(eventName, spellId)
	if ExecuteRange_Constants.SPELLS[spellId] ~= nil then
		ExecuteRange_SpellAlertsHandler:ShowOrHideFlasher();
	end
end

function ExecuteRange_Core:SPELL_ACTIVATION_OVERLAY_GLOW_HIDE(eventName, spellId)
	if ExecuteRange_Constants.SPELLS[spellId] ~= nil then
		ExecuteRange_SpellAlertsHandler:ShowOrHideFlasher();
	end
end

function ExecuteRange_Core:SlashCommandHandler(msg, editbox)
	if msg == "status" then
		ExecuteRange_SpellAlertsHandler:PrintStatus();
	elseif msg == "debug" then
		if ExecuteRange_Settings.IsDebugEnabled then
			ExecuteRange_Console:Print("Debug Disabled");
			ExecuteRange_Settings.IsDebugEnabled = false;
		else
			ExecuteRange_Console:Print("Debug Enabled");
			ExecuteRange_Settings.IsDebugEnabled = true;
		end
	else
		Settings.OpenToCategory(self.optionsCategoryID);
	end
end
