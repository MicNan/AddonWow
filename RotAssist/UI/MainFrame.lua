-- RotAssist - MainFrame
-- Riquadro principale: icona grande (prossima abilita'), due icone piccole
-- (successive), indicatore di modalita', barra risorsa e barra vita del pet.
-- Le barre ricevono direttamente i valori (anche segreti): i widget nativi
-- possono mostrarli, l'addon non li legge.

local _, ns = ...
local A, L = ns.API, ns.L
local UI = ns.UI

local BIG, SMALL, GAP = 52, 34, 4

local M = {}
UI.Main = M

local function CreateBar(parent, height, r, g, b)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetHeight(height)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(r, g, b)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.6)
    bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.text:SetPoint("CENTER")
    return bar
end

function M:Create()
    local f = CreateFrame("Frame", "RotAssistMainFrame", UIParent)
    f:SetSize(BIG + GAP + SMALL * 2 + GAP, BIG)
    f:SetFrameStrata("MEDIUM")
    UI.MakeMovable(f, "pos")
    UI.AddMoverBackground(f, L.DRAG_HINT)

    f.big = UI.CreateIcon(f, BIG)
    f.big:SetPoint("TOPLEFT")
    UI.AddGlow(f.big, 0.3, 0.8, 1)

    f.small = {}
    for i = 1, 2 do
        local s = UI.CreateIcon(f, SMALL)
        s:SetPoint("BOTTOMLEFT", f.big, "BOTTOMRIGHT", GAP + (i - 1) * (SMALL + GAP), 0)
        s:SetAlpha(0.85)
        f.small[i] = s
    end

    f.mode = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.mode:SetPoint("TOPLEFT", f.big, "TOPRIGHT", GAP, -1)

    f.resource = CreateBar(f, 8, 1, 0.5, 0.25)
    f.resource:SetPoint("TOPLEFT", f.big, "BOTTOMLEFT", 0, -3)
    f.resource:SetPoint("RIGHT", f, "RIGHT")

    f.pet = CreateBar(f, 6, 0.2, 0.9, 0.2)
    f.pet:SetPoint("TOPLEFT", f.resource, "BOTTOMLEFT", 0, -2)
    f.pet:SetPoint("RIGHT", f, "RIGHT")

    self.frame = f
    self:ApplySettings()
    return f
end

function M:ApplySettings()
    local f, db = self.frame, ns.db
    if not f then return end
    f:SetScale(db.scale or 1)
    UI.RestorePosition(f, "pos")
    f:SetUnlocked(not db.locked)
end

local function SetIcon(icon, entry)
    if not entry then
        icon:Hide()
        return
    end
    icon:Show()
    icon.tex:SetTexture(A.SpellTexture(entry.spell))
    icon.badge:SetText(entry.source == "native" and L.SRC_NATIVE or L.SRC_RULE)
    icon.hotkey:SetText(ns.Keybinds:Get(entry.spell, entry.rule and entry.rule.spell) or "")
    A.ApplyCooldown(icon.cd, entry.spell)
end

function M:Update(result, ctx)
    local f = self.frame
    if not f then return end
    SetIcon(f.big, result and result.primary)
    if result and result.primary and result.primary.source == "rule" and result.primary.rule and result.primary.rule.pin then
        f.big:SetGlow(true)
    else
        f.big:SetGlow(false)
    end
    for i = 1, 2 do SetIcon(f.small[i], result and result.next[i]) end

    if ctx then
        local label = L["MODE_" .. ctx.mode] or ctx.mode
        if ns.db.mode == "AUTO" then
            local n = ns.Enemies.lastUnknown and "?" or tostring(ctx.targets or "?")
            if ctx.modeSource == "Assisted Combat" then n = "AC" end
            label = ("%s %s (%s)"):format(L.MODE_AUTO, label, n)
        end
        f.mode:SetText(label)
    end
end

