-- RotAssist - API
-- Unico punto di contatto con le API di Blizzard. Ogni funzione:
--   * e' protetta da pcall (API assenti o cambiate non generano errori);
--   * converte i "secret values" in nil tramite Plain(), cosi' il resto
--     dell'addon non confronta ne' fa aritmetica su valori segreti.
-- Convenzione: le funzioni che rispondono si/no restituiscono true, false
-- oppure nil = "non si sa" (dato segreto o non disponibile).

local _, ns = ...
local A = {}
ns.API = A

local issecretvalue = issecretvalue or function() return false end
local GetTime = GetTime

-- Valore utilizzabile in logica, oppure nil se segreto.
local function Plain(v)
    if issecretvalue(v) then return nil end
    return v
end
A.Plain = Plain
A.IsSecret = function(v) return issecretvalue(v) and true or false end

local function Call(fn, ...)
    if type(fn) ~= "function" then return false end
    return pcall(fn, ...)
end
A.Call = Call

---------------------------------------------------------------------------
-- Giocatore, classe, specializzazione
---------------------------------------------------------------------------
function A.PlayerClass()
    local ok, _, classFile = Call(UnitClass, "player")
    if ok then return Plain(classFile) end
end

function A.SpecID()
    local getSpec = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
    local getInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
    local ok, index = Call(getSpec)
    index = ok and Plain(index)
    if not index or index == 0 then return nil end
    local ok2, specID = Call(getInfo, index)
    if ok2 then return Plain(specID) end
end

-- Icona della specializzazione attiva (fileID), oppure nil.
function A.SpecIcon()
    local getSpec = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
    local getInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
    local ok, index = Call(getSpec)
    index = ok and Plain(index)
    if not index or index == 0 then return nil end
    local ok2, _, _, _, icon = Call(getInfo, index)
    if ok2 then return Plain(icon) end
end

function A.InCombat()
    local ok, v = Call(InCombatLockdown)
    if ok and Plain(v) then return true end
    ok, v = Call(UnitAffectingCombat, "player")
    return (ok and Plain(v)) and true or false
end

-- Situazioni in cui le aure sono comunque segrete anche fuori dal combattimento.
function A.AurasRestricted()
    if A.InCombat() then return true end
    if ns.inEncounter then return true end
    if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive then
        local ok, v = Call(C_ChallengeMode.IsChallengeModeActive)
        if ok and Plain(v) then return true end
    end
    if C_PvP and C_PvP.IsActiveBattlefield then
        local ok, v = Call(C_PvP.IsActiveBattlefield)
        if ok and Plain(v) then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- Incantesimi: conoscenza, override, info statiche
---------------------------------------------------------------------------
local knownCache = {}
function A.ClearKnownCache() wipe(knownCache) end

function A.IsKnown(spellID, isPet)
    if not spellID then return false end
    local key = isPet and -spellID or spellID
    local cached = knownCache[key]
    if cached ~= nil then return cached end
    local result = false
    if isPet then
        local ok, v = Call(IsSpellKnown, spellID, true)
        result = (ok and Plain(v)) and true or false
    else
        local ok, v = Call(IsPlayerSpell, spellID)
        if ok and Plain(v) then
            result = true
        else
            ok, v = Call(IsSpellKnown, spellID)
            if ok and Plain(v) then result = true end
        end
        if not result and C_SpellBook and C_SpellBook.IsSpellKnown then
            ok, v = Call(C_SpellBook.IsSpellKnown, spellID)
            if ok and Plain(v) then result = true end
        end
    end
    knownCache[key] = result
    return result
end

function A.Override(spellID)
    if C_Spell and C_Spell.GetOverrideSpell then
        local ok, v = Call(C_Spell.GetOverrideSpell, spellID)
        v = ok and Plain(v)
        if type(v) == "number" and v > 0 then return v end
    end
    return spellID
end

function A.SpellTexture(spellID)
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, v = Call(C_Spell.GetSpellTexture, spellID)
        if ok and Plain(v) then return v end
    end
    return 134400 -- punto interrogativo
end

function A.SpellName(spellID)
    if C_Spell and C_Spell.GetSpellName then
        local ok, v = Call(C_Spell.GetSpellName, spellID)
        if ok and Plain(v) then return v end
    end
    return "spell " .. tostring(spellID)
