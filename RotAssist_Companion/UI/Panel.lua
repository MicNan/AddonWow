-- RotAssist Companion - Panel
-- Finestra con otto schede (Delve, Eventi, Settimanale, Levelling, Oro,
-- Professioni, Asta, Pet). Ogni scheda e' un elenco di righe prodotto da
-- Data\*.lua. Tipi di riga (campo 'kind', predefinito "line"):
--   { header = "titolo" }                      titolo di sezione con riga sotto
--   { kind = "sub", text }                     sottotitolo
--   { kind = "phase", text }                   titolo di una fase (arancione)
--   { kind = "pills", items = { { label, selected, onClick } } }   selettori
--   { kind = "callout", style = "info"|"tip"|"warn", title?, text }   riquadro
--   { kind = "step", badge = "10", text }      passo con numero/punti a sinistra
--   { kind = "thead"|"tr", cols = {...}, widths = {...}, align = {...},
--     colors = {...} }                         tabella (larghezze in frazioni)
--   { kind = "bar", value, max, segments = { {da, a, {r,g,b}} }, marker,
--     ticks = {...}, color, label, right }     barra di avanzamento
--   { kind = "note", text }                    nota piccola e grigia
--   riga normale: { text, right, icon | atlas, color = {r,g,b}, dim, wrap,
--     indent, badge = { text, {r,g,b} }, tooltip = {...},
--     waypoint = { mapID, x, y, titolo }, dest = { mapID, x?, y?, name, note? },
--     preview = pet, link = {...}, linkTitle }
-- Clic sinistro su una destinazione: percorso piu' veloce (Data\Travel.lua);
-- 'dest' senza coordinate porta solo fino alla zona. Maiusc + clic: solo
-- waypoint; clic destro: link Wowhead. 'preview': anteprima 3D al passaggio
-- del mouse (Data\Pets.lua).
-- In combattimento l'elenco non viene aggiornato.

local _, ns = ...
local A = ns.API

local P = { rows = {}, tab = nil }
ns.Panel = P

local WIDTH, HEIGHT, ROW_H = 640, 540, 20
local CONTENT_W = WIDTH - 48
local AUTO_REFRESH = 30

local TABS = {
    { key = "delves",   label = "TAB_DELVES",   source = function() return ns.Delves end },
    { key = "events",   label = "TAB_EVENTS",   source = function() return ns.Events end },
    { key = "weekly",   label = "TAB_WEEKLY",   source = function() return ns.Weekly end },
    { key = "leveling", label = "TAB_LEVELING", source = function() return ns.Leveling end },
    { key = "gold",     label = "TAB_GOLD",     source = function() return ns.Gold end },
    { key = "craft",    label = "TAB_CRAFT",    source = function() return ns.Craft end },
    { key = "market",   label = "TAB_MARKET",   source = function() return ns.Market end },
    { key = "pets",     label = "TAB_PETS",     source = function() return ns.Pets end },
}

-- Colori dei riquadri e degli elementi grafici
local STYLE = {
    info = { 0.35, 0.65, 1 },
    tip  = { 0.35, 0.85, 0.45 },
    warn = { 1, 0.6, 0.2 },
    gold = { 1, 0.82, 0 },
}
P.STYLE = STYLE

---------------------------------------------------------------------------
-- Righe: interazione
---------------------------------------------------------------------------
local function Interactive(d)
    return d and (d.tooltip or d.link or d.waypoint or d.dest or d.preview) and true or false
end

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

local function OnPillClick(btn)
    local item = btn.item
    if not (item and item.onClick) then return end
    local ok, err = pcall(item.onClick)
    if not ok then ns:ReportError(err) end
    P:Refresh()
end

---------------------------------------------------------------------------
-- Righe: costruzione
---------------------------------------------------------------------------
local function Color(tex, c, a)
    if tex.SetColorTexture then tex:SetColorTexture(c[1], c[2], c[3], a or 1)
    else tex:SetTexture(c[1], c[2], c[3], a or 1) end
end

local function Height(fs, fallback)
    local h = fs:GetStringHeight()
    if type(h) == "number" and h > 0 then return h end
    return fallback or 12
end

local function TextWidth(fs, text)
    local w = fs:GetStringWidth()
    if type(w) == "number" and w > 0 then return w end
    return #(text or "") * 6
end

