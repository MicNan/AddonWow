-- RotAssist Companion - Weekly
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

function W:Rows()
    local L, rows = ns.L, {}

    rows[#rows + 1] = { header = L.HDR_VAULT }
    if self:VaultReady() then
        rows[#rows + 1] = { kind = "callout", style = "tip", text = L.VAULT_READY }
    end
    local vault = self:Vault()
    for _, t in ipairs(VAULT_TYPES) do
        local slots = vault[t.type]
        if slots and #slots > 0 then
            -- una barra per tipo: avanzamento e soglie degli slot
            local done, ticks, progress, nextT = 0, {}, 0, nil
            for _, s in ipairs(slots) do
                ticks[#ticks + 1] = s.threshold
                progress = math.max(progress, s.progress)
                if s.done then done = done + 1 elseif not nextT then nextT = s.threshold end
            end
            local last = slots[#slots].threshold
            local tip = { L[t.key] }
            for i, s in ipairs(slots) do
                tip[#tip + 1] = L.VAULT_SLOT_TIP:format(i, math.min(s.progress, s.threshold), s.threshold,
                    (s.done and s.level and s.level > 0) and (" - " .. L.VAULT_ITEM_LEVEL:format(s.level)) or "")
            end
            rows[#rows + 1] = { text = L[t.key], right = L.VAULT_SLOTS:format(done, #slots), tooltip = tip,
                                color = done == #slots and { 0.4, 1, 0.4 } or nil }
            rows[#rows + 1] = { kind = "bar", min = 0, max = last, value = math.min(progress, last), ticks = ticks,
                                color = done > 0 and { 0.35, 0.85, 0.45 } or { 0.35, 0.65, 1 },
                                label = L.VAULT_PROGRESS:format(math.min(progress, last), last),
                                right = nextT and L.VAULT_NEXT:format(nextT - progress) or L.VAULT_ALL_DONE }
        end
    end

    local log = self:TravelersLog()
    if log then
        rows[#rows + 1] = { header = L.HDR_LOG }
        rows[#rows + 1] = {
            text = L.LOG_PROGRESS:format(log.month, log.done, log.total, log.points),
            right = log.secondsLeft and A.TimeText(log.secondsLeft) or nil,
        }
    end

    rows[#rows + 1] = { header = L.HDR_RESETS }
    if C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset then
        rows[#rows + 1] = { text = L.RESET_DAILY:format(A.TimeText(A.Call(C_DateAndTime.GetSecondsUntilDailyReset))) }
    end
    if C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset then
        rows[#rows + 1] = { text = L.RESET_WEEKLY:format(A.TimeText(A.Call(C_DateAndTime.GetSecondsUntilWeeklyReset))) }
    end
    return rows
end
