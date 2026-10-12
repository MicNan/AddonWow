-- RotAssist Companion - Weekly
-- Fonte di dati per la scheda Oggi (Activities.lua):
-- * Great Vault: C_WeeklyRewards.GetActivities, raggruppato per tipo
--   (1 = dungeon, 3 = raid, 6 = delve e attivita' nel mondo).
-- * Traveler's Log: C_PerksActivities.GetPerksActivitiesInfo.
-- * Tempo ai reset giornaliero e settimanale.

local _, ns = ...
local A = ns.API

local W = {}
ns.Weekly = W

local VAULT_TYPES = {
    { type = 1, key = "VAULT_DUNGEONS" },
    { type = 3, key = "VAULT_RAID" },
    { type = 6, key = "VAULT_WORLD" },
}
W.VAULT_TYPES = VAULT_TYPES

function W:VaultReady()
    if not (C_WeeklyRewards and C_WeeklyRewards.HasAvailableRewards) then return false end
    return A.Call(C_WeeklyRewards.HasAvailableRewards) and true or false
end

-- Per ogni tipo: elenco degli slot { progress, threshold, level, done }
function W:Vault()
    local byType = {}
    if not (C_WeeklyRewards and C_WeeklyRewards.GetActivities) then return byType end
    local list = A.Call(C_WeeklyRewards.GetActivities)
    if type(list) ~= "table" then return byType end
    for _, act in ipairs(list) do
        if type(act) == "table" and act.type and act.threshold then
            byType[act.type] = byType[act.type] or {}
            table.insert(byType[act.type], {
                index = act.index or 0, progress = act.progress or 0, threshold = act.threshold,
                level = act.level, done = (act.progress or 0) >= act.threshold,
            })
        end
    end
    for _, slots in pairs(byType) do
        table.sort(slots, function(a, b) return a.index < b.index end)
    end
    return byType
end

function W:TravelersLog()
    if not (C_PerksActivities and C_PerksActivities.GetPerksActivitiesInfo) then return nil end
    local info = A.Call(C_PerksActivities.GetPerksActivitiesInfo)
    if type(info) ~= "table" or type(info.activities) ~= "table" then return nil end
    local done, points = 0, 0
    for _, act in ipairs(info.activities) do
        if type(act) == "table" and act.completed then
            done = done + 1
            points = points + (act.thresholdContributionAmount or 0)
        end
    end
    return {
        month = info.displayMonthName or "", done = done, total = #info.activities,
        points = points, secondsLeft = info.secondsRemaining,
    }
end

-- Secondi ai reset giornaliero e settimanale (nil se non disponibili)
function W:Resets()
    if not C_DateAndTime then return nil, nil end
    return A.Call(C_DateAndTime.GetSecondsUntilDailyReset), A.Call(C_DateAndTime.GetSecondsUntilWeeklyReset)
end
