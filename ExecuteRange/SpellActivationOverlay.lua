-- Custom import of blizzard's spellactivationoverlay.lua
-- In 9.0.1 blizzard code spams hide overlays. If this is fixed, this code can be removed and replaced with the original methods (SpellActivationOverlay_ShowOverlay, SpellActivationOverlay_HideOverlays)

local overlaysInUse = {};
local unusedOverlays = {};
local sizeScale = 0.8;
local longSide = 256 * sizeScale;
local shortSide = 128 * sizeScale;


function ExecuteRange_SpellActivationOverlay:SpellActivationOverlay_OnLoad(self)	
	self:SetSize(longSide, longSide)
end

function ExecuteRange_SpellActivationOverlay:SpellActivationOverlay_ShowOverlay(self, spellID, texturePath, position, scale, r, g, b, vFlip, hFlip)
	local overlay = ExecuteRange_SpellActivationOverlay:SpellActivationOverlay_GetOverlay(self, spellID, position);
	overlay.spellID = spellID;
	overlay.position = position;
	
	overlay:ClearAllPoints();
	
	local texLeft, texRight, texTop, texBottom = 0, 1, 0, 1;
	if ( vFlip ) then
		texTop, texBottom = 1, 0;
	end
	if ( hFlip ) then
		texLeft, texRight = 1, 0;
	end
	overlay.texture:SetTexCoord(texLeft, texRight, texTop, texBottom);
	
	local width, height;
	if ( position == "CENTER" ) then
		width, height = longSide, longSide;
		overlay:SetPoint("CENTER", self, "CENTER", 0, 0);
	elseif ( position == "LEFT" ) then
		width, height = shortSide, longSide;
		overlay:SetPoint("RIGHT", self, "LEFT", 0, 0);
	elseif ( position == "RIGHT" ) then
		width, height = shortSide, longSide;
		overlay:SetPoint("LEFT", self, "RIGHT", 0, 0);
	elseif ( position == "TOP" ) then
		width, height = longSide, shortSide;
		overlay:SetPoint("BOTTOM", self, "TOP");
	elseif ( position == "BOTTOM" ) then
		width, height = longSide, shortSide;
		overlay:SetPoint("TOP", self, "BOTTOM");
	elseif ( position == "TOPRIGHT" ) then
		width, height = shortSide, shortSide;
		overlay:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", 0, 0);
	elseif ( position == "TOPLEFT" ) then
		width, height = shortSide, shortSide;
		overlay:SetPoint("BOTTOMRIGHT", self, "TOPLEFT", 0, 0);
	elseif ( position == "BOTTOMRIGHT" ) then
		width, height = shortSide, shortSide;
		overlay:SetPoint("TOPLEFT", self, "BOTTOMRIGHT", 0, 0);
	elseif ( position == "BOTTOMLEFT" ) then
		width, height = shortSide, shortSide;
		overlay:SetPoint("TOPRIGHT", self, "BOTTOMLEFT", 0, 0);
	else
		--GMError("Unknown SpellActivationOverlay position: "..tostring(position));
		return;
	end
	
	overlay:SetSize(width * scale, height * scale);
	
	overlay.texture:SetTexture(texturePath);
	overlay.texture:SetVertexColor(r / 255, g / 255, b / 255);
	
	overlay.animOut:Stop();	--In case we're in the process of animating this out.
    PlaySound(SOUNDKIT.UI_POWER_AURA_GENERIC);
    local overlayAlpha = GetCVar("spellActivationOverlayOpacity");
    local overlayParent = overlay:GetParent();
    overlayParent:SetAlpha(tonumber(overlayAlpha));
	overlay:Show();
	return overlay;
end

function ExecuteRange_SpellActivationOverlay:SpellActivationOverlay_GetOverlay(self, spellID, position)
	local overlayList = overlaysInUse[spellID];
	local overlay;
	if ( overlayList ) then
		for i=1, #overlayList do
			if ( overlayList[i].position == position ) then
				overlay = overlayList[i];
			end
		end
	end
	
	if ( not overlay ) then
		overlay = ExecuteRange_SpellActivationOverlay:SpellActivationOverlay_GetUnusedOverlay(self);
		if ( overlayList ) then
			tinsert(overlayList, overlay);
		else
			overlaysInUse[spellID] = { overlay };
		end
	end
	
	return overlay;
end

function ExecuteRange_SpellActivationOverlay:SpellActivationOverlay_HideOverlays(self, spellID)
	local overlayList = overlaysInUse[spellID];
	if ( overlayList ) then
		for i=1, #overlayList do
			local overlay = overlayList[i];
			overlay.pulse:Pause();
			overlay.animOut:Play();
		end
	end
end

function ExecuteRange_SpellActivationOverlay:SpellActivationOverlay_GetUnusedOverlay(self)
	local overlay = tremove(unusedOverlays, #unusedOverlays);
	if ( not overlay ) then
		overlay = ExecuteRange_SpellActivationOverlay:SpellActivationOverlay_CreateOverlay(self);
	end
	return overlay;
end

function ExecuteRange_SpellActivationOverlay:SpellActivationOverlay_CreateOverlay(self)
	return CreateFrame("Frame", nil, self, "ExecuteRangeSpellActivationOverlayTemplate");
end

function ExecuteRange_SpellActivationOverlay:SpellActivationOverlayTexture_OnShow(self)
	self.animIn:Play();
end

function ExecuteRange_SpellActivationOverlay:SpellActivationOverlayTexture_OnFadeInPlay(animGroup)
	animGroup:GetParent():SetAlpha(0);
end

function ExecuteRange_SpellActivationOverlay:SpellActivationOverlayTexture_OnFadeInFinished(animGroup)
	local overlay = animGroup:GetParent();
	overlay:SetAlpha(1);
	overlay.pulse:Play();
end

function ExecuteRange_SpellActivationOverlay:SpellActivationOverlayTexture_OnFadeOutFinished(anim)
	local overlay = anim:GetRegionParent();
	-- local overlayParent = overlay:GetParent();
	overlay.pulse:Stop();
	overlay:Hide();
	tDeleteItem(overlaysInUse[overlay.spellID], overlay)
	tinsert(unusedOverlays, overlay);
end
