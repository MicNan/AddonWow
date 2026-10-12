-- RotAssist Companion - StatPriority
-- Priorita' delle statistiche secondarie per specializzazione (Midnight 12.1,
-- Season 2), con le varianti per contenuto (raid / Mitiche+) o per talento
-- eroico quando cambiano l'ordine. Serve alla scheda Attivita' per giudicare
-- gli oggetti in ricompensa: non solo il livello oggetto, ma anche se le
-- statistiche sono quelle giuste per te.
--
-- Valori riassunti da guide pubbliche di classe aggiornate alla 12.1. Una
-- priorita' generica non sostituisce una simulazione del personaggio.
-- Specializzazioni coperte: cacciatore e sciamano (le altre mostrano solo il
-- livello oggetto).

local _, ns = ...
local A = ns.API

local S = {}
ns.StatPriority = S

local CRIT, HASTE, MASTERY, VERSA = "CRIT", "HASTE", "MASTERY", "VERSA"
S.STATS = { CRIT, HASTE, MASTERY, VERSA }

-- Talenti eroici (TraitSubTree) dell'Enhancement
local STORMBRINGER = { [55] = true, [70] = true, [73] = true }
local TOTEMIC = { [54] = true, [71] = true, [74] = true }

S.SPECS = {
    -- Beast Mastery: l'ordine cambia tra bersaglio singolo e Mitiche+
    [253] = { primary = "AGI", content = { raid = { MASTERY, HASTE, CRIT, VERSA }, mplus = { MASTERY, CRIT, VERSA, HASTE } },
              note = "STATNOTE_253" },
    [254] = { primary = "AGI", order = { CRIT, MASTERY, VERSA, HASTE }, note = "STATNOTE_254" },
    [255] = { primary = "AGI", order = { MASTERY, CRIT, HASTE, VERSA }, note = "STATNOTE_255" },
    [262] = { primary = "INT", ilvlFirst = true, order = { MASTERY, HASTE, CRIT, VERSA }, note = "STATNOTE_262" },
    -- Enhancement: l'ordine cambia con il talento eroico
    [263] = { primary = "AGI", ilvlFirst = true, note = "STATNOTE_263",
              hero = function(id)
                  if TOTEMIC[id] then return { MASTERY, HASTE, CRIT, VERSA }, "totemic" end
                  return { MASTERY, CRIT, HASTE, VERSA }, "stormbringer"
              end },
    [264] = { primary = "INT", ilvlFirst = true, order = { CRIT, VERSA, HASTE, MASTERY }, note = "STATNOTE_264" },
}

-- Chiavi delle statistiche restituite da C_Item.GetItemStats
S.ITEM_KEYS = {
    ITEM_MOD_CRIT_RATING_SHORT = CRIT, ITEM_MOD_HASTE_RATING_SHORT = HASTE,
    ITEM_MOD_MASTERY_RATING_SHORT = MASTERY, ITEM_MOD_VERSATILITY = VERSA,
}

local function SpecID()
    local getSpec = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
    local getInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
    local index = A.Call(getSpec)
    return index and A.Call(getInfo, index)
end

-- Talento eroico attivo: ID e nome (nella lingua del client)
local function HeroTree()
    if not (C_ClassTalents and C_ClassTalents.GetActiveHeroTalentSpec) then return nil end
    local id = A.Call(C_ClassTalents.GetActiveHeroTalentSpec)
    if not id then return nil end
    local name
    if C_Traits and C_Traits.GetSubTreeInfo and C_ClassTalents.GetActiveConfigID then
        local info = A.Call(C_Traits.GetSubTreeInfo, A.Call(C_ClassTalents.GetActiveConfigID), id)
        name = type(info) == "table" and info.name or nil
    end
    return id, name
end

-- Priorita' attuale: { specID, order, primary, ilvlFirst, note, contentChoice, variant }
function S:Current()
    local specID = SpecID()
    local entry = specID and self.SPECS[specID]
    if not entry then return { specID = specID } end
    local out = { specID = specID, primary = entry.primary, ilvlFirst = entry.ilvlFirst, note = entry.note }
    if entry.content then
        local mode = (ns.db and ns.db.statContent) or "mplus"
        if not entry.content[mode] then mode = "mplus" end
        out.order, out.contentChoice, out.variant = entry.content[mode], true, mode
    elseif entry.hero then
        local id, name = HeroTree()
        local order, key = entry.hero(id)
        out.order, out.variant, out.heroName = order, key, name
    else
        out.order = entry.order
    end
    return out
end

-- Pesi: la prima statistica vale 1, poi 0.75, 0.5, 0.25
function S:Weights(order)
    local w = {}
    for i, stat in ipairs(order or {}) do w[stat] = 1 - (i - 1) * 0.25 end
    return w
end

-- Quanto le statistiche secondarie di un oggetto seguono la tua priorita'
-- (0-1) e le due statistiche principali dell'oggetto.
function S:ItemMatch(link, order)
    if not (link and order and C_Item and C_Item.GetItemStats) then return nil end
    local stats = A.Call(C_Item.GetItemStats, link)
    if type(stats) ~= "table" then return nil end
    local w = self:Weights(order)
    local total, score, list = 0, 0, {}
    for key, value in pairs(stats) do
        local stat = self.ITEM_KEYS[key]
        if stat and type(value) == "number" and value > 0 then
            total = total + value
            score = score + value * (w[stat] or 0)
            list[#list + 1] = { stat = stat, value = value }
        end
    end
    if total == 0 then return nil end
    table.sort(list, function(a, b) return a.value > b.value end)
    return score / total, list
end

-- Valori attuali del personaggio (percentuali), solo fuori combattimento
function S:Values(primary)
    local v = {}
    local crit = primary == "INT" and A.Call(GetSpellCritChance, 2) or A.Call(GetCritChance)
    v.CRIT = crit
    v.HASTE = A.Call(GetHaste)
    v.MASTERY = A.Call(GetMasteryEffect)
    local cr = CR_VERSATILITY_DAMAGE_DONE or 29
    local bonus = A.Call(GetCombatRatingBonus, cr)
    local extra = A.Call(GetVersatilityBonus, cr)
    if type(bonus) == "number" then v.VERSA = bonus + (type(extra) == "number" and extra or 0) end
    return v
end

-- Nome della statistica nella lingua del client
function S:Name(stat)
    local L = ns.L
    local g = { CRIT = STAT_CRITICAL_STRIKE, HASTE = STAT_HASTE, MASTERY = STAT_MASTERY, VERSA = STAT_VERSATILITY,
                AGI = SPELL_STAT2_NAME, INT = SPELL_STAT4_NAME }
    local name = g[stat]
    if type(name) == "string" and name ~= "" then return name end
    return L["STAT_" .. stat]
end