end

---------------------------------------------------------------------------
-- Cooldown, GCD, cariche, utilizzabilita'
---------------------------------------------------------------------------
-- Restituisce isActive, isOnGCD, startTime, duration (nil dove segreto).
function A.CooldownInfo(spellID)
    if not (C_Spell and C_Spell.GetSpellCooldown) then return nil end
    local ok, info = Call(C_Spell.GetSpellCooldown, spellID)
    if not ok or type(info) ~= "table" then return nil end
    return Plain(info.isActive), Plain(info.isOnGCD), Plain(info.startTime), Plain(info.duration)
end

local GCD_SPELL = 61304 -- spell fittizia del GCD, in whitelist (mai segreta)

-- Secondi residui del GCD attuale (0 se libero) e durata del GCD.
function A.GCD()
    local _, _, start, dur = A.CooldownInfo(GCD_SPELL)
    if start and dur and dur > 0 then
        ns.gcdLength = dur
        local rem = start + dur - GetTime()
        return rem > 0 and rem or 0, dur
    end
    return 0, A.GCDLength()
end

function A.GCDLength()
    if ns.gcdLength then return ns.gcdLength end
    local ok, haste = Call(UnitSpellHaste, "player")
    haste = ok and Plain(haste) or 0
    return math.max(0.75, 1.5 / (1 + haste / 100))
end

-- Pronto ora (o entro il GCD)? true/false/nil
function A.IsReady(spellID)
    local isActive, onGCD, start, dur = A.CooldownInfo(spellID)
    if isActive == nil then
        -- client senza il campo isActive: usiamo start/duration se leggibili
        if start and dur then
            if dur == 0 then return true end
            local gcdRem = A.GCD()
            return (start + dur - GetTime()) <= gcdRem + 0.05
        end
        return nil
    end
    if not isActive then return true end
    if onGCD then return true end
    if start and dur then
        local gcdRem = A.GCD()
        return (start + dur - GetTime()) <= gcdRem + 0.05
    end
    return false
end

-- Cariche: tabella con campi leggibili (nil dove segreti) oppure nil.
function A.ChargeInfo(spellID)
    if not (C_Spell and C_Spell.GetSpellCharges) then return nil end
    local ok, info = Call(C_Spell.GetSpellCharges, spellID)
    if not ok or type(info) ~= "table" then return nil end
    return {
        cur      = Plain(info.currentCharges),
        max      = Plain(info.maxCharges),
        start    = Plain(info.cooldownStartTime),
        dur      = Plain(info.cooldownDuration),
        isActive = Plain(info.isActive),
    }
end

-- isUsable, insufficientPower (nil se segreti)
function A.IsUsable(spellID)
    local fn = (C_Spell and C_Spell.IsSpellUsable) or IsUsableSpell
    local ok, usable, noPower = Call(fn, spellID)
    if not ok then return nil end
    return Plain(usable), Plain(noPower)
end

-- Applica il cooldown a un widget Cooldown. Usa gli oggetti durata nativi,
-- che accettano valori segreti: lo swipe e' esatto anche in combattimento.
function A.ApplyCooldown(cdFrame, spellID)
    if C_Spell and C_Spell.GetSpellCooldownDuration and cdFrame.SetCooldownFromDurationObject then
        local ok, dobj = Call(C_Spell.GetSpellCooldownDuration, spellID)
        if ok and type(dobj) ~= "nil" then
            if pcall(cdFrame.SetCooldownFromDurationObject, cdFrame, dobj) then return end
        end
    end
    local _, _, start, dur = A.CooldownInfo(spellID)
    if start and dur and dur > 0 then
        pcall(cdFrame.SetCooldown, cdFrame, start, dur)
    else
        pcall(cdFrame.Clear, cdFrame)
    end
end

---------------------------------------------------------------------------
-- Assisted Combat
---------------------------------------------------------------------------
-- spellID suggerito dal sistema nativo, oppure nil + motivo.
function A.NativeSuggestion()
    local AC = C_AssistedCombat
    if not (AC and AC.GetNextCastSpell) then return nil, "api assente" end
    local ok, id = pcall(AC.GetNextCastSpell, false)
    if not ok then return nil, "errore: " .. tostring(id) end
    if issecretvalue(id) then return nil, "valore segreto" end
    if type(id) ~= "number" or id == 0 then return nil, "nessun suggerimento" end
    return id
