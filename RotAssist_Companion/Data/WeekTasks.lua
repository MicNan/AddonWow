-- RotAssist Companion - WeekTasks
-- Scheda "Settimana": le attivita' settimanali consigliate, con stato,
-- dove andare e un link a una guida.
--
-- Stato: automatico dove il gioco lo dice a un addon (chiavi e frammenti
-- delle delve, blocco del boss del mondo), altrimenti spuntato a mano. Le
-- missioni settimanali si riconoscono dall'ID quando e' noto (WEEKLY_QUESTS);
-- per trovarli /rac missioni elenca le missioni consegnate di recente con il
-- loro ID. Tutto si azzera da solo al reset settimanale.
--
-- Avviso Prey: entrando in una zona di Midnight senza una caccia attiva, se
-- le cacce della settimana sono meno di 4, compare un avviso a schermo
-- (disattivabile dalle opzioni). Solo lettura: l'addon non accetta missioni.

local _, ns = ...
local A = ns.API

local WT = {}
ns.WeekTasks = WT

local SILVERMOON, ZULAMAN, COILED_ISLE = 2393, 2437, 2512
local PREY_GOAL, DELVE_GOAL = 4, 4
-- Zone all'aperto di Midnight per l'avviso Prey
local MIDNIGHT_ZONES = { [2395] = true, [2437] = true, [2413] = true, [2405] = true, [2512] = true }
-- Missioni settimanali note: chiave -> { questID, ... } (da completare con /rac missioni)
WT.WEEKLY_QUESTS = { apex = {}, abundance = {} }
-- Missioni delle cacce Prey note (per riconoscere una caccia attiva)
WT.PREY_QUESTS = {}
-- Parole che indicano una caccia nel titolo di una missione (inglese, italiano)
local PREY_WORDS = { "prey", "preda", "hunt:" }
-- Boss del mondo (Lair) della Season 2
local WORLD_BOSS_WORDS = { "nymrissa", "tidebound" }

local GUIDES = {
    apex      = "https://warcraft.wiki.gg/wiki/Apex_Cache",
    prey      = "https://warcraft.wiki.gg/wiki/Prey",
    delves    = "https://warcraft.wiki.gg/wiki/Delve",
    worldboss = "https://www.method.gg/guides/where-to-find-the-tidebound-grotto-lair-in-wow-midnight",
    abundance = "https://www.method.gg/guides/abundance-midnight-event-and-vendor-rewards-guide",
}

---------------------------------------------------------------------------
-- Stato della settimana (per personaggio, azzerato al reset)
---------------------------------------------------------------------------
local function WeekKey()
    local _, weekly = ns.Weekly:Resets()
    if not weekly then return nil end
    return math.floor((time() + weekly) / 3600)   -- ora del prossimo reset
end

function WT:State()
    ns.db.week = ns.db.week or {}
    local s = ns.db.week
    local key = WeekKey()
    if key and s.key ~= key then
        ns.db.week = { key = key, done = {}, prey = 0, delves = 0 }
        s = ns.db.week
    end
    s.done, s.prey, s.delves = s.done or {}, s.prey or 0, s.delves or 0
    return s
end

local function QuestDone(list)
    if not (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) then return false end
    for _, id in ipairs(list or {}) do
        if A.Call(C_QuestLog.IsQuestFlaggedCompleted, id) then return true end
    end
    return false
end

-- Fatto: missione nota completata (automatico) oppure spuntato a mano
function WT:Done(key)
    if QuestDone(self.WEEKLY_QUESTS[key]) then return true, true end
    return self:State().done[key] and true or false, false
end

function WT:Toggle(key)
    local s = self:State()
    s.done[key] = not s.done[key] or nil
end

function WT:Add(field, delta, max)
    local s = self:State()
    s[field] = math.max(0, math.min(max, (s[field] or 0) + delta))
end

-- Boss del mondo: blocco settimanale (boss del mondo o istanza "Lair")
function WT:WorldBossDone()
    local function match(name)
        name = type(name) == "string" and name:lower() or ""
        for _, w in ipairs(WORLD_BOSS_WORDS) do if name:find(w, 1, true) then return true end end
        return false
    end
    local n = A.Call(GetNumSavedWorldBosses) or 0
    for i = 1, n do
        if match(A.Call(GetSavedWorldBossInfo, i)) then return true end
    end
    local m = A.Call(GetNumSavedInstances) or 0
    for i = 1, m do
        local name, _, reset, _, locked = A.Call(GetSavedInstanceInfo, i)
        if locked and (reset or 0) > 0 and match(name) then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- Caccia Prey attiva e avviso entrando in una zona di Midnight
