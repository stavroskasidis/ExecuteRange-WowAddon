ExecuteRange_Settings.CurrentClass = '';
ExecuteRange_Settings.CurrentSpell = '';
ExecuteRange_Settings.IsDebugEnabled = false;
--ExecuteRange_Settings.PreviousOptions = nil;
local previewTimerHandle = nil;

function ExecuteRange_Settings:InitializeDb(playerClass, db)
	if db.profile.showSpellAlert == nil then
		local defaultAlerts = {};
		if playerClass == "MAGE" then
			local alert1 = {
				texture = ExecuteRange_Constants.TEXTURE_FILE_IDS["TEXTURES\\SPELLACTIVATIONOVERLAYS\\BACKLASH.BLP"],
				position = "TOP",
				scale = 1,
				red = 255,
				green = 255,
				blue = 255,
				verticalFlip = false,
				horizontalFlip = false;
			};
			table.insert(defaultAlerts,alert1);
		elseif playerClass == "HUNTER" then
			local alert1 = {
				texture = ExecuteRange_Constants.TEXTURE_FILE_IDS["TEXTURES\\SPELLACTIVATIONOVERLAYS\\MASTER_MARKSMAN.BLP"],
				position = "TOP",
				scale = 1.5,
				red = 255,
				green = 255,
				blue = 255,
				verticalFlip = false,
				horizontalFlip = false;
			};
			table.insert(defaultAlerts,alert1);
		elseif playerClass == "WARLOCK" then
			local alert1 = {
				texture = ExecuteRange_Constants.TEXTURE_FILE_IDS["TEXTURES\\SPELLACTIVATIONOVERLAYS\\SUDDEN_DOOM.BLP"],
				position = "RIGHT",
				scale = 1,
				red = 255,
				green = 255,
				blue = 255,
				verticalFlip = false,
				horizontalFlip = true;
			};
			local alert2 = {
				texture = ExecuteRange_Constants.TEXTURE_FILE_IDS["TEXTURES\\SPELLACTIVATIONOVERLAYS\\SUDDEN_DOOM.BLP"],
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
				texture = ExecuteRange_Constants.TEXTURE_FILE_IDS["TEXTURES\\SPELLACTIVATIONOVERLAYS\\SUDDEN_DOOM.BLP"],
				position = "RIGHT",
				scale = 1,
				red = 255,
				green = 255,
				blue = 255,
				verticalFlip = false,
				horizontalFlip = true;
			};
			local alert2 = {
				texture = ExecuteRange_Constants.TEXTURE_FILE_IDS["TEXTURES\\SPELLACTIVATIONOVERLAYS\\SUDDEN_DOOM.BLP"],
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
		elseif playerClass == "DEATHKNIGHT" then
			local alert1 = {
				texture = ExecuteRange_Constants.TEXTURE_FILE_IDS["TEXTURES\\SPELLACTIVATIONOVERLAYS\\NECROPOLIS.BLP"],
				position = "TOP",
				scale = 1,
				red = 255,
				green = 255,
				blue = 255,
				verticalFlip = false,
				horizontalFlip = false;
			};
			table.insert(defaultAlerts,alert1);
		elseif playerClass == "PALADIN" then
			local alert1 = {
				texture = ExecuteRange_Constants.TEXTURE_FILE_IDS["TEXTURES\\SPELLACTIVATIONOVERLAYS\\PREDATORY_SWIFTNESS.BLP"],
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
				texture = ExecuteRange_Constants.TEXTURE_FILE_IDS["TEXTURES\\SPELLACTIVATIONOVERLAYS\\ULTIMATUM.BLP"],
				position = "TOP",
				scale = 1,
				red = 255,
				green = 255,
				blue = 255,
				verticalFlip = false,
				horizontalFlip = false;
			};
			table.insert(defaultAlerts,alert1);
		elseif playerClass == "MONK" then
			local alert1 = {
				texture = ExecuteRange_Constants.TEXTURE_FILE_IDS["TEXTURES\\SPELLACTIVATIONOVERLAYS\\BLOOD_SURGE.BLP"],
				position = "TOP",
				scale = 1,
				red = 255,
				green = 255,
				blue = 255,
				verticalFlip = false,
				horizontalFlip = false;
			};
			table.insert(defaultAlerts,alert1);
		end
		
		local defaults = {
			profile = {
				showSpellAlert = true,
				enabled = true,
				showOnCooldown = false,
				alerts = defaultAlerts,
				optionsVersion = "1.0"  -- For future use, if needed to reset settings
			}
		};
	
		ExecuteRange_Console:Print("Initializing defaults");
		db.profile.showSpellAlert = defaults.profile.showSpellAlert;
		db.profile.enabled = defaults.profile.enabled;
		db.profile.showOnCooldown = defaults.profile.showOnCooldown;
		db.profile.alerts = defaults.profile.alerts;
		db.profile.optionsVersion = defaults.profile.optionsVersion;
	end
end

function ExecuteRange_Settings:GetOptionsTable()
	-- doc: https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables
	
	local options = {
		name = "ExecuteRange (Skill: " .. ExecuteRange_Settings.CurrentSpell .. ")",
		type = 'group',
		args = {
			enabled = {
				type = "toggle",
				name = "Enabled",
				desc = "Enables or disables the addon",
				get = function(info)
					return ExecuteRange_DB.profile.enabled;
				end,
				set = function(info, newValue)
					ExecuteRange_DB.profile.enabled = newValue;
					if newValue then 
						ExecuteRange_Core:Enable();
					else
						ExecuteRange_Core:Disable();
					end

				end,
				order = 1
			},
			showSpellAlerts = {
				type = "toggle",
				name = "Show Spell Alert",
				desc = "Enables or disables the spell alert",
				get = function(info)
					return ExecuteRange_DB.profile.showSpellAlert;
				end,
				set = function(info, newValue)
					ExecuteRange_DB.profile.showSpellAlert = newValue;
				end,
				order = 2
			},
			reset = {
				type = "execute",
				name = "Reset",
				desc = "Resets to the default settings",
				func = function()
					ExecuteRange_DB:ResetProfile();
					ExecuteRange_Settings:InitializeDb(ExecuteRange_Settings.CurrentClass, ExecuteRange_DB);
				end,
				confirm = function()
					return "Reset to defaults ?"
				end,
				width = "half",
				order = 3
			},
			preview = {
				type = "execute",
				name = "Preview",
				desc = "Shows the alert",
				func = function()
					if previewTimerHandle ~= nil then
						ExecuteRange_Core:CancelTimer(previewTimerHandle);
					end
					ExecuteRange_SpellAlertsHandler:HideSpellAlert(ExecuteRange_Constants.OVERLAY_PREVIEW_ID);
					previewTimerHandle = ExecuteRange_Core:ScheduleTimer(function()
						ExecuteRange_Console:Debug("Hiding preview overlay");
						ExecuteRange_SpellAlertsHandler:HideSpellAlert(ExecuteRange_Constants.OVERLAY_PREVIEW_ID);
						previewTimerHandle = nil;
					end,8);
					ExecuteRange_SpellAlertsHandler:ShowSpellAlert(ExecuteRange_Constants.OVERLAY_PREVIEW_ID);
				end,
				width = "half",
				order = 4
			},
			showOnCooldown = {
				type = "toggle",
				name = "Show On Cooldown",
				desc = "If checked, glows/alerts will be shown even if skill is on cooldown",
				get = function(info)
					return ExecuteRange_DB.profile.showOnCooldown;
				end,
				set = function(info, newValue)
					ExecuteRange_DB.profile.showOnCooldown = newValue;
				end,
				order = 5
			},
			texturePositions = {
				type = "multiselect",
				name = "Spell Alert Textures",
				desc = "The positions on the screen that the textures appear",
				values = ExecuteRange_Constants.TEXTURE_POSITIONS,
				get = function(info, position)
					local alert = ExecuteRange_Settings:GetAlertByPosition(position);
					local isChecked = alert ~= nil;
					return isChecked;
				end,
				set = function(info, position, state)
					if state then
						local newAlert = {
							texture = ExecuteRange_Constants.TEXTURE_FILE_IDS["TEXTURES\\SPELLACTIVATIONOVERLAYS\\GENERICTOP_01.BLP"],
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
						local alert, key = ExecuteRange_Settings:GetAlertByPosition(position);
						table.remove(ExecuteRange_DB.profile.alerts, key);
					end
				end,
				order = 6
			}
		}
	}

	-- Build Texture options
	for position, positionDescription in pairs(ExecuteRange_Constants.TEXTURE_POSITIONS) do
		

		local textureOptions = {
				name =  positionDescription .. " Texture",
				type = "group",
				disabled = function()
					local alert = ExecuteRange_Settings:GetAlertByPosition(position);
					return alert == nil;
				end,
				args = {
					texturePreview = {
						type = "execute",
						name = "Selected Texture",
						desc = "The selected texture",
						image = function()
							local alert = ExecuteRange_Settings:GetAlertByPosition(position);
							local texturePreview = ExecuteRange_Constants.TEXTURE_FILE_IDS["TEXTURES\\SPELLACTIVATIONOVERLAYS\\GENERICTOP_01.BLP"];
							if alert ~= nil then
								texturePreview = alert.texture;
							end
							return texturePreview;
						end,
						imageWidth = 204,
						imageHeight = 102,
						imageCoords = {0, 1, 0, 1},
						func = function()
							-- do nothing
						end,
						width = "full",
						order = 1
					},
					alertTexture = {
						type = "select",
						name = "Texture",
						desc = "The displayed overlay texture",
						values = ExecuteRange_Constants.TEXTURES,
						style = "dropdown",
						get = function(self)
							local alert = ExecuteRange_Settings:GetAlertByPosition(position);
							if alert == nil then return nil; end
							return alert.texture;
						end,
						set = function(info, newValue)
							local alert = ExecuteRange_Settings:GetAlertByPosition(position);
							alert.texture = newValue;
						end,
						width = "full",
						order = 2
					},
					alertVerticalFlip = {
						type = "toggle",
						name = "Vertical Flip",
						desc = "Flips the texture vertically",
						get = function(info)
							local alert = ExecuteRange_Settings:GetAlertByPosition(position);
							if alert == nil then return nil; end
							return alert.verticalFlip;
						end,
						set = function(info, newValue)
							local alert = ExecuteRange_Settings:GetAlertByPosition(position);
							alert.verticalFlip = newValue
						end,
						order = 3
					},
					alertHorizontalFlip = {
						type = "toggle",
						name = "Horizontal Flip",
						desc = "Flips the texture horizontally",
						get = function(info)
							local alert = ExecuteRange_Settings:GetAlertByPosition(position);
							if alert == nil then return nil; end
							return alert.horizontalFlip;
						end,
						set = function(info, newValue)
							local alert = ExecuteRange_Settings:GetAlertByPosition(position);
							alert.horizontalFlip = newValue
						end,
						order = 4
					},
					alertTextureColor = {
						type = "color",
						name = "Color",
						desc = "Sets the texture color. Set to white to keep the texture's original color",
						get = function(info)
							local alert = ExecuteRange_Settings:GetAlertByPosition(position);
							if alert == nil then return nil; end
							return alert.red / 255, alert.green / 255, alert.blue / 255, 1;
						end,
						set = function(info,r,g,b,a)
							local alert = ExecuteRange_Settings:GetAlertByPosition(position);
							alert.red = r * 255;
							alert.green = g * 255;
							alert.blue = b * 255;
						end,
						order = 5
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
							local alert = ExecuteRange_Settings:GetAlertByPosition(position);
							if alert == nil then return nil; end
							return alert.scale;
						end,
						set = function(info, newValue)
							local alert = ExecuteRange_Settings:GetAlertByPosition(position);
							alert.scale = newValue
						end,
						order = 6
					}
			}
		}

		options.args["textureOptions" .. position] = textureOptions;
	end

	return options;
end

function ExecuteRange_Settings:GetClassNotSupportedOptionsTable()
	local options = {
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

	return options;
end

function ExecuteRange_Settings:GetAlertByPosition(position)
    for key, alert in pairs(ExecuteRange_DB.profile.alerts) do
        if alert.position == position then return alert, key end
    end
    return nil;
end

-- function ExecuteRange_Settings:CopyObject(obj, seen)
-- 	if type(obj) ~= 'table' then return obj end
-- 	if seen and seen[obj] then return seen[obj] end
-- 	local s = seen or {}
-- 	local res = setmetatable({}, getmetatable(obj))
-- 	s[obj] = res
-- 	for k, v in pairs(obj) do res[ExecuteRange_Settings:CopyObject(k, s)] = ExecuteRange_Settings:CopyObject(v, s) end
-- 	return res
-- end