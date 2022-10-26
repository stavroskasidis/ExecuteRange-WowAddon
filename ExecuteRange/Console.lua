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

function ExecuteRange_Console:PrintTalentNodes()
	local configInfo = C_Traits.GetConfigInfo(C_ClassTalents.GetActiveConfigID());
	local nodeids = C_Traits.GetTreeNodes(configInfo.treeIDs[1]);
	for i=1, #nodeids do
		local nodeInfo = C_Traits.GetNodeInfo(configInfo.ID, nodeids[i]);
		for j=1, #nodeInfo.entryIDs do
			local entryInfo = C_Traits.GetEntryInfo(configInfo.ID, nodeInfo.entryIDs[j]);
			local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID);
			local spellName = GetSpellInfo(definitionInfo.spellID);	
			local activeEntryId = "";
			if nodeInfo.activeEntry ~= nil then
				activeEntryId = nodeInfo.activeEntry.entryID;
			end
			print("Node: " .. nodeInfo.ID .. ",SpellName:" .. spellName ..  ",Rank:" .. nodeInfo.ranksPurchased .. ",Entryid:" .. nodeInfo.entryIDs[j] .. "ActiveEntry:" .. activeEntryId ..",SpellId: " .. definitionInfo.spellID)
		end
	end
end