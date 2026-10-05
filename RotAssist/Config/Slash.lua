-- RotAssist - Slash
-- /rotassist (alias /rota)

local _, ns = ...
local A = ns.API

local HELP = {
    "/rotassist show | hide | toggle - mostra/nasconde",
    "/rotassist lock | unlock - blocca/sblocca i riquadri",
    "/rotassist scale <0.5-2> - scala",
    "/rotassist mode auto|st|aoe - modalita' bersagli (anche da tasto)",
    "/rotassist source hybrid|native|rules - fonte del suggerimento",
    "/rotassist debug [on|off] - spiega in chat i suggerimenti",
    "/rotassist why - valutazione completa delle regole (ultimo aggiornamento)",
    "/rotassist probe - verifica quali API sono segrete adesso",
    "/rotassist config - apre il pannello opzioni",
    "/rotassist minimap - mostra/nasconde l'icona sulla minimappa",
    "/rotassist wowhead [spellID] - link Wowhead del suggerimento attuale (o dello spellID)",
    "/rotassist reset - riporta i riquadri al centro",
}

local MODES = { AUTO = true, ST = true, AOE = true }
local SOURCES = { HYBRID = true, NATIVE = true, RULES = true }

function ns:CycleMode()
    local nextMode = { AUTO = "ST", ST = "AOE", AOE = "AUTO" }
    self:Set("mode", nextMode[self.db.mode] or "AUTO")
    self:Print("modalita': %s", self.db.mode)
end

local function Describe(v)
    if A.IsSecret(v) then return "|cffff5555SEGRETO|r" end
    return "|cff55ff55" .. tostring(v) .. "|r"
end

