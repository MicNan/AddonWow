-- RotAssist Companion - Market
-- Scheda "Asta": decisioni basate sui prezzi della casa d'aste.
--  * Borse: per ogni oggetto, conviene l'asta o il vendor? (asta al netto
--    della commissione del 5%; il deposito si recupera se l'oggetto si vende)
--  * Da farmare: materiali dell'espansione attuale presenti nella scansione,
--    ordinati in base al profilo di gioco e alle professioni del personaggio.
--  * Sessione di farm: conta cio' che entra nelle borse e ne calcola il valore
--    all'ora; le rese misurate migliorano la classifica dei materiali.
-- Solo consigli: comprare e vendere restano clic del giocatore.

local _, ns = ...
local A = ns.API

local M = { session = nil }
ns.Market = M

local AH_CUT = 0.95                 -- commissione della casa d'aste: 5%
local MIN_GAIN = 10000              -- 1 oro: sotto questa differenza conviene il vendor
local MIN_SESSION = 5 * 60          -- sessioni piu' brevi non aggiornano le rese
local MAX_REQUESTS = 60             -- richieste di dati oggetto per aggiornamento
local BAGS = { 0, 1, 2, 3, 4, 5 }   -- zaino, quattro borse, borsa dei materiali

local TRADEGOODS = (Enum and Enum.ItemClass and Enum.ItemClass.Tradegoods) or 7
local QUEST_ITEM = (Enum and Enum.ItemClass and Enum.ItemClass.Questitem) or 12

-- Sottoclassi dei materiali da farmare -> professione che li raccoglie
-- (nil = chiunque: stoffa dagli umanoidi, carne dalle bestie, elementali)
local FARMABLE = {
    [9]  = 182,   -- erbe -> Erboristeria
    [7]  = 186,   -- metalli e pietre -> Estrazione
    [6]  = 393,   -- pelli -> Scuoiatura
    [12] = 333,   -- materiali d'incantamento -> Incantamento (disincanto)
    [5]  = false, -- stoffa
    [8]  = false, -- carne e pesce (anche Pesca)
    [10] = false, -- elementali
}
M.FARMABLE = FARMABLE

-- Indice dei materiali da farmare di una scansione: { [itemID] = sottoclasse }.
-- Calcolato una volta al termine della scansione (GetItemInfoInstant e'
-- immediato e non richiede dati in memoria).
function ns.BuildFarmIndex(items)
    local index = {}
    if not (C_Item and C_Item.GetItemInfoInstant) then return index end
    for itemID in pairs(items) do
        local _, _, _, _, _, classID, subclassID = A.Call(C_Item.GetItemInfoInstant, itemID)
        if classID == TRADEGOODS and FARMABLE[subclassID] ~= nil then index[itemID] = subclassID end
    end
    return index
end

---------------------------------------------------------------------------
-- Borse
---------------------------------------------------------------------------
-- Conteggio per oggetto: { [itemID] = { count, bound } }
function M:BagContents()
    local out = {}
    if not (C_Container and C_Container.GetContainerNumSlots) then return out end
    for _, bag in ipairs(BAGS) do
        local slots = A.Call(C_Container.GetContainerNumSlots, bag) or 0
        for slot = 1, slots do
            local info = A.Call(C_Container.GetContainerItemInfo, bag, slot)
            if type(info) == "table" and info.itemID then
                local e = out[info.itemID] or { count = 0, bound = false, noValue = false }
                e.count = e.count + (info.stackCount or 1)
                e.bound = e.bound or (info.isBound and true or false)
                e.noValue = e.noValue or (info.hasNoValue and true or false)
                out[info.itemID] = e
            end
        end
    end
    return out
end

-- Valore unitario "di realizzo": asta al netto della commissione, altrimenti vendor.
function M:UnitValue(itemID, bound)
    local info = ns.Prices:ItemInfo(itemID)
    local vendor = info and info.sellPrice or 0
    if not bound then
        local price = ns.Prices:Get(itemID)
        if price and price * AH_CUT > vendor then return price * AH_CUT, "ah" end
    end
    return vendor, "vendor"
end