local function CreateRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_H)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.accent = row:CreateTexture(nil, "BORDER")
    row.accent:SetWidth(3)
    row.accent:SetPoint("TOPLEFT", 0, 0)
    row.accent:SetPoint("BOTTOMLEFT", 0, 0)
    row.rule = row:CreateTexture(nil, "BORDER")
    row.rule:SetHeight(1)
    row.rule:SetPoint("BOTTOMLEFT", 0, 1)
    row.rule:SetPoint("BOTTOMRIGHT", 0, 1)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.title:SetJustifyH("LEFT")
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetJustifyH("LEFT")
    row.right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.right:SetJustifyH("RIGHT")
    row.badge = row:CreateTexture(nil, "ARTWORK")
    row.badgeText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.badgeText:SetJustifyH("CENTER")
    row.track = row:CreateTexture(nil, "ARTWORK")
    row.fill = row:CreateTexture(nil, "ARTWORK", nil, 1)
    row.marker = row:CreateTexture(nil, "OVERLAY")
    row.cols, row.segs, row.ticks, row.pills = {}, {}, {}, {}
    row:SetScript("OnEnter", OnRowEnter)
    row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    row:SetScript("OnClick", OnRowClick)
    return row
end

local function Col(row, i)
    if not row.cols[i] then
        local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetWordWrap(false)
        row.cols[i] = fs
    end
    return row.cols[i]
end

local function Seg(list, row, i, layer)
    if not list[i] then list[i] = row:CreateTexture(nil, layer or "ARTWORK") end
    return list[i]
end

local function Pill(row, i)
    if not row.pills[i] then
        local b = CreateFrame("Button", nil, row)
        b:SetHeight(20)
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints()
        b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.label:SetPoint("CENTER", 0, 0)
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        b:SetScript("OnClick", OnPillClick)
        row.pills[i] = b
    end
    return row.pills[i]
end

-- Nasconde tutto cio' che una riga riutilizzata poteva mostrare
local function Reset(row)
    for _, k in ipairs({ "bg", "accent", "rule", "icon", "title", "badge", "badgeText", "track", "fill", "marker" }) do
        row[k]:Hide()
    end
    for _, list in ipairs({ row.cols, row.segs, row.ticks, row.pills }) do
        for _, x in ipairs(list) do x:Hide() end
    end
    row.text:ClearAllPoints(); row.text:Show(); row.text:SetText("")
    row.right:ClearAllPoints(); row.right:Show(); row.right:SetText("")
    row.title:ClearAllPoints()
    row.text:SetWordWrap(false)
    row.text:SetFontObject("GameFontHighlightSmall")
    row.text:SetTextColor(1, 1, 1)
    row.text:SetJustifyV("TOP")
end

---------------------------------------------------------------------------
-- Disegno di ogni tipo di riga. Ogni funzione restituisce l'altezza.
---------------------------------------------------------------------------
local Draw = {}

function Draw.header(row, d)
    row.text:SetFontObject("GameFontNormal")
    row.text:SetPoint("BOTTOMLEFT", 2, 5)
    row.text:SetWidth(CONTENT_W - 4)
    row.text:SetText(d.header)
    Color(row.rule, STYLE.gold, 0.35)
    row.rule:Show()
    return 24
end

function Draw.sub(row, d)
    row.text:SetFontObject("GameFontHighlight")
    row.text:SetPoint("TOPLEFT", 2, -4)
    row.text:SetWidth(CONTENT_W - 4)
    row.text:SetWordWrap(true)
    row.text:SetText(d.text or "")
    return Height(row.text, 14) + 8
end

function Draw.phase(row, d)
    row.text:SetFontObject("GameFontNormalSmall")
    row.text:SetPoint("TOPLEFT", 2, -5)
    row.text:SetWidth(CONTENT_W - 4)
    row.text:SetText(d.text or "")
    row.text:SetTextColor(STYLE.warn[1], STYLE.warn[2], STYLE.warn[3])
    return 20
end

function Draw.note(row, d)
    row.text:SetFontObject("GameFontDisableSmall")
    row.text:SetPoint("TOPLEFT", 2, -3)
    row.text:SetWidth(CONTENT_W - 4)
    row.text:SetWordWrap(true)
    row.text:SetText(d.text or "")
    return Height(row.text, 12) + 6
end

function Draw.pills(row, d)
    row.text:Hide()
    local x = 0
    for i, item in ipairs(d.items or {}) do
        local b = Pill(row, i)
        b.item = item
        b.label:SetText(item.label or "?")
        local w = math.max(56, TextWidth(b.label, item.label) + 18)
        b:SetWidth(w)
        b:ClearAllPoints()
        b:SetPoint("LEFT", row, "LEFT", x, 0)
        if item.selected then
            Color(b.bg, STYLE.info, 0.45)
            b.label:SetTextColor(1, 1, 1)
        else
            Color(b.bg, { 0.12, 0.12, 0.12 }, 0.85)
            b.label:SetTextColor(0.7, 0.7, 0.7)
        end
        b:Show()
        x = x + w + 4
    end
    return 26
