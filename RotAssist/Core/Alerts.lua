-- RotAssist - Alerts
-- Libreria di tipi di avviso riutilizzabili. Ogni modulo spec elenca i tipi
-- che gli servono con i propri parametri (spec.alerts), esempio:
--   { type = "petMissing" },
--   { type = "targetAuraMissing", auras = {257284}, icon = 257284, text = "..." }
-- Ogni controllo restituisce nil (nessun avviso) oppure { text, icon }.
-- Se un dato e' segreto il controllo NON genera avvisi: meglio un avviso in
-- meno che un falso allarme.

local _, ns = ...
local A, T, L = ns.API, ns.Tracker, ns.L
local GetTime = GetTime

local AL = { checks = {} }
ns.Alerts = AL
local C = AL.checks

local combatStart = 0
ns:On("PLAYER_REGEN_DISABLED", function() combatStart = GetTime() end)

local function HostileTarget()
    return A.UnitExists("target") == true and A.UnitCanAttack("target") == true
        and A.UnitIsDead("target") == false
end

-- Pet assente o morto
C.petMissing = function(p)
    if p.notTalent and A.IsKnown(p.notTalent) then return nil end
    local exists = A.UnitExists("pet")
    if exists == false then
        return { text = L.PET_MISSING, icon = p.icon or 883 }
    end
    if exists and A.UnitIsDead("pet") == true then
        return { text = L.PET_DEAD, icon = p.reviveIcon or 982 }
    end
end

-- Pet vivo ma non in combattimento mentre il giocatore attacca un bersaglio
C.petNotAttacking = function(p)
    if not A.InCombat() or (GetTime() - combatStart) < (p.grace or 3) then return nil end
    if A.UnitExists("pet") ~= true or A.UnitIsDead("pet") ~= false then return nil end
    if not HostileTarget() then return nil end
    if A.UnitInCombat("pet") == false then
        return { text = L.PET_NOT_ATTACKING, icon = p.icon or 34026 }
    end
end

-- Vita del pet sotto soglia (solo quando il valore e' leggibile; in
-- combattimento la barra del pet nel riquadro principale lo mostra comunque)
C.petHealthLow = function(p)
    if A.UnitExists("pet") ~= true or A.UnitIsDead("pet") ~= false then return nil end
    local pct = A.HealthPct("pet")
    if pct and pct < (p.threshold or 0.4) then
        return { text = L.PET_LOW:format(math.floor((p.threshold or 0.4) * 100 + 0.5)), icon = p.icon or 136 }
    end
end

-- Debuff del giocatore mancante su un bersaglio (es. Hunter's Mark su elite/boss)
C.targetAuraMissing = function(p)
    if not HostileTarget() then return nil end
    if p.classifications then
        local c = A.Classification("target")
        if not c or not p.classifications[c] then return nil end
    end
    -- appena lanciata: evitiamo lampeggi in attesa dell'aggiornamento aura
    if p.castSpell and T.lastCast[p.castSpell] and GetTime() - T.lastCast[p.castSpell] < 2 then
        return nil
    end
    local found = A.FindAura("target", p.auras, p.filter or "HARMFUL|PLAYER")
    if found == false then
        return { text = p.text or L.DEBUFF_MISSING:format(A.SpellName(p.auras[1])), icon = p.icon or p.auras[1] }
    end
end

-- Buff del giocatore mancante (es. Lightning Shield) - solo dove leggibile
C.playerAuraMissing = function(p)
    if p.talent and not A.IsKnown(p.talent) then return nil end
    if p.spell and not A.IsKnown(p.spell) then return nil end
    local found = A.FindAura("player", p.auras, p.filter or "HELPFUL")
    if found == false then
        return { text = p.text or L.BUFF_MISSING:format(A.SpellName(p.auras[1])), icon = p.icon or p.auras[1] }
    end
end

-- Timer ricostruito dai cast in scadenza o assente (es. Flame Shock)
C.timerExpiring = function(p)
    if p.spell and not A.IsKnown(p.spell) then return nil end
    if p.inCombatOnly and not A.InCombat() then return nil end
    if p.needsTarget and not HostileTarget() then return nil end
    local rem = T:TimerRemaining(p.key)
    if rem <= 0 then
        return { text = p.textMissing or L.DEBUFF_MISSING:format(A.SpellName(p.spell)), icon = p.icon or p.spell }
    elseif rem < (p.within or 4) then
        return { text = p.textExpiring or L.DEBUFF_EXPIRING:format(A.SpellName(p.spell)), icon = p.icon or p.spell }
    end
end

-- Risorsa vicina al massimo (solo se leggibile)
C.resourceNearMax = function(p)
    local cur, max = A.Power(p.powerType)
    if cur and max and max > 0 and (max - cur) <= (p.margin or 10) then
        return { text = p.text, icon = p.icon }
    end
end

function AL:Collect(spec)
    local out = {}
    if not (spec and spec.alerts) then return out end
    for _, def in ipairs(spec.alerts) do
        local fn = C[def.type]
        if fn then
            local ok, r = pcall(fn, def)
            if not ok then
                ns:ReportError(r)
            elseif r then
                r.key = def.type .. (def.key or "")
                out[#out + 1] = r
            end
        end
    end
    return out
end
