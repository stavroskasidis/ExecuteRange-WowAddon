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
    local percentage = 0;
    if maxHealth > 0 and health > 0 then
        percentage = (health/maxHealth) * 100;
    end
    local executeRange = ExecuteRange_SpellAlertsHandler:GetExecuteRange();
    ExecuteRange_Console:Debug("======== ShowOrHideFlasher start =============");
	ExecuteRange_Console:Debug("info: percentage: " .. percentage);
    ExecuteRange_Console:Debug("info: maxHealth: " .. maxHealth);
    ExecuteRange_Console:Debug("info: health: " .. health);
    ExecuteRange_Console:Debug("info: executeRange: " .. executeRange);	
    local foundButtons = ExecuteRange_ButtonsResolver:GetValidButtons();
	local skillAvailable = false;
    for id,button in pairs(foundButtons) do
		local spellId = ExecuteRange_ButtonsResolver:GetButtonSpellId(button);
		local _, globalCooldown = GetSpellCooldown(61304);
		local start, duration = GetSpellCooldown(spellId);
		ExecuteRange_Console:Debug("info: GCD: " .. globalCooldown .. ", Spell duration: " .. duration);
		if ExecuteRange_DB.profile.showOnCooldown or duration == 0 or globalCooldown >= duration  then -- spell is not on cooldown or is shown always
			skillAvailable = true;
		end
		break;
    end

    if percentage <= executeRange and not UnitIsDead("target") and UnitCanAttack("player","target") and skillAvailable then 
--        -- Show Glow

        ExecuteRange_Console:Debug(" =>   Will show alert");
--        local foundButtons = ExecuteRange_ButtonsResolver:GetValidButtons();

        for id,button in pairs(foundButtons) do
            ActionButton_ShowOverlayGlow(button);
        end

        --Show Spell Alert
        if ExecuteRange_DB.profile.showSpellAlert and table.getn(foundButtons) > 0  then
            ExecuteRange_Console:Debug("showing alert");
            ExecuteRange_SpellAlertsHandler:ShowSpellAlert(ExecuteRange_Constants.OVERLAY_ID);
        end

    else
        -- Hide Glow
        ExecuteRange_Console:Debug(" =>   Will hide alert");
        for id,button in pairs(foundButtons) do
            ActionButton_HideOverlayGlow(button);
        end

        --Hide Spell Alert
        if ExecuteRange_DB.profile.showSpellAlert then
            ExecuteRange_SpellAlertsHandler:HideSpellAlert(ExecuteRange_Constants.OVERLAY_ID);
        end 
    end
end
    
    --Shows a Spell Alert Overlay appropriate to the logged in class
    --documentation for api call: SpellActivationOverlay_ShowOverlay(self, spellID, texturePath, position, scale, r, g, b, vFlip, hFlip)
function ExecuteRange_SpellAlertsHandler:ShowSpellAlert(id)
    -- ExecuteRange_Console:Debug("show spell alert");
    for key, alert in pairs(ExecuteRange_DB.profile.alerts) do
        -- ExecuteRange_Console:Debug("texture: " .. alert.texture);
        -- ExecuteRange_Console:Debug("position: " .. alert.position);
        -- ExecuteRange_Console:Debug("scale: " .. alert.scale);
        -- ExecuteRange_Console:Debug("red: " .. alert.red);
        -- ExecuteRange_Console:Debug("green: " .. alert.green);
        -- ExecuteRange_Console:Debug("verticalFlip: " .. tostring(alert.verticalFlip));
        -- ExecuteRange_Console:Debug("horizontalFlip: " .. tostring(alert.horizontalFlip));

        -- Using custom implementation instead of defalt (restore after/if bug is fixed):
        -- SpellActivationOverlay_ShowOverlay(SpellActivationOverlayFrame, id, alert.texture, alert.position, alert.scale, alert.red, alert.green, alert.blue, alert.verticalFlip, alert.horizontalFlip);
        ExecuteRange_SpellActivationOverlay:SpellActivationOverlay_ShowOverlay(ExecuteRangeSpellActivationOverlayFrame, id, alert.texture, alert.position, alert.scale, alert.red, alert.green, alert.blue, alert.verticalFlip, alert.horizontalFlip);
    end
end
    
