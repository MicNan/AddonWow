-- RotAssist Companion - StatPriority
-- Priorita' delle statistiche secondarie per specializzazione (Midnight 12.1,
-- Season 2), con le varianti per contenuto (raid / Mitiche+) o per talento
-- eroico quando cambiano l'ordine. Serve alla scheda Oggi per giudicare gli
-- oggetti in ricompensa: non solo il livello oggetto, ma anche se le
-- statistiche sono quelle giuste per te.
--
-- Valori riassunti da guide pubbliche di classe aggiornate alla 12.1 (agosto-
-- ottobre 2026). Una priorita' generica non sostituisce una simulazione del
-- personaggio. Tutte le 40 specializzazioni.

local _, ns = ...
local A = ns.API

local S = {}
ns.StatPriority = S

local CRIT, HASTE, MASTERY, VERSA = "CRIT", "HASTE", "MASTERY", "VERSA"
-- "EQ" tra due statistiche: valgono uguale (stesso posto in classifica).
-- Si scrive come nelle guide: { A, EQ, B } = "A = B".
local EQ = "EQ"
S.STATS = { CRIT, HASTE, MASTERY, VERSA }

-- Talenti eroici: per ID (TraitSubTree, quando noto) e per nome inglese.
-- Con il client in un'altra lingua il nome non coincide: la scheda mostra
-- allora un selettore.
S.HERO_IDS = {
    [55] = "stormbringer", [70] = "stormbringer", [73] = "stormbringer",
    [54] = "totemic", [71] = "totemic", [74] = "totemic",
}
S.HERO_NAMES = {
    ["Stormbringer"] = "stormbringer", ["Totemic"] = "totemic",
    ["Deathbringer"] = "deathbringer", ["San'layn"] = "sanlayn",
    ["Trickster"] = "trickster", ["Deathstalker"] = "deathstalker",
    ["Voidweaver"] = "voidweaver", ["Archon"] = "archon",
}
-- Nome da mostrare nel selettore (i talenti eroici hanno nomi propri)
S.HERO_LABELS = {
    stormbringer = "Stormbringer", totemic = "Totemic", deathbringer = "Deathbringer", sanlayn = "San'layn",
    trickster = "Trickster", deathstalker = "Deathstalker", voidweaver = "Voidweaver", archon = "Archon",
}

