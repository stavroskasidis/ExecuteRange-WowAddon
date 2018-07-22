-- Called when the addon is loaded
function ExecuteRange_Core:OnInitialize()
	-- Init DB
	local localizedClass, englishClass = UnitClass("player");
    ExecuteRange_Settings.CurrentClass = englishClass;
    
	ExecuteRange_DB = LibStub("AceDB-3.0"):New("ExecuteRangeDB",ExecuteRange_Settings:GetDefaults(englishClass))
    
	local options = {};
	if ExecuteRange_Settings.CurrentClass ~= "ROGUE" and ExecuteRange_Settings.CurrentClass ~="WARLOCK" and 
        ExecuteRange_Settings.CurrentClass ~= "PRIEST" and ExecuteRange_Settings.CurrentClass ~="MONK" and 
        ExecuteRange_Settings.CurrentClass ~="DEATHKNIGHT" and ExecuteRange_Settings.CurrentClass ~="WARRIOR" and 
        ExecuteRange_Settings.CurrentClass ~="PALADIN" then 
            ExecuteRange_Console:Print("Your class is not Supported !! Addon will be disabled");
			options = {
				name = "ExecuteRange",
				handler = ExecuteRange_Core,
				type = 'group',
				args = {
					message = {
						name = "ExecuteRange",
						type = 'description',
						name = "Class not supported"
					}
				}
			}
            ExecuteRange_Core:Disable();
	else
		-- Build options
		options = {
			name = "ExecuteRange",
			handler = ExecuteRange_Core,
			type = 'group',
			args = {
				enabled = {
					type = "toggle",
					name = "Enabled",
					desc = "Enables or disables the addon",
					get = "GetEnabled",
					set = "SetEnabled",
					order = 1
				},
				showSpellAlerts = {
					type = "toggle",
					name = "Show Alerts",
					desc = "Enables or disables the alerts",
					get = "GetShowAlerts",
					set = "SetShowAlerts",
					order = 2
				},
				reset = {
					type = "execute",
					name = "Reset",
					desc = "Resets to the default settings",
					func = "SettingsReset",
					order = 3,
					confirm = "SettingsResetConfirm",
					width = "half"
				},
				preview = {
					type = "execute",
					name = "Preview",
					desc = "Shows the alert",
					func = "Preview",
					order = 4,
					width = "half"
				},
				texturePositions = {
					type = "multiselect",
					name = "Enabled Textures",
					desc = "The positions on the screen that the textures appear",
					values = ExecuteRange_Constants.TEXTURE_POSITIONS,
					get = function(info, position)
						local alert = ExecuteRange_Core:GetAlertByPosition(position);
						return alert ~= nil;
					end,
					set = function(info, position, state)
						if state then
							local newAlert = {
								texture = "TEXTURES\\SPELLACTIVATIONOVERLAYS\\GENERICTOP_01.BLP",
								position = position,
								scale = 1,
								red = 255,
								green = 255,
								blue = 255,
								verticalFlip = false,
								horizontalFlip = false;
							};
							table.insert(ExecuteRange_DB.profile.alerts, newAlert);
						else
							local alert, key = ExecuteRange_Core:GetAlertByPosition(position);
							table.remove(ExecuteRange_DB.profile.alerts, key);
						end
					end,
					order = 5
				}
			}
		}


		-- Build Texture options
		for position, positionDescription in pairs(ExecuteRange_Constants.TEXTURE_POSITIONS) do
			local textureOptions = {
				  name =  positionDescription .. " Texture",
				  type = "group",
				  hidden = function()
					local alert = ExecuteRange_Core:GetAlertByPosition(position);
					return alert == nil;
				  end,
				  args = {
						alertTexture = {
							type = "select",
							name = "Texture",
							desc = "The displayed overlay texture",
							values = ExecuteRange_Constants.TEXTURES,
							style = "dropdown",
							get = function(self)
								local alert = ExecuteRange_Core:GetAlertByPosition(position);
								if alert == nil then return nil; end
								return alert.texture;
							end,
							set = function(info, newValue)
								local alert = ExecuteRange_Core:GetAlertByPosition(position);
								alert.texture = newValue
							end,
							width = "full",
							order = 1
						},
						alertVerticalFlip = {
							type = "toggle",
							name = "Vertical Flip",
							desc = "Flips the texture vertically",
							get = function(info)
								local alert = ExecuteRange_Core:GetAlertByPosition(position);
								if alert == nil then return nil; end
								return alert.verticalFlip;
							end,
							set = function(info, newValue)
								local alert = ExecuteRange_Core:GetAlertByPosition(position);
								alert.verticalFlip = newValue
							end,
							order = 2
						},
						alertHorizontalFlip = {
							type = "toggle",
							name = "Horizontal Flip",
							desc = "Flips the texture horizontally",
							get = function(info)
								local alert = ExecuteRange_Core:GetAlertByPosition(position);
								if alert == nil then return nil; end
								return alert.horizontalFlip;
							end,
							set = function(info, newValue)
								local alert = ExecuteRange_Core:GetAlertByPosition(position);
								alert.horizontalFlip = newValue
							end,
							order = 3
						},
						alertTextureColor = {
							type = "color",
							name = "Color",
							desc = "Sets the texture color. Set to white to keep the texture's original color",
							get = function(info)
								local alert = ExecuteRange_Core:GetAlertByPosition(position);
								if alert == nil then return nil; end
								return alert.red / 255, alert.green / 255, alert.blue / 255, 1;
							end,
							set = function(info,r,g,b,a)
								local alert = ExecuteRange_Core:GetAlertByPosition(position);
								alert.red = r * 255;
								alert.green = g * 255;
								alert.blue = b * 255;
							end,
							order = 4
						},
						alertTextureScale = {
							type = "range",
							name = "Scale",
							desc = "Sets the texture scale",
							min = 0.5,
							max = 2.5,
							step = 0.1,
							isPercent = true,
							get = function(info)
								local alert = ExecuteRange_Core:GetAlertByPosition(position);
								if alert == nil then return nil; end
								return alert.scale;
							end,
							set = function(info, newValue)
								local alert = ExecuteRange_Core:GetAlertByPosition(position);
								alert.scale = newValue
							end,
							order = 5
						}
				}
			}

			options.args["textureOptions" .. position] = textureOptions;
		 end

		if not ExecuteRange_DB.profile.enabled then
			ExecuteRange_Core:Disable();
		end
	end

	LibStub("AceConfig-3.0"):RegisterOptionsTable("ExecuteRange", options);
	ExecuteRange_Core.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ExecuteRange", "ExecuteRange");
	ExecuteRange_Core:RegisterChatCommand("exrange", "SlashCommandHandler", true);
