-- Called when the addon is loaded
function ExecuteRange_Core:OnInitialize()
    print("On Init");
	-- Init DB
	local localizedClass, englishClass = UnitClass("player");
    ExecuteRange_Settings.CurrentClass = englishClass;
    
	ExecuteRange_DB = LibStub("AceDB-3.0"):New("ExecuteRangeDB",ExecuteRange_Settings:GetDefaults(englishClass))
    
	if ExecuteRange_Settings.CurrentClass ~= "ROGUE" and ExecuteRange_Settings.CurrentClass ~="WARLOCK" and 
        ExecuteRange_Settings.CurrentClass ~= "PRIEST" and ExecuteRange_Settings.CurrentClass ~="MONK" and 
        ExecuteRange_Settings.CurrentClass ~="DEATHKNIGHT" and ExecuteRange_Settings.CurrentClass ~="WARRIOR" and 
        ExecuteRange_Settings.CurrentClass ~="PALADIN" then 
            ExecuteRange_Console:Print("Your class is not Supported !! Addon will be disabled");
            ExecuteRange_Core:Disable();
		return;
	end
	
	-- Registers the slash commands handler
	ExecuteRange_Core:RegisterChatCommand("exrange", "SlashCommandHandler", true);

	if ExecuteRange_DB.profile.enabled == false then
		ExecuteRange_Core:Disable();
		return;
	end
end

-- Called when the addon is enabled
function ExecuteRange_Core:OnEnable()

	-- Collects all the buttons of the UI in the global array Buttons
    --Buttons = ExecuteRange:GetAllButtons()

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

	ExecuteRange_Console:Print("To see a list of commands type /exrange help");
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
	if msg == nil or msg == "" or msg == "help" then 
		ExecuteRange_Console:Print("/exrange help  -- This info");		
		ExecuteRange_Console:Print("/exrange status  -- Current status of the addon");	
		ExecuteRange_Console:Print("/exrange sa on  -- Turns spell alerts visual on");
		ExecuteRange_Console:Print("/exrange sa off  -- Turns spell alerts visual off");
		ExecuteRange_Console:Print("/exrange enable -- Enables the addon");		
		ExecuteRange_Console:Print("/exrange disable -- Disables the addon");
	elseif msg == "sa on" then
		ExecuteRange_DB.profile.showSpellAlert = true;
		ExecuteRange_Console:Print("Spell alerts: on");
	elseif msg == "sa off" then
		ExecuteRange_DB.profile.showSpellAlert = false;
		ExecuteRange_Console:Print("Spell alerts: off");
	elseif msg == "enable" then
		ExecuteRange_DB.profile.enabled = true;
		ExecuteRange_Core:Enable();
		ExecuteRange_Console:Print("Enabled");
	elseif msg == "disable" then
		ExecuteRange_DB.profile.enabled = false;
		ExecuteRange_Core:Disable();
		ExecuteRange_Console:Print("Disabled");
	elseif msg == "status" then
		if ExecuteRange_DB.profile.enabled then 
			ExecuteRange_Console:Print("Enabled");
		else
			ExecuteRange_Console:Print("Disabled");
		end
		if ExecuteRange_DB.profile.showSpellAlert then
			ExecuteRange_Console:Print("Spell alerts: on");
		else
			ExecuteRange_Console:Print("Spell alerts: off");
		end
	elseif msg == "debug" then
		if ExecuteRange_Settings.IsDebugEnabled then
			ExecuteRange_Console:Print("Debug Disabled");
			ExecuteRange_Settings.IsDebugEnabled = false;
		else
			ExecuteRange_Console:Print("Debug Enabled");
			ExecuteRange_Settings.IsDebugEnabled = true;
		end
	else
		ExecuteRange_Console:Print("Unknown command. To see a list of commands type /exrange help");		
	end	
end