-- Diagnostica: per ogni API usata indica se il valore e' leggibile adesso.
-- Da lanciare fuori e dentro il combattimento (manichino) per verificare le
-- ipotesi dell'analisi di fattibilita'.
function ns:Probe()
    local spec = self.activeSpec
    local S = spec and spec.spells or {}
    local function try(label, fn, ...)
        local ok, a, b = pcall(fn, ...)
        if not ok then
            self:Print("%s: errore (%s)", label, a)
        else
            self:Print("%s: %s %s", label, Describe(a), Describe(b))
        end
    end
    self:Print("--- probe (in combattimento: %s) ---", tostring(A.InCombat()))
    try("UnitPower(player)", UnitPower, "player")
    if C_AssistedCombat and C_AssistedCombat.GetNextCastSpell then
        try("AssistedCombat.GetNextCastSpell", C_AssistedCombat.GetNextCastSpell, false)
    end
    local probeSpell = S.BESTIAL_WRATH or S.KILL_COMMAND or 61304
    local ok, info = pcall(C_Spell.GetSpellCooldown, probeSpell)
    if ok and type(info) == "table" then
        self:Print("GetSpellCooldown(%d): isActive %s, isOnGCD %s, start %s, duration %s", probeSpell,
            Describe(info.isActive), Describe(info.isOnGCD), Describe(info.startTime), Describe(info.duration))
    end
    local chargeSpell = S.BARBED_SHOT or S.KILL_COMMAND
    if chargeSpell then
        local ok2, c = pcall(C_Spell.GetSpellCharges, chargeSpell)
        if ok2 and type(c) == "table" then
            self:Print("GetSpellCharges(%d): current %s, max %s, isActive %s", chargeSpell,
                Describe(c.currentCharges), Describe(c.maxCharges), Describe(c.isActive))
        end
        try("IsSpellUsable(" .. chargeSpell .. ")", C_Spell.IsSpellUsable, chargeSpell)
    end
    try("UnitExists(pet)", UnitExists, "pet")
    try("UnitIsDeadOrGhost(pet)", UnitIsDeadOrGhost, "pet")
    try("UnitHealth(pet)", UnitHealth, "pet")
    try("UnitAffectingCombat(pet)", UnitAffectingCombat, "pet")
    try("UnitCanAttack(target)", UnitCanAttack, "player", "target")
    try("UnitAffectingCombat(target)", UnitAffectingCombat, "target")
    try("UnitClassification(target)", UnitClassification, "target")
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local ok3, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "target", 1, "HARMFUL")
        if ok3 then
            if A.IsSecret(aura) then
                self:Print("aura bersaglio #1: |cffff5555SEGRETA|r")
            elseif type(aura) == "table" then
                self:Print("aura bersaglio #1: spellId %s", Describe(aura.spellId))
            else
                self:Print("aura bersaglio #1: nessuna")
            end
        end
    end
    if A.PlayerClass() == "SHAMAN" then
        self:Print("-- shaman --")
        try("UnitPower(Maelstrom)", UnitPower, "player", Enum and Enum.PowerType and Enum.PowerType.Maelstrom or 11)
        if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
            local okA, mw = pcall(C_UnitAuras.GetPlayerAuraBySpellID, 344179)
            if okA then
                if A.IsSecret(mw) then self:Print("Maelstrom Weapon (aura): |cffff5555SEGRETA|r")
                elseif type(mw) == "table" then self:Print("Maelstrom Weapon stack: %s", Describe(mw.applications))
                else self:Print("Maelstrom Weapon: nessuna aura") end
            end
            local okL, ls = pcall(C_UnitAuras.GetPlayerAuraBySpellID, 192106)
            if okL then self:Print("Lightning Shield (aura): %s", A.IsSecret(ls) and "|cffff5555SEGRETA|r" or (type(ls) == "table" and "presente" or "assente")) end
        end
        try("Override(Lightning Bolt)", C_Spell.GetOverrideSpell, 188196)
        try("Override(Stormstrike)", C_Spell.GetOverrideSpell, 17364)
        try("Override(Healing Stream Totem)", C_Spell.GetOverrideSpell, 5394)
        try("GetTotemInfo(1)", GetTotemInfo, 1)
        try("GetWeaponEnchantInfo", GetWeaponEnchantInfo)
        try("GetSpellCharges(Lava Burst).isActive", function()
            local c = C_Spell.GetSpellCharges(51505); return c and c.isActive, c and c.maxCharges
        end)
    end
    local n, unknown = ns.Enemies:Count()
    self:Print("nemici contati: %d%s", n, unknown and " (incerto: dati segreti)" or "")
end

function ns:PrintWhy()
    local r = self.lastResult
    if not r then self:Print("nessuna valutazione disponibile.") return end
    self:Print("--- spec %s, hero %s, modalita' %s ---", self.activeSpec and self.activeSpec.name or "?",
        tostring(self.hero), tostring(self.lastCtx and self.lastCtx.mode))
    self:Print("Assisted Combat: %s", r.native and A.SpellName(r.native) or ("nessuno (" .. tostring(r.nativeWhy) .. ")"))
    for i, t in ipairs(r.trace) do
        local color = ({ match = "55ff55", fail = "aaaaaa", unknown = "ffcc00", skip = "666666", disabled = "ff7777" })[t.status] or "ffffff"
        self:Print("%2d |cff%s%-8s|r %s - %s (%s)%s", i, color, t.status, t.rule.id, A.SpellName(t.rule.spell), t.rule.spell,
            t.why and (" (" .. t.why .. ")") or "")
    end
end

---------------------------------------------------------------------------
-- Link Wowhead: gli addon non possono aprire il browser, quindi mostriamo
-- l'URL in un riquadro gia' selezionato, pronto per Ctrl+C.
---------------------------------------------------------------------------
local WOWHEAD_LOCALE = {
    itIT = "it/", deDE = "de/", frFR = "fr/", esES = "es/", esMX = "mx/",
    ptBR = "pt/", ruRU = "ru/", koKR = "ko/", zhCN = "cn/", zhTW = "tw/",
}

function ns:WowheadURL(spellID)
    local loc = GetLocale and WOWHEAD_LOCALE[GetLocale()] or ""
    return ("https://www.wowhead.com/%sspell=%d"):format(loc, spellID)
