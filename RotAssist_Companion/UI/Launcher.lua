-- RotAssist Companion - Launcher
-- Icona trascinabile attorno alla minimappa + voce nel menu AddOns della
-- minimappa (Addon Compartment). Nessuna libreria esterna.
-- Clic sinistro: apri/chiudi il pannello | Clic destro: opzioni.

local _, ns = ...

local LN = {}
ns.Launcher = LN

function ns:HandleLauncherClick(button)
    if button == "RightButton" then
        self:OpenSettings()
    else
        ns.Panel:Toggle()
    end
end

-- Tooltip con un riepilogo veloce (solo fuori combattimento).
function ns:FillTooltip(tt)
    local L = self.L
    tt:AddLine(L.TITLE)
    if not ns.API.InCombat() then
        local bountiful, keys = ns.Delves:Summary()
        if #bountiful > 0 then
            tt:AddLine(L.LOGIN_BOUNTIFUL:format(#bountiful, table.concat(bountiful, ", ")), 1, 0.82, 0, true)
        end
        if keys then tt:AddLine(L.LOGIN_KEYS:format(keys), 1, 1, 1) end
        if ns.Weekly:VaultReady() then tt:AddLine(L.LOGIN_VAULT, 0.3, 1, 0.3) end
    end
    tt:AddLine(" ")
    tt:AddLine(L.TT_LEFT, 0.7, 0.7, 0.7)
    tt:AddLine(L.TT_RIGHT, 0.7, 0.7, 0.7)
    tt:Show()
end

function RotAssistCompanion_OnAddonCompartmentClick(_, button)
    local ok, err = pcall(ns.HandleLauncherClick, ns, button)
    if not ok then ns:ReportError(err) end
end

function RotAssistCompanion_OnAddonCompartmentEnter(_, frame)
    if not (GameTooltip and frame) then return end
    GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
    pcall(ns.FillTooltip, ns, GameTooltip)
end

function RotAssistCompanion_OnAddonCompartmentLeave()
    if GameTooltip then GameTooltip:Hide() end
end

local function UpdatePosition(btn)
    local angle = math.rad(ns.db.minimapAngle or 200)
    local x, y = math.cos(angle), math.sin(angle)
    local radius = (Minimap:GetWidth() / 2) + 5
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    if shape == "SQUARE" then
        local m = math.max(math.abs(x), math.abs(y))
        x, y = x / m, y / m
        radius = radius - 2
    end
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x * radius, y * radius)
end

local function OnDragUpdate(self)
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale
    ns.db.minimapAngle = math.deg(math.atan2(py - my, px - mx)) % 360
    UpdatePosition(self)
end

function LN:Create()
    if not Minimap then return end
    local btn = CreateFrame("Button", "RotAssistCompanionMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", 7, -5)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    btn:SetScript("OnClick", function(_, button)
        local ok, err = pcall(ns.HandleLauncherClick, ns, button)
        if not ok then ns:ReportError(err) end
    end)
    btn:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", OnDragUpdate) end)
    btn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        pcall(ns.FillTooltip, ns, GameTooltip)
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.button = btn
    self:ApplySettings()
end

function LN:ApplySettings()
    if not self.button then return end
    UpdatePosition(self.button)
    self.button:SetShown(ns.db.showMinimap and true or false)
end
