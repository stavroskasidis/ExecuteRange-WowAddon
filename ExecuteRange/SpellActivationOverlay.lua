-- Custom import of Blizzard's SpellActivationOverlay (Blizzard_FrameXML/SpellActivationOverlay.lua).
-- Kept as our own frames (with our own overlay IDs) so Blizzard's SPELL_ACTIVATION_OVERLAY_* events never
-- touch our overlays (in 9.0.1 Blizzard's code spammed hide events), and extended with string positions
-- and vertical/horizontal flips, which Blizzard's version derives from the position.
--
-- Frame layout (SpellActivationOverlay.xml):
--   ExecuteRangeAlertGateFrame                      alpha = "target in execute range" (0 or 1)
--     .CooldownGate                                 alpha = "spell off cooldown" (0 or 1)
--       ExecuteRangeSpellActivationOverlayFrame     the live alert overlays
--   ExecuteRangeSpellActivationOverlayPreviewFrame  the settings "Preview", never gated
-- The gate alphas may be secret values (see SpellAlertsHandler), which is why the overlays live under
-- plain frames whose alpha we set instead of being shown/hidden by the addon.

local sizeScale = 0.8;
local longSide = 256 * sizeScale;
local shortSide = 128 * sizeScale;

-- ExecuteRange_SpellActivationOverlay is declared in Init.lua and used as the frames' mixin

function ExecuteRange_SpellActivationOverlay:OnLoad()
	self.overlaysInUse = {};
	self.overlayPool = CreateFramePool("FRAME", self, "ExecuteRangeSpellActivationOverlayTemplate");
	self:SetSize(longSide, longSide);
end

-- Shows every alert of the profile under the given overlay ID (see ExecuteRange_Constants.OVERLAY_ID)
--@param alerts ExecuteRange_DB.profile.alerts
--@param spellID the (fake) spell ID the overlays are keyed by
--@param playSound whether to play the spell alert sound
function ExecuteRange_SpellActivationOverlay:ShowAlerts(alerts, spellID, playSound)
	for _, alert in pairs(alerts) do
		self:ShowOverlay(spellID, alert.texture, alert.position, alert.scale, alert.red, alert.green, alert.blue, alert.verticalFlip, alert.horizontalFlip, playSound);
		-- one sound per alert, not per texture
		playSound = false;
	end
end

function ExecuteRange_SpellActivationOverlay:ShowOverlay(spellID, texturePath, position, scale, r, g, b, vFlip, hFlip, playSound)
	local overlay = self:GetOverlay(spellID, position);
	local alreadyShown = overlay:IsShown() and overlay.spellID == spellID;

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
	if ( playSound and not alreadyShown ) then
		PlaySound(SOUNDKIT.UI_POWER_AURA_GENERIC);
	end
	-- Honour the "Spell Alert Opacity" game setting like Blizzard's overlay does
	self:SetAlpha(ExecuteRange_SpellActivationOverlay:GetOverlayOpacity());
	overlay:Show();
	return overlay;
end

function ExecuteRange_SpellActivationOverlay:GetOverlayOpacity()
	local opacity;
	if ( Settings and Settings.GetValue ) then
		opacity = Settings.GetValue("spellActivationOverlayOpacity");
	end
	if ( opacity == nil ) then
		opacity = tonumber(GetCVar("spellActivationOverlayOpacity"));
	end
	return opacity or 1;
end

function ExecuteRange_SpellActivationOverlay:GetOverlay(spellID, position)
	if ( not self.overlaysInUse[spellID] ) then
		self.overlaysInUse[spellID] = {};
	end

	local overlayList = self.overlaysInUse[spellID];
	local overlay = overlayList[position];

	if ( not overlay ) then
		overlay = self.overlayPool:Acquire();
		overlayList[position] = overlay;
	end

	return overlay;
end

function ExecuteRange_SpellActivationOverlay:HideOverlays(spellID)
	local overlayList = self.overlaysInUse[spellID];
	if ( overlayList ) then
		for _, overlay in pairs(overlayList) do
			overlay.pulse:Pause();
			overlay.animOut:Play();
		end
	end
end

function ExecuteRange_SpellActivationOverlay:ReleaseOverlay(overlay)
	self.overlaysInUse[overlay.spellID][overlay.position] = nil;
	self.overlayPool:Release(overlay);
end

-- ExecuteRangeSpellActivationOverlayTemplate scripts

function ExecuteRange_SpellActivationOverlay:SpellActivationOverlayTexture_OnShow(overlay)
	overlay.animIn:Play();
end

function ExecuteRange_SpellActivationOverlay:SpellActivationOverlayTexture_OnFadeInPlay(animGroup)
	animGroup:GetParent():SetAlpha(0);
end

function ExecuteRange_SpellActivationOverlay:SpellActivationOverlayTexture_OnFadeInFinished(animGroup)
	local overlay = animGroup:GetParent();
	overlay:SetAlpha(1);
	overlay.pulse:Play();
end

function ExecuteRange_SpellActivationOverlay:SpellActivationOverlayTexture_OnFadeOutFinished(animGroup)
	local overlay = animGroup:GetParent();
	overlay.pulse:Stop();
	overlay:GetParent():ReleaseOverlay(overlay);
end
