-- RotAssist Companion - Prices
-- Prezzi della casa d'aste per gli altri moduli (scheda Asta, tooltip).
--
-- Fonti, dalla piu' affidabile:
--   1. scansione propria recente (C_AuctionHouse.ReplicateItems, possibile solo
--      con la casa d'aste aperta, al massimo ogni 15 minuti per account);
--   2. Auctionator, se installato (Auctionator.API.v1.GetAuctionPriceByItemID);
--   3. TSM, se installato (TSM_API.GetCustomPriceValue "dbmarket");
--   4. scansione propria anche se vecchia.
-- I prezzi sono salvati per reame in RotAssistCompanionPrices (SavedVariables
-- dell'account): valgono per tutti i personaggi e restano dopo il logout.
-- L'addon legge soltanto: comprare e vendere restano clic del giocatore.

local _, ns = ...
local A = ns.API

local PR = { scanning = false }
ns.Prices = PR

local FRESH = 3 * 86400          -- oltre 3 giorni la scansione propria e' "vecchia"
local SCAN_THROTTLE = 15 * 60    -- limite di Blizzard tra due scansioni complete
local CHUNK = 4000               -- aste elaborate per frame
local SCAN_TIMEOUT = 15          -- secondi di attesa dei dati dopo la richiesta

local function RealmKey()
    return A.Call(GetNormalizedRealmName) or A.Call(GetRealmName) or "realm"
end

function PR:DB()
    RotAssistCompanionPrices = RotAssistCompanionPrices or {}
    local key = RealmKey()
    RotAssistCompanionPrices[key] = RotAssistCompanionPrices[key] or { items = {} }
    return RotAssistCompanionPrices[key]
end

function PR:ScanAge()
    local db = self:DB()
    if not db.time then return nil end
    return time() - db.time
end

---------------------------------------------------------------------------
-- Informazioni sugli oggetti (con richiesta di caricamento se mancano)
---------------------------------------------------------------------------
local pending = {}
function PR:ItemInfo(itemID)
    if not (C_Item and C_Item.GetItemInfo) then return nil end
    local name, link, quality, _, _, _, _, stack, _, icon, sellPrice, classID, subclassID,
          bindType, expansionID, _, isReagent = A.Call(C_Item.GetItemInfo, itemID)
    if not name then
        if not pending[itemID] and C_Item.RequestLoadItemDataByID then
            pending[itemID] = true
            pcall(C_Item.RequestLoadItemDataByID, itemID)
        end
        return nil
    end
    pending[itemID] = nil
    return {
        name = name, link = link, quality = quality or 1, stack = stack or 1, icon = icon,
        sellPrice = sellPrice or 0, classID = classID, subclassID = subclassID,
        bindType = bindType or 0, expansionID = expansionID, isReagent = isReagent and true or false,
    }
end

function PR:CurrentExpansion()
    return A.Call(GetServerExpansionLevel) or A.Call(GetExpansionLevel) or LE_EXPANSION_LEVEL_CURRENT
end

---------------------------------------------------------------------------
-- Prezzo unitario di un oggetto: prezzo, fonte, eta' in secondi, quantita' in vendita
---------------------------------------------------------------------------
local function Own(itemID)
    local db = PR:DB()
    local e = db.items[itemID]
    if e and e.p then return e.p, "scan", db.time and (time() - db.time) or nil, e.q end
end

local function FromAuctionator(itemID)
    local api = Auctionator and Auctionator.API and Auctionator.API.v1
    if not (api and api.GetAuctionPriceByItemID) then return nil end
    local price = A.Call(api.GetAuctionPriceByItemID, "RotAssist Companion", itemID)
    if not price or price <= 0 then return nil end
    local days = api.GetAuctionAgeByItemID and A.Call(api.GetAuctionAgeByItemID, "RotAssist Companion", itemID)
    return price, "Auctionator", days and days * 86400 or nil
end

local function FromTSM(itemID)
    if not (TSM_API and TSM_API.GetCustomPriceValue) then return nil end
    local price = A.Call(TSM_API.GetCustomPriceValue, "dbmarket", "i:" .. itemID)
    if not price or price <= 0 then return nil end
    return price, "TSM", nil
end

function PR:Get(itemID)
    if not itemID then return nil end
    local p, src, age, qty = Own(itemID)
    if p and age and age <= FRESH then return p, src, age, qty end
    local ap, asrc, aage = FromAuctionator(itemID)
    if ap then return ap, asrc, aage, qty end
    local tp, tsrc = FromTSM(itemID)
    if tp then return tp, tsrc, nil, qty end
    return p, src, age, qty
end

-- Descrizione della fonte prezzi per l'intestazione della scheda
function PR:SourceStatus()
    local L = ns.L
    local age = self:ScanAge()
    local parts = {}
    if age then
        parts[#parts + 1] = (age < 60) and L.PRICE_SCAN_NOW or L.PRICE_SCAN_AGE:format(A.TimeText(age))
    end
    if Auctionator and Auctionator.API then parts[#parts + 1] = "Auctionator" end
    if TSM_API then parts[#parts + 1] = "TSM" end
    if #parts == 0 then return nil end
    return table.concat(parts, " + ")
end

---------------------------------------------------------------------------
-- Scansione completa (casa d'aste aperta)
---------------------------------------------------------------------------
function PR:CanScan()
    if not (C_AuctionHouse and C_AuctionHouse.ReplicateItems) then return false, "api" end
    if not self.ahOpen then return false, "closed" end
    if self.scanning then return false, "busy" end
    local last = RotAssistCompanionPrices and RotAssistCompanionPrices._lastScan
    if last and time() - last < SCAN_THROTTLE then return false, "throttle", SCAN_THROTTLE - (time() - last) end
    return true
end

function PR:StartScan()
    local L = ns.L
    local ok, why, wait = self:CanScan()
    if not ok then
        if why == "closed" then ns:Print(L.SCAN_NEED_AH)
        elseif why == "throttle" then ns:Print(L.SCAN_THROTTLED, A.TimeText(wait))
        elseif why == "busy" then ns:Print(L.SCAN_BUSY)
        else ns:Print(L.SCAN_UNAVAILABLE) end
        return
    end
    self.scanning, self.waiting = true, true
    self.requestedAt = GetTime()
    ns:Print(L.SCAN_STARTED)
    if not pcall(C_AuctionHouse.ReplicateItems) then
        self.scanning, self.waiting = false, false
        ns:Print(L.SCAN_UNAVAILABLE)
        return
    end
    -- se i dati non arrivano (limite di Blizzard non rispettato), rinunciamo
    ns:After(SCAN_TIMEOUT, function()
        if PR.waiting then
            PR.scanning, PR.waiting = false, false
            ns:Print(L.SCAN_NO_DATA)
        end
    end)
end

-- Dati pronti: li elaboriamo a blocchi in OnUpdate per non bloccare il gioco.
function PR:OnReplicateReady()
    if not self.waiting then return end
    self.waiting = false
    local total = A.Call(C_AuctionHouse.GetNumReplicateItems) or 0
    local acc, index = {}, 0
    local frame = self.worker or CreateFrame("Frame")
    self.worker = frame
    frame:SetScript("OnUpdate", function(f)
        local last = math.min(index + CHUNK, total) - 1
        for i = index, last do
            local _, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID =
                A.Call(C_AuctionHouse.GetReplicateItemInfo, i)
            if itemID and buyout and buyout > 0 and count and count > 0 then
                local unit = math.floor(buyout / count)
                local e = acc[itemID]
                if not e then
                    acc[itemID] = { p = unit, q = count }
                else
                    if unit < e.p then e.p = unit end
                    e.q = e.q + count
                end
            end
        end
        index = last + 1
        if index >= total then
            f:SetScript("OnUpdate", nil)
            PR:FinishScan(acc, total)
        end
    end)
end

function PR:FinishScan(acc, total)
    local db = self:DB()
    local n = 0
    for _ in pairs(acc) do n = n + 1 end
    db.items, db.time, db.auctions = acc, time(), total
    db.farmIndex = ns.BuildFarmIndex and ns.BuildFarmIndex(acc) or {}
    RotAssistCompanionPrices._lastScan = time()
    self.scanning = false
    ns:Print(ns.L.SCAN_DONE, n, total)
    if ns.Panel then ns.Panel:RequestRefresh() end
end

---------------------------------------------------------------------------
-- Pulsante di scansione sulla finestra della casa d'aste
---------------------------------------------------------------------------
function PR:OnAuctionHouseShow()
    self.ahOpen = true
    local parent = AuctionHouseFrame or UIParent
    if not self.button then
        local b = CreateFrame("Button", "RotAssistCompanionScanButton", parent, "UIPanelButtonTemplate")
        b:SetSize(170, 22)
        b:SetScript("OnClick", function() PR:StartScan() end)
        self.button = b
    end
    local b = self.button
    b:SetParent(parent)
    b:ClearAllPoints()
    if parent == UIParent then b:SetPoint("TOP", 0, -120) else b:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -30, -2) end
    b:SetText(ns.L.SCAN_BUTTON)
    b:Show()
end

function PR:OnAuctionHouseClosed()
    self.ahOpen = false
    if self.button then self.button:Hide() end
end