---------------------------------------------------------------------------
function WT:PreyActive()
    local QL = C_QuestLog
    if not (QL and QL.GetNumQuestLogEntries and QL.GetInfo) then return false end
    for _, id in ipairs(self.PREY_QUESTS) do
        if QL.IsOnQuest and A.Call(QL.IsOnQuest, id) then return true end
    end
    local n = A.Call(QL.GetNumQuestLogEntries) or 0
    for i = 1, n do
        local info = A.Call(QL.GetInfo, i)
        local title = type(info) == "table" and not info.isHeader and type(info.title) == "string" and info.title:lower()
        if title then
            for _, w in ipairs(PREY_WORDS) do if title:find(w, 1, true) then return true end end
        end
    end
    return false
end

function WT:OnZoneChanged()
    if not (ns.db and ns.db.preyWarning) or A.InCombat() then return end
    local map = C_Map and A.Call(C_Map.GetBestMapForUnit, "player")
    if not (map and MIDNIGHT_ZONES[map]) then return end
    self.warned = self.warned or {}
    if self.warned[map] then return end
    local s = self:State()
    if s.prey >= PREY_GOAL or self:PreyActive() then return end
    self.warned[map] = true
    local msg = ns.L.WEEK_PREY_WARNING:format(s.prey, PREY_GOAL)
    if UIErrorsFrame and UIErrorsFrame.AddMessage then pcall(UIErrorsFrame.AddMessage, UIErrorsFrame, msg, 1, 0.6, 0.2) end
    ns:Print(msg)
end

-- Missioni consegnate di recente (per trovare gli ID delle settimanali)
function WT:OnQuestTurnedIn(questID)
    questID = A.Plain(questID)
    if type(questID) ~= "number" then return end
    local title = C_QuestLog and C_QuestLog.GetTitleForQuestID and A.Call(C_QuestLog.GetTitleForQuestID, questID)
    ns.db.turnedIn = ns.db.turnedIn or {}
    table.insert(ns.db.turnedIn, 1, { id = questID, title = title, time = time() })
    while #ns.db.turnedIn > 30 do table.remove(ns.db.turnedIn) end
end