-- Barre: valori passati direttamente ai widget (consentito anche se segreti).
function M:UpdateBars(spec)
    local f = self.frame
    if not f then return end
    local showRes = ns.db.showResource and spec and (spec.resource or spec.stackBar)
    f.resource:SetShown(showRes and true or false)
    if showRes and spec.stackBar then
        -- stack di un'aura in whitelist (es. Maelstrom Weapon): valore leggibile
        local sb = spec.stackBar
        local stacks = A.PlayerAuraStacks(sb.aura, true) or 0
        f.resource:SetMinMaxValues(0, sb.max)
        f.resource:SetValue(stacks)
        f.resource.text:SetText(stacks > 0 and tostring(stacks) or "")
        if stacks >= (sb.full or sb.max) then f.resource:SetStatusBarColor(1, 0.85, 0.1)
        else f.resource:SetStatusBarColor(0.2, 0.55, 1) end
    elseif showRes then
        local pt = spec.resource
        pcall(function()
            f.resource:SetMinMaxValues(0, UnitPowerMax("player", pt))
            f.resource:SetValue(UnitPower("player", pt))
        end)
        pcall(f.resource.text.SetText, f.resource.text, UnitPower("player", pt))
        if spec.resourceWarn then self:ColorResourceBar(pt, spec.resourceWarn) end
    end

    local showPet = ns.db.showResource and spec and spec.petBar and A.UnitExists("pet") == true
    f.pet:SetShown(showPet and true or false)
    if showPet then
        pcall(function()
            f.pet:SetMinMaxValues(0, UnitHealthMax("pet"))
            f.pet:SetValue(UnitHealth("pet"))
        end)
        local pct = A.HealthPct("pet")
        local threshold = spec.petBar.threshold or 0.4
        if pct then
            if pct < threshold then f.pet:SetStatusBarColor(1, 0.15, 0.15)
            else f.pet:SetStatusBarColor(0.2, 0.9, 0.2) end
        else
            self:ColorPetBarByCurve(threshold)
        end
    end
end

-- Risorsa vicina al massimo (es. Maelstrom di Elemental): se il valore e'
-- leggibile coloriamo noi, altrimenti proviamo la curva colore nativa con
-- UnitPowerPercent. Firma da verificare in gioco: in caso di errore la barra
-- resta del colore base.
function M:ColorResourceBar(powerType, warnPct)
    local bar = self.frame.resource
    local cur, max = A.Power(powerType)
    local normal, warn = { 0.25, 0.5, 1 }, { 1, 0.35, 0.1 }
    if cur and max and max > 0 then
        local c = (cur / max >= warnPct) and warn or normal
        bar:SetStatusBarColor(c[1], c[2], c[3])
        return
    end
    if not (C_CurveUtil and C_CurveUtil.CreateColorCurve and UnitPowerPercent and CreateColor) then return end
    if not self.resCurve or self.resCurvePct ~= warnPct then
        local ok, curve = pcall(C_CurveUtil.CreateColorCurve)
        if not ok or not curve then return end
        local okAdd = pcall(function()
            curve:AddPoint(0, CreateColor(normal[1], normal[2], normal[3]))
            curve:AddPoint(math.max(0, warnPct - 0.01), CreateColor(normal[1], normal[2], normal[3]))
            curve:AddPoint(warnPct, CreateColor(warn[1], warn[2], warn[3]))
            curve:AddPoint(1, CreateColor(warn[1], warn[2], warn[3]))
        end)
        if not okAdd then return end
        self.resCurve, self.resCurvePct = curve, warnPct
    end
    pcall(function()
        local color = UnitPowerPercent("player", powerType, false, self.resCurve)
        if type(color) == "table" and color.GetRGB then bar:SetStatusBarColor(color:GetRGB()) end
    end)
end

-- In combattimento la vita del pet e' segreta: proviamo a colorare la barra
-- con una curva di colore nativa (rossa sotto soglia). Se l'API non e'
-- disponibile o ha una firma diversa la barra resta verde: nessun errore.
function M:ColorPetBarByCurve(threshold)
    if not (C_CurveUtil and C_CurveUtil.CreateColorCurve and UnitHealthPercent and CreateColor) then return end
    if not self.petCurve or self.petCurveThreshold ~= threshold then
        local ok, curve = pcall(C_CurveUtil.CreateColorCurve)
        if not ok or not curve then return end
        local red, green = CreateColor(1, 0.15, 0.15), CreateColor(0.2, 0.9, 0.2)
        local okAdd = pcall(function()
            curve:AddPoint(0, red)
            curve:AddPoint(threshold, red)
            curve:AddPoint(math.min(1, threshold + 0.01), green)
            curve:AddPoint(1, green)
        end)
        if not okAdd then return end
        self.petCurve, self.petCurveThreshold = curve, threshold
    end
    pcall(function()
        local color = UnitHealthPercent("pet", true, self.petCurve)
        if type(color) == "table" and color.GetRGB then
            self.frame.pet:SetStatusBarColor(color:GetRGB())
        end
    end)
end
