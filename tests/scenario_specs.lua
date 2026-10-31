-- Simulazione di tutte le spec con modulo
local ns = {}
for _, f in ipairs(FILES) do
    local chunk, err = load(f.src, "@" .. f.name)
    if not chunk then error(err) end
    chunk("RotAssist", ns)
end
local RA = RotAssist
RA.ReportError = function(self, e) print("!!! ERRORE: " .. tostring(e)); table.insert(MOCK.errors, tostring(e)) end
MOCK.names = {}
MOCK.usableSecret = false           -- in gioco IsSpellUsable e' leggibile
MOCK.mw = 0
C_UnitAuras.GetPlayerAuraBySpellID = function(id)
    if id == 344179 and MOCK.mw > 0 then return { applications = MOCK.mw } end
end
MOCK.fire("ADDON_LOADED", "RotAssist")
MOCK.fire("PLAYER_LOGIN")

local function Setup(specID, classFile, knownExtra)
    UnitClass = function() return classFile, classFile end
    local spec = RA.specs[specID]
    MOCK.specID = specID
    MOCK.known, MOCK.charges, MOCK.cd, MOCK.cdBase, MOCK.override = {}, {}, {}, {}, {}
    for k, id in pairs(spec.spells) do MOCK.known[id] = true; MOCK.names[id] = k end
    for _, id in ipairs(knownExtra or {}) do MOCK.known[id] = nil end   -- talenti da escludere
    for id in pairs(spec.overrideOf or {}) do MOCK.known[id] = nil end
    for _, id in ipairs(spec.track.charges or {}) do
        local b = spec.base and spec.base[id]
        MOCK.charges[id] = { cur = 2, max = 2, dur = (b and (b.recharge or b.cd)) or 8 }
    end
    for id in pairs(spec.track.cooldowns or {}) do
        local b = spec.base and spec.base[id]
        MOCK.cdBase[id] = (b and b.cd) or 30
    end
    MOCK.restricted = false
    MOCK.fire("PLAYER_SPECIALIZATION_CHANGED", "player")
    MOCK.restricted = true
    MOCK.fire("PLAYER_REGEN_DISABLED")
    return spec
end

