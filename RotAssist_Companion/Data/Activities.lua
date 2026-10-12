-- RotAssist Companion - Activities
-- Scheda "Oggi": cosa fare oggi e questa settimana. Il selettore in cima
-- sceglie la vista: riepilogo (il meglio di ogni obiettivo, eventi,
-- festivita', world quest in scadenza, Traveler's Log e reset) oppure un
-- obiettivo (equipaggiamento, Great Vault, reputazione, oro).
-- Unica lettura delle world quest dell'addon: le altre schede non le leggono.
--
-- Dati letti dal gioco (sempre aggiornati):
--  * world quest di Quel'Thalas e del continente in cui ti trovi, con le
--    ricompense: oggetti (livello e
--    statistiche confrontati con quello che indossi e con la priorita' delle
--    statistiche della tua specializzazione, StatPriority.lua), crest, oro,
--    reputazione delle fazioni maggiori;
--  * Great Vault, Traveler's Log e reset (Weekly.lua); eventi sulla mappa e
--    festivita' (Events.lua);
--  * Renown delle fazioni maggiori.
-- In piu' un elenco curato di attivita' settimanali ricorrenti della 12.1 e i
-- livelli oggetto della Season 2, riassunti da guide pubbliche.

local _, ns = ...
local A = ns.API

local AC = { pending = 0 }
ns.Activities = AC

local GOALS = { "summary", "gear", "vault", "rep", "gold" }
AC.GOALS = GOALS
local ROOT = 2537            -- Quel'Thalas: tutte le zone di Midnight
local SCAN_TTL = 20
local MAX_ROWS = 12

-- Crest della Season 2 (Mistcrest): ordine dal piu' basso al piu' alto
local CREST_TIER = {
    [3437] = 1, [3442] = 1, [3438] = 2, [3443] = 2, [3439] = 3, [3444] = 3,
    [3440] = 4, [3445] = 4, [3441] = 5, [3446] = 5,
}

-- Slot dell'equipaggiamento per tipo di oggetto
local SLOTS = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_CHEST = { 5 },
    INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 },
    INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_CLOAK = { 15 }, INVTYPE_WEAPON = { 16, 17 }, INVTYPE_2HWEAPON = { 16 },
    INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_RANGED = { 16 }, INVTYPE_RANGEDRIGHT = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 },
}

---------------------------------------------------------------------------
-- World quest e ricompense
---------------------------------------------------------------------------
function AC:ReadRewards(q)
    local QL = C_QuestLog or {}
    local id = q.questID
    q.money = A.Call(GetQuestLogRewardMoney, id) or 0
    q.items = {}
    local n = A.Call(GetNumQuestLogRewards, id) or 0
    for i = 1, n do
        local name, icon, count, quality, usable, itemID, ilvl = A.Call(GetQuestLogRewardInfo, i, id)
        if itemID then
            local _, _, _, equipLoc = A.Call(C_Item and C_Item.GetItemInfoInstant, itemID)
            q.items[#q.items + 1] = {
                itemID = itemID, name = name, icon = icon, count = count or 1, quality = quality,
                usable = usable ~= false, ilvl = ilvl, equipLoc = equipLoc,
                link = A.Call(GetQuestLogItemLink, "reward", i, id),
            }
        end
    end
    local cur = A.Call(QL.GetQuestRewardCurrencies, id)
    q.currencies = type(cur) == "table" and cur or {}
    local reps = A.Call(QL.GetQuestLogMajorFactionReputationRewards, id)
    q.reps = type(reps) == "table" and reps or {}
end

