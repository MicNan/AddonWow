-- RotAssist - Launcher
-- Due punti di accesso, senza librerie esterne (niente LibDBIcon):
--   * icona trascinabile attorno alla minimappa;
--   * voce nel menu AddOns della minimappa (Addon Compartment, campi nel .toc).
-- Clic sinistro: opzioni | Clic destro: blocca/sblocca riquadri
-- Maiusc + clic sinistro: mostra/nascondi | Clic centrale: cambia modalita'

local _, ns = ...
local L = ns.L
local UI = ns.UI

local LN = {}
UI.Launcher = LN

---------------------------------------------------------------------------
-- Azioni e tooltip condivisi
---------------------------------------------------------------------------
function ns:HandleLauncherClick(button)
    if button == "RightButton" then
        self:Set("locked", not self.db.locked)
        self:Print(self.db.locked and L.MSG_LOCKED or L.MSG_UNLOCKED)
    elseif button == "MiddleButton" then
        self:CycleMode()
    elseif IsShiftKeyDown and IsShiftKeyDown() then
        self:Set("shown", not self.db.shown)
    else
        self:OpenSettings()
    end
end

local function OnOff(v) return v and ("|cff55ff55" .. L.TT_YES .. "|r") or ("|cffff5555" .. L.TT_NO .. "|r") end

function ns:FillTooltip(tt)
    local db = self.db
    tt:AddLine("RotAssist")
    local spec = self.activeSpec
    tt:AddDoubleLine(L.TT_SPEC, spec and spec.name or "-", 1, 0.82, 0, 1, 1, 1)
    if self.hero then tt:AddDoubleLine(L.TT_HERO, self.hero, 1, 0.82, 0, 1, 1, 1) end
    tt:AddDoubleLine(L.TT_MODE, db.mode, 1, 0.82, 0, 1, 1, 1)
    tt:AddDoubleLine(L.TT_SOURCE, db.source, 1, 0.82, 0, 1, 1, 1)
    tt:AddDoubleLine(L.TT_SHOWN, OnOff(db.shown), 1, 0.82, 0, 1, 1, 1)
    tt:AddDoubleLine(L.TT_LOCKED, OnOff(db.locked), 1, 0.82, 0, 1, 1, 1)
    tt:AddLine(" ")
    tt:AddLine(L.TT_LEFT, 0.7, 0.7, 0.7)
    tt:AddLine(L.TT_SHIFT, 0.7, 0.7, 0.7)
    tt:AddLine(L.TT_RIGHT, 0.7, 0.7, 0.7)
    tt:AddLine(L.TT_MIDDLE, 0.7, 0.7, 0.7)
    tt:Show()
end

---------------------------------------------------------------------------
-- Addon Compartment (funzioni globali richiamate dal .toc)
---------------------------------------------------------------------------
function RotAssist_OnAddonCompartmentClick(_, button)
    local ok, err = pcall(ns.HandleLauncherClick, ns, button)
    if not ok then ns:ReportError(err) end
end

function RotAssist_OnAddonCompartmentEnter(_, frame)
    if not (GameTooltip and frame) then return end
    GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
    pcall(ns.FillTooltip, ns, GameTooltip)
end

function RotAssist_OnAddonCompartmentLeave()
    if GameTooltip then GameTooltip:Hide() end
end

---------------------------------------------------------------------------
-- Icona sulla minimappa
---------------------------------------------------------------------------
local function UpdatePosition(btn)
    local angle = math.rad(ns.db.minimapAngle or 225)
    local x, y = math.cos(angle), math.sin(angle)
    local radius = (Minimap:GetWidth() / 2) + 5
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    if shape == "SQUARE" then
        -- minimappa quadrata: proiettiamo sul bordo del quadrato
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
    local btn = CreateFrame("Button", "RotAssistMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", 7, -5)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\Ability_Hunter_BestialDiscipline")
    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    btn.icon = icon

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    btn:SetScript("OnClick", function(_, button)
        local ok, err = pcall(ns.HandleLauncherClick, ns, button)
        if not ok then ns:ReportError(err) end
    end)
    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", OnDragUpdate)
    end)
    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        pcall(ns.FillTooltip, ns, GameTooltip)
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.button = btn
    self:ApplySettings()
end

-- Icona della spec attiva sul pulsante (aggiornata al cambio spec).
function LN:SetIcon(texture)
    if self.button and texture then self.button.icon:SetTexture(texture) end
end

function LN:ApplySettings()
    if not self.button then return end
    UpdatePosition(self.button)
    self.button:SetShown(ns.db.showMinimap and true or false)
end