end

function ns:ShowWowheadLink(spellID)
    if type(spellID) ~= "number" then
        local r = self.lastResult
        spellID = r and r.primary and r.primary.spell
    end
    if type(spellID) ~= "number" then
        self:Print("nessun suggerimento attivo: usa /rotassist wowhead <spellID>.")
        return
    end
    local url = self:WowheadURL(spellID)
    if StaticPopupDialogs and StaticPopup_Show then
        StaticPopupDialogs.ROTASSIST_WOWHEAD = StaticPopupDialogs.ROTASSIST_WOWHEAD or {
            text = "Wowhead - %s\n(Ctrl+C per copiare)",
            button1 = OKAY or "OK",
            hasEditBox = true,
            editBoxWidth = 340,
            OnShow = function(popup, data)
                local eb = popup.EditBox or popup.editBox
                if eb and data then eb:SetText(data); eb:HighlightText(); eb:SetFocus() end
            end,
            EditBoxOnEnterPressed = function(eb) eb:GetParent():Hide() end,
            EditBoxOnEscapePressed = function(eb) eb:GetParent():Hide() end,
            timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
        }
        if pcall(StaticPopup_Show, "ROTASSIST_WOWHEAD", A.SpellName(spellID), nil, url) then return end
    end
    self:Print("%s: %s", A.SpellName(spellID), url)
end

local function Handler(msg)
    msg = (msg or ""):lower()
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    if cmd == "show" then ns:Set("shown", true)
    elseif cmd == "hide" then ns:Set("shown", false)
    elseif cmd == "toggle" then ns:Set("shown", not ns.db.shown)
    elseif cmd == "lock" then ns:Set("locked", true)
    elseif cmd == "unlock" then ns:Set("locked", false); ns:Print("riquadri sbloccati: trascinali, poi /rotassist lock.")
    elseif cmd == "scale" then
        local v = tonumber(arg)
        if v and v >= 0.5 and v <= 2 then ns:Set("scale", v) else ns:Print("uso: /rotassist scale 0.5-2") end
    elseif cmd == "mode" then
        local m = arg:upper()
        if MODES[m] then ns:Set("mode", m); ns:Print("modalita': %s", m) else ns:CycleMode() end
    elseif cmd == "source" then
        local s = arg:upper()
        if SOURCES[s] then ns:Set("source", s); ns:Print("fonte: %s", s) else ns:Print("uso: /rotassist source hybrid|native|rules") end
    elseif cmd == "debug" then
        local v
        if arg == "on" then v = true elseif arg == "off" then v = false else v = not ns.db.debug end
        ns:Set("debug", v)
        ns:Print("debug %s", v and "attivo" or "disattivato")
    elseif cmd == "why" then ns:PrintWhy()
    elseif cmd == "probe" then ns:Probe()
    elseif cmd == "config" or cmd == "options" then ns:OpenSettings()
    elseif cmd == "wowhead" or cmd == "wh" then
        ns:ShowWowheadLink(tonumber(arg))
    elseif cmd == "minimap" then
        ns:Set("showMinimap", not ns.db.showMinimap)
        ns:Print("icona minimappa %s", ns.db.showMinimap and "visibile" or "nascosta (resta nel menu AddOns)")
    elseif cmd == "reset" then
        for _, k in ipairs({ "pos", "cdPos", "alertPos" }) do
            ns.db[k] = CopyTable(ns.defaults[k])
        end
        ns:OnSettingChanged("scale", ns.db.scale)
        ns:Print("posizioni ripristinate.")
    else
        for _, line in ipairs(HELP) do ns:Print(line) end
    end
end

SLASH_ROTASSIST1 = "/rotassist"
SLASH_ROTASSIST2 = "/rota"
SlashCmdList.ROTASSIST = function(msg)
    local ok, err = pcall(Handler, msg)
    if not ok then ns:ReportError(err) end
end
