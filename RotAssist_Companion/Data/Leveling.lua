-- RotAssist Companion - Leveling
-- Supporto leggero al levelling (per le guide complete esistono addon
-- dedicati come RestedXP):
-- * livello, XP, riposo e XP/ora della sessione con stima del prossimo livello;
-- * livelli consigliati della zona attuale (C_Map.GetMapLevels);
-- * zone del continente adatte al livello del personaggio;
-- * numero di missioni nel diario.

local _, ns = ...
local A = ns.API

local LV = { session = nil }
ns.Leveling = LV

local MIN_SAMPLE = 120   -- secondi minimi prima di stimare l'XP/ora
local QUEST_LOG_MAX = 35

local function XP()
    return A.Call(UnitXP, "player") or 0, A.Call(UnitXPMax, "player") or 0
end

function LV:StartSession()
    local cur, max = XP()
    self.session = { start = GetTime(), gained = 0, last = cur, lastMax = max }
end

-- Aggiorna l'XP guadagnata. Se l'XP scende c'e' stato un passaggio di
-- livello: si conta il resto del livello precedente piu' l'XP del nuovo.
function LV:OnXPUpdate()
    if not self.session then self:StartSession() return end
    local cur, max = XP()
    local s = self.session
    if cur >= s.last then
        s.gained = s.gained + (cur - s.last)
    else
        s.gained = s.gained + math.max(0, (s.lastMax or 0) - s.last) + cur
    end
    s.last, s.lastMax = cur, max
end

function LV:Rate()
    local s = self.session
    if not s then return nil end
    local elapsed = GetTime() - s.start
    if elapsed < MIN_SAMPLE or s.gained <= 0 then return nil end
    return s.gained / elapsed * 3600
end

local function MaxLevel()
    local fn = GetMaxLevelForPlayerExpansion or GetMaxPlayerLevel
    return A.Call(fn) or 90
end

function LV:Rows()
    local L, rows = ns.L, {}
    local level = A.Call(UnitLevel, "player") or 0
    local maxLevel = MaxLevel()

    rows[#rows + 1] = { header = L.HDR_CHARACTER }
    rows[#rows + 1] = { text = L.LEVEL:format(level, maxLevel) }
    if level >= maxLevel then
        rows[#rows + 1] = { text = L.MAX_LEVEL, color = { 0.3, 1, 0.3 } }
    else
        local cur, max = XP()
        local pct = max > 0 and math.floor(cur / max * 100) or 0
        rows[#rows + 1] = { text = L.XP:format(A.Number(cur), A.Number(max), pct) }
        local rested = A.Call(GetXPExhaustion)
        if rested and rested > 0 then
            rows[#rows + 1] = { text = L.RESTED:format(A.Number(rested)), color = { 0.4, 0.6, 1 } }
        end
        local rate = self:Rate()
        if rate and rate > 0 then
            rows[#rows + 1] = { text = L.XP_RATE:format(A.Number(rate), A.TimeText((max - cur) / rate * 3600)) }
        else
            rows[#rows + 1] = { text = L.XP_RATE_WAIT, dim = true }
        end
    end

    -- zona attuale
    local mapID = A.PlayerMap()
    if mapID then
        rows[#rows + 1] = { header = L.HDR_ZONE }
        local name = A.ZoneName(mapID)
        local minL, maxL = A.Call(C_Map.GetMapLevels, mapID)
        local text = (minL and maxL and maxL > 0) and L.ZONE_LEVELS:format(name, minL, maxL) or name
        rows[#rows + 1] = { text = text, link = { search = name }, linkTitle = name }
    end

    -- zone del continente adatte al livello
    if level < maxLevel then
        rows[#rows + 1] = { header = L.HDR_ZONES }
        local continentID = A.ContinentOf(mapID)
        local found = {}
        if continentID then
            for _, z in ipairs(A.Zones(continentID)) do
                local minL, maxL = A.Call(C_Map.GetMapLevels, z.mapID)
                if minL and maxL and maxL > 0 and level >= minL and level <= maxL then
                    found[#found + 1] = { name = z.name, min = minL, max = maxL }
                end
            end
        end
        table.sort(found, function(a, b) return a.min < b.min end)
        for _, z in ipairs(found) do
            rows[#rows + 1] = { text = L.ZONE_LEVELS:format(z.name, z.min, z.max),
                                link = { search = z.name }, linkTitle = z.name }
        end
        if #found == 0 then rows[#rows + 1] = { text = L.NO_ZONES, dim = true } end
    end

    -- diario delle missioni
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
        local _, numQuests = A.Call(C_QuestLog.GetNumQuestLogEntries)
        if numQuests then
            rows[#rows + 1] = { header = "" }
            rows[#rows + 1] = { text = L.QUEST_LOG:format(numQuests, QUEST_LOG_MAX),
                                color = numQuests >= QUEST_LOG_MAX - 2 and { 1, 0.5, 0.2 } or nil }
        end
    end
    return rows
end
