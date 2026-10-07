-- RotAssist Companion - API
-- Accesso protetto (pcall) alle API di Blizzard, mappe, waypoint, link
-- Wowhead e formattazione. Ogni valore passa da Plain(): se in qualche
-- situazione fosse un "secret value" diventa nil invece di generare errori.

local _, ns = ...
local A = {}
ns.API = A

local issecretvalue = issecretvalue or function() return false end
local function Plain(v)
    if issecretvalue(v) then return nil end
    return v
end
A.Plain = Plain

-- Chiama fn in modo protetto e restituisce i risultati (nil se fallisce).
local function Pack(...) return { n = select("#", ...), ... } end

function A.Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = Pack(pcall(fn, ...))
    if not res[1] then return nil end
    for i = 2, res.n do res[i] = Plain(res[i]) end
    return unpack(res, 2, res.n)
end
local Call = A.Call

function A.InCombat()
    if InCombatLockdown and Call(InCombatLockdown) then return true end
    return Call(UnitAffectingCombat, "player") and true or false
end

---------------------------------------------------------------------------
-- Mappe
---------------------------------------------------------------------------
local MAP_CONTINENT = (Enum and Enum.UIMapType and Enum.UIMapType.Continent) or 2
local MAP_ZONE      = (Enum and Enum.UIMapType and Enum.UIMapType.Zone) or 3
local MAP_COSMIC    = 946   -- radice di tutte le mappe

function A.MapInfo(mapID)
    if not (C_Map and C_Map.GetMapInfo) or not mapID then return nil end
    local info = Call(C_Map.GetMapInfo, mapID)
    return type(info) == "table" and info or nil
end

function A.PlayerMap()
    return C_Map and Call(C_Map.GetBestMapForUnit, "player")
end

-- Continente che contiene la mappa (o la mappa stessa se e' gia' un continente).
function A.ContinentOf(mapID)
    local info = A.MapInfo(mapID)
    local guard = 0
    while info and guard < 10 do
        if info.mapType == MAP_CONTINENT then return info.mapID, info.name end
        if not info.parentMapID or info.parentMapID == 0 then break end
        info = A.MapInfo(info.parentMapID)
        guard = guard + 1
    end
    return nil
end

-- Tutte le zone discendenti di una mappa (default: tutte le mappe del gioco).
local zoneCache = {}
function A.Zones(rootMapID)
    rootMapID = rootMapID or MAP_COSMIC
    if zoneCache[rootMapID] then return zoneCache[rootMapID] end
    local list = {}
    if C_Map and C_Map.GetMapChildrenInfo then
        local children = Call(C_Map.GetMapChildrenInfo, rootMapID, MAP_ZONE, true)
        if type(children) == "table" then
            for _, z in ipairs(children) do
                if type(z) == "table" and z.mapID then list[#list + 1] = z end
            end
        end
    end
    zoneCache[rootMapID] = list
    return list
end

function A.ZoneName(mapID)
    local info = A.MapInfo(mapID)
    return info and info.name or ("map " .. tostring(mapID))
end

---------------------------------------------------------------------------
-- Cache delle scansioni (esplorare tutte le mappe costa: si ripete al
-- massimo ogni 'ttl' secondi, o subito con A.ClearCache)
---------------------------------------------------------------------------
local cache = {}
function A.Cached(key, ttl, fn)
    local now = GetTime()
    local c = cache[key]
    if c and now - c.t < ttl then return unpack(c.v, 1, c.n) end
    local v = Pack(fn())
    cache[key] = { t = now, v = v, n = v.n }
    return unpack(v, 1, v.n)
end

function A.ClearCache() wipe(cache) end

---------------------------------------------------------------------------
-- Valute e tempo
---------------------------------------------------------------------------
function A.Currency(currencyID)
    if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then return nil end
    local info = Call(C_CurrencyInfo.GetCurrencyInfo, currencyID)
    return type(info) == "table" and info or nil
end

function A.TimeText(seconds)
    local L = ns.L
    seconds = tonumber(seconds)
    if not seconds or seconds <= 0 then return "-" end
    local d = math.floor(seconds / 86400)
    local h = math.floor((seconds % 86400) / 3600)
    local m = math.floor((seconds % 3600) / 60)
    if d > 0 then return L.T_DAYS:format(d, h) end
    if h > 0 then return L.T_HOURS:format(h, m) end
    return L.T_MINUTES:format(math.max(1, m))
end

function A.Money(copper)
    copper = math.floor(tonumber(copper) or 0)
    if copper >= 10000 then return A.Number(math.floor(copper / 10000)) .. "g" end
    if copper >= 100 then return math.floor(copper / 100) .. "s" end
    return copper .. "c"
end

function A.Number(n)
    n = tonumber(n) or 0
    if BreakUpLargeNumbers then
        local ok, s = pcall(BreakUpLargeNumbers, n)
        if ok and s then return s end
    end
    return tostring(math.floor(n))
end

---------------------------------------------------------------------------
-- Waypoint: TomTom se presente, altrimenti il waypoint di Blizzard
---------------------------------------------------------------------------
function ns:SetWaypoint(mapID, x, y, title)
    if not (mapID and x and y) then return false end
    local L = self.L
    if TomTom and TomTom.AddWaypoint then
        local ok = pcall(TomTom.AddWaypoint, TomTom, mapID, x, y,
            { title = title, from = "RotAssist Companion", persistent = false })
        if ok then
            self:Print(L.MSG_WAYPOINT, title or "")
            return true
        end
    end
    if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        if C_Map.CanSetUserWaypointOnMap and not Call(C_Map.CanSetUserWaypointOnMap, mapID) then
            self:Print(L.MSG_NO_WAYPOINT)
            return false
        end
        local ok = pcall(function()
            C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y))
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            end
        end)
        if ok then
            self:Print(L.MSG_WAYPOINT, title or "")
            return true
        end
    end
    self:Print(L.MSG_NO_WAYPOINT)
    return false
