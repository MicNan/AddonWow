-- RotAssist Companion - Panel
-- Finestra con sette schede (Delve, Eventi, Settimanale, Levelling, Oro,
-- Asta, Pet). Ogni scheda e' un elenco di righe prodotto da Data\*.lua:
--   { header = "titolo" } oppure
--   { text, right, icon | atlas, color = {r,g,b}, dim, tooltip = {...},
--     waypoint = { mapID, x, y, titolo }, dest = { mapID, x?, y?, name, note? },
--     preview = pet, link = {...}, linkTitle, wrap }
-- Clic sinistro su una destinazione: percorso piu' veloce (Data\Travel.lua);
-- 'dest' senza coordinate porta solo fino alla zona. Maiusc + clic: solo
-- waypoint; clic destro: link Wowhead. 'preview': anteprima 3D al passaggio
-- del mouse (Data\Pets.lua).
-- In combattimento l'elenco non viene aggiornato.

local _, ns = ...
local A = ns.API

local P = { rows = {}, tab = nil }
ns.Panel = P

local WIDTH, HEIGHT, ROW_H = 600, 540, 20
local AUTO_REFRESH = 30

local TABS = {
    { key = "delves",   label = "TAB_DELVES",   source = function() return ns.Delves end },
    { key = "events",   label = "TAB_EVENTS",   source = function() return ns.Events end },
    { key = "weekly",   label = "TAB_WEEKLY",   source = function() return ns.Weekly end },
    { key = "leveling", label = "TAB_LEVELING", source = function() return ns.Leveling end },
    { key = "gold",     label = "TAB_GOLD",     source = function() return ns.Gold end },
    { key = "market",   label = "TAB_MARKET",   source = function() return ns.Market end },
    { key = "pets",     label = "TAB_PETS",     source = function() return ns.Pets end },
}

---------------------------------------------------------------------------
-- Righe
---------------------------------------------------------------------------
local function ShowTooltip(row)
    local d = row.data
    if not (d and GameTooltip) or d.header then return end
    -- con l'anteprima 3D aperta il tooltip va sotto di essa, non sopra
    local preview = d.preview and ns.Pets and ns.Pets.preview
    if preview and preview:IsShown() then
        GameTooltip:SetOwner(preview, "ANCHOR_BOTTOM")
    else
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    end
    local lines = d.tooltip or { d.text }
    local first = true
    for i = 1, 16 do
        local line = lines[i]
        if line and line ~= "" then
            if first then GameTooltip:AddLine(line, 1, 1, 1); first = false
            else GameTooltip:AddLine(line, 0.8, 0.8, 0.8, true) end
        end
    end
    if d.waypoint or (d.dest and d.dest.x) then GameTooltip:AddLine(ns.L.HINT_ROUTE, 0.5, 0.8, 1)
    elseif d.dest then GameTooltip:AddLine(ns.L.HINT_ROUTE_ZONE, 0.5, 0.8, 1) end
    if d.link then GameTooltip:AddLine(ns.L.HINT_WOWHEAD, 0.5, 0.8, 1) end
    GameTooltip:Show()
end

local function OnRowEnter(row)
    local d = row.data
    if d and d.preview and ns.Pets then
        local ok, err = pcall(ns.Pets.ShowPreview, ns.Pets, d.preview)
        if not ok then ns:ReportError(err) end
    end
    ShowTooltip(row)
end