function WT:PrintTurnedIn()
    local list = ns.db.turnedIn or {}
    ns:Print(ns.L.WEEK_QUESTS_HDR:format(#list))
    for i = 1, math.min(20, #list) do
        local q = list[i]
        ns:Print(("  %d  %s  (%s)"):format(q.id, tostring(q.title or "?"), A.TimeText(time() - q.time)))
    end
end

---------------------------------------------------------------------------
-- Righe della scheda
---------------------------------------------------------------------------
local GREEN, ORANGE, GREY = { 0.4, 1, 0.4 }, { 1, 0.6, 0.2 }, { 0.6, 0.6, 0.6 }

-- Un'attivita': titolo con stato, cosa fare, dove andare, guida e comandi
local function Task(rows, t)
    local L = ns.L
    local color = t.done and GREEN or (t.progress and ORANGE or nil)
    rows[#rows + 1] = { kind = "sub", text = (t.done and "|cff66ff66" .. L.WEEK_DONE_MARK .. "|r " or "") .. t.title }
    if t.bar then
        rows[#rows + 1] = { kind = "bar", min = 0, max = t.bar.max, value = math.min(t.bar.value, t.bar.max),
                            color = t.done and GREEN or ORANGE, label = t.bar.label, right = t.bar.right }
    end
    rows[#rows + 1] = { kind = "step", badge = "-", badgeColor = color or GREY, text = t.what }
    if t.where then
        rows[#rows + 1] = { text = L.WEEK_WHERE:format(t.where), icon = "Interface\\Icons\\INV_Misc_Map_01",
                            waypoint = t.waypoint, dim = not t.waypoint,
                            link = { url = t.guide }, linkTitle = t.title }
    end
    rows[#rows + 1] = { text = L.WEEK_GUIDE, icon = "Interface\\Icons\\INV_Misc_Book_09", dim = true,
                        link = { url = t.guide }, linkTitle = t.title, tooltip = { t.title, t.guide } }
    if t.pills then rows[#rows + 1] = { kind = "pills", items = t.pills } end
    if t.note then rows[#rows + 1] = { kind = "note", text = t.note } end
end

local function TogglePill(key, done, auto)
    local L = ns.L
    if auto and done then return nil end
    return { { label = done and L.WEEK_MARK_UNDO or L.WEEK_MARK_DONE, action = true,
               onClick = function() WT:Toggle(key) end } }
end

local function CounterPills(field, max)
    local L = ns.L
    return {
        { label = "-1", onClick = function() WT:Add(field, -1, max) end },
        { label = L.WEEK_ADD_ONE, action = true, onClick = function() WT:Add(field, 1, max) end },
    }
end

function WT:Rows()
    local L, rows = ns.L, {}
    local s = self:State()
    local _, weekly = ns.Weekly:Resets()
    local doneCount, total = 0, 5

    -- 1. Apex Cache: missione settimanale di Lady Liadrin
    local apex, apexAuto = self:Done("apex")
    -- 2. Prey
    local prey = s.prey
    -- 3. Delve abbondanti e chiavi
    local delves = s.delves
    local keys, shards = ns.Delves:Keys()
    -- 4. Boss del mondo
    local boss = self:WorldBossDone()
    local bossManual = s.done.worldboss and true or false
    -- 5. Abbondanza
    local abundance, abundanceAuto = self:Done("abundance")

    for _, d in ipairs({ apex, prey >= PREY_GOAL, delves >= DELVE_GOAL, boss or bossManual, abundance }) do
        if d then doneCount = doneCount + 1 end
    end
    rows[#rows + 1] = { kind = "bar", min = 0, max = total, value = doneCount, color = doneCount >= total and GREEN or { 0.35, 0.65, 1 },
                        label = L.WEEK_PROGRESS:format(doneCount, total),
                        right = weekly and L.WEEK_RESET_IN:format(A.TimeText(weekly)) or nil }
    if (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) and #self.WEEKLY_QUESTS.apex == 0 then
        rows[#rows + 1] = { kind = "note", text = L.WEEK_MANUAL_NOTE }
    end

    rows[#rows + 1] = { header = L.WEEK_HDR }
    Task(rows, {
        title = L.WEEK_APEX, done = apex, what = L.WEEK_APEX_WHAT,
        where = L.WEEK_APEX_WHERE, waypoint = nil, guide = GUIDES.apex,
        pills = TogglePill("apex", apex, apexAuto),
    })
    Task(rows, {
        title = L.WEEK_PREY, done = prey >= PREY_GOAL, progress = prey > 0, what = L.WEEK_PREY_WHAT,
        bar = { max = PREY_GOAL, value = prey, label = L.WEEK_COUNT:format(prey, PREY_GOAL) },
        where = L.WEEK_PREY_WHERE, guide = GUIDES.prey,
        pills = CounterPills("prey", 15),
        note = self:PreyActive() and L.WEEK_PREY_ACTIVE or L.WEEK_PREY_NONE,
    })
    local keyText
    if keys or shards then
        local maxW = shards and shards.maxWeeklyQuantity or 0
        keyText = L.WEEK_KEYS:format(keys and keys.quantity or 0, shards and shards.quantity or 0,
            shards and shards.quantityEarnedThisWeek or 0, maxW)
    end
    Task(rows, {
        title = L.WEEK_DELVES, done = delves >= DELVE_GOAL, progress = delves > 0, what = L.WEEK_DELVES_WHAT,
        bar = { max = DELVE_GOAL, value = delves, label = L.WEEK_COUNT:format(delves, DELVE_GOAL), right = keyText },
        where = L.WEEK_DELVES_WHERE, guide = GUIDES.delves,
        pills = CounterPills("delves", 30),
    })
    Task(rows, {
        title = L.WEEK_BOSS, done = boss or bossManual, what = L.WEEK_BOSS_WHAT,
        where = L.WEEK_BOSS_WHERE, guide = GUIDES.worldboss,
        pills = TogglePill("worldboss", boss or bossManual, boss),
        note = boss and L.WEEK_BOSS_AUTO or nil,
    })
    Task(rows, {
        title = L.WEEK_ABUNDANCE, done = abundance, what = L.WEEK_ABUNDANCE_WHAT,
        where = L.WEEK_ABUNDANCE_WHERE, waypoint = { ZULAMAN, 0.3162, 0.2614, "Loaknit Den" }, guide = GUIDES.abundance,
        pills = TogglePill("abundance", abundance, abundanceAuto),
    })
    rows[#rows + 1] = { kind = "note", text = L.WEEK_LINKS }
    return rows
end

WT.SILVERMOON, WT.COILED_ISLE = SILVERMOON, COILED_ISLE
