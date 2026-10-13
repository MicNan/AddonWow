-- RotAssist Companion - Orders
-- Ordini di lavoro (crafting orders) per la scheda Professioni, sezione
-- "Ordini". Il server manda gli ordini solo al tavolo degli ordini, quando la
-- finestra di Blizzard li chiede: l'addon legge quello che e' gia' arrivato
-- (C_CraftingOrders.GetCrafterOrders) mentre la finestra e' aperta, senza fare
-- richieste proprie, e lo salva per mostrarlo anche dopo.
--
-- Per ogni ordine: guadagno netto = commissione - quota del Consorzio -
-- materiali che metti tu (ai prezzi d'asta) + valore delle ricompense dei
-- Patron (oggetti ai prezzi d'asta). Solo lettura: accettare e creare restano
-- clic del giocatore.

local _, ns = ...
local A = ns.API

local O = { open = false }
ns.Orders = O

local POLL = 3                         -- secondi tra due letture con la finestra aperta
local AH_CUT = 0.95                    -- commissione della casa d'aste: 5%
local MAX_ROWS = 12

-- Enum.CraftingOrderType: 0 pubblico, 1 gilda, 2 personale, 3 Patron (PNG)
local TYPE_KEYS = { [0] = "public", [1] = "guild", [2] = "personal", [3] = "npc" }
-- Enum.CraftingOrderReagentSource: 1 = messo dal cliente
local SOURCE_CUSTOMER = 1

local function ItemIDFromLink(link)
    if type(link) ~= "string" then return nil end
    local id = C_Item and C_Item.GetItemInfoInstant and A.Call(C_Item.GetItemInfoInstant, link)
    if type(id) == "number" then return id end
    id = link:match("item:(%d+)")
    return id and tonumber(id)
end

-- Professione di un ordine: dalla ricetta letta, altrimenti quella aperta
local function ProfessionOf(spellID)
    for baseID, scan in pairs(ns.db.craft or {}) do
        for _, r in ipairs(scan.recipes or {}) do if r.id == spellID then return baseID, r end end
        for _, r in ipairs(scan.locked or {}) do if r.id == spellID then return baseID, r, true end end
    end
    local base = C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo and A.Call(C_TradeSkillUI.GetBaseProfessionInfo)
    return type(base) == "table" and base.professionID or nil
end

-- Copia semplice di un ordine (niente valori speciali del gioco)
local function Simplify(o)
    local spellID = A.Plain(o.spellID)
    if type(spellID) ~= "number" then return nil end
    local e = {
        recipe = spellID, type = TYPE_KEYS[A.Plain(o.orderType)] or "public",
        tip = tonumber(A.Plain(o.tipAmount)) or 0, cut = tonumber(A.Plain(o.consortiumCut)) or 0,
        minQ = tonumber(A.Plain(o.minQuality)) or 0, expires = tonumber(A.Plain(o.expirationTime)),
        customer = type(o.customerName) == "string" and o.customerName or nil,
        out = type(o.outputItemHyperlink) == "string" and o.outputItemHyperlink or nil,
        recraft = o.isRecraft and true or false, provided = {}, rewards = {},
    }
    for _, rg in ipairs(type(o.reagents) == "table" and o.reagents or {}) do
        local info = type(rg) == "table" and rg.reagentInfo
        local reagent = type(info) == "table" and (info.reagent or info)
        local id = type(reagent) == "table" and A.Plain(reagent.itemID)
        local source = A.Plain(rg.source)
        if type(id) == "number" and (source == nil or source == SOURCE_CUSTOMER) then
            e.provided[id] = (e.provided[id] or 0) + (tonumber(A.Plain(info.quantity)) or 1)
        end
    end
    for _, rw in ipairs(type(o.npcOrderRewards) == "table" and o.npcOrderRewards or {}) do
        if type(rw) == "table" then
            local id = ItemIDFromLink(rw.itemLink)
            local count = tonumber(A.Plain(rw.count)) or 1
            if id then
                e.rewards[#e.rewards + 1] = { item = id, count = count, link = rw.itemLink }
            elseif A.Plain(rw.currencyType) then
                e.rewards[#e.rewards + 1] = { currency = A.Plain(rw.currencyType), count = count }
            end
        end
    end
    local info = C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo and A.Call(C_TradeSkillUI.GetRecipeInfo, spellID)
    e.name = type(info) == "table" and info.name or nil
    return e
end

-- Lettura degli ordini gia' caricati dalla finestra di Blizzard
function O:Read()
    if not (C_CraftingOrders and C_CraftingOrders.GetCrafterOrders) or not ns.db then return end
    local list = A.Call(C_CraftingOrders.GetCrafterOrders)
    if type(list) ~= "table" or #list == 0 then return end
    local byProf, now = {}, time()
    for _, o in ipairs(list) do
        local ok, e = pcall(Simplify, o)
        if ok and e then
            local baseID = ProfessionOf(e.recipe)
            if baseID then
                byProf[baseID] = byProf[baseID] or {}
                table.insert(byProf[baseID], e)
            end
        end
    end
    ns.db.orders = ns.db.orders or {}
    for baseID, orders in pairs(byProf) do
        -- gli ordini di una lettura sostituiscono quelli dello stesso tipo
        local old = ns.db.orders[baseID]
        local seen = {}
        for _, e in ipairs(orders) do seen[e.type] = true end
        if old and old.list then
            for _, e in ipairs(old.list) do
                if not seen[e.type] and (not e.expires or e.expires > now) then orders[#orders + 1] = e end
            end
        end
        ns.db.orders[baseID] = { time = now, list = orders }
    end
    if ns.Panel then ns.Panel:RequestRefresh() end
end

-- Con il tavolo aperto si rilegge ogni POLL secondi: la finestra di Blizzard
-- carica gli ordini man mano che sfogli le schede.
function O:OnShow()
    self.open = true
    if self.ticker then self.ticker:Cancel() end
    if C_Timer and C_Timer.NewTicker then
        self.ticker = C_Timer.NewTicker(POLL, function()
            local ok, err = pcall(O.Read, O)
            if not ok then ns:ReportError(err) end
        end)
    end
    self:Read()
end

function O:OnHide()
    if self.ticker then self.ticker:Cancel(); self.ticker = nil end
    if self.open then self:Read() end
    self.open = false
end

---------------------------------------------------------------------------
-- Calcolo
---------------------------------------------------------------------------
local function Cheapest(items)
    local price
    for _, id in ipairs(items) do
        local p = ns.Prices:Get(id)
        if p and (not price or p < price) then price = p end
    end
    return price
end

-- Guadagno di un ordine: { net, tip, mats, matsPartial, rewards, recipeKnown, missing = {...} }
function O:Evaluate(e, baseID)
    local _, r, locked = ProfessionOf(e.recipe)
    if baseID and not r then
        local scan = ns.db.craft and ns.db.craft[baseID]
        for _, x in ipairs(scan and scan.recipes or {}) do if x.id == e.recipe then r = x end end
    end
    local out = { tip = e.tip - e.cut, mats = 0, rewards = 0, known = r ~= nil and not locked, recipe = r, missing = {} }
    if r then
        for _, slot in ipairs(r.reagents or {}) do
            local given = 0
            for _, id in ipairs(slot.items) do given = given + (e.provided[id] or 0) end
            local need = math.max(0, slot.qty - given)
            if need > 0 then
                local p = Cheapest(slot.items)
                out.missing[#out.missing + 1] = { item = slot.items[1], qty = need, cost = p and p * need }
                if p then out.mats = out.mats + p * need else out.matsPartial = true end
            end
        end
    else
        out.matsUnknown = true
    end
    for _, rw in ipairs(e.rewards) do
        if rw.item then
            local p = ns.Prices:Get(rw.item)
            rw.value = p and p * AH_CUT * rw.count or nil
            if rw.value then out.rewards = out.rewards + rw.value end
        end
    end
    out.net = out.tip - out.mats + out.rewards
    -- qualita' richiesta oltre il rango che otterresti (ricette con i ranghi)
    if r and r.outs and e.minQ > (r.rank or 1) then out.quality = true end
    return out
end

---------------------------------------------------------------------------
-- Righe (sezione "Ordini" della scheda Professioni)
---------------------------------------------------------------------------
local function OrderName(e)
    if e.out then
        local name = e.out:match("%[(.-)%]")
        if name then return name end
    end
    return e.name or ("#" .. e.recipe)
end

function O:Rows(rows, p)
    local L = ns.L
    local data = ns.db.orders and ns.db.orders[p.skillLine]
    local now = time()
    local list = {}
    for _, e in ipairs(data and data.list or {}) do
        if not e.expires or e.expires > now then list[#list + 1] = { e = e, v = self:Evaluate(e, p.skillLine) } end
    end
    if #list == 0 then
        rows[#rows + 1] = { kind = "callout", style = "info", title = L.ORD_OPEN_TITLE,
                            text = data and L.ORD_NONE or L.ORD_OPEN }
        rows[#rows + 1] = { kind = "note", text = L.ORD_PUBLIC_RARE }
        return
    end
    table.sort(list, function(a, b)
        if a.v.known ~= b.v.known then return a.v.known end
        return a.v.net > b.v.net
    end)
    local best = list[1]
    if best.v.known and best.v.net > 0 then
        rows[#rows + 1] = { kind = "callout", style = "tip", title = L.ORD_BEST_TITLE,
                            text = L.ORD_BEST:format(OrderName(best.e), A.Money(best.v.net)) }
    end
    local widths, align = { 0.4, 0.18, 0.16, 0.26 }, { "LEFT", "LEFT", "RIGHT", "RIGHT" }
    rows[#rows + 1] = { kind = "thead", widths = widths, align = align,
                        cols = { L.ORD_COL_ORDER, L.ORD_COL_TYPE, L.ORD_COL_NET, L.ORD_COL_STATE } }
    for i = 1, math.min(MAX_ROWS, #list) do
        local e, v = list[i].e, list[i].v
        local name = OrderName(e)
        local state, stateColor
        if not v.known then state, stateColor = L.ORD_STATE_UNKNOWN, { 1, 0.5, 0.3 }
        elseif v.quality then state, stateColor = L.ORD_STATE_QUALITY, { 1, 0.82, 0 }
        else state, stateColor = L.ORD_STATE_OK, { 0.4, 1, 0.4 } end
        local tip = { name, L.ORD_TIP_TIP:format(A.Money(e.tip), A.Money(e.cut)) }
        if e.minQ > 0 then tip[#tip + 1] = L.ORD_TIP_QUALITY:format(e.minQ) end
        if v.matsUnknown then
            tip[#tip + 1] = L.ORD_TIP_MATS_UNKNOWN
        elseif #v.missing == 0 then
            tip[#tip + 1] = L.ORD_TIP_MATS_NONE
        else
            tip[#tip + 1] = L.ORD_TIP_MATS:format(A.Money(v.mats)) .. (v.matsPartial and (" " .. L.CRAFT_SELL_PARTIAL) or "")
            for _, m in ipairs(v.missing) do
                local info = ns.Prices:ItemInfo(m.item)
                tip[#tip + 1] = ("  %d x %s  %s"):format(m.qty, info and info.name or ("item:" .. m.item),
                    m.cost and A.Money(m.cost) or L.CRAFT_NO_PRICE)
            end
        end
        for _, rw in ipairs(e.rewards) do
            if rw.item then
                local info = ns.Prices:ItemInfo(rw.item)
                tip[#tip + 1] = L.ORD_TIP_REWARD:format(rw.count, info and info.name or ("item:" .. rw.item),
                    rw.value and A.Money(rw.value) or L.CRAFT_NO_PRICE)
            else
                local c = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and A.Call(C_CurrencyInfo.GetCurrencyInfo, rw.currency)
                tip[#tip + 1] = L.ORD_TIP_REWARD:format(rw.count, type(c) == "table" and c.name or ("#" .. tostring(rw.currency)), "")
            end
        end
        if e.expires then tip[#tip + 1] = L.ORD_TIP_EXPIRES:format(A.TimeText(e.expires - now)) end
        if e.customer then tip[#tip + 1] = L.ORD_TIP_CUSTOMER:format(e.customer) end
        local net = (v.net < 0 and "-" or "") .. A.Money(math.abs(v.net)) .. ((v.matsPartial or v.matsUnknown) and "*" or "")
        rows[#rows + 1] = {
            kind = "tr", widths = widths, align = align,
            cols = { name, L["ORD_TYPE_" .. e.type] or e.type, net, state },
            colors = { nil, { 0.75, 0.75, 0.75 }, v.net > 0 and { 0.4, 1, 0.4 } or { 1, 0.4, 0.3 }, stateColor },
            tooltip = tip, link = { spell = e.recipe }, linkTitle = name,
        }
    end
    if #list > MAX_ROWS then rows[#rows + 1] = { kind = "note", text = L.CRAFT_MORE:format(#list - MAX_ROWS) } end
    rows[#rows + 1] = { kind = "note", text = L.ORD_HOW }
    rows[#rows + 1] = { kind = "note", text = L.ORD_AGE:format(A.TimeText(math.max(60, now - (data.time or now)))) }
end
