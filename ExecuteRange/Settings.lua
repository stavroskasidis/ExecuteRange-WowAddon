ExecuteRange_Settings.CurrentClass = '';
ExecuteRange_Settings.IsDebugEnabled = false;

function ExecuteRange_Settings:GetDefaults(playerClass) 
    local defaultAlerts = {};
    if playerClass == "ROGUE" then
        local alert1 = {
            texture = "TEXTURES\\SPELLACTIVATIONOVERLAYS\\SUDDEN_DEATH.BLP",
            position = "RIGHT",
            scale = 1,
            red = 255,
            green = 255,
            blue = 255,
            verticalFlip = false,
            horizontalFlip = true;
        };
        local alert2 = {
            texture = "TEXTURES\\SPELLACTIVATIONOVERLAYS\\SUDDEN_DEATH.BLP",
            position = "LEFT",
            scale = 1,
            red = 255,
            green = 255,
            blue = 255,
            verticalFlip = false,
            horizontalFlip = false;
        };
        table.insert(defaultAlerts,alert1);
        table.insert(defaultAlerts,alert2);
    elseif playerClass == "WARLOCK" then
        local alert1 = {
            texture = "TEXTURES\\SPELLACTIVATIONOVERLAYS\\SUDDEN_DOOM.BLP",
            position = "RIGHT",
            scale = 1,
            red = 255,
            green = 255,
            blue = 255,
            verticalFlip = false,
            horizontalFlip = true;
        };
        local alert2 = {
            texture = "TEXTURES\\SPELLACTIVATIONOVERLAYS\\SUDDEN_DOOM.BLP",
            position = "LEFT",
            scale = 1,
            red = 255,
            green = 255,
            blue = 255,
            verticalFlip = false,
            horizontalFlip = false;
        };
        table.insert(defaultAlerts,alert1);
        table.insert(defaultAlerts,alert2);
    elseif playerClass == "PRIEST" then
        local alert1 = {
            texture = "TEXTURES\\SPELLACTIVATIONOVERLAYS\\NECROPOLIS.BLP",
            position = "BOTTOM",
            scale = 1,
            red = 255,
            green = 255,
            blue = 255,
            verticalFlip = true,
            horizontalFlip = true;
        };
        table.insert(defaultAlerts,alert1);
    elseif playerClass == "DEATHKNIGHT" then
        local alert1 = {
            texture = "TEXTURES\\SPELLACTIVATIONOVERLAYS\\NECROPOLIS.BLP",
            position = "BOTTOM",
            scale = 1,
            red = 255,
            green = 255,
            blue = 255,
            verticalFlip = true,
            horizontalFlip = true;
        };
        table.insert(defaultAlerts,alert1);
    elseif playerClass == "MONK" then
        local alert1 = {
            texture = "TEXTURES\\SPELLACTIVATIONOVERLAYS\\DENOUNCE.BLP",
            position = "TOP",
            scale = 2,
            red = 255,
            green = 255,
            blue = 255,
            verticalFlip = false,
            horizontalFlip = false;
        };
        table.insert(defaultAlerts,alert1);
    elseif playerClass == "PALADIN" then
        local alert1 = {
            texture = "TEXTURES\\SPELLACTIVATIONOVERLAYS\\PREDATORY_SWIFTNESS.BLP",
            position = "TOP",
            scale = 1,
            red = 255,
            green = 255,
            blue = 0,
            verticalFlip = false,
            horizontalFlip = false;
        };
        table.insert(defaultAlerts,alert1);
    elseif playerClass == "WARRIOR" then
        local alert1 = {
            texture = "TEXTURES\\SPELLACTIVATIONOVERLAYS\\ULTIMATUM.BLP",
            position = "TOP",
            scale = 1,
            red = 255,
            green = 255,
            blue = 255,
            verticalFlip = false,
            horizontalFlip = false;
        };
        table.insert(defaultAlerts,alert1);
        --local id, specName, description, icon, background,role=GetSpecializationInfo(GetSpecialization());
        --if specName == "Protection" then --if protection spec'ed, show alert on bottom.
        --    SpellActivationOverlay_ShowOverlay(SpellActivationOverlayFrame, "EXECUTE_RANGE_OVERLAY", "TEXTURES\\SPELLACTIVATIONOVERLAYS\\ULTIMATUM.BLP", "BOTTOM", 1, 255, 255,255, true, false);
        --else
        --    SpellActivationOverlay_ShowOverlay(SpellActivationOverlayFrame, "EXECUTE_RANGE_OVERLAY", "TEXTURES\\SPELLACTIVATIONOVERLAYS\\ULTIMATUM.BLP", "TOP", 1, 255, 255,255, false, false);
        --end
    end
    
    local defaults = {
        profile = {
            showSpellAlert = true,
            enabled = true,
            alerts = defaultAlerts
        }
    };
    return defaults;
end