end

function Draw.callout(row, d)
    local c = STYLE[d.style or "info"] or STYLE.info
    Color(row.bg, c, 0.12); row.bg:Show()
    Color(row.accent, c, 0.9); row.accent:Show()
    local top = -5
    local h = 10
    if d.title then
        row.title:SetPoint("TOPLEFT", 10, top)
        row.title:SetWidth(CONTENT_W - 16)
        row.title:SetText(d.title)
        row.title:SetTextColor(c[1], c[2], c[3])
        row.title:Show()
        local th = Height(row.title, 12)
        top = top - th - 2
        h = h + th + 2
    end
    row.text:SetPoint("TOPLEFT", 10, top)
    row.text:SetWidth(CONTENT_W - 16)
    row.text:SetWordWrap(true)
    row.text:SetText(d.text or "")
    row.text:SetTextColor(0.92, 0.92, 0.92)
    return h + Height(row.text, 12)
end

function Draw.step(row, d)
    local c = d.badgeColor or STYLE.warn
    row.badgeText:SetText(d.badge or "")
    local bw = math.max(30, TextWidth(row.badgeText, d.badge) + 10)
    row.badge:ClearAllPoints()
    row.badge:SetPoint("TOPLEFT", 4, -3)
    row.badge:SetSize(bw, 15)
    Color(row.badge, c, 0.25); row.badge:Show()
    row.badgeText:ClearAllPoints()
    row.badgeText:SetPoint("CENTER", row.badge, "CENTER", 0, 0)
    row.badgeText:SetTextColor(c[1], c[2], c[3])
    row.badgeText:Show()
    row.text:SetPoint("TOPLEFT", bw + 12, -4)
    row.text:SetWidth(CONTENT_W - bw - 16)
    row.text:SetWordWrap(true)
    row.text:SetText(d.text or "")
    if d.color then row.text:SetTextColor(d.color[1], d.color[2], d.color[3]) end
    return math.max(ROW_H, Height(row.text, 12) + 8)
end

