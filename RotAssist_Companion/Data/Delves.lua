-- RotAssist Companion - Delves
-- Delve attive su tutte le mappe (C_AreaPoiInfo.GetDelvesForMap), con le
-- "abbondanti" in evidenza, chiavi (Restored Coffer Key / Coffer Key Shards)
-- e livello del compagno delle delve.
--
-- Una delve e' considerata abbondante se l'atlas della sua icona contiene
-- "bountiful" (come in The War Within). VERIFICARE in gioco con la scheda.

local _, ns = ...
local A = ns.API

local D = {}
ns.Delves = D

local CURRENCY_KEYS   = 3028  -- Restored Coffer Key (verificato su Wowhead, ancora in uso in Midnight)
local CURRENCY_SHARDS = 3310  -- Coffer Key Shards

local function IsBountiful(info)
    local atlas = info.atlasName and tostring(info.atlasName):lower() or ""
    return atlas:find("bountiful", 1, true) ~= nil
end

-- Elenco delle delve: { name, zone, mapID, x, y, bountiful, locked, description, atlas, poiID }
local SCAN_TTL = 20

function D:List()
    return A.Cached("delves", SCAN_TTL, function() return self:Scan() end)
end

function D:Scan()
    local out, seen = {}, {}
    if not (C_AreaPoiInfo and C_AreaPoiInfo.GetDelvesForMap) then return out end
    for _, zone in ipairs(A.Zones()) do
        local ids = A.Call(C_AreaPoiInfo.GetDelvesForMap, zone.mapID)
        if type(ids) == "table" then
            for _, poiID in ipairs(ids) do
                if not seen[poiID] then
                    local info = A.Call(C_AreaPoiInfo.GetAreaPOIInfo, zone.mapID, poiID)
                    if type(info) == "table" and info.name then
                        seen[poiID] = true
                        local pos = info.position
                        out[#out + 1] = {
                            poiID = poiID, name = info.name, description = info.description,
                            zone = zone.name, mapID = zone.mapID,
                            x = pos and pos.x, y = pos and pos.y,
                            bountiful = IsBountiful(info), locked = info.isLocked and true or false,
                            atlas = info.atlasName,
                        }
                    end
                end
            end
        end
    end
    table.sort(out, function(a, b)
        if a.bountiful ~= b.bountiful then return a.bountiful end
        if a.zone ~= b.zone then return tostring(a.zone) < tostring(b.zone) end
        return tostring(a.name) < tostring(b.name)
    end)
    return out
end

function D:Keys()
    local keys = A.Currency(CURRENCY_KEYS)
    local shards = A.Currency(CURRENCY_SHARDS)
    return keys, shards
end

-- Compagno delle delve: nome, livello attuale e massimo (nil se non disponibile).
function D:Companion()
    if not (C_DelvesUI and C_DelvesUI.GetFactionForCompanion) then return nil end
    local factionID = A.Call(C_DelvesUI.GetFactionForCompanion)
    if not factionID or factionID == 0 then return nil end
    local name
    if C_Reputation and C_Reputation.GetFactionDataByID then
        local data = A.Call(C_Reputation.GetFactionDataByID, factionID)
        name = type(data) == "table" and data.name or nil
    end
    local ranks = C_GossipInfo and A.Call(C_GossipInfo.GetFriendshipReputationRanks, factionID)
    if type(ranks) ~= "table" or not ranks.currentLevel then return nil end
    return name or "Companion", ranks.currentLevel, ranks.maxLevel or ranks.currentLevel
end

-- Righe per la scheda
function D:Rows()
    local L, rows = ns.L, {}
    rows[#rows + 1] = { header = L.HDR_DELVE_STATUS }
    local keys, shards = self:Keys()
    if keys then
        rows[#rows + 1] = { text = L.KEYS:format(keys.quantity or 0), icon = keys.iconFileID,
                            link = { currency = CURRENCY_KEYS }, linkTitle = keys.name }
    end
    if shards then
        rows[#rows + 1] = { text = L.SHARDS:format(shards.quantity or 0, shards.quantityEarnedThisWeek or 0,
                                                   shards.maxWeeklyQuantity or 0),
                            icon = shards.iconFileID, link = { currency = CURRENCY_SHARDS }, linkTitle = shards.name }
    end
    local cname, lvl, max = self:Companion()
    if cname then
        rows[#rows + 1] = { text = L.COMPANION:format(cname, lvl, max), link = { search = cname }, linkTitle = cname }
    end

    rows[#rows + 1] = { header = L.HDR_DELVES }
    local n = 0
    for _, d in ipairs(self:List()) do
        if d.bountiful or not ns.db.onlyBountiful then
            n = n + 1
            rows[#rows + 1] = {
                text = d.name, right = d.zone, atlas = d.atlas,
                color = d.bountiful and { 1, 0.82, 0 } or (d.locked and { 0.5, 0.5, 0.5 } or nil),
                tooltip = { d.name, d.zone, d.bountiful and L.DELVE_BOUNTIFUL or nil,
                            d.locked and L.DELVE_LOCKED or nil, d.description },
                waypoint = d.x and { d.mapID, d.x, d.y, d.name } or nil,
                link = { search = d.name }, linkTitle = d.name,
            }
        end
    end
    if n == 0 then rows[#rows + 1] = { text = L.NO_DELVES, dim = true } end
    return rows
end

-- Riepilogo per la chat all'accesso
function D:Summary()
    local names = {}
    for _, d in ipairs(self:List()) do
        if d.bountiful then names[#names + 1] = d.name end
    end
    local keys = self:Keys()
    return names, keys and keys.quantity
end
