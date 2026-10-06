-- Mock aggiuntivi per RotAssist Companion (mappe, delve, eventi, Great Vault...)

-- Show() deve eseguire OnShow come nel gioco
do
    local probe = CreateFrame("Frame")
    local mt = getmetatable(probe)
    local index = mt.__index
    mt.__index = function(t, k)
        if k == "Show" then
            return function(self)
                local was = self._shown
                self._shown = true
                if not was and self._scripts.OnShow then self._scripts.OnShow(self) end
            end
        end
        if k == "GetChecked" then return function(self) return self._checked end end
        if k == "SetChecked" then return function(self, v) self._checked = v end end
        return index(t, k)
    end
end

C_Timer = { After = function(_, fn) fn() end }
UISpecialFrames = {}
BreakUpLargeNumbers = function(n) return tostring(math.floor(n)) end
date = date or function() return "12:34" end

-- Mondo con gli UiMapID reali (wago.tools, 12.1.5)
MOCK.maps = {
    [946]  = { mapID = 946,  name = "Cosmic",            mapType = 0, parentMapID = 0 },
    [947]  = { mapID = 947,  name = "Azeroth",           mapType = 1, parentMapID = 946 },
    [13]   = { mapID = 13,   name = "Eastern Kingdoms",  mapType = 2, parentMapID = 947 },
    [12]   = { mapID = 12,   name = "Kalimdor",          mapType = 2, parentMapID = 947 },
    [2537] = { mapID = 2537, name = "Quel'Thalas",       mapType = 2, parentMapID = 13 },
    [2395] = { mapID = 2395, name = "Eversong Woods",    mapType = 3, parentMapID = 2537 },
    [2393] = { mapID = 2393, name = "Silvermoon City",   mapType = 3, parentMapID = 2395 },
    [2437] = { mapID = 2437, name = "Zul'Aman",          mapType = 3, parentMapID = 2537 },
    [2413] = { mapID = 2413, name = "Harandar",          mapType = 3, parentMapID = 2537 },
    [2405] = { mapID = 2405, name = "Voidstorm",         mapType = 3, parentMapID = 2537 },
    [84]   = { mapID = 84,   name = "Stormwind City",    mapType = 3, parentMapID = 13 },
    [85]   = { mapID = 85,   name = "Orgrimmar",         mapType = 3, parentMapID = 12 },
    [88]   = { mapID = 88,   name = "Thunder Bluff",     mapType = 3, parentMapID = 12 },
    [2274] = { mapID = 2274, name = "Khaz Algar",        mapType = 2, parentMapID = 947 },
    [2248] = { mapID = 2248, name = "Isle of Dorn",      mapType = 3, parentMapID = 2274 },
    [2339] = { mapID = 2339, name = "Dornogal",          mapType = 3, parentMapID = 2248 },
    [2214] = { mapID = 2214, name = "The Ringing Deeps", mapType = 3, parentMapID = 2274 },
}
MOCK.playerMap = 2395
MOCK.levels = { [2395] = { 80, 83 }, [2437] = { 82, 85 }, [2214] = { 70, 80 } }

