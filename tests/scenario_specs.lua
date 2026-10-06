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
}) do
    Setup(t[1], t[2], t[4])
    Plates(1); Run(t[3] .. " - 1 bersaglio", 30)
    Plates(3); Run(t[3] .. " - 3 bersagli", 20)
    Plates(5); Run(t[3] .. " - 5 bersagli", 20)
    MOCK.restricted = false; MOCK.fire("PLAYER_REGEN_ENABLED"); MOCK.now = MOCK.now + 60
end
print("ERRORI TOTALI:", #MOCK.errors)
-- Focus esaurito: Raptor Strike non utilizzabile -> deve passare a Kill Command
Setup(255, "HUNTER", {1264902, 1253601})
Plates(1)
C_Spell.IsSpellUsable = function(id) if id == 186270 then return false, true end return true, false end
RA:Tick()
print("SV PL senza Focus -> primario:", MOCK.names[RA.lastResult.primary and RA.lastResult.primary.spell] or "nessuno")

local real = C_Spell.GetSpellName
C_Spell.GetSpellName = function(id) if id == 466990 then return nil end return MOCK.names[id] end
SlashCmdList.ROTASSIST("verify")
C_Spell.GetSpellName = real
print("ERRORI TOTALI FINALI:", #MOCK.errors)
