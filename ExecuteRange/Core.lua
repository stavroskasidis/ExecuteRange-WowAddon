-- Called when the addon is loaded
function ExecuteRange_Core:OnInitialize()
	-- Init DB
	local localizedClass, englishClass = UnitClass("player");
    ExecuteRange_Settings.CurrentClass = englishClass;
    
	ExecuteRange_DB = LibStub("AceDB-3.0"):New("ExecuteRangeDB",ExecuteRange_Settings:GetDefaults(englishClass))
    
	local options = {};
	local disableOnInit = false;
	if ExecuteRange_Settings.CurrentClass ~= "ROGUE" and ExecuteRange_Settings.CurrentClass ~="WARLOCK" and 
        ExecuteRange_Settings.CurrentClass ~= "PRIEST" and ExecuteRange_Settings.CurrentClass ~="DEATHKNIGHT" and 
		ExecuteRange_Settings.CurrentClass ~="WARRIOR" and ExecuteRange_Settings.CurrentClass ~="PALADIN" then 
            ExecuteRange_Console:Print("'" .. localizedClass .. "' class is not supported");
			options = ExecuteRange_Settings:GetClassNotSupportedOptionsTable();
            disableOnInit = true;
	else
		ExecuteRange_Settings.CurrentSpell = ExecuteRange_Constants.VALID_SPELLS_NAMES_PER_CLASS[ExecuteRange_Settings.CurrentClass];
		options = ExecuteRange_Settings:GetOptionsTable();
		disableOnInit = not ExecuteRange_DB.profile.enabled;
	end

	LibStub("AceConfig-3.0"):RegisterOptionsTable("ExecuteRange", options);
	ExecuteRange_Core.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ExecuteRange", "ExecuteRange");
	ExecuteRange_Core:RegisterChatCommand("exrange", "SlashCommandHandler", true);

	if disableOnInit then
		ExecuteRange_Core:Disable();
	end
end

-- Called when the addon is enabled
function ExecuteRange_Core:OnEnable()

	--Registers the UNIT_HEALTH event that fires when a unit's health changes
	self:RegisterEvent("UNIT_HEALTH");

	--Registers the PLAYER_TARGET_CHANGED event. This event is fired whenever the player's target is changed, including when the target is lost. 
	self:RegisterEvent("PLAYER_TARGET_CHANGED");

	--Registers the UNIT_AURA event. This event is fired when a buff, debuff, status, or item bonus was gained by or faded from an entity (player, pet, NPC, or mob.) 
	--Used to monitor Monk's Touch of Death, Warrior's Sudden Death and Retribution Paladin's  Avenging Wrath
	if ExecuteRange_Settings.CurrentClass == "MONK" or ExecuteRange_Settings.CurrentClass == "WARRIOR" or
       ExecuteRange_Settings.CurrentClass == "PALADIN" then
		self:RegisterEvent("UNIT_AURA");
	end

end

-- Called when the addon is disabled
function ExecuteRange_Core:OnDisable()
    
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

--UNIT_AURA event handler
--@param eventName Placeholder parameter by Ace. The name of the event
--@param arg1 the UnitID that triggered the event. e.x. "target","focus"
function ExecuteRange_Core:UNIT_AURA(eventName, arg1)
	if arg1 == "player" then
		ExecuteRange_SpellAlertsHandler:ShowOrHideFlasher();
	end
end

function ExecuteRange_Core:SlashCommandHandler(msg, editbox)
	if msg == nil or msg == "" then
		InterfaceOptionsFrame_OpenToCategory(self.optionsFrame);
	elseif msg == "debug" then
		if ExecuteRange_Settings.IsDebugEnabled then
			ExecuteRange_Console:Print("Debug Disabled");
			ExecuteRange_Settings.IsDebugEnabled = false;
		else
			ExecuteRange_Console:Print("Debug Enabled");
			ExecuteRange_Settings.IsDebugEnabled = true;
		end
	end
end