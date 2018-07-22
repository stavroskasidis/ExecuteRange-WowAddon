--dependencies
local ExecuteRange_Console = ExecuteRange_Console;
local ExecuteRange_ButtonsResolver = ExecuteRange_ButtonsResolver;
local ExecuteRange_Constants = ExecuteRange_Constants;
local ExecuteRange_Settings = ExecuteRange_Settings;
--------------

--Main function. Shows or hides the glow/spell alert accordingly
function ExecuteRange_SpellAlertsHandler:ShowOrHideFlasher()
    local health = UnitHealth("target");
    local maxHealth = UnitHealthMax("target"); 
    local percentage = (health/maxHealth) * 100;
    local executeRange = ExecuteRange_SpellAlertsHandler:GetExecuteRange();
    ExecuteRange_Console:Debug("percentage" .. percentage);
    ExecuteRange_Console:Debug("maxHealth" .. maxHealth);
    ExecuteRange_Console:Debug("health" .. health);
    ExecuteRange_Console:Debug("executeRange" .. executeRange);	
    if percentage <= executeRange and not UnitIsDead("target") and UnitCanAttack("player","target") then 
        -- Show Glow
        ExecuteRange_Console:Debug("will show alert");
        local foundButtons = ExecuteRange_ButtonsResolver:GetValidButtons();

        for id,button in pairs(foundButtons) do
            ActionButton_ShowOverlayGlow(button);
        end

        --Show Spell Alert
        if ExecuteRange_DB.profile.showSpellAlert and table.getn(foundButtons) > 0  then
            ExecuteRange_Console:Debug("showing alert");
            ExecuteRange_SpellAlertsHandler:ShowSpellAlert();
        end

    else
        -- Hide Glow
        ExecuteRange_Console:Debug("will hide alert");
        local foundButtons = ExecuteRange_ButtonsResolver:GetValidButtons();
        for id,button in pairs(foundButtons) do
            ActionButton_HideOverlayGlow(button);
        end

        --Hide Spell Alert
        if ExecuteRange_DB.profile.showSpellAlert then
            ExecuteRange_SpellAlertsHandler:HideSpellAlert();
        end 
    end
end
    
    --Shows a Spell Alert Overlay appropriate to the logged in class
    --documentation for api call: SpellActivationOverlay_ShowOverlay(self, spellID, texturePath, position, scale, r, g, b, vFlip, hFlip)
function ExecuteRange_SpellAlertsHandler:ShowSpellAlert()
    ExecuteRange_Console:Debug("showing alert")
    for key, alert in pairs(ExecuteRange_DB.profile.alerts) do
        ExecuteRange_Console:Debug("texture: " .. alert.texture);
        ExecuteRange_Console:Debug("position: " .. alert.position);
        ExecuteRange_Console:Debug("scale: " .. alert.scale);
        ExecuteRange_Console:Debug("red: " .. alert.red);
        ExecuteRange_Console:Debug("green: " .. alert.green);
        ExecuteRange_Console:Debug("verticalFlip: " .. tostring(alert.verticalFlip));
        ExecuteRange_Console:Debug("horizontalFlip: " .. tostring(alert.horizontalFlip));
        SpellActivationOverlay_ShowOverlay(SpellActivationOverlayFrame, "EXECUTE_RANGE_OVERLAY", alert.texture, alert.position, alert.scale, alert.red, alert.green, alert.blue, alert.verticalFlip, alert.horizontalFlip);
    end
end
    
function ExecuteRange_SpellAlertsHandler:HideSpellAlert()
    SpellActivationOverlay_HideOverlays(SpellActivationOverlayFrame, "EXECUTE_RANGE_OVERLAY");
end
    	
function ExecuteRange_SpellAlertsHandler:UnitHasBuff(unit, buffName)
	for i=1,40 do
	  local name = UnitBuff(unit,i)
	  if name == buffName then
		return true;
	  end
	end
	return false;
end

    --Gets the health percentage that execute procs depending on logged in class
function ExecuteRange_SpellAlertsHandler:GetExecuteRange()
    ExecuteRange_Console:Debug("geting execute range")	
    if ExecuteRange_Settings.CurrentClass == "ROGUE" then
        return ExecuteRange_Constants.DISPATCH_EXECUTE_RANGE;
    elseif ExecuteRange_Settings.CurrentClass == "WARLOCK" then
        return ExecuteRange_Constants.SHADOWBURN_EXECUTE_RANGE;
    elseif ExecuteRange_Settings.CurrentClass == "PRIEST" then
        return ExecuteRange_Constants.SHADOW_WORD_DEATH_EXECUTE_RANGE;
    elseif ExecuteRange_Settings.CurrentClass == "DEATHKNIGHT" then
        --check if deathknight has draenor perk "Improved Soul Reaper"
        spellName = GetSpellInfo("Improved Soul Reaper");
        if spellName~=nill then 
            ExecuteRange_Console:Debug("dk has perk")
            return ExecuteRange_Constants.IMPROVED_SOUL_REAPER_EXECUTE_RANGE;
        else
            return ExecuteRange_Constants.NORMAL_SOUL_REAPER_EXECUTE_RANGE;
        end
    elseif ExecuteRange_Settings.CurrentClass == "PALADIN" then
        local id, specName, description, icon, background,role=GetSpecializationInfo(GetSpecialization());
        --For Paladins we first check if spec is Retribution and Avenging Wrath is active. If not return the execute range
        if specName == "Retribution" then
            ExecuteRange_Console:Debug("pala is retri")
            if ExecuteRange_SpellAlertsHandler:UnitHasBuff("player","Avenging Wrath") then
                ExecuteRange_Console:Debug("avenging wrath is active")
                return 101;		--A execute range of 101 will always be higher than the target's life percentage, so the effect will be activated
            end
        end
                --check if paladin has draenor perk "Empowered Hammer of Wrath"
        spellName = GetSpellInfo("Empowered Hammer of Wrath");
        if spellName~=nill then 
            ExecuteRange_Console:Debug("pala has perk")
            return ExecuteRange_Constants.EMPOWERED_HAMMER_OF_WRATH_EXECUTE_RANGE;
        else
            return ExecuteRange_Constants.NORMAL_HAMMER_OF_WRATH_EXECUTE_RANGE;
        end
    elseif ExecuteRange_Settings.CurrentClass == "WARRIOR" then
        --For Warriors we first check if Sudden Death proc is active. If not return the normal Execute range
        if ExecuteRange_SpellAlertsHandler:UnitHasBuff("player","Sudden Death") then
            return 101;		--A execute range of 101 will always be higher than the target's life percentage, so the effect will be activated
        else 
            return ExecuteRange_Constants.EXECUTE_RANGE;
        end
    elseif ExecuteRange_Settings.CurrentClass == "MONK" then  
    --Monk is a special case. The percentage is not fixed. If the buff "Death Note" is active you can cast Touch of Death.
        if ExecuteRange_SpellAlertsHandler:UnitHasBuff("player","Death Note") then -- if name is nil then "Death Note" is not active
            return 101;		--A execute range of 101 will always be higher than the target's life percentage, so the effect will be activated
        else 
            return 0;		--A execute range of 0 will always be lower than the target's life percentage, so the effect will NOT be activated
        end
    end
end
    