local function Cast(id)
    if MOCK.cdRemaining(61304) > 0 then return false end
    local c = MOCK.charges[id]
    if c then
        MOCK.advance(id)
        if c.cur < 1 then return false end
        if c.cur == c.max then c.start = MOCK.now end
        c.cur = c.cur - 1
    elseif (MOCK.cdBase[id] or 0) > 0 then
        if MOCK.cdRemaining(id) > 0 then return false end
        MOCK.cd[id] = { start = MOCK.now, dur = MOCK.cdBase[id] }
    end
    MOCK.cd[61304] = { start = MOCK.now, dur = 1.3 }
    -- generatori/spender di Maelstrom Weapon (Enhancement)
    if id == 17364 or id == 60103 or id == 187874 or id == 115356 then MOCK.mw = math.min(10, MOCK.mw + 3) end
    if id == 188196 or id == 188443 or id == 454009 or id == 1218047 then MOCK.mw = 0 end
    -- Holy Power del paladino: generatori +1 (Avenger's Shield e Divine Toll +3), spender -3
    if MOCK.hp then
        local gen = { [275779] = 1, [204019] = 1, [53595] = 1, [24275] = 1, [31935] = 3, [375576] = 3 }
        if gen[id] then MOCK.hp = math.min(5, MOCK.hp + gen[id]) end
        if id == 53600 or id == 85673 then MOCK.hp = math.max(0, MOCK.hp - 3) end
    end
    MOCK.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", id)
    return true
end

local function Run(label, seconds)
    local seq, stop, modes = {}, MOCK.now + seconds, {}
    while MOCK.now < stop do
        MOCK.now = MOCK.now + 0.1
        MOCK.native = nil
        RA:Tick()
        local r = RA.lastResult
        local m = RA.lastCtx and RA.lastCtx.mode or "?"
        modes[m] = (modes[m] or 0) + 1
        if MOCK.cdRemaining(61304) <= 0 and r and r.primary then
            local p = r.primary
            if Cast(p.spell) then
                seq[#seq + 1] = ("%-18s %-14s"):format(MOCK.names[p.spell] or p.spell, p.rule and p.rule.id or p.reason)
            end
        end
    end
    local ms = "" for k, v in pairs(modes) do ms = ms .. k .. "=" .. v .. " " end
    print(("=== %s | hero %s | modi: %s"):format(label, tostring(RA.hero), ms))
    local line = {}
    for i = 1, math.min(#seq, 18) do line[#line + 1] = seq[i] end
    print("   " .. table.concat(line, "\n   "))
end

local baseUsable = C_Spell.IsSpellUsable
C_Spell.IsSpellUsable = function(id, ...)
    if MOCK.hp and (id == 53600 or id == 85673) then return MOCK.hp >= 3, MOCK.hp < 3 end
    return baseUsable(id, ...)
end

local function Plates(n)
    for k in pairs(MOCK.plates) do MOCK.plates[k] = nil; MOCK.fire("NAME_PLATE_UNIT_REMOVED", k) end
    for i = 1, n do MOCK.plates["nameplate" .. i] = true; MOCK.fire("NAME_PLATE_UNIT_ADDED", "nameplate" .. i) end
end
-- nameplate di mob veri: in combattimento
UnitAffectingCombat = function(u) if u == "player" then return MOCK.restricted end return true end

for _, t in ipairs({
    { 262, "SHAMAN", "Elemental Farseer", {454009, 455110} },
    { 262, "SHAMAN", "Elemental Stormbringer", {467646, 443454} },
    { 263, "SHAMAN", "Enhancement Stormbringer", {444995} },
    { 263, "SHAMAN", "Enhancement Totemic", {454009, 455110} },
    { 264, "SHAMAN", "Restoration Totemic", {467646, 443454} },
    { 254, "HUNTER", "Marksmanship Sentinel", {466932} },
    { 254, "HUNTER", "Marksmanship Dark Ranger", {1264902, 1253601, 1253732} },
    { 255, "HUNTER", "Survival Sentinel", {471876} },
    { 255, "HUNTER", "Survival Pack Leader", {1264902, 1253601} },
    { 66, "PALADIN", "Protection Templar", {432459, 432472} },
    { 66, "PALADIN", "Protection Lightsmith", {427445, 427453} },
}) do
    Setup(t[1], t[2], t[4])
    MOCK.hp = (t[2] == "PALADIN") and 1 or nil
    Plates(1); Run(t[3] .. " - 1 bersaglio", 30)
    Plates(3); Run(t[3] .. " - 3 bersagli", 20)
    Plates(5); Run(t[3] .. " - 5 bersagli", 20)
    MOCK.restricted = false; MOCK.fire("PLAYER_REGEN_ENABLED"); MOCK.now = MOCK.now + 60
end
print("ERRORI TOTALI:", #MOCK.errors)

-- Paladin Protection: Word of Glory con Shining Light (glow) e difese in base alla vita
local pala = Setup(66, "PALADIN", {427445, 427453})
Plates(1)
local function Def(label)
    RA:Tick()
    local list = RA.Defensives:Collect(pala)
    local parts = {}
    for _, e in ipairs(list) do
        parts[#parts + 1] = ("%s:%s(%s)"):format(e.tier.key, MOCK.names[e.spell] or e.spell,
            e.visible == nil and "curva" or tostring(e.visible))
    end
    local icons = {}
    for i = 1, 2 do
        local d = RA.UI.Main.frame.def[i]
        icons[i] = d:IsShown() and ("mostrata alpha " .. tostring(d._a)) or "nascosta"
    end
    print(("difese %-30s -> %s | icone: %s"):format(label, #parts > 0 and table.concat(parts, ", ") or "nessuna",
        table.concat(icons, " / ")))
end
-- interrupt: il bersaglio inizia un cast (eventi; nome e dettagli segreti)
local function Kick(label)
    RA:Tick()
    local p = RA.lastResult.primary
    local alerts = RA.Alerts:Collect(RA.activeSpec)
    local al = {}
    for _, x in ipairs(alerts) do if x.key == "interrupt" then al[#al + 1] = x.text end end
    print(("interrupt %-32s -> primario %s | avviso %s"):format(label, p and (MOCK.names[p.spell] or p.spell) or "nessuno",
        #al > 0 and table.concat(al, ", ") or "nessuno"))
end
Kick("nessun cast")
MOCK.fire("UNIT_SPELLCAST_START", "target", "guid", 1)
Kick("cast interrompibile")
MOCK.fire("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "target")
Kick("cast non interrompibile")
MOCK.fire("UNIT_SPELLCAST_INTERRUPTIBLE", "target")
MOCK.cd[96231] = { start = MOCK.now, dur = 15 }
Kick("Rebuke in ricarica")
MOCK.cd[96231] = nil
MOCK.fire("UNIT_SPELLCAST_STOP", "target", "guid", 1)
Kick("cast finito")
-- Retribution (modulo generico): avviso con l"interrupt della classe
MOCK.fire("UNIT_SPELLCAST_START", "target", "guid", 2)
local gen = RA.Alerts:Collect(RA.genericSpec)
print("interrupt generico (paladino Retribution):", gen[1] and gen[1].text or "nessuno")
MOCK.fire("UNIT_SPELLCAST_STOP", "target", "guid", 2)
MOCK.fire("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", 85673)
RA:Tick()
local wogNext = false
for _, m in ipairs(RA.lastResult.next) do if m.rule and m.rule.id == "wog_sl" then wogNext = true end end
local wogTrace
for _, t in ipairs(RA.lastResult.trace) do if t.rule.id == "wog_sl" then wogTrace = t.status end end
print("Word of Glory con Shining Light (glow): regola", wogTrace, "| tra le icone piccole:", wogNext)
MOCK.fire("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", 85673)
-- vita segreta (scontro con un boss): decide la curva nativa
for i = 1, 2 do RA.UI.Main.frame.def[i].SetAlpha = function(self, v) self._a = v end end
-- curva nativa simulata: restituisce la vita (segreta) come alpha
C_CurveUtil = C_CurveUtil or {}
C_CurveUtil.CreateCurve = function() return { AddPoint = function() end } end
UnitHealthPercent = function(u) return UnitHealth(u) end
Def("vita segreta")
-- vita leggibile in combattimento (mondo aperto)
local realHealth, realMax = UnitHealth, UnitHealthMax
UnitHealth = function(u) if u == "player" then return MOCK.playerHP end return realHealth(u) end
UnitHealthMax = function(u) if u == "player" then return 100 end return realMax(u) end
for _, hp in ipairs({ 80, 45, 30 }) do
    MOCK.playerHP = hp
    Def("vita " .. hp .. "%")
end
-- Ardent Defender in cooldown: tocca a Guardian of Ancient Kings
MOCK.cd[31850] = { start = MOCK.now, dur = 90 }
Def("vita 30%, Ardent Defender in cd")
-- niente Holy Power: Word of Glory non lanciabile
local realUsable = C_Spell.IsSpellUsable
C_Spell.IsSpellUsable = function(id) if id == 85673 then return false, true end return true, false end
Def("vita 30%, senza Holy Power")
C_Spell.IsSpellUsable = realUsable
-- opzione disattivata
RA.db.showDefensives = false
Def("vita 30%, opzione spenta")
RA.db.showDefensives = true
-- fuori combattimento: niente difese
MOCK.restricted = false; MOCK.fire("PLAYER_REGEN_ENABLED")
Def("fuori combattimento")
UnitHealth, UnitHealthMax = realHealth, realMax
MOCK.cd[31850] = nil
MOCK.fire("PLAYER_REGEN_DISABLED")
print("ERRORI TOTALI:", #MOCK.errors)
-- Focus esaurito: Raptor Strike non utilizzabile -> deve passare a Kill Command
Setup(255, "HUNTER", {1264902, 1253601})
Plates(1)
C_Spell.IsSpellUsable = function(id) if id == 186270 then return false, true end return true, false end
RA:Tick()
print("SV PL senza Focus -> primario:", MOCK.names[RA.lastResult.primary and RA.lastResult.primary.spell] or "nessuno")

-- blocco note dei quarti di Azta'rec
local SF = RA.Sermon
local function St(label)
    local cur = SF:Current()
    print(("sermone %-28s fase %-7s sequenza {%s} prossimo %s | finestra %s"):format(label, SF.phase,
        table.concat(SF.seq, ","), tostring(cur), SF.frame and SF.frame:IsShown() and "aperta" or "chiusa"))
end
MOCK.fire("ENCOUNTER_START", 3001, [[Azta'rec]], 8, 1)
St("inizio scontro")
SF:Mark(1); SF:Mark(4); SF:Mark(2)
St("tre giri annotati")
SF:ToggleReplay()
St("ripeti")
RotAssist_SermonMark(3)
St("primo quarto passato")
SF:Next(); SF:Next()
St("sequenza finita")
SF:Mark(3)
St("nuovo intermezzo")
SF:Undo()
St("tolto l ultimo")
SF:ToggleReplay()
St("ripeti senza sequenza")
MOCK.fire("ENCOUNTER_END", 3001, [[Azta'rec]], 8, 1, 1)
St("fine scontro")
MOCK.fire("ENCOUNTER_START", 3002, "Altro boss", 8, 1)
St("altro boss")
SlashCmdList.ROTASSIST("sermone")
St("comando")
SlashCmdList.ROTASSIST("sermone")

local real = C_Spell.GetSpellName
C_Spell.GetSpellName = function(id) if id == 466990 then return nil end return MOCK.names[id] end
SlashCmdList.ROTASSIST("verify")
C_Spell.GetSpellName = real
print("ERRORI TOTALI FINALI:", #MOCK.errors)