C_Map = {
    GetBestMapForUnit = function() return MOCK.playerMap end,
    GetMapInfo = function(id) return MOCK.maps[id] end,
    GetMapChildrenInfo = function(root, mapType, all)
        local out = {}
        local function inside(id)
            local m = MOCK.maps[id]
            while m do
                if m.parentMapID == root then return true end
                m = MOCK.maps[m.parentMapID]
            end
        end
        for id, m in pairs(MOCK.maps) do
            if m.mapType == mapType and inside(id) then out[#out + 1] = m end
        end
        return out
    end,
    GetMapLevels = function(id) local l = MOCK.levels[id]; if l then return l[1], l[2], 0, 0 end return 0, 0, 0, 0 end,
    CanSetUserWaypointOnMap = function() return true end,
    SetUserWaypoint = function(p) MOCK.waypoint = p end,
}
UiMapPoint = { CreateFromCoordinates = function(m, x, y) return { m = m, x = x, y = y } end }
C_SuperTrack = { SetSuperTrackedUserWaypoint = function() end }

MOCK.pois = {
    [101] = { areaPoiID = 101, name = "Shadowguard Point", atlasName = "delves-bountiful", position = { x = 0.4, y = 0.5 } },
    [102] = { areaPoiID = 102, name = "Sunkiller Sanctum", atlasName = "delves-regular",   position = { x = 0.6, y = 0.2 } },
    [103] = { areaPoiID = 103, name = "Earthcrawl Mines",  atlasName = "delves-regular",   position = { x = 0.3, y = 0.3 } },
    [201] = { areaPoiID = 201, name = "Harvest Festival",  atlasName = "event", position = { x = 0.5, y = 0.5 },
              description = "Evento di prova", isCurrentEvent = true },
}
C_AreaPoiInfo = {
    GetDelvesForMap = function(id)
        if id == 2395 then return { 101, 102 } end
        if id == 2437 then return { 101 } end       -- duplicato su un'altra mappa
        if id == 2214 then return { 103 } end
        return {}
    end,
    GetEventsForMap = function(id) if id == 2437 then return { 201 } end return {} end,
    GetAreaPOIInfo = function(_, id) return MOCK.pois[id] end,
    GetAreaPOISecondsLeft = function(id) return 5400 end,
}
C_TaskQuest = {
    GetQuestsOnMap = function(id)
        if id == 2395 then return { { questID = 9001, x = 0.1, y = 0.2, mapID = 2395 }, { questID = 9002, x = 0.3, y = 0.4, mapID = 2395 } } end
        if id == 2214 then return { { questID = 9100, x = 0.1, y = 0.1, mapID = 2214 } } end
        return {}
    end,
    GetQuestInfoByQuestID = function(id) return "World Quest " .. id end,
    GetQuestTimeLeftSeconds = function(id) return id == 9002 and 3600 or 86400 end,
}
C_QuestLog = {
    IsWorldQuest = function() return true end,
    GetQuestTagInfo = function(id) return { tagName = "World Quest", isElite = id == 9002 } end,
    GetNumQuestLogEntries = function() return 30, 28 end,
}
C_CurrencyInfo = {
    GetCurrencyInfo = function(id)
        if id == 3028 then return { name = "Restored Coffer Key", quantity = 2, iconFileID = 1 } end
        if id == 3310 then return { name = "Coffer Key Shards", quantity = 150, quantityEarnedThisWeek = 300, maxWeeklyQuantity = 600, iconFileID = 2 } end
    end,
}
C_DelvesUI = { GetFactionForCompanion = function() return 2744 end }
C_Reputation = { GetFactionDataByID = function() return { name = "Valeera Sanguinar" } end }
C_GossipInfo = { GetFriendshipReputationRanks = function() return { currentLevel = 23, maxLevel = 60 } end }
C_WeeklyRewards = {
    HasAvailableRewards = function() return true end,
    GetActivities = function()
        return {
            { type = 1, index = 1, threshold = 1, progress = 3, level = 10 },
            { type = 1, index = 2, threshold = 4, progress = 3 },
            { type = 6, index = 1, threshold = 2, progress = 2, level = 8 },
            { type = 6, index = 2, threshold = 4, progress = 2 },
            { type = 6, index = 3, threshold = 8, progress = 2 },
        }
    end,
}
C_PerksActivities = {
    GetPerksActivitiesInfo = function()
        return { displayMonthName = "Ottobre", secondsRemaining = 2000000,
                 activities = { { completed = true, thresholdContributionAmount = 50 }, { completed = false }, { completed = true, thresholdContributionAmount = 25 } } }
    end,
}
C_DateAndTime = {
    GetCurrentCalendarTime = function() return { monthDay = 6, month = 10, year = 2026 } end,
    GetSecondsUntilDailyReset = function() return 30000 end,
    GetSecondsUntilWeeklyReset = function() return 400000 end,
}
C_Calendar = {
    OpenCalendar = function() end,
    GetMonthInfo = function() return { month = 9, year = 2026 } end,
    SetAbsMonth = function(m, y) MOCK.calendarMonth = m end,
    GetNumDayEvents = function() return 2 end,
    GetDayEvent = function(_, _, i)
        if i == 1 then return { title = "Brewfest", calendarType = "HOLIDAY", iconTexture = 3 } end
        return { title = "Raid night", calendarType = "GUILD_EVENT" }
    end,
}
MOCK.xp, MOCK.xpMax, MOCK.level = 1000, 10000, 82
UnitXP = function() return MOCK.xp end
UnitXPMax = function() return MOCK.xpMax end
UnitLevel = function() return MOCK.level end
GetXPExhaustion = function() return 5000 end
GetMaxLevelForPlayerExpansion = function() return 90 end
GetLocale = function() return "itIT" end

-- Viaggio
MOCK.faction, MOCK.bind, MOCK.hearthCD = "Alliance", "Silvermoon City", 0
UnitFactionGroup = function() return MOCK.faction end
GetBindLocation = function() return MOCK.bind end
C_Container = { GetItemCooldown = function() if MOCK.hearthCD > 0 then return MOCK.now, MOCK.hearthCD, 1 end return 0, 0, 1 end }

-- Professioni
MOCK.profs = { 1, 2 }
MOCK.profInfo = {
    [1] = { "Alchemy", 101, 85, 100, 0, 0, 171 },
    [2] = { "Herbalism", 102, 100, 100, 0, 0, 182 },
}
GetProfessions = function() return MOCK.profs[1], MOCK.profs[2], nil, nil, nil end
GetProfessionInfo = function(i) local t = MOCK.profInfo[i]; if t then return table.unpack(t) end end
C_TradeSkillUI = {
    GetBaseProfessionInfo = function() return { professionID = 171 } end,
    GetChildProfessionInfo = function() return { professionID = 2906 } end,
    GetConcentrationCurrencyID = function(id) return 3200 end,
}
C_ProfSpecs = { GetCurrencyInfoForSkillLine = function() return { numAvailable = 5 } end }
local _currency = C_CurrencyInfo.GetCurrencyInfo
C_CurrencyInfo.GetCurrencyInfo = function(id)
    if id == 3200 then return { name = "Concentration", quantity = 1000, maxQuantity = 1000 } end
    return _currency(id)
end
