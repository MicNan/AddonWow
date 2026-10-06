-- RotAssist Companion - Panel
-- Finestra con quattro schede (Delve, Eventi, Settimanale, Levelling).
-- Ogni scheda e' un elenco di righe prodotto da Data\*.lua:
--   { header = "titolo" } oppure
--   { text, right, icon | atlas, color = {r,g,b}, dim, tooltip = {...},
--     waypoint = { mapID, x, y, titolo }, link = {...}, linkTitle }
-- Clic sinistro: waypoint (se presente) altrimenti link; clic destro: link Wowhead.
-- In combattimento l'elenco non viene aggiornato.

local _, ns = ...
local A = ns.API

local P = { rows = {}, tab = nil }
ns.Panel = P

local WIDTH, HEIGHT, ROW_H = 460, 500, 20
local AUTO_REFRESH = 30

local TABS = {
    { key = "delves",   label = "TAB_DELVES",   source = function() return ns.Delves end },
    { key = "events",   label = "TAB_EVENTS",   source = function() return ns.Events end },
    { key = "weekly",   label = "TAB_WEEKLY",   source = function() return ns.Weekly end },
    { key = "leveling", label = "TAB_LEVELING", source = function() return ns.Leveling end },
}

---------------------------------------------------------------------------
-- Righe
---------------------------------------------------------------------------
local function ShowTooltip(row)
    local d = row.data
    if not (d and GameTooltip) or d.header then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    local lines = d.tooltip or { d.text }
    local first = true
    for i = 1, 8 do
        local line = lines[i]
        if line and line ~= "" then
            if first then GameTooltip:AddLine(line, 1, 1, 1); first = false
            else GameTooltip:AddLine(line, 0.8, 0.8, 0.8, true) end
        end
    end
    if d.waypoint then GameTooltip:AddLine(ns.L.HINT_WAYPOINT, 0.5, 0.8, 1) end
    if d.link then GameTooltip:AddLine(ns.L.HINT_WOWHEAD, 0.5, 0.8, 1) end
    GameTooltip:Show()
end

local function OnRowClick(row, button)
    local d = row.data
    if not d or d.header then return end
    local ok, err = pcall(function()
        if button == "LeftButton" and d.waypoint then
            local w = d.waypoint
            ns:SetWaypoint(w[1], w[2], w[3], w[4])
        elseif d.link then
            ns:ShowLink(d.linkTitle or d.text, d.link)
        end
    end)
    if not ok then ns:ReportError(err) end
end

local function CreateRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_H)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("LEFT", 2, 0)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetJustifyH("LEFT")
    row.right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.right:SetPoint("RIGHT", -4, 0)
    row.right:SetJustifyH("RIGHT")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.text:SetPoint("RIGHT", row.right, "LEFT", -6, 0)
    row:SetScript("OnEnter", ShowTooltip)
    row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    row:SetScript("OnClick", OnRowClick)
    return row
end

local function FillRow(row, d)
    row.data = d
    row.icon:SetTexture(nil)
    if d.header then
        row.icon:Hide()
        row.text:SetFontObject("GameFontNormal")
        row.text:SetText(d.header)
        row.right:SetText("")
        row:EnableMouse(false)
        return
    end
    row:EnableMouse(true)
    row.text:SetFontObject("GameFontHighlightSmall")
    if d.atlas and row.icon.SetAtlas then
        if not pcall(row.icon.SetAtlas, row.icon, d.atlas) then row.icon:SetTexture(nil) end
        row.icon:Show()
    elseif d.icon then
        row.icon:SetTexture(d.icon)
        row.icon:Show()
    else
        row.icon:Hide()
    end
    row.text:SetText(d.text or "")
    row.right:SetText(d.right or "")
    if d.color then
        row.text:SetTextColor(d.color[1], d.color[2], d.color[3])
    elseif d.dim then
        row.text:SetTextColor(0.6, 0.6, 0.6)
    else
        row.text:SetTextColor(1, 1, 1)
    end
end

