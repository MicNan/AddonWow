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

local function Bullets(rows, lines)
    for _, line in ipairs(lines) do
        rows[#rows + 1] = { text = "- " .. line, wrap = true }
    end
end

function G:Rows()
    local L, rows = ns.L, {}
    local profile = ns.db.playerType or "medium"
    local profs = self:Professions()

    rows[#rows + 1] = { header = L.HDR_PROFESSIONS }
    for _, p in ipairs(profs) do
        local cur, max = self:Concentration(p.skillLine)
        local tip = { p.name, L.PROF_RANK:format(p.rank, p.max) }
        local right
        if cur then
            right = L.CONCENTRATION:format(cur, max)
            if cur >= max then
                tip[#tip + 1] = L.CONC_FULL
            else
                tip[#tip + 1] = L.CONC_FULL_IN:format(A.TimeText((max - cur) / CONCENTRATION_PER_DAY * 86400))
            end
        else
            tip[#tip + 1] = L.CONC_UNKNOWN
        end
        local knowledge = self:Knowledge(p.skillLine)
        if knowledge and knowledge > 0 then tip[#tip + 1] = L.KNOWLEDGE:format(knowledge) end
        rows[#rows + 1] = {
            text = L.PROF_LINE:format(p.name, p.rank, p.max), right = right, icon = p.icon,
            color = (cur and cur >= max) and { 1, 0.6, 0.2 } or nil,
            tooltip = tip, link = { search = p.name }, linkTitle = p.name,
        }
    end
    if #profs == 0 then rows[#rows + 1] = { text = L.NO_PROFESSIONS, dim = true } end

    local S = ns.GoldStrategies
    rows[#rows + 1] = { header = L.HDR_GOLD_GENERAL:format(L["PROFILE_" .. profile]) }
    Bullets(rows, S:Get("general", profile))
    local covered = 0
    for _, p in ipairs(profs) do
        if p.key then
            covered = covered + 1
            rows[#rows + 1] = { header = L.HDR_GOLD_PROF:format(p.name) }
            Bullets(rows, S:Get(p.key, profile))
        end
    end
    if covered == 0 then
        rows[#rows + 1] = { header = L.HDR_GOLD_NONE }
        Bullets(rows, S:Get("none", profile))
    end
    rows[#rows + 1] = { header = "" }
    rows[#rows + 1] = { text = L.GOLD_DISCLAIMER, dim = true, wrap = true }
    return rows
end