end

---------------------------------------------------------------------------
-- Link Wowhead: gli addon non aprono il browser, mostriamo l'URL da copiare.
-- Solo link a pagine pubbliche: nessun dato viene scaricato da Wowhead.
---------------------------------------------------------------------------
local WOWHEAD_LOCALE = {
    itIT = "it/", deDE = "de/", frFR = "fr/", esES = "es/", esMX = "mx/",
    ptBR = "pt/", ruRU = "ru/", koKR = "ko/", zhCN = "cn/", zhTW = "tw/",
}

local function UrlEncode(s)
    return (tostring(s):gsub("[^%w%-_%.~ ]", function(c) return ("%%%02X"):format(c:byte()) end):gsub(" ", "+"))
end

-- link = { quest = id } | { spell = id } | { npc = id } | { search = "testo" }
function ns:WowheadURL(link)
    local loc = (GetLocale and WOWHEAD_LOCALE[GetLocale()]) or ""
    if link.quest then return ("https://www.wowhead.com/%squest=%d"):format(loc, link.quest) end
    if link.spell then return ("https://www.wowhead.com/%sspell=%d"):format(loc, link.spell) end
    if link.currency then return ("https://www.wowhead.com/%scurrency=%d"):format(loc, link.currency) end
    if link.item then return ("https://www.wowhead.com/%sitem=%d"):format(loc, link.item) end
    if link.npc then return ("https://www.wowhead.com/%snpc=%d"):format(loc, link.npc) end
    return ("https://www.wowhead.com/%ssearch?q=%s"):format(loc, UrlEncode(link.search or ""))
end

function ns:ShowLink(title, link)
    local url = self:WowheadURL(link)
    if StaticPopupDialogs and StaticPopup_Show then
        StaticPopupDialogs.ROTASSIST_COMPANION_URL = StaticPopupDialogs.ROTASSIST_COMPANION_URL or {
            button1 = OKAY or "OK",
            hasEditBox = true,
            editBoxWidth = 340,
            OnShow = function(popup, data)
                local eb = popup.EditBox or popup.editBox
                if eb and data then eb:SetText(data); eb:HighlightText(); eb:SetFocus() end
            end,
            EditBoxOnEnterPressed = function(eb) eb:GetParent():Hide() end,
            EditBoxOnEscapePressed = function(eb) eb:GetParent():Hide() end,
            timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
        }
        StaticPopupDialogs.ROTASSIST_COMPANION_URL.text = self.L.WOWHEAD_POPUP
        if pcall(StaticPopup_Show, "ROTASSIST_COMPANION_URL", title or "", nil, url) then return end
    end
    self:Print("%s: %s", title or "", url)
end
