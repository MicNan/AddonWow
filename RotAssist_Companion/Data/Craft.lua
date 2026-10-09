-- RotAssist Companion - Craft
-- Scheda "Professioni": per ogni professione del personaggio
--  * la fase della guida in cui ti trovi (CraftGuide.lua);
--  * cosa creare adesso per salire spendendo poco: si calcola dalle ricette
--    che conosci, lette quando apri la finestra della professione (colore
--    della ricetta = punti attesi, prezzi d'asta dei materiali);
--  * cosa comprare: i materiali che servono meno quelli che hai gia' in
--    borse, banca, banca dei reagenti e banca della brigata;
--  * la specializzazione consigliata per l'equipaggiamento del personaggio.
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

local function PhaseOf(phases, level)
    for i, ph in ipairs(phases) do
        if level < ph[2] or i == #phases then return ph, phases[i + 1] end
    end
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

function C:SpecRows(rows, key, childID)
    local L = ns.L
    local guide = ns.CraftGuide:Text(key)
    if not (guide and guide.specs) then return end
    local _, class = A.Call(UnitClass, "player")
    local getSpec = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
    local getInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
    local index = A.Call(getSpec)
    local specID = index and A.Call(getInfo, index)
    local tip = { L.CRAFT_SPECS_ALL }
    for _, line in ipairs(guide.specs) do tip[#tip + 1] = "- " .. line end
    if guide.unlock then tip[#tip + 1] = guide.unlock end
    -- nomi delle specializzazioni nel tuo client (possono essere tradotti)
    if C_ProfSpecs and C_ProfSpecs.GetSpecTabIDsForSkillLine and C_ProfSpecs.GetTabInfo and childID then
        local tabs = A.Call(C_ProfSpecs.GetSpecTabIDsForSkillLine, childID)
        local names = {}
        if type(tabs) == "table" then
            for _, tabID in ipairs(tabs) do
                local info = A.Call(C_ProfSpecs.GetTabInfo, tabID)
                if type(info) == "table" and info.name then names[#names + 1] = info.name end
            end
        end
        if #names > 0 then tip[#tip + 1] = L.CRAFT_SPECS_CLIENT:format(table.concat(names, ", ")) end
    end
    for _, adv in ipairs(ns.CraftGuide:Advice(key, class, specID)) do
        rows[#rows + 1] = { text = L[adv], wrap = true, color = { 0.6, 1, 0.6 }, tooltip = tip }
    end
end

function C:ProfessionRows(rows, p)
    local L = ns.L
    local key = p.key
    local guide = key and ns.CraftGuide:Text(key)
    local scan = ns.db.craft and ns.db.craft[p.skillLine]
    local level = (scan and scan.level) or p.rank or 0
    local max = (scan and scan.max) or p.max or 100
    local knowledge = ns.Gold:Knowledge(p.skillLine)
    rows[#rows + 1] = { header = L.HDR_CRAFT_PROF:format(p.name, level, max) }
    if knowledge and knowledge > 0 then
        rows[#rows + 1] = { text = L.KNOWLEDGE:format(knowledge), color = { 1, 0.82, 0 } }
    end
    if not guide then
        rows[#rows + 1] = { text = L.CRAFT_NO_GUIDE, dim = true }
        return
    end

    -- fase della guida
    if guide.phases then
        local ph, nextPh = PhaseOf(guide.phases, level)
        if level >= max then
            rows[#rows + 1] = { text = L.CRAFT_MAXED, color = { 0.5, 0.9, 0.5 } }
        elseif ph then
            local tip = { L.CRAFT_TRAINER:format(guide.trainer) }
            for _, x in ipairs(guide.phases) do tip[#tip + 1] = ("%d-%d: %s"):format(x[1], x[2], x[3]) end
            rows[#rows + 1] = { text = L.CRAFT_PHASE:format(ph[1], ph[2], ph[3]), wrap = true, tooltip = tip,
                                link = { search = p.name }, linkTitle = p.name }
            if nextPh then
                rows[#rows + 1] = { text = L.CRAFT_NEXT:format(nextPh[1], nextPh[3]), wrap = true, dim = true }
            end
        end
    end
    if guide.tips then rows[#rows + 1] = { text = guide.tips, wrap = true, dim = true } end
    rows[#rows + 1] = { text = L.CRAFT_TRAINER:format(guide.trainer), dim = true }

    -- cosa creare e cosa comprare (solo professioni di creazione)
    if not ns.CraftGuide.GATHERING[p.skillLine] then
        if self.otherExpansion and self.otherExpansion.base == p.skillLine then
            rows[#rows + 1] = { text = L.CRAFT_OTHER_EXPANSION:format(self.otherExpansion.name or "?"),
                                wrap = true, color = { 1, 0.6, 0.2 } }
        end
        local plan = self:Plan(p.skillLine)
        if not plan then
            rows[#rows + 1] = { text = L.CRAFT_OPEN, wrap = true, color = { 0.5, 0.85, 1 } }
        else
            self:PlanRows(rows, plan)
        end
        self:SpecRows(rows, key, ns.CraftGuide.MIDNIGHT[p.skillLine])
    end
end

function C:PlanRows(rows, plan)
    local L = ns.L
    local cache = {}
    local age = time() - (plan.scan.time or time())
    rows[#rows + 1] = { text = L.CRAFT_SCAN_AGE:format(A.TimeText(math.max(60, age))), dim = true }
    -- senza prezzi i costi restano "prezzo?": serve la casa d'aste aperta
    local hasPrices = (ns.Prices:ScanAge() or (Auctionator and Auctionator.API) or TSM_API) and true or false
    if not hasPrices then
        rows[#rows + 1] = { text = L.CRAFT_NEED_PRICES, wrap = true, color = { 0.5, 0.85, 1 } }
    end

    -- prime creazioni: punti conoscenza
    if #plan.firsts > 0 then
        rows[#rows + 1] = { text = L.CRAFT_FIRSTS:format(#plan.firsts), color = { 1, 0.82, 0 } }
        for i = 1, math.min(MAX_FIRST, #plan.firsts) do
            local e = plan.firsts[i]
            local tip = { e.recipe.name, L.CRAFT_FIRST_TIP }
            for _, l in ipairs(ReagentLines(e.recipe, cache)) do tip[#tip + 1] = l end
            rows[#rows + 1] = {
                text = "   " .. e.recipe.name, icon = e.recipe.icon,
                right = e.canCraft > 0 and L.CRAFT_READY or (e.cost and A.Money(e.cost) or ""),
                color = DIFF_COLOR[e.recipe.diff], tooltip = tip,
                link = { spell = e.recipe.id }, linkTitle = e.recipe.name,
            }
        end
        if #plan.firsts > MAX_FIRST then
            rows[#rows + 1] = { text = L.CRAFT_MORE:format(#plan.firsts - MAX_FIRST), dim = true }
        end
    end

    -- ricette migliori per salire
    if #plan.best == 0 then
        rows[#rows + 1] = { text = L.CRAFT_NO_SKILLUPS, wrap = true, dim = true }
    else
        rows[#rows + 1] = { text = L.CRAFT_BEST, color = { 1, 0.82, 0 } }
        for i = 1, math.min(MAX_BEST, #plan.best) do
            local e = plan.best[i]
            local tip = { e.recipe.name, L["CRAFT_DIFF_" .. e.recipe.diff]:format(e.points) }
            for _, l in ipairs(ReagentLines(e.recipe, cache)) do tip[#tip + 1] = l end
            if e.cost then tip[#tip + 1] = L.CRAFT_COST:format(A.Money(e.cost)) end
            if e.canCraft > 0 then tip[#tip + 1] = L.CRAFT_CAN:format(e.canCraft) end
            if i == 1 then tip[#tip + 1] = L.CRAFT_TIMES:format(plan.topCrafts) end
            rows[#rows + 1] = {
                text = "   " .. e.recipe.name, icon = e.recipe.icon,
                right = e.perPoint and L.CRAFT_PER_POINT:format(A.Money(e.perPoint)) or L.CRAFT_NO_PRICE,
                color = DIFF_COLOR[e.recipe.diff], tooltip = tip,
                link = { spell = e.recipe.id }, linkTitle = e.recipe.name,
            }
        end
        rows[#rows + 1] = { text = L.CRAFT_TOP:format(plan.top.recipe.name, plan.topCrafts), wrap = true }
    end

    -- lista della spesa
    if #plan.shopping == 0 then
        rows[#rows + 1] = { text = L.CRAFT_SHOP_NONE, color = { 0.5, 0.9, 0.5 } }
    else
        rows[#rows + 1] = { text = plan.total > 0 and L.CRAFT_SHOP:format(A.Money(plan.total)) or L.CRAFT_SHOP_PLAIN,
                            color = { 1, 0.82, 0 } }
        for _, s in ipairs(plan.shopping) do
            local name = ItemName(s.itemID)
            rows[#rows + 1] = {
                text = L.CRAFT_BUY:format(s.missing, name), right = s.cost and A.Money(s.cost) or (hasPrices and L.CRAFT_VENDOR or L.CRAFT_NO_PRICE),
                tooltip = { name, L.CRAFT_BUY_TIP:format(s.need, s.have, s.missing) },
                link = { item = s.itemID }, linkTitle = name,
            }
        end
        if plan.unknown > 0 and hasPrices then rows[#rows + 1] = { text = L.CRAFT_SHOP_UNKNOWN, wrap = true, dim = true } end
    end
end

function C:Rows()
    local L, rows = ns.L, {}
    local profs = ns.Gold:Professions()
    local shown = 0
    for _, p in ipairs(profs) do
        if p.key and p.key ~= "cooking" and p.key ~= "fishing" then
            self:ProfessionRows(rows, p)
            shown = shown + 1
        end
    end
    if shown == 0 then
        rows[#rows + 1] = { header = L.HDR_CRAFT }
        rows[#rows + 1] = { text = L.CRAFT_NONE, wrap = true, dim = true }
    end
    rows[#rows + 1] = { header = L.HDR_CRAFT_KNOWLEDGE }
    for _, line in ipairs(ns.CraftGuide:Text("knowledge")) do
        rows[#rows + 1] = { text = "- " .. line, wrap = true }
    end
    rows[#rows + 1] = { header = "" }
    rows[#rows + 1] = { text = L.CRAFT_NOTE, wrap = true, dim = true }
    return rows
end