local function OnRowClick(row, button)
    local d = row.data
    if not d or d.header then return end
    local ok, err = pcall(function()
        if button == "LeftButton" and d.waypoint then
            local w = d.waypoint
            if IsShiftKeyDown and IsShiftKeyDown() then
                ns:SetWaypoint(w[1], w[2], w[3], w[4])
            else
                ns.Travel:Start({ mapID = w[1], x = w[2], y = w[3], name = w[4] })
            end
        elseif button == "LeftButton" and d.dest then
            local t = d.dest
            if t.x and IsShiftKeyDown and IsShiftKeyDown() then
                ns:SetWaypoint(t.mapID, t.x, t.y, t.name)
            else
                ns.Travel:Start(t)
            end
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
    row:SetScript("OnEnter", OnRowEnter)
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
        row.text:SetWordWrap(false)
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
    -- righe lunghe (strategie): vanno a capo invece di essere troncate
    row.text:SetWordWrap(d.wrap and true or false)
    row.text:SetJustifyV(d.wrap and "TOP" or "MIDDLE")
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
    scroll:SetPoint("BOTTOMRIGHT", -32, 64)
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

    -- percorso in corso
    f.route = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.route:SetPoint("BOTTOMLEFT", 14, 40)
    f.route:SetPoint("RIGHT", f, "RIGHT", -100, 0)
    f.route:SetJustifyH("LEFT")
    f.route:SetTextColor(0.5, 0.85, 1)
    f.routeCancel = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.routeCancel:SetSize(80, 20)
    f.routeCancel:SetPoint("BOTTOMRIGHT", -10, 36)
    f.routeCancel:SetText(L.BTN_CANCEL_ROUTE)
    f.routeCancel:SetScript("OnClick", function() ns.Travel:Stop() end)
    f.routeCancel:Hide()

    -- profilo di gioco (scheda Oro)
    f.profile = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.profile:SetSize(160, 22)
    f.profile:SetPoint("BOTTOMLEFT", 10, 10)
    f.profile:SetScript("OnClick", function() ns:CycleProfile() end)
    f.profile:Hide()

    -- sessione di farm (scheda Asta)
    f.farm = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.farm:SetSize(180, 22)
    f.farm:SetPoint("BOTTOMLEFT", 10, 10)
    f.farm:SetScript("OnClick", function() ns.Market:ToggleSession() end)
    f.farm:Hide()

    -- filtro dei pet (scheda Pet)
    f.petFilter = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.petFilter:SetSize(180, 22)
    f.petFilter:SetPoint("BOTTOMLEFT", 10, 10)
    f.petFilter:SetScript("OnClick", function() ns.Pets:CycleFilter() end)
    f.petFilter:Hide()

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
        local h = ROW_H
        if d.wrap then
            local th = row.text:GetStringHeight()
            if type(th) == "number" and th > 0 then h = math.max(ROW_H, th + 6) end
        end
        row:SetHeight(h)
        y = y + h
    end
    content:SetHeight(math.max(10, y))
end

-- Aggiornamento richiesto da un evento: raggruppato (al massimo uno ogni 2 s).
function P:RequestRefresh(delay)
    if self.pending or not (self.frame and self.frame:IsShown()) then return end
    self.pending = true
    ns:After(delay or 2, function() P.pending = false; P:Refresh() end)
end

function P:Refresh()
    local f = self.frame
    if not (f and f:IsShown()) then return end
    local L = ns.L
    for _, b in ipairs(f.tabs) do
        if b.key == self.tab then b:Disable() else b:Enable() end
    end
    f.bountiful:SetShown(self.tab == "delves")
    f.profile:SetShown(self.tab == "gold")
    f.farm:SetShown(self.tab == "market")
    f.farm:SetText(ns.Market.session and L.BTN_FARM_STOP or L.BTN_FARM_START)
    f.petFilter:SetShown(self.tab == "pets")
    f.petFilter:SetText(L.BTN_PET_FILTER:format(L["PET_FILTER_" .. ns.Pets.filter]))
    if self.tab ~= "pets" then ns.Pets:HidePreview() end
    f.profile:SetText(L.BTN_PROFILE:format(L["PROFILE_" .. (ns.db.playerType or "medium")]))
    self:UpdateRoute()
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

-- Testo del percorso in corso (o niente)
function P:UpdateRoute()
    local f = self.frame
    if not f then return end
    local text = ns.Travel and ns.Travel:CurrentText()
    f.route:SetText(text or "")
    f.routeCancel:SetShown(text ~= nil)
end
