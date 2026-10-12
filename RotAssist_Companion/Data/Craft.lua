-- RotAssist Companion - Craft
-- Scheda "Professioni": per ogni professione del personaggio
--  * la fase della guida in cui ti trovi (CraftGuide.lua);
--  * cosa creare adesso per salire spendendo poco: si calcola dalle ricette
--    che conosci, lette quando apri la finestra della professione (colore
--    della ricetta = punti attesi, prezzi d'asta dei materiali);
--  * cosa comprare: i materiali che servono meno quelli che hai gia' in
--    borse, banca, banca dei reagenti e banca della brigata;
--  * la specializzazione consigliata per l'equipaggiamento del personaggio e
--    le build delle specializzazioni, fase per fase (CraftBuilds.lua);
--  * le fonti dei punti conoscenza.
-- Selettori in alto: professione e sezione (livellamento, cosa creare,
-- specializzazioni, conoscenza), ricordati in RotAssistCompanionDB.
-- Solo lettura: l'addon non crea nulla e non compra nulla.

local _, ns = ...
local A = ns.API

local C = { pending = false }
ns.Craft = C

local TRIVIAL = 3                      -- Enum.TradeskillRelativeDifficulty: 0 arancione, 1 giallo, 2 verde, 3 grigio
local CHANCE = { [0] = 1, [1] = 0.5, [2] = 0.15 }   -- probabilita' stimata di un punto
local PLAN_POINTS = 10                 -- la lista della spesa copre i prossimi 10 punti
local MAX_BEST, MAX_FIRST = 5, 8       -- righe mostrate

---------------------------------------------------------------------------
-- Lettura delle ricette (finestra della professione aperta)
---------------------------------------------------------------------------
function C:RequestScan()
    if self.pending then return end
    self.pending = true
    ns:After(1, function() C.pending = false; C:Scan() end)
end

local function BasicSlot(slot)
    if type(slot) ~= "table" or type(slot.reagents) ~= "table" then return false end
    if slot.required ~= nil then return slot.required and true or false end
    local basic = (Enum and Enum.CraftingReagentType and Enum.CraftingReagentType.Basic) or 1
    return slot.reagentType == basic
end

-- Ricetta utile: imparata e che da' ancora punti o la prima creazione.
function C:ReadRecipe(recipeID, childID)
    local T = C_TradeSkillUI
    if T.IsRecipeInSkillLine then
        if not A.Call(T.IsRecipeInSkillLine, recipeID, childID) then return nil end
    elseif T.GetTradeSkillLineForRecipe then
        if A.Call(T.GetTradeSkillLineForRecipe, recipeID) ~= childID then return nil end
    end
    local info = A.Call(T.GetRecipeInfo, recipeID)
    if type(info) ~= "table" or not info.learned then return nil end
    if info.isRecraft or info.isSalvageRecipe or info.isGatheringRecipe or info.isDummyRecipe then return nil end
    local diff = tonumber(info.relativeDifficulty) or TRIVIAL
    if diff >= TRIVIAL and not info.firstCraft then return nil end
    local r = {
        id = recipeID, name = info.name or ("#" .. recipeID), icon = info.icon,
        diff = diff, ups = math.max(1, tonumber(info.numSkillUps) or 1),
        first = info.firstCraft and true or false, reagents = {},
    }
    local sch = A.Call(T.GetRecipeSchematic, recipeID, false)
    if type(sch) == "table" then
        r.out = sch.outputItemID
        if type(sch.reagentSlotSchematics) == "table" then
            for _, slot in ipairs(sch.reagentSlotSchematics) do
                if BasicSlot(slot) then
                    local items = {}
                    for _, rg in ipairs(slot.reagents) do
                        local id = type(rg) == "table" and A.Plain(rg.itemID)
                        if type(id) == "number" then items[#items + 1] = id end
                    end
                    if #items > 0 then
                        r.reagents[#r.reagents + 1] = { items = items, qty = tonumber(slot.quantityRequired) or 1 }
                    end
                end
            end
        end
    end
    return r
end

function C:Scan()
    local T = C_TradeSkillUI
    if not (T and T.GetAllRecipeIDs and T.GetRecipeInfo) or A.InCombat() or not ns.db then return end
    -- professione di un altro giocatore, della gilda o di un PNG: non e' la tua
    if A.Call(T.IsTradeSkillLinked) or A.Call(T.IsTradeSkillGuild) or A.Call(T.IsNPCCrafting) then return end
    local base = A.Call(T.GetBaseProfessionInfo)
    local child = A.Call(T.GetChildProfessionInfo)
    if type(base) ~= "table" or type(child) ~= "table" then return end
    local baseID, childID = base.professionID, child.professionID
    if not (baseID and childID) then return end
    if ns.CraftGuide.MIDNIGHT[baseID] ~= childID then
        -- e' aperta la scheda di un'altra espansione
        self.otherExpansion = { base = baseID, name = child.professionName }
        if ns.Panel then ns.Panel:RequestRefresh() end
        return
    end
    self.otherExpansion = nil
    local ids = A.Call(T.GetAllRecipeIDs)
    if type(ids) ~= "table" then return end
    local recipes = {}
    for _, id in ipairs(ids) do
        local ok, r = pcall(self.ReadRecipe, self, id, childID)
        if ok and r then recipes[#recipes + 1] = r end
    end
    ns.db.craft = ns.db.craft or {}
    ns.db.craft[baseID] = {
        child = childID, name = child.professionName,
        level = tonumber(child.skillLevel), max = tonumber(child.maxSkillLevel),
        time = time(), recipes = recipes,
    }
    ns:Log(("[prof] %s %s/%s: %d ricette utili"):format(tostring(child.professionName),
        tostring(child.skillLevel), tostring(child.maxSkillLevel), #recipes))
    if ns.Panel then ns.Panel:RequestRefresh() end
end

---------------------------------------------------------------------------
-- Calcolo: costo per punto e lista della spesa
---------------------------------------------------------------------------
-- Quanti ne hai (borse, banca, banca dei reagenti, banca della brigata)
local function Have(itemID, cache)
    if cache[itemID] then return cache[itemID] end
    local n
    if C_Item and C_Item.GetItemCount then n = A.Call(C_Item.GetItemCount, itemID, true, false, true, true) end
    if type(n) ~= "number" and GetItemCount then n = A.Call(GetItemCount, itemID, true) end
    n = type(n) == "number" and n or 0
    cache[itemID] = n
    return n
end

-- Materiale con piu' qualita': si contano tutte, si compra la piu' economica.
local function SlotInfo(slot, cache)
    local have, price, cheapest = 0, nil, slot.items[1]
    for _, id in ipairs(slot.items) do
        have = have + Have(id, cache)
        local p = ns.Prices:Get(id)
        if p and (not price or p < price) then price, cheapest = p, id end
    end
    return have, price, cheapest
end

function C:Evaluate(recipe, cache)
    local cost, known, crafts = 0, true, math.huge
    for _, slot in ipairs(recipe.reagents) do
        local have, price = SlotInfo(slot, cache)
        if price then cost = cost + price * slot.qty else known = false end
        crafts = math.min(crafts, math.floor(have / slot.qty))
    end
    if #recipe.reagents == 0 then crafts, known = 0, false end
    local points = recipe.diff < TRIVIAL and (CHANCE[recipe.diff] or 0) * recipe.ups or 0
    return {
        recipe = recipe, cost = known and cost or nil, points = points,
        perPoint = (known and points > 0) and cost / points or nil,
        canCraft = crafts == math.huge and 0 or crafts,
    }
end

-- Piano per una professione letta: prime creazioni, ricette migliori, spesa.
function C:Plan(baseID)
    local scan = ns.db.craft and ns.db.craft[baseID]
    if not scan then return nil end
    local cache, firsts, best = {}, {}, {}
    for _, r in ipairs(scan.recipes) do
        local e = self:Evaluate(r, cache)
        if r.first then firsts[#firsts + 1] = e end
        if e.points > 0 then best[#best + 1] = e end
    end
    table.sort(best, function(a, b)
        if (a.perPoint ~= nil) ~= (b.perPoint ~= nil) then return a.perPoint ~= nil end
        if a.perPoint and b.perPoint and a.perPoint ~= b.perPoint then return a.perPoint < b.perPoint end
        if a.recipe.diff ~= b.recipe.diff then return a.recipe.diff < b.recipe.diff end
        return a.recipe.name < b.recipe.name
    end)
    table.sort(firsts, function(a, b) return (a.cost or math.huge) < (b.cost or math.huge) end)

    -- lista della spesa: una volta ogni prima creazione + la ricetta migliore
    -- per i prossimi punti
    local needs, order = {}, {}
    local function need(slot, amount)
        local key = table.concat(slot.items, ",")
        if not needs[key] then needs[key] = { slot = slot, qty = 0 }; order[#order + 1] = key end
        needs[key].qty = needs[key].qty + amount
    end
    for _, e in ipairs(firsts) do
        for _, slot in ipairs(e.recipe.reagents) do need(slot, slot.qty) end
    end
    local top, topCrafts = best[1], 0
    if top then
        local left = math.max(1, math.min(PLAN_POINTS, (scan.max or 100) - (scan.level or 0)))
        topCrafts = math.ceil(left / top.points)
        for _, slot in ipairs(top.recipe.reagents) do need(slot, slot.qty * topCrafts) end
    end
    local shopping, total, unknown = {}, 0, 0
    for _, key in ipairs(order) do
        local n = needs[key]
        local have, price, cheapest = SlotInfo(n.slot, cache)
        local missing = math.max(0, n.qty - have)
        if missing > 0 then
            shopping[#shopping + 1] = { itemID = cheapest, need = n.qty, have = have, missing = missing,
                                        cost = price and price * missing or nil }
            if price then total = total + price * missing else unknown = unknown + 1 end
        end
    end
    table.sort(shopping, function(a, b) return (a.cost or 0) > (b.cost or 0) end)
    return { scan = scan, firsts = firsts, best = best, top = top, topCrafts = topCrafts,
             shopping = shopping, total = total, unknown = unknown }
end

---------------------------------------------------------------------------
-- Righe della scheda
---------------------------------------------------------------------------
local function ItemName(itemID)
    local info = ns.Prices:ItemInfo(itemID)
    return info and info.name or ("item:" .. tostring(itemID))
end

local DIFF_COLOR = { [0] = { 1, 0.5, 0.25 }, [1] = { 1, 1, 0 }, [2] = { 0.25, 0.75, 0.25 }, [3] = { 0.6, 0.6, 0.6 } }
local SECTIONS = { "level", "make", "specs", "knowledge" }
-- tonalita' delle fasi nella barra dei livelli (dalla prima all'ultima)
local PHASE_COLORS = { { 0.55, 0.75, 1 }, { 0.4, 0.62, 0.95 }, { 0.3, 0.5, 0.85 }, { 0.22, 0.4, 0.75 }, { 0.16, 0.32, 0.65 } }

local function PhaseIndex(phases, level)
    for i, ph in ipairs(phases) do
        if level < ph[2] then return i end
    end
    return #phases
end

local function HasPrices()
    return (ns.Prices:ScanAge() or (Auctionator and Auctionator.API) or TSM_API) and true or false
end

-- Dettaglio dei materiali per una creazione (tooltip)
local function ReagentLines(recipe, cache)
    local L, lines = ns.L, {}
    for _, slot in ipairs(recipe.reagents) do
        local have, price, cheapest = SlotInfo(slot, cache)
        lines[#lines + 1] = L.CRAFT_REAGENT:format(slot.qty, ItemName(cheapest), have,
            price and A.Money(price) or L.CRAFT_NO_PRICE)
    end
    return lines
end

local function PlayerSpec()
    local _, class = A.Call(UnitClass, "player")
    local getSpec = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
    local getInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
    local index = A.Call(getSpec)
    return class, index and A.Call(getInfo, index)
end

-- Professioni mostrate (cucina e pesca escluse) e quella selezionata
function C:Selected(profs)
    local list = {}
    for _, p in ipairs(profs) do
        if p.key and p.key ~= "cooking" and p.key ~= "fishing" then list[#list + 1] = p end
    end
    local sel = list[1]
    for _, p in ipairs(list) do
        if p.skillLine == ns.db.craftProf then sel = p end
    end
    return list, sel
end

---------------------------------------------------------------------------
-- Sezione: livellamento
---------------------------------------------------------------------------
function C:LevelRows(rows, p, guide, level, max)
    local L = ns.L
    local phases = guide.phases or {}
    if #phases > 0 then
        local cur = PhaseIndex(phases, level)
        local segments = {}
        for i, ph in ipairs(phases) do
            local c = PHASE_COLORS[math.min(i, #PHASE_COLORS)]
            segments[#segments + 1] = { ph[1] - 1, ph[2], c, i == cur and 1 or 0.45 }
        end
        rows[#rows + 1] = { kind = "bar", min = 0, max = max > 0 and max or 100, segments = segments, marker = level,
                            label = L.CRAFT_BAR_LABEL:format(level, max), right = L.CRAFT_BAR_PHASE:format(phases[cur][1], phases[cur][2]) }
        if level >= max then
            rows[#rows + 1] = { kind = "callout", style = "tip", title = L.CRAFT_MAXED_TITLE, text = L.CRAFT_MAXED }
        else
            local ph = phases[cur]
            rows[#rows + 1] = { kind = "callout", style = "info", title = L.CRAFT_NOW:format(ph[1], ph[2]), text = ph[3] }
            local nextPh = phases[cur + 1]
            if nextPh then
                rows[#rows + 1] = { kind = "step", badge = tostring(nextPh[1]), badgeColor = { 0.6, 0.6, 0.6 },
                                    text = L.CRAFT_NEXT:format(nextPh[3]), color = { 0.75, 0.75, 0.75 } }
            end
        end
    end
    if guide.tips then rows[#rows + 1] = { kind = "callout", style = "tip", text = guide.tips } end
    rows[#rows + 1] = { text = L.CRAFT_TRAINER:format(guide.trainer), icon = "Interface\\Icons\\INV_Misc_Book_09", dim = true }

    -- tutte le fasi, per avere il quadro completo
    rows[#rows + 1] = { kind = "sub", text = L.CRAFT_ALL_PHASES }
    for _, ph in ipairs(phases) do
        rows[#rows + 1] = { kind = "step", badge = ("%d-%d"):format(ph[1], ph[2]), text = ph[3],
                            badgeColor = (level >= ph[1] - 1 and level < ph[2]) and { 0.35, 0.65, 1 } or { 0.6, 0.6, 0.6 } }
    end
end

---------------------------------------------------------------------------
-- Sezione: cosa creare e cosa comprare
---------------------------------------------------------------------------
function C:MakeRows(rows, p)
    local L = ns.L
    if self.otherExpansion and self.otherExpansion.base == p.skillLine then
        rows[#rows + 1] = { kind = "callout", style = "warn", text = L.CRAFT_OTHER_EXPANSION:format(self.otherExpansion.name or "?") }
    end
    local plan = self:Plan(p.skillLine)
    if not plan then
        rows[#rows + 1] = { kind = "callout", style = "info", title = L.CRAFT_OPEN_TITLE, text = L.CRAFT_OPEN }
        return
    end
    local hasPrices = HasPrices()
    if not hasPrices then
        rows[#rows + 1] = { kind = "callout", style = "info", title = L.CRAFT_NEED_PRICES_TITLE, text = L.CRAFT_NEED_PRICES }
    end
    local cache = {}
    local age = time() - (plan.scan.time or time())

    -- l'azione da fare subito
    if plan.top then
        rows[#rows + 1] = { kind = "callout", style = "tip", title = L.CRAFT_TOP_TITLE,
                            text = L.CRAFT_TOP:format(plan.top.recipe.name, plan.topCrafts) }
    else
        rows[#rows + 1] = { kind = "callout", style = "warn", text = L.CRAFT_NO_SKILLUPS }
    end

    -- ricette per salire
    if #plan.best > 0 then
        rows[#rows + 1] = { kind = "sub", text = L.CRAFT_BEST }
        local widths, align = { 0.56, 0.16, 0.28 }, { "LEFT", "RIGHT", "RIGHT" }
        rows[#rows + 1] = { kind = "thead", cols = { L.CRAFT_COL_RECIPE, L.CRAFT_COL_POINTS, L.CRAFT_COL_PER_POINT },
                            widths = widths, align = align }
        for i = 1, math.min(MAX_BEST, #plan.best) do
            local e = plan.best[i]
            local tip = { e.recipe.name, L["CRAFT_DIFF_" .. e.recipe.diff]:format(e.points) }
            for _, l in ipairs(ReagentLines(e.recipe, cache)) do tip[#tip + 1] = l end
            if e.cost then tip[#tip + 1] = L.CRAFT_COST:format(A.Money(e.cost)) end
            if e.canCraft > 0 then tip[#tip + 1] = L.CRAFT_CAN:format(e.canCraft) end
            rows[#rows + 1] = {
                kind = "tr", icon = e.recipe.icon, widths = widths, align = align,
                cols = { e.recipe.name, ("%.2g"):format(e.points), e.perPoint and A.Money(e.perPoint) or L.CRAFT_NO_PRICE },
                colors = { DIFF_COLOR[e.recipe.diff] },
                tooltip = tip, link = { spell = e.recipe.id }, linkTitle = e.recipe.name,
            }
        end
    end

    -- prime creazioni
    if #plan.firsts > 0 then
        rows[#rows + 1] = { kind = "sub", text = L.CRAFT_FIRSTS:format(#plan.firsts) }
        local widths, align = { 0.7, 0.3 }, { "LEFT", "RIGHT" }
        rows[#rows + 1] = { kind = "thead", cols = { L.CRAFT_COL_RECIPE, L.CRAFT_COL_STATUS }, widths = widths, align = align }
        for i = 1, math.min(MAX_FIRST, #plan.firsts) do
            local e = plan.firsts[i]
            local tip = { e.recipe.name, L.CRAFT_FIRST_TIP }
            for _, l in ipairs(ReagentLines(e.recipe, cache)) do tip[#tip + 1] = l end
            local status = e.canCraft > 0 and L.CRAFT_READY or (e.cost and A.Money(e.cost) or L.CRAFT_NO_PRICE)
            rows[#rows + 1] = {
                kind = "tr", icon = e.recipe.icon, widths = widths, align = align,
                cols = { e.recipe.name, status },
                colors = { DIFF_COLOR[e.recipe.diff], e.canCraft > 0 and { 0.4, 1, 0.4 } or nil },
                tooltip = tip, link = { spell = e.recipe.id }, linkTitle = e.recipe.name,
            }
        end
        if #plan.firsts > MAX_FIRST then
            rows[#rows + 1] = { kind = "note", text = L.CRAFT_MORE:format(#plan.firsts - MAX_FIRST) }
        end
    end

    -- lista della spesa
    if #plan.shopping == 0 then
        rows[#rows + 1] = { kind = "callout", style = "tip", text = L.CRAFT_SHOP_NONE }
    else
        rows[#rows + 1] = { kind = "sub", text = plan.total > 0 and L.CRAFT_SHOP:format(A.Money(plan.total)) or L.CRAFT_SHOP_PLAIN }
        local widths, align = { 0.12, 0.52, 0.14, 0.22 }, { "RIGHT", "LEFT", "RIGHT", "RIGHT" }
        rows[#rows + 1] = { kind = "thead", widths = widths, align = align,
                            cols = { L.CRAFT_COL_QTY, L.CRAFT_COL_ITEM, L.CRAFT_COL_HAVE, L.CRAFT_COL_COST } }
        for _, s in ipairs(plan.shopping) do
            local name = ItemName(s.itemID)
            rows[#rows + 1] = {
                kind = "tr", widths = widths, align = align,
                cols = { tostring(s.missing), name, tostring(s.have),
                         s.cost and A.Money(s.cost) or (hasPrices and L.CRAFT_VENDOR or L.CRAFT_NO_PRICE) },
                tooltip = { name, L.CRAFT_BUY_TIP:format(s.need, s.have, s.missing) },
                link = { item = s.itemID }, linkTitle = name,
            }
        end
        if plan.unknown > 0 and hasPrices then rows[#rows + 1] = { kind = "note", text = L.CRAFT_SHOP_UNKNOWN } end
    end
    rows[#rows + 1] = { kind = "note", text = L.CRAFT_SCAN_AGE:format(A.TimeText(math.max(60, age))) }
end

---------------------------------------------------------------------------
-- Sezione: specializzazioni e build
---------------------------------------------------------------------------
function C:SpecRows(rows, p, guide)
    local L = ns.L
    local key = p.key
    local childID = ns.CraftGuide.MIDNIGHT[p.skillLine]
    -- consiglio per il personaggio
    local class, specID = PlayerSpec()
    local advice, suggested = ns.CraftGuide:Advice(key, class, specID)
    if #advice > 0 then
        local lines = {}
        for _, k in ipairs(advice) do lines[#lines + 1] = L[k] end
        rows[#rows + 1] = { kind = "callout", style = "tip", title = L.CRAFT_FOR_YOU, text = table.concat(lines, "\n") }
    end

    -- panoramica delle specializzazioni
    if guide.specs then
        rows[#rows + 1] = { kind = "sub", text = L.CRAFT_SPECS_OVERVIEW }
        for _, line in ipairs(guide.specs) do
            local name, desc = line:match("^(.-):%s*(.*)$")
            rows[#rows + 1] = { kind = "step", badge = "-", badgeColor = { 0.35, 0.65, 1 },
                                text = name and ("|cffffd100" .. name .. "|r  " .. desc) or line }
        end
        if guide.unlock then rows[#rows + 1] = { kind = "note", text = guide.unlock } end
        -- nomi nel client (possono essere tradotti)
        if C_ProfSpecs and C_ProfSpecs.GetSpecTabIDsForSkillLine and C_ProfSpecs.GetTabInfo and childID then
            local tabs = A.Call(C_ProfSpecs.GetSpecTabIDsForSkillLine, childID)
            local names = {}
            if type(tabs) == "table" then
                for _, tabID in ipairs(tabs) do
                    local info = A.Call(C_ProfSpecs.GetTabInfo, tabID)
                    if type(info) == "table" and info.name then names[#names + 1] = info.name end
                end
            end
            if #names > 0 then rows[#rows + 1] = { kind = "note", text = L.CRAFT_SPECS_CLIENT:format(table.concat(names, ", ")) } end
        end
    end

    -- quale build scegliere
    local builds = ns.CraftBuilds:Get(key)
    if not builds then return end
    rows[#rows + 1] = { kind = "sub", text = L.CRAFT_WHICH_BUILD }
    local widths = { 0.4, 0.6 }
    for i, b in ipairs(builds) do
        rows[#rows + 1] = { kind = "tr", widths = widths, cols = { b.name, b.use },
                            colors = { i == suggested and { 0.4, 1, 0.4 } or { 1, 0.82, 0 }, { 0.8, 0.8, 0.8 } } }
    end
    ns.db.craftBuild = ns.db.craftBuild or {}
    local chosen = ns.db.craftBuild[key]
    if not (chosen and builds[chosen]) then chosen = suggested end
    local items = {}
    for i, b in ipairs(builds) do
        items[#items + 1] = { label = b.short or b.name, selected = i == chosen,
                              onClick = function() ns.db.craftBuild[key] = i end }
    end
    rows[#rows + 1] = { kind = "pills", items = items }
    local b = builds[chosen]
    rows[#rows + 1] = { kind = "callout", style = "info", title = b.name, text = b.use }
    local total = 0
    for n, ph in ipairs(b.phases or {}) do
        rows[#rows + 1] = { kind = "phase", text = L.CRAFT_PHASE_TITLE:format(n, ph[1]) }
        for _, st in ipairs(ph[2]) do
            if st[1] then total = total + st[1] end
            rows[#rows + 1] = { kind = "step", badge = st[1] and tostring(st[1]) or "-", text = st[2] }
        end
    end
    for _, note in ipairs(b.notes or {}) do rows[#rows + 1] = { kind = "note", text = note } end
    if total > 0 then rows[#rows + 1] = { kind = "note", text = L.CRAFT_BUILD_TOTAL:format(total) } end
    rows[#rows + 1] = { kind = "note", text = L.CRAFT_SEE_GOLD }
end

---------------------------------------------------------------------------
-- Sezione: punti conoscenza
---------------------------------------------------------------------------
function C:KnowledgeRows(rows, p)
    local L = ns.L
    local widths, align = { 0.5, 0.2, 0.3 }, { "LEFT", "RIGHT", "RIGHT" }
    rows[#rows + 1] = { kind = "thead", widths = widths, align = align,
                        cols = { L.CRAFT_COL_SOURCE, L.CRAFT_COL_KP, L.CRAFT_COL_WHEN } }
    for _, k in ipairs(ns.CraftGuide:Text("knowledge")) do
        rows[#rows + 1] = { kind = "tr", widths = widths, align = align, cols = { k[1], k[2], k[3] } }
    end
    for _, note in ipairs(ns.CraftGuide:Text("knowledgeNotes")) do
        rows[#rows + 1] = { kind = "step", badge = "!", badgeColor = { 0.35, 0.65, 1 }, text = note }
    end
end

---------------------------------------------------------------------------
-- Stato della professione: Concentrazione e punti conoscenza da spendere
---------------------------------------------------------------------------
function C:StatusRows(rows, p)
    local L, G = ns.L, ns.Gold
    local cur, max = G:Concentration(p.skillLine)
    if cur then
        local full = cur >= max
        rows[#rows + 1] = {
            kind = "bar", min = 0, max = max, value = cur,
            color = full and { 1, 0.6, 0.2 } or { 0.35, 0.65, 1 },
            label = L.CONCENTRATION:format(cur, max), labelColor = full and { 1, 0.6, 0.2 } or nil,
            right = full and L.CONC_FULL_SHORT or L.CONC_FULL_IN:format(A.TimeText((max - cur) / G.CONCENTRATION_PER_DAY * 86400)),
        }
    elseif not ns.CraftGuide.GATHERING[p.skillLine] then
        rows[#rows + 1] = { kind = "note", text = L.CONC_UNKNOWN }
    end
    local knowledge = G:Knowledge(p.skillLine)
    if knowledge and knowledge > 0 then
        rows[#rows + 1] = { kind = "callout", style = "warn", text = L.CRAFT_KP_TO_SPEND:format(knowledge) }
    end
end

---------------------------------------------------------------------------
-- Scheda
---------------------------------------------------------------------------
function C:Rows()
    local L, rows = ns.L, {}
    local list, p = self:Selected(ns.Gold:Professions())
    if not p then
        rows[#rows + 1] = { kind = "callout", style = "info", title = L.HDR_CRAFT, text = L.CRAFT_NONE }
        return rows
    end

    -- selettore della professione
    local items = {}
    for _, x in ipairs(list) do
        local scan = ns.db.craft and ns.db.craft[x.skillLine]
        local lvl = (scan and scan.level) or x.rank or 0
        items[#items + 1] = { label = ("%s %d/%d"):format(x.name, lvl, (scan and scan.max) or x.max or 100),
                              selected = x == p, onClick = function() ns.db.craftProf = x.skillLine end }
    end
    rows[#rows + 1] = { kind = "pills", items = items }

    -- selettore della sezione
    local gathering = ns.CraftGuide.GATHERING[p.skillLine]
    local section = ns.db.craftSection or "level"
    if gathering and section == "make" then section = "level" end
    local sItems = {}
    for _, s in ipairs(SECTIONS) do
        if not (gathering and s == "make") then
            sItems[#sItems + 1] = { label = L["CRAFT_SEC_" .. s], selected = s == section,
                                    onClick = function() ns.db.craftSection = s end }
        end
    end
    rows[#rows + 1] = { kind = "pills", items = sItems }

    local guide = p.key and ns.CraftGuide:Text(p.key)
    if not guide then
        rows[#rows + 1] = { kind = "callout", style = "info", text = L.CRAFT_NO_GUIDE }
        return rows
    end
    local scan = ns.db.craft and ns.db.craft[p.skillLine]
    local level = (scan and scan.level) or p.rank or 0
    local max = (scan and scan.max) or p.max or 100

    self:StatusRows(rows, p)
    rows[#rows + 1] = { header = L["CRAFT_SEC_" .. section] }
    if section == "level" then
        self:LevelRows(rows, p, guide, level, max)
    elseif section == "make" then
        self:MakeRows(rows, p)
    elseif section == "specs" then
        self:SpecRows(rows, p, guide)
    else
        self:KnowledgeRows(rows, p)
    end
    return rows
end
