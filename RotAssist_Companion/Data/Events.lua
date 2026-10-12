-- RotAssist Companion - Events
-- Fonte di dati per la scheda Oggi (Activities.lua):
-- * Eventi sulla mappa: C_AreaPoiInfo.GetEventsForMap su tutte le zone.
-- * Festivita' di oggi: calendario di gioco (C_Calendar), richiesto all'accesso.

local _, ns = ...
local A = ns.API

local E = {}
ns.Events = E


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

