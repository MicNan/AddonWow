-- RotAssist - Enemies
-- Conteggio euristico dei nemici tramite le nameplate visibili.
-- Limiti: nessun controllo di distanza (IsSpellInRange in combattimento e'
-- segreto) e richiede le nameplate nemiche attive. Se i controlli sulle unita'
-- risultano segreti il conteggio viene marcato come "incerto" e la modalita'
-- automatica resta su bersaglio singolo: il tasto manuale e' sempre valido.

local _, ns = ...
local A = ns.API

local E = { plates = {}, lastCount = 0, lastUnknown = false }
ns.Enemies = E

ns:On("NAME_PLATE_UNIT_ADDED", function(_, unit)
    if type(unit) == "string" then E.plates[unit] = true end
end)
ns:On("NAME_PLATE_UNIT_REMOVED", function(_, unit)
    if type(unit) == "string" then E.plates[unit] = nil end
end)
ns:On("PLAYER_ENTERING_WORLD", function() wipe(E.plates) end)

-- Il mob e' "ingaggiato"? Vero se e' in combattimento oppure se il giocatore
-- e' nella sua tabella di minaccia. Il secondo controllo serve per i manichini
-- di addestramento, che risultano NON in combattimento anche mentre li si
-- attacca (verificato in gioco il 05/10/2026).
local function Engaged(unit)
    local fighting = A.UnitInCombat(unit)
    if fighting then return true end
    local ok, threat = pcall(UnitThreatSituation, "player", unit)
    threat = ok and A.Plain(threat)
    if type(threat) == "number" then return true end
    if fighting == nil then return nil end
    return false
end

-- Restituisce numero di nemici ingaggiati e flag "incerto".
function E:Count()
    local n, unknown = 0, false
    for unit in pairs(self.plates) do
        local hostile = A.UnitCanAttack(unit)
        if hostile == nil then
            unknown = true
        elseif hostile then
            local dead = A.UnitIsDead(unit)
            local engaged = Engaged(unit)
            if engaged == nil or dead == nil then
                unknown = true
            elseif engaged and not dead then
                n = n + 1
            end
        end
    end
    -- con le nameplate disattivate contiamo almeno il bersaglio
    if n == 0 and A.UnitExists("target") and A.UnitCanAttack("target") and not A.UnitIsDead("target") then
        n = 1
    end
    self.lastCount, self.lastUnknown = n, unknown
    return n, unknown
end
