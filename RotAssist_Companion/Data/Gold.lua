-- RotAssist Companion - Gold
-- Scheda "Oro": professioni del personaggio, Concentrazione, punti conoscenza
-- da spendere e strategie per fare oro adatte al profilo scelto
-- (occasionale / medio / assiduo, opzione 'playerType').
--
-- Concentrazione e conoscenza dipendono dalla professione di Midnight
-- (professione "figlia"): il suo ID si legge solo con la finestra della
-- professione aperta, quindi l'addon lo ricorda la prima volta che la apri
-- (evento TRADE_SKILL_SHOW) e poi lo usa sempre.

local _, ns = ...
local A = ns.API

local G = {}
ns.Gold = G

local CONCENTRATION_PER_DAY = 240   -- Midnight: +240 al giorno, massimo 1000
G.PROFILES = { "casual", "medium", "hardcore" }

-- Professioni conosciute: { name, icon, rank, max, skillLine, key }
function G:Professions()
    local out = {}
    if not (GetProfessions and GetProfessionInfo) then return out end
    local list = { A.Call(GetProfessions) }
    for i = 1, 5 do
        local index = list[i]
        if index then
            local name, icon, rank, maxRank, _, _, skillLine = A.Call(GetProfessionInfo, index)
            if name and skillLine and skillLine ~= 794 then   -- 794 = Archeologia (esclusa)
                out[#out + 1] = {
                    name = name, icon = icon, rank = rank or 0, max = maxRank or 0,
                    skillLine = skillLine, key = ns.GoldStrategies.PROFESSIONS[skillLine],
                }
            end
        end
    end
    return out
end

-- Professione aperta: ricordiamo l'ID della professione di Midnight e la
-- valuta della Concentrazione (si tiene l'ID piu' alto = espansione recente).
function G:OnTradeSkillShow()
    if not C_TradeSkillUI then return end
    local base = A.Call(C_TradeSkillUI.GetBaseProfessionInfo)
    local child = A.Call(C_TradeSkillUI.GetChildProfessionInfo)
    if type(base) ~= "table" or type(child) ~= "table" then return end
    local baseID, childID = base.professionID, child.professionID
    if not (baseID and childID) then return end
    ns.db.professions = ns.db.professions or {}
    local saved = ns.db.professions[baseID]
    if saved and saved.child and saved.child > childID then return end
    ns.db.professions[baseID] = {
        child = childID,
        concentration = A.Call(C_TradeSkillUI.GetConcentrationCurrencyID, childID),
    }
end

-- Concentrazione attuale e massima (nil se non ancora nota)
function G:Concentration(skillLine)
    local saved = ns.db.professions and ns.db.professions[skillLine]
    if not (saved and saved.concentration) then return nil end
    local info = A.Currency(saved.concentration)
    if not info then return nil end
    return info.quantity or 0, info.maxQuantity or 1000
end

-- Punti conoscenza non spesi (nil se non disponibili)
function G:Knowledge(skillLine)
    local saved = ns.db.professions and ns.db.professions[skillLine]
    if not (saved and saved.child and C_ProfSpecs and C_ProfSpecs.GetCurrencyInfoForSkillLine) then return nil end
    local info = A.Call(C_ProfSpecs.GetCurrencyInfoForSkillLine, saved.child)
    return type(info) == "table" and info.numAvailable or nil
end

local TIER_COLOR = { S = { 1, 0.55, 0.1 }, A = { 0.35, 0.65, 1 }, B = { 0.65, 0.65, 0.65 } }

-- Passi numerati
local function Steps(rows, lines)
    for i, line in ipairs(lines) do
        rows[#rows + 1] = { kind = "step", badge = tostring(i), badgeColor = { 1, 0.82, 0 }, text = line }
    end
end

function G:Rows()
    local L, rows = ns.L, {}
    local S = ns.GoldStrategies
    local profile = ns.db.playerType or "medium"
    local profs = self:Professions()

    -- profilo di gioco
    local items = {}
    for _, key in ipairs(self.PROFILES) do
        items[#items + 1] = { label = L["PROFILE_" .. key], selected = key == profile,
                              onClick = function() ns:Set("playerType", key) end }
    end
    rows[#rows + 1] = { kind = "pills", items = items }
    rows[#rows + 1] = { kind = "note", text = L["PROFILE_DESC_" .. profile] }

    -- le tue professioni: fascia per l'oro, Concentrazione, conoscenza
    rows[#rows + 1] = { header = L.HDR_PROFESSIONS }
    if #profs == 0 then
        rows[#rows + 1] = { kind = "callout", style = "info", text = L.NO_PROFESSIONS }
    end
    for _, p in ipairs(profs) do
        local tier = p.key and S:Tier(p.key)
        local letter = tier and tier:sub(1, 1)
        rows[#rows + 1] = {
            text = L.PROF_LINE:format(p.name, p.rank, p.max), icon = p.icon,
            badge = letter and { L.TIER_BADGE:format(letter), TIER_COLOR[letter] } or nil,
            tooltip = { p.name, tier and L.TIER_TIP:format(tier) or nil, p.key and S:Why(p.key) or nil },
            link = { search = p.name }, linkTitle = p.name,
        }
        local cur, max = self:Concentration(p.skillLine)
        if cur then
            local full = cur >= max
            rows[#rows + 1] = {
                kind = "bar", min = 0, max = max, value = cur,
                color = full and { 1, 0.6, 0.2 } or { 0.35, 0.65, 1 },
                label = L.CONCENTRATION:format(cur, max), labelColor = full and { 1, 0.6, 0.2 } or nil,
                right = full and L.CONC_FULL_SHORT or L.CONC_FULL_IN:format(A.TimeText((max - cur) / CONCENTRATION_PER_DAY * 86400)),
            }
        elseif not (p.key == "herbalism" or p.key == "mining" or p.key == "skinning") then
            rows[#rows + 1] = { kind = "note", text = L.CONC_UNKNOWN }
        end
        local knowledge = self:Knowledge(p.skillLine)
        if knowledge and knowledge > 0 then
            rows[#rows + 1] = { kind = "step", badge = tostring(knowledge), badgeColor = { 1, 0.6, 0.2 }, text = L.KNOWLEDGE_SPEND }
        end
    end

    -- cosa fare con le tue professioni
    local covered = 0
    for _, p in ipairs(profs) do
        if p.key then
            if covered == 0 then rows[#rows + 1] = { header = L.HDR_GOLD_TODO:format(L["PROFILE_" .. profile]) } end
            covered = covered + 1
            local tier = S:Tier(p.key)
            rows[#rows + 1] = { kind = "sub", text = tier and L.HDR_GOLD_PROF_TIER:format(p.name, tier) or p.name }
            local why = S:Why(p.key)
            if why then rows[#rows + 1] = { kind = "callout", style = "info", title = L.GOLD_WHY, text = why } end
            Steps(rows, S:Get(p.key, profile))
        end
    end
    if covered == 0 then
        rows[#rows + 1] = { header = L.HDR_GOLD_NONE }
        Steps(rows, S:Get("none", profile))
    end

    -- consigli validi per tutti
    rows[#rows + 1] = { header = L.HDR_GOLD_GENERAL:format(L["PROFILE_" .. profile]) }
    Steps(rows, S:Get("general", profile))
    rows[#rows + 1] = { kind = "note", text = L.GOLD_SOURCES }
    rows[#rows + 1] = { kind = "note", text = L.GOLD_DISCLAIMER }
    return rows
end
