-- RotAssist - SermonFrame
-- Blocco note per gli intermezzi di Azta'rec (Sermon of Ula'tek): la stanza
-- e' divisa in quattro quarti, il boss mostra in sequenza quale e' pulito e
-- poi ripete la stessa sequenza senza indicatori.
--
-- L'addon NON vede i quarti avvelenati: li segni tu. Fase "annota": a ogni
-- giro clicchi (o premi il tasto 1-4) il quarto pulito e la sequenza si
-- allunga. Fase "ripeti": il riquadro evidenzia il prossimo quarto e ogni
-- clic o tasto passa al successivo. Finita la ripetizione, il prossimo
-- quarto segnato apre una sequenza nuova (intermezzo successivo).
--
-- I quattro quarti hanno i colori dei segnalini mondo 1-4 (/wm [@cursor] 1-4):
-- quadrato blu, triangolo verde, rombo viola, croce rossa.
-- Si apre da solo all'inizio dello scontro con Azta'rec (ENCOUNTER_START,
-- nome leggibile) e con /rotassist sermone. Nessuna azione automatica.

local _, ns = ...
local UI, L = ns.UI, ns.L

local SZ, GAP = 44, 4
local MARKERS = {
    { tex = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6", r = 0.2, g = 0.55, b = 1 },    -- 1 quadrato blu
    { tex = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4", r = 0.25, g = 0.9, b = 0.25 }, -- 2 triangolo verde
    { tex = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3", r = 0.75, g = 0.35, b = 1 },   -- 3 rombo viola
    { tex = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7", r = 1, g = 0.25, b = 0.2 },    -- 4 croce rossa
}
local BOSS_WORDS = { "azta" }

local SF = { seq = {}, phase = "record", pos = 1 }
UI.Sermon = SF
ns.Sermon = SF

---------------------------------------------------------------------------
-- Logica (senza interfaccia: si puo' provare da sola)
---------------------------------------------------------------------------
function SF:Reset()
    self.seq, self.phase, self.pos = {}, "record", 1
    self:Refresh()
end

-- Un quarto segnato: in annotazione si aggiunge, in ripetizione si avanza
function SF:Mark(q)
    if type(q) ~= "number" or q < 1 or q > 4 then return end
    if self.phase == "done" then
        self.seq, self.phase, self.pos = {}, "record", 1
    end
    if self.phase == "record" then
        self.seq[#self.seq + 1] = q
    else
        self:Next()
        return
    end
    self:Refresh()
end

function SF:Undo()
    if self.phase == "record" and #self.seq > 0 then table.remove(self.seq) end
    self:Refresh()
end

-- Passa alla ripetizione (o torna ad annotare)
function SF:ToggleReplay()
    if self.phase == "record" then
        if #self.seq == 0 then return end
        self.phase, self.pos = "replay", 1
    else
        self.phase, self.pos = "record", 1
    end
    self:Refresh()
end

function SF:Next()
    if self.phase ~= "replay" then return end
    self.pos = self.pos + 1
    if self.pos > #self.seq then self.phase = "done" end
    self:Refresh()
end

-- Prossimo quarto da raggiungere (nil se non in ripetizione)
function SF:Current()
    if self.phase == "replay" then return self.seq[self.pos] end
end

---------------------------------------------------------------------------
-- Interfaccia
---------------------------------------------------------------------------
function SF:Create()
    if self.frame then return self.frame end
    local f = CreateFrame("Frame", "RotAssistSermonFrame", UIParent)
    f:SetSize(SZ * 2 + GAP, SZ * 2 + GAP + 58)
    f:SetFrameStrata("HIGH")
    UI.MakeMovable(f, "sermonPos")
    UI.AddMoverBackground(f, L.SERMON_DRAG)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", -6, 6)
    bg:SetPoint("BOTTOMRIGHT", 6, -6)
    bg:SetColorTexture(0, 0, 0, 0.6)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.title:SetPoint("TOP", f, "TOP", 0, 0)
    f.title:SetWidth(SZ * 2 + GAP + 40)

    f.quads = {}
    for i = 1, 4 do
        local b = CreateFrame("Button", nil, f)
        b:SetSize(SZ, SZ)
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", col * (SZ + GAP), -16 - row * (SZ + GAP))
        b.fill = b:CreateTexture(nil, "BACKGROUND")
        b.fill:SetAllPoints()
        b.fill:SetColorTexture(MARKERS[i].r, MARKERS[i].g, MARKERS[i].b, 0.35)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetSize(SZ * 0.6, SZ * 0.6)
        b.icon:SetPoint("CENTER")
        b.icon:SetTexture(MARKERS[i].tex)
        b.key = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        b.key:SetPoint("BOTTOMRIGHT", -2, 2)
        b.key:SetText(tostring(i))
        UI.AddGlow(b, 1, 1, 1)
        b:SetScript("OnClick", function() SF:Mark(i) end)
        f.quads[i] = b
    end

    f.seqText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.seqText:SetPoint("TOP", f, "TOP", 0, -16 - 2 * (SZ + GAP) - 2)
    f.seqText:SetWidth(SZ * 2 + GAP + 40)

    local function Btn(label, x, fn)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(46, 18)
        b:SetPoint("BOTTOM", f, "BOTTOM", x, 0)
        b:SetText(label)
        b:SetScript("OnClick", fn)
        return b
    end
    f.replay = Btn(L.SERMON_REPLAY, -48, function() SF:ToggleReplay() end)
    f.undo = Btn(L.SERMON_UNDO, 0, function() SF:Undo() end)
    f.reset = Btn(L.SERMON_RESET, 48, function() SF:Reset() end)

    f:Hide()
    self.frame = f
    UI.RestorePosition(f, "sermonPos")
    f:SetUnlocked(not ns.db.locked)
    self:Refresh()
    return f
end

local function Icon(q) return ("|T%s:14|t"):format(MARKERS[q].tex) end

function SF:Refresh()
    local f = self.frame
    if not f then return end
    local cur = self:Current()
    for i = 1, 4 do
        local b = f.quads[i]
        local on = (cur == nil) or (cur == i)
        b:SetAlpha(on and 1 or 0.25)
        b:SetGlow(cur == i)
    end
    local parts = {}
    for k, q in ipairs(self.seq) do
        local s = k .. Icon(q)
        if self.phase == "replay" and k == self.pos then s = "[" .. s .. "]" end
        parts[#parts + 1] = s
    end
    f.seqText:SetText(#parts > 0 and table.concat(parts, " ") or L.SERMON_EMPTY)
    if self.phase == "record" then
        f.title:SetText(L.SERMON_RECORD:format(#self.seq))
        f.replay:SetText(L.SERMON_REPLAY)
    elseif self.phase == "replay" then
        f.title:SetText(L.SERMON_GO:format(Icon(cur), self.pos, #self.seq))
        f.replay:SetText(L.SERMON_BACK)
    else
        f.title:SetText(L.SERMON_DONE)
        f.replay:SetText(L.SERMON_REPLAY)
    end
end

function SF:Show(on)
    local f = self:Create()
    if on == nil then on = not f:IsShown() end
    f:SetShown(on and true or false)
    if on then self:Refresh() end
end

-- Apertura automatica nello scontro con Azta'rec
ns:On("ENCOUNTER_START", function(_, _, name)
    if not ns.db.sermonAuto then return end
    name = ns.API.Plain(name)
    name = type(name) == "string" and name:lower() or ""
    for _, w in ipairs(BOSS_WORDS) do
        if name:find(w, 1, true) then
            SF:Reset()
            SF:Show(true)
            return
        end
    end
end)
ns:On("ENCOUNTER_END", function()
    if SF.frame and SF.frame:IsShown() and ns.db.sermonAuto then SF.frame:Hide() end
end)

-- Funzioni per i tasti (Bindings.xml)
function RotAssist_SermonMark(q) SF:Mark(q) end
function RotAssist_SermonReplay() SF:ToggleReplay() end
function RotAssist_SermonReset() SF:Reset() end