-- primary: statistica primaria; ilvlFirst: prima il livello oggetto;
-- order: ordine unico; content: { raid, mplus }; hero: { chiave = ordine o
-- { raid, mplus } } con heroOrder per l'ordine del selettore; flat: nessuna
-- priorita' fissa (solo livello oggetto e simulazione).
S.SPECS = {
    -- Warrior
    [71] = { primary = "STR", order = { CRIT, HASTE, MASTERY, VERSA }, note = "STATNOTE_71" },
    [72] = { primary = "STR", order = { MASTERY, HASTE, CRIT, EQ, VERSA } },
    [73] = { primary = "STR", ilvlFirst = true, order = { HASTE, CRIT, EQ, VERSA, MASTERY }, note = "STATNOTE_TANK" },
    -- Paladin
    [65] = { primary = "INT", ilvlFirst = true, note = "STATNOTE_65",
             content = { raid = { MASTERY, HASTE, EQ, CRIT, VERSA }, mplus = { HASTE, EQ, CRIT, VERSA, MASTERY } } },
    [66] = { primary = "STR", ilvlFirst = true, order = { HASTE, CRIT, VERSA, MASTERY }, note = "STATNOTE_TANK" },
    [70] = { primary = "STR", order = { MASTERY, HASTE, CRIT, VERSA } },
    -- Death Knight
    [250] = { primary = "STR", note = "STATNOTE_250", heroOrder = { "deathbringer", "sanlayn" },
              hero = { deathbringer = { CRIT, EQ, VERSA, EQ, MASTERY, HASTE }, sanlayn = { HASTE, CRIT, EQ, VERSA, EQ, MASTERY } } },
    [251] = { primary = "STR", order = { CRIT, MASTERY, HASTE, VERSA }, note = "STATNOTE_251" },
    [252] = { primary = "STR", order = { CRIT, MASTERY, HASTE, VERSA } },
    -- Rogue
    [259] = { primary = "AGI", order = { CRIT, HASTE, MASTERY, VERSA } },
    [260] = { primary = "AGI", order = { HASTE, CRIT, VERSA, MASTERY }, note = "STATNOTE_260" },
    [261] = { primary = "AGI", note = "STATNOTE_261", heroOrder = { "trickster", "deathstalker" },
              hero = { trickster = { MASTERY, HASTE, CRIT, VERSA }, deathstalker = { HASTE, MASTERY, CRIT, VERSA } } },
    -- Demon Hunter
    [577] = { primary = "AGI", order = { CRIT, MASTERY, HASTE, VERSA }, note = "STATNOTE_577" },
    [581] = { primary = "AGI", ilvlFirst = true, order = { HASTE, CRIT, EQ, VERSA, EQ, MASTERY }, note = "STATNOTE_581" },
    [1480] = { primary = "INT", order = { MASTERY, HASTE, CRIT, VERSA }, note = "STATNOTE_1480" },
    -- Monk
    [268] = { primary = "AGI", ilvlFirst = true, order = { CRIT, EQ, VERSA, MASTERY, HASTE } },
    [269] = { primary = "AGI", order = { HASTE, MASTERY, EQ, CRIT, VERSA } },
    [270] = { primary = "INT", order = { HASTE, CRIT, EQ, VERSA, MASTERY } },
    -- Druid
    [102] = { primary = "INT", order = { MASTERY, HASTE, EQ, CRIT, VERSA } },
    [103] = { primary = "AGI", ilvlFirst = true, flat = true },
    [104] = { primary = "AGI", ilvlFirst = true, order = { HASTE, VERSA, CRIT, MASTERY } },
    [105] = { primary = "INT", ilvlFirst = true, note = "STATNOTE_105",
              content = { raid = { HASTE, EQ, MASTERY, CRIT, VERSA }, mplus = { HASTE, MASTERY, VERSA, CRIT } } },
    -- Hunter (Beast Mastery: l'ordine cambia tra bersaglio singolo e Mitiche+)
    [253] = { primary = "AGI", content = { raid = { MASTERY, HASTE, CRIT, VERSA }, mplus = { MASTERY, CRIT, VERSA, HASTE } },
              note = "STATNOTE_253" },
    [254] = { primary = "AGI", order = { CRIT, MASTERY, VERSA, HASTE }, note = "STATNOTE_254" },
    [255] = { primary = "AGI", order = { MASTERY, CRIT, HASTE, VERSA }, note = "STATNOTE_255" },
    -- Mage
    [62] = { primary = "INT", order = { HASTE, VERSA, CRIT, MASTERY } },
    [63] = { primary = "INT", order = { HASTE, VERSA, MASTERY, CRIT } },
    [64] = { primary = "INT", order = { MASTERY, EQ, CRIT, HASTE, VERSA } },
    -- Priest
    [256] = { primary = "INT", ilvlFirst = true, order = { HASTE, MASTERY, CRIT, VERSA }, note = "STATNOTE_256" },
    [257] = { primary = "INT", ilvlFirst = true,
              content = { raid = { CRIT, MASTERY, VERSA, HASTE }, mplus = { HASTE, VERSA, EQ, CRIT, MASTERY } } },
    [258] = { primary = "INT", ilvlFirst = true, note = "STATNOTE_258", heroOrder = { "voidweaver", "archon" },
              hero = { voidweaver = { raid = { MASTERY, HASTE, CRIT, VERSA }, mplus = { HASTE, MASTERY, CRIT, VERSA } },
                       archon = { raid = { MASTERY, CRIT, HASTE, VERSA }, mplus = { MASTERY, HASTE, CRIT, VERSA } } } },
    -- Shaman (Enhancement: l'ordine cambia con il talento eroico)
    [262] = { primary = "INT", ilvlFirst = true, order = { MASTERY, HASTE, CRIT, VERSA }, note = "STATNOTE_262" },
    [263] = { primary = "AGI", ilvlFirst = true, note = "STATNOTE_263", heroOrder = { "stormbringer", "totemic" },
              hero = { stormbringer = { MASTERY, CRIT, HASTE, VERSA }, totemic = { MASTERY, HASTE, CRIT, VERSA } } },
    [264] = { primary = "INT", ilvlFirst = true, order = { CRIT, VERSA, HASTE, MASTERY }, note = "STATNOTE_264" },
    -- Warlock
    [265] = { primary = "INT", note = "STATNOTE_265",
              content = { raid = { CRIT, HASTE, EQ, MASTERY, VERSA }, mplus = { HASTE, EQ, CRIT, MASTERY, VERSA } } },
    [266] = { primary = "INT", order = { CRIT, HASTE, EQ, MASTERY, VERSA } },
    [267] = { primary = "INT", order = { HASTE, CRIT, EQ, MASTERY, VERSA } },
    -- Evoker
    [1467] = { primary = "INT", order = { CRIT, HASTE, EQ, MASTERY, VERSA } },
    [1468] = { primary = "INT", order = { MASTERY, CRIT, HASTE, VERSA }, note = "STATNOTE_1468" },
    [1473] = { primary = "INT", order = { MASTERY, HASTE, EQ, CRIT, VERSA } },
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
S.SpecID = SpecID

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

-- Ordine con i pari merito: { stat, ... } e { stat = posto }
local function Parse(list)
    local order, ranks, rank, tie = {}, {}, 0, false
    for _, item in ipairs(list or {}) do
        if item == EQ then
            tie = true
        else
            if not tie then rank = #order + 1 end
            order[#order + 1] = item
            ranks[item] = rank
            tie = false
        end
    end
    return order, ranks
end

-- Priorita' attuale: { specID, order, ranks, primary, ilvlFirst, note, flat,
-- contentChoice, variant, heroName, heroChoice, heroKey }
function S:Current()
    local specID = SpecID()
    local entry = specID and self.SPECS[specID]
    if not entry then return { specID = specID } end
    local out = { specID = specID, primary = entry.primary, ilvlFirst = entry.ilvlFirst, note = entry.note, flat = entry.flat }
    local list = entry.order
    local content = entry.content
    if entry.hero then
        local id, name = HeroTree()
        local key = (id and self.HERO_IDS[id]) or (name and self.HERO_NAMES[name])
        if key and entry.hero[key] then
            out.heroName = name or self.HERO_LABELS[key]
        else
            -- talento eroico non riconosciuto: lo sceglie il giocatore
            local saved = ns.db and ns.db.statHero and ns.db.statHero[specID]
            key = (saved and entry.hero[saved]) and saved or entry.heroOrder[1]
            out.heroChoice, out.heroOrder = true, entry.heroOrder
        end
        out.heroKey = key
        local h = entry.hero[key]
        if h.raid then content = h else list = h end
    end
    if content then
        local mode = (ns.db and ns.db.statContent) or "mplus"
        if not content[mode] then mode = "mplus" end
        list, out.contentChoice, out.variant = content[mode], true, mode
    end
    if list then out.order, out.ranks = Parse(list) end
    return out
end

-- Sceglie a mano il talento eroico (quando il gioco non lo fa riconoscere)
function S:SetHero(specID, key)
    ns.db.statHero = ns.db.statHero or {}
    ns.db.statHero[specID] = key
end

-- Pesi: il primo posto vale 1, poi 0.75, 0.5, 0.25 (pari merito: stesso peso)
function S:Weights(order, ranks)
    local w = {}
    for i, stat in ipairs(order or {}) do w[stat] = 1 - (((ranks and ranks[stat]) or i) - 1) * 0.25 end
    return w
end

-- Quanto le statistiche secondarie di un oggetto seguono la tua priorita'
-- (0-1) e le due statistiche principali dell'oggetto.
function S:ItemMatch(link, order, ranks)
    if not (link and order and C_Item and C_Item.GetItemStats) then return nil end
    local stats = A.Call(C_Item.GetItemStats, link)
    if type(stats) ~= "table" then return nil end
    local w = self:Weights(order, ranks)
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
                STR = SPELL_STAT1_NAME, AGI = SPELL_STAT2_NAME, INT = SPELL_STAT4_NAME }
    local name = g[stat]
    if type(name) == "string" and name ~= "" then return name end
    return L["STAT_" .. stat]
end
