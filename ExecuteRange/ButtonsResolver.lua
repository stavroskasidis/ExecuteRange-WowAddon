--dependencies
local _G = _G --Global enviroment table provided by WoW Api
local ExecuteRange_Constants = ExecuteRange_Constants;
local ExecuteRange_Console = ExecuteRange_Console;
local IsAddOnLoaded = _G.IsAddOnLoaded
--------------

ExecuteRange_ButtonsResolver.Buttons = nil ; 

--Finds the buttons that have valid abilities e.x. "Execute", "Hammer of Wrath" etc
--@param buttons The array of buttons to look into
function ExecuteRange_ButtonsResolver:GetValidButtons()
    --init buttons array
    if ExecuteRange_ButtonsResolver.Buttons == nil then
        ExecuteRange_ButtonsResolver.Buttons = ExecuteRange_ButtonsResolver:GetAllButtons();
    end
    
    local foundButtons = {};
    for name,button in pairs(ExecuteRange_ButtonsResolver.Buttons) do
        local LAB = LibStub("LibActionButton-1.0", true);
        local spellId = ExecuteRange_ButtonsResolver:GetButtonSpellId(button);
        if ExecuteRange_ButtonsResolver:TableContainsItem(ExecuteRange_Constants.VALID_SPELLS_IDS,spellId) then
            table.insert(foundButtons,button);
        end
    end
    return foundButtons;
end

function ExecuteRange_ButtonsResolver:GetButtonSpellId(button)
	local spellId; 
	if IsAddOnLoaded('Bartender4') then
		spellId = button:GetSpellId();
	else		 --blizzardUI/dominos
		_,spellId = GetActionInfo(button.action);
	end

	return spellId;
end

--Checks if an item is contained in a table
--@param tbl The table to check
--@param item The item to check if it exists in the table
function ExecuteRange_ButtonsResolver:TableContainsItem(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return true end
    end
    return false
end

--Gets all the buttons of the UI. Currently Bartender and Blizzard UI are supported
function ExecuteRange_ButtonsResolver:GetAllButtons()
    
    --TODO
    --'LibActionButton-1.0-ElvUI'
	--'LibActionButton-1.0-nMainbar'

    local buttons ={};
    if IsAddOnLoaded('Bartender4') then
        ExecuteRange_Console:Print("Bartender4 Detected");
        local LAB = LibStub("LibActionButton-1.0", true);
        for button in pairs(LAB:GetAllButtons()) do
            buttons[button:GetName()] = button;
        end
    elseif IsAddOnLoaded("Dominos") then
        ExecuteRange_Console:Print("Dominos Detected");
        for i = 1, 120 do
            local button = _G["DominosActionButton"..i];
            if button then
                buttons[button:GetName()] = button;
            end
        end
        -- Dominos reuses blizzard's UI
        ExecuteRange_ButtonsResolver:GetBlizzardButtons("ActionButton",buttons);
        ExecuteRange_ButtonsResolver:GetBlizzardButtons("MultiBarRightButton",buttons);
        ExecuteRange_ButtonsResolver:GetBlizzardButtons("MultiBarLeftButton",buttons);
        ExecuteRange_ButtonsResolver:GetBlizzardButtons("MultiBarBottomRightButton",buttons);
        ExecuteRange_ButtonsResolver:GetBlizzardButtons("MultiBarBottomLeftButton",buttons);
    else
        ExecuteRange_Console:Print("BlizzardUI Detected");
        ExecuteRange_ButtonsResolver:GetBlizzardButtons("ActionButton",buttons);
        ExecuteRange_ButtonsResolver:GetBlizzardButtons("BonusActionButton",buttons);
        ExecuteRange_ButtonsResolver:GetBlizzardButtons("MultiBarRightButton",buttons);
        ExecuteRange_ButtonsResolver:GetBlizzardButtons("MultiBarLeftButton",buttons);
        ExecuteRange_ButtonsResolver:GetBlizzardButtons("MultiBarBottomRightButton",buttons);
        ExecuteRange_ButtonsResolver:GetBlizzardButtons("MultiBarBottomLeftButton",buttons);
    end
    return buttons;
end

-- Collects Blizzard's UI buttons and adds them to the given buttons array.
--@param barName The name of the blizzard bar to collect buttons from. e.x. "ActionButton", "MultiBarRightButton"
--@param buttonsArray The array to insert into the buttons found.
--@param count The number of buttons of this type. Default 12.
function ExecuteRange_ButtonsResolver:GetBlizzardButtons(buttonType, buttonsArray, count)
    for i=1,(count or 12) do
        if _G[buttonType .. i] ~= nil then
            buttonsArray[buttonType .. i] = _G[buttonType .. i];
        end
    end
end