end

function A.NativeAvailable()
    local AC = C_AssistedCombat
    if not (AC and AC.IsAvailable) then return nil end
    local ok, avail, reason = pcall(AC.IsAvailable)
    if not ok then return nil end
    return Plain(avail), Plain(reason)
end

---------------------------------------------------------------------------
-- Unita'
---------------------------------------------------------------------------
function A.UnitExists(unit)
    local ok, v = Call(UnitExists, unit)
    if not ok then return nil end
    v = Plain(v)
    if v == nil then return nil end
    return v and true or false
end

function A.UnitIsDead(unit)
    local ok, v = Call(UnitIsDeadOrGhost, unit)
    if not ok then return nil end
    v = Plain(v)
    if v == nil then return nil end
    return v and true or false
end

function A.UnitCanAttack(unit)
    local ok, v = Call(UnitCanAttack, "player", unit)
    if not ok then return nil end
    v = Plain(v)
    if v == nil then return nil end
    return v and true or false
end

function A.UnitInCombat(unit)
    local ok, v = Call(UnitAffectingCombat, unit)
    if not ok then return nil end
    v = Plain(v)
    if v == nil then return nil end
    return v and true or false
end

-- "worldboss", "rareelite", "elite", "rare", "normal", ... oppure nil.
function A.Classification(unit)
    local ok, c = Call(UnitClassification, unit)
    c = ok and Plain(c)
    local okL, lvl = Call(UnitLevel, unit)
    lvl = okL and Plain(lvl)
    if lvl == -1 then return "worldboss" end
    return c
end

-- Vita in percentuale 0..1, oppure nil se segreta.
function A.HealthPct(unit)
    local ok, cur = Call(UnitHealth, unit)
    local ok2, max = Call(UnitHealthMax, unit)
    cur, max = ok and Plain(cur), ok2 and Plain(max)
    if cur and max and max > 0 then return cur / max end
end

-- Risorsa del giocatore: valore, massimo (nil se segreti).
function A.Power(powerType)
    local ok, cur = Call(UnitPower, "player", powerType)
    local ok2, max = Call(UnitPowerMax, "player", powerType)
    return ok and Plain(cur) or nil, ok2 and Plain(max) or nil
end

-- Stack di un'aura del giocatore (0 se assente) oppure nil se non leggibile.
-- In 12.1 le API delle aure restituiscono segreti oppure nil durante le
-- restrizioni: un "nil" e' quindi affidabile come "assente" solo per le aure
-- in whitelist (whitelisted = true, es. Maelstrom Weapon) o senza restrizioni.
function A.PlayerAuraStacks(auraID, whitelisted)
    if not (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then return nil end
    local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, auraID)
    if not ok or issecretvalue(aura) then return nil end
    if type(aura) ~= "table" then
        if whitelisted or not A.AurasRestricted() then return 0 end
        return nil
    end
    local n = Plain(aura.applications)
    if n == nil then return nil end
    return (n == 0) and 1 or n   -- aure senza stack riportano 0 applicazioni
end

-- Incantamenti temporanei delle armi: hasMain, hasOff (nil se segreti).
function A.WeaponEnchants()
    local ok, hasMain, _, _, _, hasOff = Call(GetWeaponEnchantInfo)
    if not ok then return nil end
    return Plain(hasMain), Plain(hasOff)
end

---------------------------------------------------------------------------
-- Aure (solo quando NON sono segrete: fuori combattimento e fuori istanze
-- ristrette). Restituisce: trovata (true/false) e scadenza, oppure nil.
---------------------------------------------------------------------------
function A.FindAura(unit, spellIDs, filter)
    if A.AurasRestricted() then return nil end
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return nil end
    local wanted = {}
    for _, id in ipairs(spellIDs) do wanted[id] = true end
    for i = 1, 40 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, filter)
        if not ok then return nil end
        if issecretvalue(aura) then return nil end
        if type(aura) ~= "table" then break end
        local sid = Plain(aura.spellId)
        if sid == nil then return nil end
        if wanted[sid] then
            return true, Plain(aura.expirationTime), Plain(aura.duration), Plain(aura.applications)
        end
    end
    return false
end
