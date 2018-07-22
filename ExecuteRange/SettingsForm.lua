--dependencies
local ExecuteRange_Console = ExecuteRange_Console;
local ExecuteRange_Constants = ExecuteRange_Constants;
local _G = _G --Global enviroment table provided by WoW Api
local r,g,b,a = 1, 0, 0, 1;
--------------

-- ================= EVENTS =====================

function SettingsForm_OnLoad(panel)
        panel.name = "ExecuteRange";
		SettingsForm:Hide();
		VersionLabel:SetText("v" .. GetAddOnMetadata("ExecuteRange", "Version"));
        -- InterfaceOptions_AddCategory(panel);
		
		EnabledCheckButton.label = _G[EnabledCheckButton:GetName() .. "Text"];
		EnabledCheckButton.label:SetText("Enabled");

		ShowAlertCheckButton.label = _G[ShowAlertCheckButton:GetName() .. "Text"];
		ShowAlertCheckButton.label:SetText("Show alerts");

		Alert1VerticalFlipCheckButton.label = _G[Alert1VerticalFlipCheckButton:GetName() .. "Text"];
		Alert1VerticalFlipCheckButton.label:SetText("Vertical Flip");

		Alert1HorizontalFlipCheckButton.label = _G[Alert1HorizontalFlipCheckButton:GetName() .. "Text"];
		Alert1HorizontalFlipCheckButton.label:SetText("Horizontal Flip");
		
end

function SettingsForm_OnShow()
	local profile = ExecuteRange_DB.profile;
	EnabledCheckButton:SetChecked(profile.enabled);
	ShowAlertCheckButton:SetChecked(profile.showSpellAlert);
	
	local alert1 = profile.alerts[1];
	SetTextureDropDown(alert1,AlertTexture1DropDown);
	UpdateTexturePreview(alert1, AlertTexture1);
	

	
    local scrollChild = CreateFrame("Frame",nil,ScrollFrame1);
    scrollChild:SetWidth(ScrollFrame1:GetWidth()) --optional
    --fill scrollchild with data and adjust size
    genData(scrollChild,100);

	ScrollFrame1:SetScrollChild(scrollChild);
end

function AlertTexture1DropDown_OnLoad(self)
	-- set function that creates the list of buttons
	UIDropDownMenu_Initialize(self, function(self)
		AlertDropDownInit(AlertTexture1);
	end);
end


function genData(scrollChild,maxx)
	if not maxx then maxx = 99 end
	scrollChild.data = scrollChild.data or {}
	local padding = 10
	local height = 0
	local width = 0
	for i=1, maxx  do
		scrollChild.data[i] = scrollChild.data[i] or scrollChild:CreateFontString(nil, nil, "GameFontNormal")
		local fs = scrollChild.data[i]
		fs:SetText("String"..i)
		local fheight = fs:GetStringHeight()
		if i == 1 then
			fs:SetPoint("TOPLEFT", 0, 0)
		else
			fs:SetPoint("TOPLEFT", scrollChild.data[i - 1], "BOTTOMLEFT", 0, -padding)
		end
		height = height + fheight + padding
	end
	scrollChild:SetHeight(height)
end

-- =====================================================

function SetTextureDropDown(alert,dropdown)
	dropdown.selectedName = ExecuteRange_Constants.TEXTURES[alert.texture];
	print(dropdown.selectedName);
	dropdown.selectedValue = alert.texture;	
	UIDropDownMenu_SetText(dropdown, dropdown.selectedName);
end

function UpdateTexturePreview(alert,texture)
	texture:SetTexture(alert.texture);
	local rotationRads = 0;
	if alert.verticalFlip then
		rotationRads = rotationRads + math.pi;
	end
	if alert.horizontalFlip then
		rotationRads = rotationRads + (3 * math.pi) / 2
	end
	texture:SetRotation(rotationRads);
	texture:SetVertexColor(alert.red/255, alert.green/255, alert.blue/255, 1);
end

function AlertDropDownInit(texture)
	for key, value in pairs(ExecuteRange_Constants.TEXTURES) do
        local info = UIDropDownMenu_CreateInfo();
		info.text = value; -- displayed text
		info.value = key; -- value to work with instead of displayed text
		info.func = AlertDropDownSelect; -- function to handle selection
		info.arg1 = texture;
		UIDropDownMenu_AddButton(info);
    end
end

function AlertDropDownSelect(self, arg1, arg2, checked)
	-- show arguments in default chat
	local texture = arg1;
	texture:SetTexture(self.value);
end

function ShowColorPicker(r, g, b, a, changedCallback)
	ColorPickerFrame:SetColorRGB(r,g,b);
	ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a;
	ColorPickerFrame.previousValues = {r,g,b,a};
	ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = changedCallback, changedCallback, changedCallback;
	ColorPickerFrame:Hide(); -- Need to run the OnShow handler.
	ColorPickerFrame:Show();
end


local function colorPickerCallback(restore)
	local newR, newG, newB, newA;
	if restore then
		-- The user bailed, we extract the old color from the table created by ShowColorPicker.
		newR, newG, newB, newA = unpack(restore);
	else
		-- Something changed
		newA, newR, newG, newB = OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB();
	end
 
	-- Update our internal storage.
	r, g, b, a = newR, newG, newB, newA;
	-- And update any UI elements that use this color...
end