-- Consiglio per gli oggetti nelle borse
function M:BagAdvice()
    local auction, vendor, loading = {}, {}, 0
    for itemID, e in pairs(self:BagContents()) do
        local info = ns.Prices:ItemInfo(itemID)
        if not info then
            loading = loading + 1
        elseif info.classID ~= QUEST_ITEM then
            local vUnit = e.noValue and 0 or info.sellPrice
            local vTotal = vUnit * e.count
            local price, src, age, qty = nil, nil, nil, nil
            if not e.bound and info.quality > 0 then price, src, age, qty = ns.Prices:Get(itemID) end
            local entry = {
                itemID = itemID, name = info.name, icon = info.icon, count = e.count,
                vendorTotal = vTotal, vendorUnit = vUnit, price = price, source = src, age = age,
                depth = qty, bound = e.bound, reagent = info.isReagent,
            }
            if price then
                entry.ahTotal = price * e.count * AH_CUT
                if entry.ahTotal - vTotal >= math.max(MIN_GAIN, vTotal * 0.25) or vTotal == 0 then
                    auction[#auction + 1] = entry
                elseif vTotal > 0 then
                    vendor[#vendor + 1] = entry
                end
            elseif vTotal > 0 then
                entry.noPrice = not e.bound and info.quality > 0
                vendor[#vendor + 1] = entry
            end
        end
    end
    table.sort(auction, function(a, b) return (a.ahTotal - a.vendorTotal) > (b.ahTotal - b.vendorTotal) end)
    table.sort(vendor, function(a, b) return a.vendorTotal > b.vendorTotal end)
    return auction, vendor, loading
end

---------------------------------------------------------------------------
-- Materiali da farmare
---------------------------------------------------------------------------
local function Score(price, depth)
    -- valore unitario pesato per la profondita' del mercato: preferisce i
    -- materiali che valgono e che si scambiano davvero
    return price * math.sqrt(math.max(1, depth or 1))
end

function M:FarmCandidates()
    local db, expansion = ns.Prices:DB(), ns.Prices:CurrentExpansion()
    local rates = ns.db.farmRates or {}
    local list = {}
    for itemID, subclassID in pairs(db.farmIndex or {}) do
        local e = db.items[itemID]
        if e then
            list[#list + 1] = { itemID = itemID, price = e.p, depth = e.q, subclass = subclassID,
                                score = Score(e.p, e.q) }
        end
    end
    table.sort(list, function(a, b) return a.score > b.score end)
    -- solo materiali dell'espansione attuale (dati oggetto caricati a richiesta)
    local out, requests = {}, 0
    for _, c in ipairs(list) do
        local info = ns.Prices:ItemInfo(c.itemID)
        if info then
            if not expansion or info.expansionID == expansion then
                c.name, c.icon = info.name, info.icon
                c.gatherer = FARMABLE[c.subclass] or nil
                local r = rates[c.itemID]
                if r and r.rate then c.rate = r.rate; c.gph = r.rate * c.price * AH_CUT end
                out[#out + 1] = c
            end
        else
            requests = requests + 1
            if requests >= MAX_REQUESTS then break end
        end
    end
    return out
end

-- Classifica per profilo: { list, needScan }
function M:FarmSuggestions(profile)
    local db = ns.Prices:DB()
    if not db.time then return {}, true end
    local mine = {}
    for _, p in ipairs(ns.Gold:Professions()) do mine[p.skillLine] = true end
    local candidates = self:FarmCandidates()
    local out = {}
    for _, c in ipairs(candidates) do
        local usable = (c.gatherer == nil) or mine[c.gatherer]
        if profile == "hardcore" or usable then
            c.usable = usable
            out[#out + 1] = c
        end
    end
    if profile == "casual" then
        -- alto valore unitario e mercato non vuoto: si raccoglie giocando
        local filtered = {}
        for _, c in ipairs(out) do if (c.depth or 0) >= 20 then filtered[#filtered + 1] = c end end
        table.sort(filtered, function(a, b) return a.price > b.price end)
        out = filtered
    elseif profile == "hardcore" then
        table.sort(out, function(a, b)
            if a.gph and b.gph then return a.gph > b.gph end
            if a.gph or b.gph then return a.gph ~= nil end
            return a.score > b.score
        end)
    end
    local limit = (profile == "casual" and 5) or (profile == "medium" and 6) or 10
    while #out > limit do table.remove(out) end
    return out, false
end

---------------------------------------------------------------------------
-- Sessione di farm
---------------------------------------------------------------------------
local function Counts()
    local out = {}
    for id, e in pairs(M:BagContents()) do out[id] = e.count end
    return out
end

function M:StartSession()
    self.session = { start = GetTime(), base = Counts(), gained = {}, zone = A.ZoneName(A.PlayerMap()) }
    ns:Print(ns.L.FARM_STARTED)
    if ns.Panel then ns.Panel:Refresh() end
end

function M:OnBagUpdate()
    local s = self.session
    if not s then return end
    for id, n in pairs(Counts()) do
        local diff = n - (s.base[id] or 0)
        if diff > (s.gained[id] or 0) then s.gained[id] = diff end
    end
end

-- Valore guadagnato e durata della sessione in corso
function M:SessionValue()
    local s = self.session
    if not s then return nil end
    local total, items = 0, {}
    for id, n in pairs(s.gained) do
        local unit = self:UnitValue(id, false)
        total = total + unit * n
        items[#items + 1] = { itemID = id, count = n, value = unit * n }
    end
    table.sort(items, function(a, b) return a.value > b.value end)
    return total, GetTime() - s.start, items
end

function M:StopSession()
    local s = self.session
    if not s then return end
    local total, elapsed = self:SessionValue()
    self.session = nil
    ns.db.farmRates = ns.db.farmRates or {}
    if elapsed >= MIN_SESSION then
        local hours = elapsed / 3600
        for id, n in pairs(s.gained) do
            local rate = n / hours
            local r = ns.db.farmRates[id]
            ns.db.farmRates[id] = { rate = r and r.rate and (r.rate * 0.5 + rate * 0.5) or rate, zone = s.zone }
        end
        ns.db.lastSession = { value = total, minutes = math.floor(elapsed / 60), zone = s.zone, when = time() }
        ns:Print(ns.L.FARM_DONE, A.Money(total), math.floor(elapsed / 60), A.Money(total / hours))
    else
        ns:Print(ns.L.FARM_TOO_SHORT)
    end
    if ns.Panel then ns.Panel:Refresh() end
end

function M:ToggleSession()
    if self.session then self:StopSession() else self:StartSession() end
end

---------------------------------------------------------------------------
-- Righe della scheda
---------------------------------------------------------------------------
local function ItemRow(e, right, tip)
    return {
        text = (e.count and e.count > 1) and (e.name .. " x" .. e.count) or e.name,
        right = right, icon = e.icon, tooltip = tip,
        link = { item = e.itemID }, linkTitle = e.name,
    }
end

function M:Rows()
    local L, rows = ns.L, {}
    local profile = ns.db.playerType or "medium"

    -- fonte dei prezzi
    rows[#rows + 1] = { header = L.HDR_PRICES }
    local status = ns.Prices:SourceStatus()
    if status then
        rows[#rows + 1] = { text = L.PRICE_SOURCES:format(status), dim = true }
    else
        rows[#rows + 1] = { text = L.PRICE_NONE, color = { 1, 0.6, 0.2 }, wrap = true }
    end

    -- sessione di farm
    rows[#rows + 1] = { header = L.HDR_FARM_SESSION }
    local total, elapsed, items = self:SessionValue()
    if total then
        local hours = math.max(elapsed, 60) / 3600
        rows[#rows + 1] = { text = L.FARM_RUNNING:format(A.TimeText(elapsed), A.Money(total)),
                            right = L.PER_HOUR:format(A.Money(total / hours)), color = { 0.4, 1, 0.4 } }
        for i = 1, math.min(3, #items) do
            local it = items[i]
            local info = ns.Prices:ItemInfo(it.itemID)
            rows[#rows + 1] = { text = "  " .. ((info and info.name) or ("item " .. it.itemID)) .. " x" .. it.count,
                                right = A.Money(it.value), icon = info and info.icon }
        end
    elseif ns.db.lastSession then
        local ls = ns.db.lastSession
        rows[#rows + 1] = { text = L.FARM_LAST:format(ls.zone or "?", ls.minutes or 0, A.Money(ls.value or 0)), dim = true }
    else
        rows[#rows + 1] = { text = L.FARM_HINT, dim = true, wrap = true }
    end

    -- borse
    local auction, vendor, loading = self:BagAdvice()
    local aTotal, vTotal = 0, 0
    for _, e in ipairs(auction) do aTotal = aTotal + e.ahTotal end
    for _, e in ipairs(vendor) do vTotal = vTotal + e.vendorTotal end
    rows[#rows + 1] = { header = L.HDR_BAG_AUCTION:format(#auction, A.Money(aTotal)) }
    for i = 1, math.min(15, #auction) do
        local e = auction[i]
        local tip = { e.name, L.TIP_AH_UNIT:format(A.Money(e.price), e.source or "?",
                      e.age and A.TimeText(e.age) or "?"),
                      L.TIP_VENDOR_UNIT:format(A.Money(e.vendorUnit)),
                      e.depth and L.TIP_DEPTH:format(A.Number(e.depth)) or nil,
                      e.reagent and L.TIP_REAGENT or nil }
        rows[#rows + 1] = ItemRow(e, A.Money(e.ahTotal), tip)
    end
    if #auction == 0 then rows[#rows + 1] = { text = L.BAG_NONE, dim = true } end

    rows[#rows + 1] = { header = L.HDR_BAG_VENDOR:format(#vendor, A.Money(vTotal)) }
    for i = 1, math.min(15, #vendor) do
        local e = vendor[i]
        local why = e.bound and L.WHY_BOUND or (e.noPrice and L.WHY_NO_PRICE) or L.WHY_VENDOR_BETTER
        local row = ItemRow(e, A.Money(e.vendorTotal), { e.name, why,
            e.price and L.TIP_AH_UNIT:format(A.Money(e.price), e.source or "?", e.age and A.TimeText(e.age) or "?") or nil,
            L.TIP_VENDOR_UNIT:format(A.Money(e.vendorUnit)) })
        if e.noPrice then row.dim = true end
        rows[#rows + 1] = row
    end
    if #vendor == 0 then rows[#rows + 1] = { text = L.BAG_NONE, dim = true } end
    if loading > 0 then rows[#rows + 1] = { text = L.ITEMS_LOADING:format(loading), dim = true } end

    -- da farmare
    rows[#rows + 1] = { header = L.HDR_FARM:format(L["PROFILE_" .. profile]) }
    local list, needScan = self:FarmSuggestions(profile)
    if needScan then
        rows[#rows + 1] = { text = L.FARM_NEED_SCAN, color = { 1, 0.6, 0.2 }, wrap = true }
    else
        for _, c in ipairs(list) do
            local who = c.gatherer and L["GATHER_" .. c.gatherer] or L.GATHER_ANY
            local text = L.FARM_LINE:format(c.name, A.Money(c.price), A.Number(c.depth or 0))
            local row = {
                text = text, right = c.gph and L.PER_HOUR:format(A.Money(c.gph)) or who, icon = c.icon,
                tooltip = { c.name, L["SUB_" .. c.subclass] or "", who,
                            c.rate and L.TIP_RATE:format(math.floor(c.rate)) or L.TIP_RATE_UNKNOWN,
                            (c.usable == false) and L.TIP_NEED_PROF or nil },
                link = { item = c.itemID }, linkTitle = c.name,
            }
            if c.usable == false then row.dim = true end
            rows[#rows + 1] = row
        end
        if #list == 0 then rows[#rows + 1] = { text = L.FARM_EMPTY, dim = true, wrap = true } end
        rows[#rows + 1] = { text = L["FARM_TIP_" .. profile], dim = true, wrap = true }
    end

    rows[#rows + 1] = { header = "" }
    rows[#rows + 1] = { text = L.MARKET_DISCLAIMER, dim = true, wrap = true }
    return rows
end

---------------------------------------------------------------------------
-- Tooltip degli oggetti: prezzo d'asta, vendor e consiglio
---------------------------------------------------------------------------
function M:HookTooltips()
    if self.hooked or not (TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum
                           and Enum.TooltipDataType and Enum.TooltipDataType.Item) then return end
    self.hooked = true
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if not (ns.db and ns.db.tooltipPrices) or type(data) ~= "table" then return end
        local ok = pcall(function()
            local itemID = A.Plain(data.id)
            if type(itemID) ~= "number" then return end
            local price, src, age = ns.Prices:Get(itemID)
            local info = ns.Prices:ItemInfo(itemID)
            if not price and not (info and info.sellPrice > 0) then return end
            local L = ns.L
            if price then
                tooltip:AddDoubleLine(L.TT_AH, A.Money(price) .. " (" .. tostring(src) ..
                    (age and (", " .. A.TimeText(age)) or "") .. ")", 0.4, 0.8, 1, 1, 1, 1)
            end
            if info and info.sellPrice > 0 then
                tooltip:AddDoubleLine(L.TT_VENDOR, A.Money(info.sellPrice), 0.4, 0.8, 1, 1, 1, 1)
            end
            if price and info then
                -- confronto per singolo pezzo; il consiglio sulle pile intere e'
                -- nella scheda Asta (sotto 1 oro di guadagno conviene il vendor)
                local gain = price * AH_CUT - info.sellPrice
                if gain > 0 then
                    tooltip:AddLine(L.TT_ADVICE_AH:format(A.Money(gain)), 0.6, 0.6, 0.6)
                else
                    tooltip:AddLine(L.TT_ADVICE_VENDOR, 0.6, 0.6, 0.6)
                end
            end
        end)
        if not ok then return end
    end)
end