---------------------------------------------------------------------------
-- Finestra
---------------------------------------------------------------------------
function P:Create()
    local L = ns.L
    local f = CreateFrame("Frame", "RotAssistCompanionFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(WIDTH, HEIGHT)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint(1)
        ns.db.pos = { point = point or "CENTER", x = x or 0, y = y or 0 }
    end)
    f:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames, "RotAssistCompanionFrame") end

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOP", 0, -5)
    f.title:SetText(L.TITLE)

    -- schede
    f.tabs = {}
    local tabW = (WIDTH - 24) / #TABS
    for i, t in ipairs(TABS) do
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(tabW - 4, 22)
        b:SetPoint("TOPLEFT", 12 + (i - 1) * tabW, -28)
        b:SetText(L[t.label])
        b:SetScript("OnClick", function() P:SelectTab(t.key) end)
        b.key = t.key
        f.tabs[i] = b
    end

    -- elenco scorrevole
    local scroll = CreateFrame("ScrollFrame", "RotAssistCompanionScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -56)
    scroll:SetPoint("BOTTOMRIGHT", -32, 40)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(WIDTH - 48, 10)
    scroll:SetScrollChild(content)
    f.scroll, f.content = scroll, content

    -- barra in basso
    f.refresh = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.refresh:SetSize(90, 22)
    f.refresh:SetPoint("BOTTOMRIGHT", -10, 10)
    f.refresh:SetText(L.BTN_REFRESH)
    f.refresh:SetScript("OnClick", function() A.ClearCache(); P:Refresh() end)

    f.status = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.status:SetPoint("RIGHT", f.refresh, "LEFT", -8, 0)

    f.bountiful = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    f.bountiful:SetSize(22, 22)
    f.bountiful:SetPoint("BOTTOMLEFT", 10, 10)
    f.bountiful.label = f.bountiful:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.bountiful.label:SetPoint("LEFT", f.bountiful, "RIGHT", 2, 0)
    f.bountiful.label:SetText(L.ONLY_BOUNTIFUL)
    f.bountiful:SetScript("OnClick", function(self)
        ns.db.onlyBountiful = self:GetChecked() and true or false
        P:Refresh()
    end)

    -- aggiornamento automatico mentre il pannello e' aperto
    local elapsed = 0
    f:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed >= AUTO_REFRESH then
            elapsed = 0
            P:Refresh()
        end
    end)
    f:SetScript("OnShow", function() elapsed = 0; P:Refresh() end)

    self.frame = f
    self:ApplyPosition()
    self.tab = ns.db.tab or "delves"
end

function P:ApplyPosition()
    local f, p = self.frame, ns.db.pos or ns.defaults.pos
    if not f then return end
    f:ClearAllPoints()
    f:SetPoint(p.point or "CENTER", UIParent, p.point or "CENTER", p.x or 0, p.y or 0)
end

function P:SelectTab(key)
    self.tab = key
    ns.db.tab = key
    if self.frame and self.frame:IsShown() then self:Refresh() else self:Show() end
end

function P:Toggle()
    if not self.frame then return end
    if self.frame:IsShown() then self.frame:Hide() else self.frame:Show() end
end

function P:Show(tab)
    if tab then self.tab = tab; ns.db.tab = tab end
    if not self.frame then return end
    if self.frame:IsShown() then self:Refresh() else self.frame:Show() end
end

local function TabSource(key)
    for _, t in ipairs(TABS) do
        if t.key == key then return t.source() end
    end
end

function P:Render(rows)
    local content = self.frame.content
    for _, r in ipairs(self.rows) do r:Hide() end
    local y = 0
    for i, d in ipairs(rows) do
        local row = self.rows[i]
        if not row then
            row = CreateRow(content)
            self.rows[i] = row
        end
        row:ClearAllPoints()
        if d.header and i > 1 then y = y + 6 end
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
        FillRow(row, d)
        row:Show()
        y = y + ROW_H
    end
    content:SetHeight(math.max(10, y))
end

-- Aggiornamento richiesto da un evento: raggruppato (al massimo uno ogni 2 s).
function P:RequestRefresh()
    if self.pending or not (self.frame and self.frame:IsShown()) then return end
    self.pending = true
    ns:After(2, function() P.pending = false; P:Refresh() end)
end

function P:Refresh()
    local f = self.frame
    if not (f and f:IsShown()) then return end
    local L = ns.L
    for _, b in ipairs(f.tabs) do
        if b.key == self.tab then b:Disable() else b:Enable() end
    end
    f.bountiful:SetShown(self.tab == "delves")
    f.bountiful:SetChecked(ns.db.onlyBountiful and true or false)
    if A.InCombat() then
        f.status:SetText(L.IN_COMBAT)
        return
    end
    local source = TabSource(self.tab) or ns.Delves
    local ok, rows = pcall(source.Rows, source)
    if not ok then
        ns:ReportError(rows)
        rows = {}
    end
    self:Render(rows or {})
    f.status:SetText(L.UPDATED_AT:format(date and date("%H:%M") or ""))
end