function ExecuteRange_SpellAlertsHandler:HideSpellAlert(id)
    ExecuteRange_Console:Debug("Hiding spell alert");
    -- Using custom implementation instead of defalt (restore after/if bug is fixed):
    -- SpellActivationOverlay_HideOverlays(SpellActivationOverlayFrame, id);
    ExecuteRange_SpellActivationOverlay:SpellActivationOverlay_HideOverlays(ExecuteRangeSpellActivationOverlayFrame, id);
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
    -- ExecuteRange_Console:Debug("geting execute range")	
    if ExecuteRange_Settings.CurrentClass == "HUNTER" then
		local usable = IsUsableSpell(ExecuteRange_Constants.VALID_SPELLS_IDS["KILL_SHOT_ID"]);
		local usableSurv = IsUsableSpell(ExecuteRange_Constants.VALID_SPELLS_IDS["KILL_SHOT_SURVIVAL_ID"]);
        if usable or usableSurv then
           return 101;		--A execute range of 101 will always be higher than the target's life percentage, so the effect will be activated
        else 
            return 0;		--A execute range of 0 will always be lower than the target's life percentage, so the effect will NOT be activated
        end
        -- return ExecuteRange_Constants.KILL_SHOT_EXECUTE_RANGE;
    elseif ExecuteRange_Settings.CurrentClass == "WARLOCK" then
        
        local id, specName = GetSpecializationInfo(GetSpecialization());
        if specName == "Destruction" then
            local soulShards=UnitPower("player",7);
            if soulShards >= 1 then
                return ExecuteRange_Constants.SHADOWBURN_EXECUTE_RANGE;
            else
                return 0; -- No soul shards to cast shadowburn, return 0 to prevent show
            end
        else
            return ExecuteRange_Constants.DRAIN_SOUL_EXECUTE_RANGE;
        end
	elseif ExecuteRange_Settings.CurrentClass == "MAGE" then
        local id, specName = GetSpecializationInfo(GetSpecialization());
        if specName == "Fire" then
            local talentID, name, texture, selected = GetTalentInfo(1, 3, 1);
            if selected then
                return ExecuteRange_Constants.SCORCH_EXECUTE_RANGE;
            else
                return 0; -- Untalented scorch
            end
        else
			return 0;
		end
    elseif ExecuteRange_Settings.CurrentClass == "PRIEST" then
        return ExecuteRange_Constants.SHADOW_WORD_DEATH_EXECUTE_RANGE;
    elseif ExecuteRange_Settings.CurrentClass == "DEATHKNIGHT" then
        return ExecuteRange_Constants.SOUL_REAPER_EXECUTE_RANGE;
    elseif ExecuteRange_Settings.CurrentClass == "PALADIN" then
        local usable = IsUsableSpell(ExecuteRange_Constants.VALID_SPELLS_IDS["HAMMER_OF_WRATH_ID"]);
        if usable then
            return 101;		--A execute range of 101 will always be higher than the target's life percentage, so the effect will be activated
        else 
            return 0;		--A execute range of 0 will always be lower than the target's life percentage, so the effect will NOT be activated
        end
    elseif ExecuteRange_Settings.CurrentClass == "WARRIOR" then
		local usable = IsUsableSpell(ExecuteRange_Constants.VALID_SPELLS_IDS["EXECUTE_FURY_ID"]);
		local usableFuryMass = IsUsableSpell(ExecuteRange_Constants.VALID_SPELLS_IDS["EXECUTE_FURY_MASSACRE_ID"]);
		local usableArmsProt = IsUsableSpell(ExecuteRange_Constants.VALID_SPELLS_IDS["EXECUTE_ARMS_PROT_ID"]);
		local usableMass = IsUsableSpell(ExecuteRange_Constants.VALID_SPELLS_IDS["EXECUTE_ARMS_MASSACRE_ID"]);
        if usable or usableFuryMass or usableArmsProt or usableMass then
            return 101;		--A execute range of 101 will always be higher than the target's life percentage, so the effect will be activated
        else 
            return 0;		--A execute range of 0 will always be lower than the target's life percentage, so the effect will NOT be activated
        end
    elseif ExecuteRange_Settings.CurrentClass == "MONK" then  
		local usable = IsUsableSpell(ExecuteRange_Constants.VALID_SPELLS_IDS["TOUCH_OF_DEATH_ID"]);
        if usable then
            return 101;		--A execute range of 101 will always be higher than the target's life percentage, so the effect will be activated
        else 
            return 0;		--A execute range of 0 will always be lower than the target's life percentage, so the effect will NOT be activated
        end
    end
end
    