end

-- ========================  OPTIONS HANDLERS ==========================


function ExecuteRange_Core:GetAlertByPosition(position)
    for key, alert in pairs(ExecuteRange_DB.profile.alerts) do
        if alert.position == position then return alert, key end
    end
    return nil;
end


function ExecuteRange_Core:SettingsReset()
	ExecuteRange_DB:ResetProfile();
end

function ExecuteRange_Core:SettingsResetConfirm()
	return "Reset to the defaults of your class ?"
end

function ExecuteRange_Core:Preview()
	ExecuteRange_Core:CancelAllTimers();
	ExecuteRange_SpellAlertsHandler:HideSpellAlert();
	ExecuteRange_Core:ScheduleTimer("PreviewTimerExpired",5);
	ExecuteRange_SpellAlertsHandler:ShowSpellAlert();
end

function ExecuteRange_Core:PreviewTimerExpired()
	ExecuteRange_SpellAlertsHandler:HideSpellAlert();
end

function ExecuteRange_Core:GetEnabled(info)
    return ExecuteRange_DB.profile.enabled;
end

function ExecuteRange_Core:SetEnabled(info, newValue)
    ExecuteRange_DB.profile.enabled = newValue
	if newValue then 
		ExecuteRange_Core:Enable();
	else
		ExecuteRange_Core:Disable();
	end

end

function ExecuteRange_Core:GetShowAlerts(info)
    return ExecuteRange_DB.profile.showSpellAlert;
end

function ExecuteRange_Core:SetShowAlerts(info, newValue)
    ExecuteRange_DB.profile.showSpellAlert = newValue
end

function ExecuteRange_Core:GetTexturesCount(info)
	return table.getn(ExecuteRange_DB.profile.alerts);
end

function ExecuteRange_Core:SetTexturesCount(info, newValue)
    if newValue > table.getn(ExecuteRange_DB.profile.alerts) then
		local newAlert = {
            texture = "TEXTURES\\SPELLACTIVATIONOVERLAYS\\GENERICTOP_01.BLP",
            position = "BOTTOM",
            scale = 1,
            red = 255,
            green = 255,
            blue = 255,
            verticalFlip = true,
            horizontalFlip = false;
        };
		table.insert(ExecuteRange_DB.profile.alerts, newAlert);
	else
		table.remove(ExecuteRange_DB.profile.alerts);
	end
end

-- ==============================================================


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

	-- ExecuteRange_Console:Print("To see a list of commands type /exrange help");
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
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame);

	--if msg == nil or msg == "" or msg == "help" then 
	--	ExecuteRange_Console:Print("/exrange help  -- This info");		
	--	ExecuteRange_Console:Print("/exrange status  -- Current status of the addon");	
	--	ExecuteRange_Console:Print("/exrange sa on  -- Turns spell alerts visual on");
	--	ExecuteRange_Console:Print("/exrange sa off  -- Turns spell alerts visual off");
	--	ExecuteRange_Console:Print("/exrange enable -- Enables the addon");		
	--	ExecuteRange_Console:Print("/exrange disable -- Disables the addon");
	--elseif msg == "sa on" then
	--	ExecuteRange_DB.profile.showSpellAlert = true;
	--	ExecuteRange_Console:Print("Spell alerts: on");
	--elseif msg == "sa off" then
	--	ExecuteRange_DB.profile.showSpellAlert = false;
	--	ExecuteRange_Console:Print("Spell alerts: off");
	--elseif msg == "enable" then
	--	ExecuteRange_DB.profile.enabled = true;
	--	ExecuteRange_Core:Enable();
	--	ExecuteRange_Console:Print("Enabled");
	--elseif msg == "disable" then
	--	ExecuteRange_DB.profile.enabled = false;
	--	ExecuteRange_Core:Disable();
	--	ExecuteRange_Console:Print("Disabled");
	--elseif msg == "status" then
	--	if ExecuteRange_DB.profile.enabled then 
	--		ExecuteRange_Console:Print("Enabled");
	--	else
	--		ExecuteRange_Console:Print("Disabled");
	--	end
	--	if ExecuteRange_DB.profile.showSpellAlert then
	--		ExecuteRange_Console:Print("Spell alerts: on");
	--	else
	--		ExecuteRange_Console:Print("Spell alerts: off");
	--	end
	--elseif msg == "debug" then
	--	if ExecuteRange_Settings.IsDebugEnabled then
	--		ExecuteRange_Console:Print("Debug Disabled");
	--		ExecuteRange_Settings.IsDebugEnabled = false;
	--	else
	--		ExecuteRange_Console:Print("Debug Enabled");
	--		ExecuteRange_Settings.IsDebugEnabled = true;
	--	end
	--else
	--	ExecuteRange_Console:Print("Unknown command. To see a list of commands type /exrange help");		
	--end	
end