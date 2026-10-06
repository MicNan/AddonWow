-- RotAssist Companion - Events
-- * Eventi sulla mappa: C_AreaPoiInfo.GetEventsForMap su tutte le zone.
-- * World quest: C_TaskQuest.GetQuestsOnMap sulle zone del continente in cui
--   si trova il giocatore (per non elencare quelle delle espansioni passate).
-- * Festivita' di oggi: calendario di gioco (C_Calendar), richiesto all'accesso.

local _, ns = ...
local A = ns.API

local E = {}
ns.Events = E

local MAX_WORLD_QUESTS = 40

---------------------------------------------------------------------------
-- Eventi sulla mappa
---------------------------------------------------------------------------
local SCAN_TTL = 20

function E:MapEvents()
    return A.Cached("events", SCAN_TTL, function() return self:ScanMapEvents() end)
end

function E:ScanMapEvents()
    local out, seen = {}, {}
    if not (C_AreaPoiInfo and C_AreaPoiInfo.GetEventsForMap) then return out end
    for _, zone in ipairs(A.Zones()) do
        local ids = A.Call(C_AreaPoiInfo.GetEventsForMap, zone.mapID)
        if type(ids) == "table" then
            for _, poiID in ipairs(ids) do
                if not seen[poiID] then
                    local info = A.Call(C_AreaPoiInfo.GetAreaPOIInfo, zone.mapID, poiID)
                    if type(info) == "table" and info.name then
                        seen[poiID] = true
                        local pos = info.position
                        out[#out + 1] = {
                            name = info.name, description = info.description, zone = zone.name,
                            mapID = zone.mapID, x = pos and pos.x, y = pos and pos.y,
                            atlas = info.atlasName, current = info.isCurrentEvent,
                            secondsLeft = A.Call(C_AreaPoiInfo.GetAreaPOISecondsLeft, poiID),
                        }
                    end
                end
            end
        end
    end
    table.sort(out, function(a, b)
        if (a.current and 1 or 0) ~= (b.current and 1 or 0) then return a.current end
        return tostring(a.name) < tostring(b.name)
    end)
    return out
end

---------------------------------------------------------------------------
-- World quest del continente attuale
---------------------------------------------------------------------------
function E:WorldQuests()
    return A.Cached("worldquests", SCAN_TTL, function() return self:ScanWorldQuests() end)
end

function E:ScanWorldQuests()
    local out, seen = {}, {}
    local QL = C_QuestLog or {}
    local continentID, continentName = A.ContinentOf(A.PlayerMap())
    if not continentID or not (C_TaskQuest and C_TaskQuest.GetQuestsOnMap) then return out, continentName end
    for _, zone in ipairs(A.Zones(continentID)) do
        local quests = A.Call(C_TaskQuest.GetQuestsOnMap, zone.mapID)
        if type(quests) == "table" then
            for _, q in ipairs(quests) do
                local id = type(q) == "table" and q.questID
                if id and not seen[id] and (not q.mapID or q.mapID == zone.mapID)
                   and A.Call(QL.IsWorldQuest, id) then
                    seen[id] = true
                    local title = A.Call(C_TaskQuest.GetQuestInfoByQuestID, id)
                    local tag = A.Call(QL.GetQuestTagInfo, id)
                    out[#out + 1] = {
                        questID = id, name = title or ("quest " .. id), zone = zone.name,
                        mapID = zone.mapID, x = q.x, y = q.y,
                        secondsLeft = A.Call(C_TaskQuest.GetQuestTimeLeftSeconds, id),
                        elite = type(tag) == "table" and tag.isElite or false,
                        tagName = type(tag) == "table" and tag.tagName or nil,
                    }
                end
            end
        end
    end
    table.sort(out, function(a, b) return (a.secondsLeft or 1e9) < (b.secondsLeft or 1e9) end)
    while #out > MAX_WORLD_QUESTS do table.remove(out) end
    return out, continentName
end

---------------------------------------------------------------------------
-- Festivita' di oggi (calendario)
---------------------------------------------------------------------------
function E:RequestCalendar()
    if C_Calendar and C_Calendar.OpenCalendar then pcall(C_Calendar.OpenCalendar) end
end

function E:Holidays()
    local out = {}
    if not (C_Calendar and C_Calendar.GetNumDayEvents and C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime) then
        return out
    end
    local now = A.Call(C_DateAndTime.GetCurrentCalendarTime)
    if type(now) ~= "table" or not now.monthDay then return out end
    -- il calendario lavora sul mese "visualizzato": lo allineiamo al mese
    -- corrente solo se il calendario di Blizzard non e' aperto
    local month = C_Calendar.GetMonthInfo and A.Call(C_Calendar.GetMonthInfo, 0)
    if type(month) == "table" and (month.month ~= now.month or month.year ~= now.year) then
        if CalendarFrame and CalendarFrame:IsShown() then return out end
        pcall(C_Calendar.SetAbsMonth, now.month, now.year)
    end
    local n = A.Call(C_Calendar.GetNumDayEvents, 0, now.monthDay) or 0
    for i = 1, n do
        local ev = A.Call(C_Calendar.GetDayEvent, 0, now.monthDay, i)
        if type(ev) == "table" and ev.calendarType == "HOLIDAY" and ev.title then
            out[#out + 1] = { name = ev.title, icon = ev.iconTexture }
        end
    end
    return out
end

---------------------------------------------------------------------------
-- Righe per la scheda
---------------------------------------------------------------------------
function E:Rows()
    local L, rows = ns.L, {}

    rows[#rows + 1] = { header = L.HDR_HOLIDAYS }
    local hol = self:Holidays()
    for _, h in ipairs(hol) do
        rows[#rows + 1] = { text = h.name, icon = h.icon, link = { search = h.name }, linkTitle = h.name }
    end
    if #hol == 0 then rows[#rows + 1] = { text = L.NO_HOLIDAYS, dim = true } end

    rows[#rows + 1] = { header = L.HDR_EVENTS }
    local evs = self:MapEvents()
    for _, e in ipairs(evs) do
        rows[#rows + 1] = {
            text = e.name, right = e.secondsLeft and L.TIME_LEFT:format(A.TimeText(e.secondsLeft)) or e.zone,
            atlas = e.atlas, color = e.current and { 0.4, 1, 0.4 } or nil,
            tooltip = { e.name, e.zone, e.description },
            waypoint = e.x and { e.mapID, e.x, e.y, e.name } or nil,
            link = { search = e.name }, linkTitle = e.name,
        }
    end
    if #evs == 0 then rows[#rows + 1] = { text = L.NO_EVENTS, dim = true } end

    local wqs, continent = self:WorldQuests()
    rows[#rows + 1] = { header = L.HDR_WORLD_QUESTS:format(continent or "?") }
    for _, q in ipairs(wqs) do
        local name = q.elite and (q.name .. " (" .. L.ELITE .. ")") or q.name
        rows[#rows + 1] = {
            text = name, right = A.TimeText(q.secondsLeft),
            color = q.elite and { 0.8, 0.5, 1 } or nil,
            tooltip = { q.name, q.zone, q.tagName },
            waypoint = q.x and { q.mapID, q.x, q.y, q.name } or nil,
            link = { quest = q.questID }, linkTitle = q.name,
        }
    end
    if #wqs == 0 then rows[#rows + 1] = { text = L.NO_WORLD_QUESTS, dim = true } end
    return rows
end
