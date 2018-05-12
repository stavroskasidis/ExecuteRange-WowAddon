--dependencies
local ExecuteRange_Settings = ExecuteRange_Settings;
local ExecuteRange_Core = ExecuteRange_Core;
--------------

function ExecuteRange_Console:Debug(msg)
	if ExecuteRange_Settings.IsDebugEnabled then
		ExecuteRange_Core:Print(msg);
	end
end

function ExecuteRange_Console:Print(msg)
	ExecuteRange_Core:Print(msg);
    
    
end