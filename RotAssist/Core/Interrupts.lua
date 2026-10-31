-- RotAssist - Interrupts
-- Quando interrompere: il bersaglio sta lanciando un incantesimo
-- interrompibile e il tuo interrupt e' pronto.
--
-- In Midnight, negli scontri e nelle Mitiche+, nome e dettagli del cast del
-- bersaglio sono segreti. Gli EVENTI pero' arrivano lo stesso: inizio e fine
-- del cast (UNIT_SPELLCAST_START / STOP / ...) e il cambio di
-- interrompibilita' (UNIT_SPELLCAST_INTERRUPTIBLE / NOT_INTERRUPTIBLE).
-- L'addon usa solo questi: sa "sta lanciando qualcosa" ma non cosa, quindi
-- non distingue un cast importante da uno innocuo. Se l'interrompibilita' e'
-- segreta si considera interrompibile (meglio un avviso in piu').
--
-- Fornisce:
--   * l'avviso { type = "interrupt", spells = {...} } (senza 'spells' usa
--     l'interrupt della classe), aggiunto a tutte le spec, Generico compreso;
--   * il predicato {"targetCasting"} per le regole (es. Rebuke come icona
--     principale per il Paladin Protection).
-- Non lancia nulla: mostra soltanto.

local _, ns = ...
local A, AL, E = ns.API, ns.Alerts, ns.Engine
local GetTime = GetTime

local I = { cast = nil }
ns.Interrupts = I

-- Interrupt di ogni classe (il primo conosciuto)
I.CLASS = {
    PALADIN = { 96231 },             -- Rebuke
    WARRIOR = { 6552 },              -- Pummel
    ROGUE = { 1766 },                -- Kick
    MAGE = { 2139 },                 -- Counterspell
    DEATHKNIGHT = { 47528 },         -- Mind Freeze
    DEMONHUNTER = { 183752 },        -- Disrupt
    MONK = { 116705 },               -- Spear Hand Strike
    DRUID = { 106839, 78675 },       -- Skull Bash, Solar Beam
    PRIEST = { 15487 },              -- Silence (Shadow)
    WARLOCK = { 19647, 119910 },     -- Spell Lock (pet)
    EVOKER = { 351338 },             -- Quell
    HUNTER = { 147362, 187707 },     -- Counter Shot, Muzzle
    SHAMAN = { 57994 },              -- Wind Shear
}

-- Stato del cast del bersaglio, ricostruito dagli eventi
local function Start(unit)
    if unit ~= "target" then return end
    local notInt
    -- all'inizio l'interrompibilita' puo' essere leggibile (fuori dagli scontri)
    local ok, _, _, _, _, _, _, _, ni = A.Call(UnitCastingInfo, "target")
    if ok then notInt = A.Plain(ni) end
    if notInt == nil then
        local okC, _, _, _, _, _, _, ni2 = A.Call(UnitChannelInfo, "target")
        if okC then notInt = A.Plain(ni2) end
    end
    I.cast = { start = GetTime(), notInterruptible = notInt }
end

local function Stop(unit)
    if unit == "target" then I.cast = nil end
end

for _, ev in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_EMPOWER_START" }) do
    ns:On(ev, function(_, unit) Start(unit) end, "target")
end
for _, ev in ipairs({ "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_EMPOWER_STOP",
                      "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED" }) do
    ns:On(ev, function(_, unit) Stop(unit) end, "target")
end
ns:On("UNIT_SPELLCAST_INTERRUPTIBLE", function(_, unit)
    if unit == "target" and I.cast then I.cast.notInterruptible = false end
end, "target")
ns:On("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", function(_, unit)
    if unit == "target" and I.cast then I.cast.notInterruptible = true end
end, "target")
ns:On("PLAYER_TARGET_CHANGED", function()
    I.cast = nil
    -- nuovo bersaglio gia' in cast: un valore (anche segreto) vuol dire "sta lanciando"
    -- (niente confronti su valori segreti: prima si chiede se lo sono)
    local function present(okv, v) return okv and (A.IsSecret(v) or A.Plain(v) ~= nil) end
    local ok, name = A.Call(UnitCastingInfo, "target")
    local okC, cname = A.Call(UnitChannelInfo, "target")
    if present(ok, name) or present(okC, cname) then Start("target") end
end)
ns:On("PLAYER_REGEN_ENABLED", function() I.cast = nil end)

-- Il bersaglio ostile sta lanciando qualcosa che si puo' interrompere?
-- true / false (nil non serve: senza eventi non c'e' cast)
function I:TargetCasting()
    local c = self.cast
    if not c then return false end
    if GetTime() - c.start > 10 then self.cast = nil; return false end   -- evento di fine perso
    if c.notInterruptible == true then return false end
    if A.UnitExists("target") ~= true or A.UnitCanAttack("target") ~= true or A.UnitIsDead("target") == true then
        return false
    end
    return true
end

-- Primo interrupt conosciuto e pronto tra quelli dati (o della classe)
function I:Ready(spells)
    for _, id in ipairs(spells or self.CLASS[A.PlayerClass() or ""] or {}) do
        if A.IsKnown(id) and A.IsReady(id) ~= false then
            local usable = A.IsUsable(id)
            if usable ~= false then return id end
        end
    end
    return nil
end

-- Avviso
AL.checks.interrupt = function(p)
    if not ns.db.showInterrupts then return nil end
    if not I:TargetCasting() then return nil end
    local spell = I:Ready(p.spells)
    if not spell then return nil end
    return { text = ns.L.INTERRUPT_NOW:format(A.SpellName(spell)), icon = spell }
end

-- Predicato per le regole: {"targetCasting"}
E.predicates.targetCasting = function()
    if not ns.db.showInterrupts then return false end
    return I:TargetCasting()
end