function AC:Scan()
    local out, seen, pending = {}, {}, 0
    local QL = C_QuestLog or {}
    if not (C_TaskQuest and C_TaskQuest.GetQuestsOnMap) then return out, 0 end
    local zones, seenZone = {}, {}
    local here = A.ContinentOf(A.PlayerMap())
    for _, root in ipairs({ ROOT, here ~= ROOT and here or nil }) do
        for _, z in ipairs(A.Zones(root)) do
            if not seenZone[z.mapID] then seenZone[z.mapID] = true; zones[#zones + 1] = z end
        end
    end
    for _, zone in ipairs(zones) do
        local quests = A.Call(C_TaskQuest.GetQuestsOnMap, zone.mapID)
        if type(quests) == "table" then
            for _, q in ipairs(quests) do
                local id = type(q) == "table" and q.questID
                if id and not seen[id] and (not q.mapID or q.mapID == zone.mapID) and A.Call(QL.IsWorldQuest, id) then
                    seen[id] = true
                    local wq = {
                        questID = id, name = A.Call(C_TaskQuest.GetQuestInfoByQuestID, id) or ("quest " .. id),
                        zone = zone.name, mapID = zone.mapID, x = q.x, y = q.y,
                        secondsLeft = A.Call(C_TaskQuest.GetQuestTimeLeftSeconds, id),
                    }
                    local tag = A.Call(QL.GetQuestTagInfo, id)
                    wq.elite = type(tag) == "table" and tag.isElite or false
                    -- le ricompense arrivano dal server: se mancano le chiediamo
                    if HaveQuestRewardData and A.Call(HaveQuestRewardData, id) == false then
                        if C_TaskQuest.RequestPreloadRewardData then pcall(C_TaskQuest.RequestPreloadRewardData, id) end
                        pending = pending + 1
                        wq.loading = true
                    else
                        self:ReadRewards(wq)
                    end
                    out[#out + 1] = wq
                end
            end
        end
    end
    return out, pending
end

function AC:Quests()
    local list, pending = A.Cached("activities", SCAN_TTL, function() return self:Scan() end)
    self.pending = pending or 0
    return list or {}
end

-- Ricompense arrivate: rileggere le world quest
function AC:OnQuestData()
    if self.pending > 0 then
        A.Forget("activities")
        if ns.Panel then ns.Panel:RequestRefresh() end
    end
end

---------------------------------------------------------------------------
-- Equipaggiamento: confronto con quello che indossi
---------------------------------------------------------------------------
local function Equipped(slot)
    local link = A.Call(GetInventoryItemLink, "player", slot)
    if not link then return 0, nil end
    local lvl = C_Item and C_Item.GetDetailedItemLevelInfo and A.Call(C_Item.GetDetailedItemLevelInfo, link)
    return tonumber(lvl) or 0, link
end

-- Per un oggetto in ricompensa: guadagno di livello rispetto al pezzo che
-- sostituiresti (il piu' basso tra due anelli, monili o armi) e statistiche.
function AC:Evaluate(item, prio)
    local slots = item.equipLoc and SLOTS[item.equipLoc]
    if not (slots and item.ilvl) then return nil end
    local worst, worstLink, worstSlot = math.huge, nil, nil
    for _, slot in ipairs(slots) do
        local lvl, link = Equipped(slot)
        if lvl < worst then worst, worstLink, worstSlot = lvl, link, slot end
    end
    local e = { delta = item.ilvl - worst, equipped = worst, slot = worstSlot }
    if prio and prio.order then
        e.match, e.stats = ns.StatPriority:ItemMatch(item.link, prio.order)
        e.oldMatch = ns.StatPriority:ItemMatch(worstLink, prio.order)
    end
    return e
end

---------------------------------------------------------------------------
-- Righe comuni
---------------------------------------------------------------------------
local function TimeLeft(q)
    return q.secondsLeft and A.TimeText(q.secondsLeft) or "-"
end

local function QuestTip(q, extra)
    local tip = { q.name, q.zone }
    for _, l in ipairs(extra or {}) do tip[#tip + 1] = l end
    if q.secondsLeft then tip[#tip + 1] = ns.L.TIME_LEFT:format(A.TimeText(q.secondsLeft)) end
    return tip
end

local function QuestRow(q, cols, widths, align, extra, colors)
    return {
        kind = "tr", cols = cols, widths = widths, align = align, colors = colors,
        tooltip = QuestTip(q, extra),
        waypoint = q.x and { q.mapID, q.x, q.y, q.name } or nil,
        link = { quest = q.questID }, linkTitle = q.name,
    }
end

-- Attivita' settimanali ricorrenti (elenco curato), filtrate per obiettivo
function AC:ChecklistRows(rows, goal)
    local L = ns.L
    local list = ns.L.ACT_WEEKLY
    if type(list) ~= "table" then return end
    local shown = 0
    for _, item in ipairs(list) do
        if item.tags and item.tags[goal] then
            if shown == 0 then rows[#rows + 1] = { kind = "sub", text = L.ACT_WEEKLY_TITLE } end
            shown = shown + 1
            rows[#rows + 1] = { kind = "step", badge = tostring(shown), badgeColor = { 1, 0.82, 0 }, text = item.text }
        end
    end
end

---------------------------------------------------------------------------
-- Obiettivo: equipaggiamento
---------------------------------------------------------------------------
function AC:StatRows(rows, prio)
    local L, SP = ns.L, ns.StatPriority
    rows[#rows + 1] = { header = L.ACT_STATS }
    if not prio.order then
        rows[#rows + 1] = { kind = "callout", style = "info", text = L.ACT_STATS_NONE }
        return
    end
    local title = L.ACT_STATS_FOR
    if prio.heroName then title = title .. " - " .. prio.heroName end
    rows[#rows + 1] = { kind = "sub", text = title }
    if prio.contentChoice then
        local items = {}
        for _, mode in ipairs({ "raid", "mplus" }) do
            items[#items + 1] = { label = L["ACT_CONTENT_" .. mode], selected = prio.variant == mode,
                                  onClick = function() ns.db.statContent = mode end }
        end
        rows[#rows + 1] = { kind = "pills", items = items }
    end
    local values = SP:Values(prio.primary)
    local widths, align = { 0.12, 0.58, 0.3 }, { "RIGHT", "LEFT", "RIGHT" }
    rows[#rows + 1] = { kind = "thead", widths = widths, align = align, cols = { "#", L.ACT_COL_STAT, L.ACT_COL_YOURS } }
    local n = 0
    if prio.ilvlFirst then
        n = n + 1
        rows[#rows + 1] = { kind = "tr", widths = widths, align = align,
                            cols = { tostring(n), L.ACT_ILVL .. " (" .. SP:Name(prio.primary) .. ")", "" },
                            colors = { nil, { 1, 0.82, 0 } } }
    end
    for _, stat in ipairs(prio.order) do
        n = n + 1
        local v = values[stat]
        rows[#rows + 1] = { kind = "tr", widths = widths, align = align,
                            cols = { tostring(n), SP:Name(stat), type(v) == "number" and ("%.1f%%"):format(v) or "-" },
                            colors = { nil, n <= (prio.ilvlFirst and 3 or 2) and { 0.4, 1, 0.4 } or nil } }
    end
    if prio.note then rows[#rows + 1] = { kind = "note", text = L[prio.note] } end
end

-- Oggetti in ricompensa che migliorano il tuo equipaggiamento (dal migliore)
function AC:GearUpgrades(prio)
    local ups, others = {}, 0
    for _, q in ipairs(self:Quests()) do
        for _, item in ipairs(q.items or {}) do
            if item.usable and item.equipLoc and SLOTS[item.equipLoc] then
                local e = self:Evaluate(item, prio)
                if e and e.delta > 0 then ups[#ups + 1] = { q = q, item = item, e = e } else others = others + 1 end
            end
        end
    end
    table.sort(ups, function(a, b)
        if a.e.delta ~= b.e.delta then return a.e.delta > b.e.delta end
        return (a.e.match or 0) > (b.e.match or 0)
    end)
    return ups, others
end

function AC:GearRows(rows)
    local L = ns.L
    local prio = ns.StatPriority:Current()
    local quests = self:Quests()
    local ups, others = self:GearUpgrades(prio)
    rows[#rows + 1] = { header = L.ACT_GEAR_UPGRADES }
    if #ups == 0 then
        rows[#rows + 1] = { kind = "callout", style = "info", text = L.ACT_GEAR_NONE }
    else
        rows[#rows + 1] = { kind = "callout", style = "tip", title = L.ACT_BEST_NOW,
                            text = L.ACT_GEAR_BEST:format(ups[1].item.name or "?", ups[1].e.delta, ups[1].q.name) }
        local widths, align = { 0.4, 0.12, 0.3, 0.18 }, { "LEFT", "RIGHT", "LEFT", "RIGHT" }
        rows[#rows + 1] = { kind = "thead", widths = widths, align = align,
                            cols = { L.ACT_COL_REWARD, L.ACT_COL_ILVL, L.ACT_COL_STATS, L.ACT_COL_TIME } }
        for i = 1, math.min(MAX_ROWS, #ups) do
            local u = ups[i]
            local statText, color = "-", nil
            if u.e.stats then
                local names = {}
                for k = 1, math.min(2, #u.e.stats) do names[#names + 1] = ns.StatPriority:Name(u.e.stats[k].stat) end
                statText = table.concat(names, " + ")
                if u.e.match and u.e.match >= 0.7 then color = { 0.4, 1, 0.4 }
                elseif u.e.match and u.e.match < 0.45 then color = { 1, 0.6, 0.2 } end
            end
            local extra = { L.ACT_TIP_ITEM:format(u.item.name or "?", u.item.ilvl or 0, u.e.equipped) }
            if u.e.match then
                extra[#extra + 1] = L.ACT_TIP_MATCH:format(math.floor(u.e.match * 100),
                    u.e.oldMatch and math.floor(u.e.oldMatch * 100) or 0)
            end
            rows[#rows + 1] = QuestRow(u.q, { u.item.name or "?", "+" .. u.e.delta, statText, TimeLeft(u.q) },
                                       widths, align, extra, { nil, { 0.4, 1, 0.4 }, color })
        end
        rows[#rows + 1] = { kind = "note", text = L.ACT_GEAR_LEGEND }
    end
    if others > 0 then rows[#rows + 1] = { kind = "note", text = L.ACT_GEAR_OTHERS:format(others) } end

    -- crest (per potenziare quello che hai)
    local crests = {}
    for _, q in ipairs(quests) do
        for _, c in ipairs(q.currencies or {}) do
            local tier = type(c) == "table" and CREST_TIER[c.currencyID]
            if tier then crests[#crests + 1] = { q = q, c = c, tier = tier } end
        end
    end
    table.sort(crests, function(a, b) return a.tier > b.tier end)
    if #crests > 0 then
        rows[#rows + 1] = { kind = "sub", text = L.ACT_CRESTS }
        local widths, align = { 0.5, 0.32, 0.18 }, { "LEFT", "LEFT", "RIGHT" }
        for i = 1, math.min(6, #crests) do
            local x = crests[i]
            rows[#rows + 1] = QuestRow(x.q, { x.q.name, ("%d %s"):format(x.c.totalRewardAmount or x.c.quantity or 0, x.c.name or "?"),
                                              TimeLeft(x.q) }, widths, align)
        end
    end
    if self.pending > 0 then rows[#rows + 1] = { kind = "note", text = L.ACT_LOADING:format(self.pending) } end

    self:StatRows(rows, prio)

    -- fonti di equipaggiamento della stagione
    rows[#rows + 1] = { header = L.ACT_SOURCES }
    local widths = { 0.62, 0.38 }
    rows[#rows + 1] = { kind = "thead", widths = widths, cols = { L.ACT_COL_SOURCE, L.ACT_COL_TRACK } }
    for _, s in ipairs(L.ACT_GEAR_SOURCES) do
        rows[#rows + 1] = { kind = "tr", widths = widths, cols = { s[1], s[2] }, colors = { nil, { 0.6, 0.85, 1 } } }
    end
    self:ChecklistRows(rows, "gear")
end

---------------------------------------------------------------------------
-- Obiettivo: Great Vault
---------------------------------------------------------------------------
-- Categorie della Great Vault, la piu' vicina al prossimo slot per prima
function AC:VaultCategories()
    local W = ns.Weekly
    local vault = W:Vault()
    local cats, unlocked = {}, 0
    for _, t in ipairs(W.VAULT_TYPES) do
        local slots = vault[t.type]
        if slots and #slots > 0 then
            local done, nextT, progress, best = 0, nil, 0, nil
            for _, s in ipairs(slots) do
                progress = math.max(progress, s.progress)
                if s.done then
                    done = done + 1
                    if s.level and s.level > 0 then best = math.max(best or 0, s.level) end
                elseif not nextT then
                    nextT = s.threshold
                end
            end
            unlocked = unlocked + done
            cats[#cats + 1] = { t = t, slots = slots, done = done, nextT = nextT, progress = progress, best = best,
                                remaining = nextT and (nextT - progress) or math.huge }
        end
    end
    table.sort(cats, function(a, b) return a.remaining < b.remaining end)
    return cats, unlocked
end

function AC:VaultRows(rows)
    local L, W = ns.L, ns.Weekly
    local cats, unlocked = self:VaultCategories()

    rows[#rows + 1] = { header = L.ACT_VAULT }
    if W:VaultReady() then rows[#rows + 1] = { kind = "callout", style = "tip", text = L.VAULT_READY } end
    if #cats == 0 then
        rows[#rows + 1] = { kind = "callout", style = "info", text = L.ACT_VAULT_NONE }
    else
        local first = cats[1]
        if first.nextT then
            rows[#rows + 1] = { kind = "callout", style = "tip", title = L.ACT_BEST_NOW,
                                text = L.ACT_VAULT_BEST:format(L[first.t.key], first.remaining) }
        end
        for _, c in ipairs(cats) do
            local last = c.slots[#c.slots].threshold
            local ticks = {}
            for _, s in ipairs(c.slots) do ticks[#ticks + 1] = s.threshold end
            rows[#rows + 1] = { kind = "sub", text = L.ACT_VAULT_CAT:format(L[c.t.key], c.done, #c.slots) }
            rows[#rows + 1] = { kind = "bar", min = 0, max = last, value = math.min(c.progress, last), ticks = ticks,
                                color = c.done > 0 and { 0.35, 0.85, 0.45 } or { 0.35, 0.65, 1 },
                                label = L.VAULT_PROGRESS:format(math.min(c.progress, last), last),
                                right = c.nextT and L.VAULT_NEXT:format(c.remaining) or L.VAULT_ALL_DONE }
            local hint = L["ACT_VAULT_HINT_" .. c.t.type]
            if hint then rows[#rows + 1] = { kind = "step", badge = "!", badgeColor = { 0.35, 0.65, 1 }, text = hint } end
            if c.best then rows[#rows + 1] = { kind = "note", text = L["ACT_VAULT_BEST_" .. c.t.type]:format(c.best) } end
        end
        rows[#rows + 1] = { kind = "callout", style = unlocked >= 3 and "tip" or "info",
                            text = unlocked >= 3 and L.ACT_VAULT_ROLL_OK or L.ACT_VAULT_ROLL:format(3 - unlocked) }
    end

    -- livello oggetto della Vault per attivita'
    rows[#rows + 1] = { header = L.ACT_VAULT_LEVELS }
    local widths = { 0.62, 0.38 }
    rows[#rows + 1] = { kind = "thead", widths = widths, cols = { L.ACT_COL_ACTIVITY, L.ACT_COL_VAULT } }
    for _, s in ipairs(L.ACT_VAULT_TABLE) do
        rows[#rows + 1] = { kind = "tr", widths = widths, cols = { s[1], s[2] }, colors = { nil, { 0.6, 0.85, 1 } } }
    end
    self:ChecklistRows(rows, "vault")
end

---------------------------------------------------------------------------
-- Obiettivo: reputazione
---------------------------------------------------------------------------
function AC:Factions()
    local out = {}
    local MF = C_MajorFactions
    if not (MF and MF.GetMajorFactionIDs and MF.GetMajorFactionData) then return out end
    local exp = A.Call(GetServerExpansionLevel) or A.Call(GetExpansionLevel)
    local ids = A.Call(MF.GetMajorFactionIDs, exp)
    if type(ids) ~= "table" then return out end
    for _, id in ipairs(ids) do
        local d = A.Call(MF.GetMajorFactionData, id)
        if type(d) == "table" and d.isUnlocked ~= false then
            local maxed = MF.HasMaximumRenown and A.Call(MF.HasMaximumRenown, id) or false
            local th = tonumber(d.renownLevelThreshold) or 0
            out[#out + 1] = {
                id = id, name = d.name or ("#" .. id), level = d.renownLevel or 0, earned = d.renownReputationEarned or 0,
                threshold = th, maxed = maxed and true or false,
                frac = (th > 0) and (d.renownReputationEarned or 0) / th or 0,
            }
        end
    end
    table.sort(out, function(a, b)
        if a.maxed ~= b.maxed then return not a.maxed end
        return a.frac > b.frac
    end)
    return out
end

-- World quest con reputazione per fazioni non al massimo
function AC:RepQuests(factions)
    local byID, list = {}, {}
    for _, f in ipairs(factions) do byID[f.id] = f end
    for _, q in ipairs(self:Quests()) do
        for _, r in ipairs(q.reps or {}) do
            local f = type(r) == "table" and byID[r.factionID]
            if f and not f.maxed and (r.rewardAmount or 0) > 0 then
                list[#list + 1] = { q = q, f = f, amount = r.rewardAmount }
            end
        end
    end
    table.sort(list, function(a, b)
        if a.f.frac ~= b.f.frac then return a.f.frac > b.f.frac end
        return a.amount > b.amount
    end)
    return list
end

-- World quest con oro, dalla piu' ricca
function AC:GoldQuests()
    local list, total = {}, 0
    for _, q in ipairs(self:Quests()) do
        if (q.money or 0) > 0 then list[#list + 1] = q; total = total + q.money end
    end
    table.sort(list, function(a, b) return a.money > b.money end)
    return list, total
end

function AC:RepRows(rows)
    local L = ns.L
    local factions = self:Factions()

    rows[#rows + 1] = { header = L.ACT_REP }
    if #factions == 0 then
        rows[#rows + 1] = { kind = "callout", style = "info", text = L.ACT_REP_NONE }
    end
    for _, f in ipairs(factions) do
        rows[#rows + 1] = {
            kind = "bar", min = 0, max = math.max(1, f.threshold), value = f.maxed and f.threshold or f.earned,
            color = f.maxed and { 0.6, 0.6, 0.6 } or { 0.35, 0.85, 0.45 },
            label = L.ACT_REP_LINE:format(f.name, f.level),
            right = f.maxed and L.ACT_REP_MAX or L.ACT_REP_LEFT:format(A.Number(f.threshold - f.earned)),
        }
    end

    local list = self:RepQuests(factions)
    rows[#rows + 1] = { kind = "sub", text = L.ACT_REP_QUESTS }
    if #list == 0 then
        rows[#rows + 1] = { kind = "note", text = L.ACT_REP_QUESTS_NONE }
    else
        rows[#rows + 1] = { kind = "callout", style = "tip", title = L.ACT_BEST_NOW,
                            text = L.ACT_REP_BEST:format(list[1].q.name, list[1].amount, list[1].f.name) }
        local widths, align = { 0.42, 0.28, 0.12, 0.18 }, { "LEFT", "LEFT", "RIGHT", "RIGHT" }
        rows[#rows + 1] = { kind = "thead", widths = widths, align = align,
                            cols = { L.ACT_COL_QUEST, L.ACT_COL_FACTION, L.ACT_COL_REP, L.ACT_COL_TIME } }
        for i = 1, math.min(MAX_ROWS, #list) do
            local x = list[i]
            rows[#rows + 1] = QuestRow(x.q, { x.q.name, x.f.name, "+" .. x.amount, TimeLeft(x.q) }, widths, align)
        end
    end
    if self.pending > 0 then rows[#rows + 1] = { kind = "note", text = L.ACT_LOADING:format(self.pending) } end
    self:ChecklistRows(rows, "rep")
end

---------------------------------------------------------------------------
-- Obiettivo: oro
---------------------------------------------------------------------------
function AC:GoldRows(rows)
    local L = ns.L
    local list, total = self:GoldQuests()
    rows[#rows + 1] = { header = L.ACT_GOLD }
    if #list == 0 then
        rows[#rows + 1] = { kind = "callout", style = "info", text = L.ACT_GOLD_NONE }
    else
        rows[#rows + 1] = { kind = "callout", style = "tip", title = L.ACT_BEST_NOW,
                            text = L.ACT_GOLD_BEST:format(#list, A.Money(total)) }
        local widths, align = { 0.52, 0.28, 0.2 }, { "LEFT", "RIGHT", "RIGHT" }
        rows[#rows + 1] = { kind = "thead", widths = widths, align = align, cols = { L.ACT_COL_QUEST, L.ACT_COL_GOLD, L.ACT_COL_TIME } }
        for i = 1, math.min(MAX_ROWS, #list) do
            local q = list[i]
            rows[#rows + 1] = QuestRow(q, { q.name, A.Money(q.money), TimeLeft(q) }, widths, align, nil, { nil, { 1, 0.82, 0 } })
        end
    end
    if self.pending > 0 then rows[#rows + 1] = { kind = "note", text = L.ACT_LOADING:format(self.pending) } end
    rows[#rows + 1] = { kind = "callout", style = "info", text = L.ACT_GOLD_MORE }
    self:ChecklistRows(rows, "gold")
end

---------------------------------------------------------------------------
-- Riepilogo: il meglio di ogni obiettivo, eventi, world quest, settimana
---------------------------------------------------------------------------
-- Ricompensa principale di una world quest, in breve
local function RewardText(q)
    local L = ns.L
    if q.loading then return L.TODAY_LOADING end
    for _, item in ipairs(q.items or {}) do
        if item.equipLoc and SLOTS[item.equipLoc] and item.ilvl then return L.TODAY_REWARD_ITEM:format(item.ilvl) end
    end
    for _, c in ipairs(q.currencies or {}) do
        if type(c) == "table" and CREST_TIER[c.currencyID] then
            return ("%d %s"):format(c.totalRewardAmount or c.quantity or 0, c.name or "?")
        end
    end
    if (q.money or 0) > 0 then return A.Money(q.money) end
    local r = q.reps and q.reps[1]
    if type(r) == "table" and (r.rewardAmount or 0) > 0 then return L.TODAY_REWARD_REP:format(r.rewardAmount) end
    local item = q.items and q.items[1]
    if item then return item.name or "?" end
    return "-"
end

function AC:SummaryRows(rows)
    local L, W, E = ns.L, ns.Weekly, ns.Events
    local function goalStep(label, text)
        rows[#rows + 1] = { kind = "step", badge = label, badgeColor = { 0.35, 0.85, 0.45 }, text = text }
    end

    -- da fare adesso, per obiettivo
    rows[#rows + 1] = { header = L.ACT_BEST_NOW }
    if W:VaultReady() then rows[#rows + 1] = { kind = "callout", style = "tip", text = L.VAULT_READY } end
    local ups = self:GearUpgrades(ns.StatPriority:Current())
    if ups[1] then
        goalStep(L.ACT_GOAL_gear, L.ACT_GEAR_BEST:format(ups[1].item.name or "?", ups[1].e.delta, ups[1].q.name))
    end
    local cats = self:VaultCategories()
    if cats[1] and cats[1].nextT then
        goalStep(L.ACT_GOAL_vault, L.ACT_VAULT_BEST:format(L[cats[1].t.key], cats[1].remaining))
    end
    local reps = self:RepQuests(self:Factions())
    if reps[1] then
        goalStep(L.ACT_GOAL_rep, L.ACT_REP_BEST:format(reps[1].q.name, reps[1].amount, reps[1].f.name))
    end
    local golds, total = self:GoldQuests()
    if golds[1] then goalStep(L.ACT_GOAL_gold, L.ACT_GOLD_BEST:format(#golds, A.Money(total))) end
    if not (ups[1] or (cats[1] and cats[1].nextT) or reps[1] or golds[1]) then
        rows[#rows + 1] = { kind = "note", text = L.TODAY_NOTHING }
    end
    rows[#rows + 1] = { kind = "note", text = L.TODAY_PICK_GOAL }

    -- festivita' ed eventi sulla mappa
    rows[#rows + 1] = { header = L.TODAY_EVENTS }
    local widths, align = { 0.5, 0.3, 0.2 }, { "LEFT", "LEFT", "RIGHT" }
    local hol, evs = E:Holidays(), E:MapEvents()
    if #hol + #evs == 0 then
        rows[#rows + 1] = { kind = "note", text = L.TODAY_NO_EVENTS }
    else
        rows[#rows + 1] = { kind = "thead", widths = widths, align = align, cols = { L.TODAY_COL_EVENT, L.TODAY_COL_WHERE, L.ACT_COL_TIME } }
        for _, h in ipairs(hol) do
            rows[#rows + 1] = { kind = "tr", icon = h.icon, widths = widths, align = align,
                                cols = { h.name, L.TODAY_HOLIDAY, "" }, colors = { { 1, 0.82, 0 } },
                                link = { search = h.name }, linkTitle = h.name }
        end
        for _, e in ipairs(evs) do
            rows[#rows + 1] = {
                kind = "tr", widths = widths, align = align,
                cols = { e.name, e.zone or "", e.secondsLeft and A.TimeText(e.secondsLeft) or "" },
                colors = { e.current and { 0.4, 1, 0.4 } or nil },
                tooltip = { e.name, e.zone, e.description },
                waypoint = e.x and { e.mapID, e.x, e.y, e.name } or nil,
                link = { search = e.name }, linkTitle = e.name,
            }
        end
    end

    -- world quest in scadenza, con la ricompensa
    local quests = {}
    for _, q in ipairs(self:Quests()) do quests[#quests + 1] = q end
    table.sort(quests, function(a, b) return (a.secondsLeft or 1e9) < (b.secondsLeft or 1e9) end)
    rows[#rows + 1] = { header = L.TODAY_WORLD_QUESTS:format(#quests) }
    if #quests == 0 then
        rows[#rows + 1] = { kind = "note", text = L.NO_WORLD_QUESTS }
    else
        local w2, a2 = { 0.42, 0.24, 0.2, 0.14 }, { "LEFT", "LEFT", "LEFT", "RIGHT" }
        rows[#rows + 1] = { kind = "thead", widths = w2, align = a2,
                            cols = { L.ACT_COL_QUEST, L.ACT_COL_REWARD, L.TODAY_COL_WHERE, L.ACT_COL_TIME } }
        for i = 1, math.min(15, #quests) do
            local q = quests[i]
            local name = q.elite and (q.name .. " (" .. L.ELITE .. ")") or q.name
            rows[#rows + 1] = QuestRow(q, { name, RewardText(q), q.zone or "", TimeLeft(q) }, w2, a2, nil,
                                       { q.elite and { 0.8, 0.5, 1 } or nil })
        end
        if #quests > 15 then rows[#rows + 1] = { kind = "note", text = L.TODAY_MORE_QUESTS:format(#quests - 15) } end
    end
    if self.pending > 0 then rows[#rows + 1] = { kind = "note", text = L.ACT_LOADING:format(self.pending) } end

    -- la settimana: Traveler's Log e reset
    rows[#rows + 1] = { header = L.TODAY_WEEK }
    local log = W:TravelersLog()
    if log and log.total > 0 then
        rows[#rows + 1] = { kind = "bar", min = 0, max = log.total, value = log.done, color = { 1, 0.75, 0.3 },
                            label = L.LOG_PROGRESS:format(log.month, log.done, log.total, log.points),
                            right = log.secondsLeft and L.TIME_LEFT:format(A.TimeText(log.secondsLeft)) or nil }
    end
    local daily, weekly = W:Resets()
    local w3 = { 0.6, 0.4 }
    if daily then rows[#rows + 1] = { kind = "tr", widths = w3, align = { "LEFT", "RIGHT" }, cols = { L.TODAY_RESET_DAILY, A.TimeText(daily) } } end
    if weekly then rows[#rows + 1] = { kind = "tr", widths = w3, align = { "LEFT", "RIGHT" }, cols = { L.TODAY_RESET_WEEKLY, A.TimeText(weekly) } } end
end

---------------------------------------------------------------------------
-- Scheda
---------------------------------------------------------------------------
function AC:Rows()
    local L, rows = ns.L, {}
    local goal = ns.db.actGoal or "summary"
    local items = {}
    for _, g in ipairs(GOALS) do
        items[#items + 1] = { label = L["ACT_GOAL_" .. g], selected = g == goal, onClick = function() ns.db.actGoal = g end }
    end
    rows[#rows + 1] = { kind = "pills", items = items }
    rows[#rows + 1] = { kind = "note", text = L["ACT_GOAL_DESC_" .. goal] }
    if goal == "summary" then self:SummaryRows(rows)
    elseif goal == "vault" then self:VaultRows(rows)
    elseif goal == "rep" then self:RepRows(rows)
    elseif goal == "gold" then self:GoldRows(rows)
    else self:GearRows(rows) end
    rows[#rows + 1] = { kind = "note", text = L.ACT_NOTE }
    return rows
end