local function DrawCols(row, d, header)
    row.text:Hide()
    local widths, align, colors = d.widths or {}, d.align or {}, d.colors or {}
    local x = d.icon and 22 or 4
    if d.icon then
        row.icon:ClearAllPoints(); row.icon:SetPoint("LEFT", 2, 0)
        row.icon:SetTexture(d.icon); row.icon:Show()
    end
    local avail = CONTENT_W - x - 4
    for i, txt in ipairs(d.cols or {}) do
        local fs = Col(row, i)
        local w = math.floor(avail * (widths[i] or (1 / #d.cols)))
        fs:SetFontObject(header and "GameFontDisableSmall" or "GameFontHighlightSmall")
        fs:ClearAllPoints()
        fs:SetPoint("LEFT", row, "LEFT", x, 0)
        fs:SetWidth(w - 6)
        fs:SetJustifyH(align[i] or "LEFT")
        fs:SetText(txt or "")
        local c = colors[i]
        if c then fs:SetTextColor(c[1], c[2], c[3])
        elseif not header then fs:SetTextColor(1, 1, 1) end
        fs:Show()
        x = x + w
    end
    if header then
        Color(row.rule, { 0.5, 0.5, 0.5 }, 0.35)
        row.rule:Show()
    end
    return header and 18 or ROW_H
end

function Draw.thead(row, d) return DrawCols(row, d, true) end
function Draw.tr(row, d) return DrawCols(row, d, false) end

function Draw.bar(row, d)
    local W = CONTENT_W - 8
    local minV, maxV = d.min or 0, d.max or 100
    local span = math.max(1, maxV - minV)
    local function X(v) return math.floor(W * (math.min(maxV, math.max(minV, v)) - minV) / span) end
    row.track:ClearAllPoints()
    row.track:SetPoint("TOPLEFT", 4, -4)
    row.track:SetSize(W, 8)
    Color(row.track, { 0.1, 0.1, 0.1 }, 0.9); row.track:Show()
    if d.segments then
        for i, s in ipairs(d.segments) do
            local t = Seg(row.segs, row, i)
            local x1, x2 = X(s[1]), X(s[2])
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", row.track, "TOPLEFT", x1, 0)
            t:SetSize(math.max(1, x2 - x1 - 1), 8)
            Color(t, s[3] or STYLE.info, s[4] or 0.8)
            t:Show()
        end
    elseif d.value then
        row.fill:ClearAllPoints()
        row.fill:SetPoint("TOPLEFT", row.track, "TOPLEFT", 0, 0)
        row.fill:SetSize(math.max(1, X(d.value)), 8)
        Color(row.fill, d.color or STYLE.info, 0.9); row.fill:Show()
    end
    for i, v in ipairs(d.ticks or {}) do
        local t = Seg(row.ticks, row, i, "OVERLAY")
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", row.track, "TOPLEFT", X(v) - 1, 1)
        t:SetSize(2, 10)
        Color(t, { 0.85, 0.85, 0.85 }, 0.9)
        t:Show()
    end
    if d.marker then
        row.marker:ClearAllPoints()
        row.marker:SetPoint("TOPLEFT", row.track, "TOPLEFT", X(d.marker) - 1, 3)
        row.marker:SetSize(3, 14)
        Color(row.marker, { 1, 1, 1 }, 1); row.marker:Show()
    end
    row.text:SetPoint("TOPLEFT", 4, -16)
    row.text:SetWidth(W * 0.7)
    row.text:SetText(d.label or "")
    if d.labelColor then row.text:SetTextColor(d.labelColor[1], d.labelColor[2], d.labelColor[3]) end
    row.right:SetPoint("TOPRIGHT", -4, -16)
    row.right:SetText(d.right or "")
    return 32
end

function Draw.line(row, d)
    local left = (d.indent or 0) + 2
    if d.atlas and row.icon.SetAtlas then
        if not pcall(row.icon.SetAtlas, row.icon, d.atlas) then row.icon:SetTexture(nil) end
        row.icon:Show()
    elseif d.icon then
        row.icon:SetTexture(d.icon)
        row.icon:Show()
    end
    if row.icon:IsShown() then
        row.icon:ClearAllPoints()
        row.icon:SetPoint("TOPLEFT", left, -2)
        left = left + 20
    end
    local rightEdge = 4
    if d.badge then
        local c = d.badge[2] or STYLE.gold
        row.badge:ClearAllPoints()
        row.badge:SetPoint("TOPRIGHT", -4, -3)
        row.badgeText:SetText(d.badge[1] or "")
        local bw = math.max(22, TextWidth(row.badgeText, d.badge[1]) + 10)
        row.badge:SetSize(bw, 15)
        Color(row.badge, c, 0.3); row.badge:Show()
        row.badgeText:ClearAllPoints()
        row.badgeText:SetPoint("CENTER", row.badge, "CENTER", 0, 0)
        row.badgeText:SetTextColor(c[1], c[2], c[3])
        row.badgeText:Show()
        rightEdge = rightEdge + bw + 6
    end
    local rightW = 0
    if d.right and d.right ~= "" then
        row.right:SetPoint("TOPRIGHT", -rightEdge, -4)
        row.right:SetText(d.right)
        rightW = TextWidth(row.right, d.right) + 10
    end
    row.text:SetPoint("TOPLEFT", left + 2, -4)
    row.text:SetWidth(math.max(80, CONTENT_W - left - 4 - rightEdge - rightW))
    row.text:SetWordWrap(d.wrap and true or false)
    row.text:SetText(d.text or "")
    if d.color then
        row.text:SetTextColor(d.color[1], d.color[2], d.color[3])
    elseif d.dim then
        row.text:SetTextColor(0.6, 0.6, 0.6)
    end
    if d.wrap then return math.max(ROW_H, Height(row.text, 12) + 8) end
    return ROW_H
end

-- Spazio prima di alcuni tipi di riga
local GAP = { header = 8, sub = 4, phase = 2, callout = 4, pills = 2, bar = 2, thead = 2 }

local function FillRow(row, d)
    row.data = d
    Reset(row)
    local kind = d.header and "header" or d.kind or "line"
    row:EnableMouse(Interactive(d))
    local draw = Draw[kind] or Draw.line
    return draw(row, d), GAP[kind] or 0, kind
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
    content:SetSize(CONTENT_W, 10)
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

    -- sessione di farm (scheda Asta)
    f.farm = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.farm:SetSize(180, 22)
    f.farm:SetPoint("BOTTOMLEFT", 10, 10)
    f.farm:SetScript("OnClick", function() ns.Market:ToggleSession() end)
    f.farm:Hide()

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
        row:SetWidth(CONTENT_W)
        local h, gap = FillRow(row, d)
        if i > 1 then y = y + gap end
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetHeight(h)
        row:Show()
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
    f.farm:SetShown(self.tab == "market")
    f.farm:SetText(ns.Market.session and L.BTN_FARM_STOP or L.BTN_FARM_START)
    if self.tab ~= "pets" then ns.Pets:HidePreview() end
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
