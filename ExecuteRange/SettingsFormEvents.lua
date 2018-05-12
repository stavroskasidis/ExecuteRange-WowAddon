--dependencies
local ExecuteRange_Console = ExecuteRange_Console;
--------------

function ExecuteRange_SettingsFormEvents:OnLoad(panel)
        ExecuteRange_Console:Debug("form loaded");
        -- Set the name for the Category for the Panel
        panel.name = "Execute Range " .. GetAddOnMetadata("ExecuteRange", "Version");
    
        -- When the player clicks okay, run this function.
        panel.okay = function (self) ExecuteRange_SettingsFormEvents:OnOk(); end;
    
        -- When the player clicks cancel, run this function.
        panel.cancel = function (self)  ExecuteRange_SettingsFormEvents:OnCancel();  end;
    
        -- Add the panel to the Interface Options
        InterfaceOptions_AddCategory(panel);
end
    
function ExecuteRange_SettingsFormEvents:OnOk()
    ExecuteRange_Console:Debug("form ok pressed");
end

function ExecuteRange_SettingsFormEvents:OnCancel()
    ExecuteRange_Console:Debug("form cancel pressed");
end