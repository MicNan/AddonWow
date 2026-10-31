-- RotAssist Companion - Delves
-- Delve attive su tutte le mappe (C_AreaPoiInfo.GetDelvesForMap), con le
-- "abbondanti" in evidenza, chiavi (Restored Coffer Key / Coffer Key Shards)
-- e livello del compagno delle delve.
--
-- Una delve e' considerata abbondante se l'atlas della sua icona contiene
-- "bountiful" (come in The War Within). VERIFICARE in gioco con la scheda.
--
-- Labirinto di Kindo'jan (patch 12.1.5): una "mega-delve" di 9 stanze con un
-- suo Journey (rinomanza). Ha un riquadro dedicato: ingresso con percorso,
-- come sbloccarlo, come funziona, ricompense e ranghi del Journey. Il Journey
-- si cerca tra le fazioni maggiori per nome; se il gioco lo elenca tra le
-- delve, la riga del labirinto esce dalla tabella delle delve.
--
-- Nemesis della Season 2, Azta'rec: scheda con ingresso, sblocco, ordine
-- delle abilita' (cosa fare con ognuna, Venom Storm compresa), intermezzi,
-- Valeera, livello difficile e consigli per la tua classe. Dati da guide
-- pubbliche (ottobre 2026), da confermare in gioco.
--
-- Selettore in cima: Delve, Labirinto, Nemesis (ns.db.delveSection).

local _, ns = ...
local A = ns.API

local D = {}
ns.Delves = D

local CURRENCY_KEYS   = 3028  -- Restored Coffer Key (verificato su Wowhead, ancora in uso in Midnight)
local CURRENCY_SHARDS = 3310  -- Coffer Key Shards

-- Ingresso del Labirinto: Eversong Woods (2395), a nord dell'Amani Pass
local LABYRINTH = { map = 2395, x = 0.630, y = 0.722 }
local LABYRINTH_RANKS = 9
-- Venomfall Deeps (Azta'rec): Coiled Isle (2512)
local NEMESIS = { map = 2512, x = 0.5123, y = 0.3070 }
D.SECTIONS = { "list", "labyrinth", "nemesis" }
-- Consigli per classe: interrupt e movimento
local NEMESIS_CLASS = { PALADIN = "NEM_CLASS_PALADIN", HUNTER = "NEM_CLASS_HUNTER", SHAMAN = "NEM_CLASS_SHAMAN" }

local function IsLabyrinth(name)
    return type(name) == "string" and name:lower():find("kindo", 1, true) ~= nil
end
D.IsLabyrinth = IsLabyrinth

-- Journey del Labirinto: fazione maggiore con "Labyrinth", "Labirinto" o
-- "Kindo" nel nome. { name, level, earned, threshold } o nil.
function D:LabyrinthJourney()
    local MF = C_MajorFactions
    if not (MF and MF.GetMajorFactionIDs and MF.GetMajorFactionData) then return nil end
    local exp = A.Call(GetServerExpansionLevel) or A.Call(GetExpansionLevel)
    local ids = A.Call(MF.GetMajorFactionIDs, exp)
    for _, id in ipairs(type(ids) == "table" and ids or {}) do
        local d = A.Call(MF.GetMajorFactionData, id)
        local name = type(d) == "table" and type(d.name) == "string" and d.name:lower() or ""
        if name:find("labyrinth", 1, true) or name:find("labirint", 1, true) or name:find("kindo", 1, true) then
            return { id = id, name = d.name, level = d.renownLevel or 0, earned = d.renownReputationEarned or 0,
                     threshold = tonumber(d.renownLevelThreshold) or 0, unlocked = d.isUnlocked ~= false }
        end
    end
    return nil
end

-- Scheda della Nemesis: Azta'rec
function D:NemesisRows(rows)
    local L = ns.L
    rows[#rows + 1] = { header = L.HDR_NEMESIS }
    rows[#rows + 1] = { text = L.NEM_WHERE, icon = "Interface\\Icons\\INV_Misc_Map_01",
                        waypoint = { NEMESIS.map, NEMESIS.x, NEMESIS.y, "Venomfall Deeps" },
                        link = { url = "https://www.icy-veins.com/wow/aztarec-delve-guide" }, linkTitle = "Azta'rec" }
    rows[#rows + 1] = { kind = "callout", style = "info", title = L.NEM_UNLOCK_TITLE, text = L.NEM_UNLOCK }

    rows[#rows + 1] = { kind = "sub", text = L.NEM_ORDER_TITLE }
    local widths = { 0.3, 0.7 }
    rows[#rows + 1] = { kind = "thead", widths = widths, cols = { L.NEM_COL_ABILITY, L.NEM_COL_WHAT } }
    for _, a in ipairs(L.NEM_ABILITIES) do
        rows[#rows + 1] = { kind = "tr", widths = widths, cols = { a[1], a[2] },
                            colors = { a[3] and { 1, 0.35, 0.25 } or { 1, 0.82, 0 }, { 0.9, 0.9, 0.9 } } }
    end
    rows[#rows + 1] = { kind = "callout", style = "warn", title = L.NEM_KICK_TITLE, text = L.NEM_KICK }

    rows[#rows + 1] = { kind = "sub", text = L.NEM_STORM_TITLE }
    for i, line in ipairs(L.NEM_STORM) do
        rows[#rows + 1] = { kind = "step", badge = tostring(i), badgeColor = { 0.4, 0.85, 0.35 }, text = line }
    end

    rows[#rows + 1] = { kind = "sub", text = L.NEM_SERMON_TITLE }
    for i, line in ipairs(L.NEM_SERMON) do
        rows[#rows + 1] = { kind = "step", badge = tostring(i), badgeColor = { 0.55, 0.45, 0.95 }, text = line }
    end

    rows[#rows + 1] = { kind = "sub", text = L.NEM_VALEERA_TITLE }
    rows[#rows + 1] = { kind = "step", badge = "-", badgeColor = { 0.35, 0.65, 1 }, text = L.NEM_VALEERA }

    local _, class = A.Call(UnitClass, "player")
    local key = class and NEMESIS_CLASS[class]
    if key then rows[#rows + 1] = { kind = "callout", style = "tip", title = L.NEM_CLASS_TITLE, text = L[key] } end

    rows[#rows + 1] = { kind = "sub", text = L.NEM_HARD_TITLE }
    for i, line in ipairs(L.NEM_HARD) do
        rows[#rows + 1] = { kind = "step", badge = tostring(i), badgeColor = { 1, 0.45, 0.25 }, text = line }
    end
    rows[#rows + 1] = { kind = "note", text = L.NEM_REWARDS }
    rows[#rows + 1] = { kind = "note", text = L.NEM_SOURCE }
end

-- Riquadro del Labirinto di Kindo'jan
function D:LabyrinthRows(rows)
    local L = ns.L
    rows[#rows + 1] = { header = L.HDR_LABYRINTH }
    local j = self:LabyrinthJourney()
    if j and j.unlocked then
        local maxed = j.level >= LABYRINTH_RANKS
        rows[#rows + 1] = { kind = "bar", min = 0, max = LABYRINTH_RANKS, value = math.min(j.level, LABYRINTH_RANKS),
                            color = { 0.55, 0.45, 0.95 }, label = L.LAB_JOURNEY:format(j.level, LABYRINTH_RANKS),
                            right = (not maxed and j.threshold > 0) and L.LAB_JOURNEY_NEXT:format(j.earned, j.threshold) or nil }
    else
        rows[#rows + 1] = { kind = "callout", style = "info", title = L.LAB_UNLOCK_TITLE, text = L.LAB_UNLOCK }
    end
    rows[#rows + 1] = { text = L.LAB_ENTRANCE, icon = "Interface\\Icons\\INV_Misc_Map_01",
                        waypoint = { LABYRINTH.map, LABYRINTH.x, LABYRINTH.y, L.LAB_NAME },
                        link = { search = L.LAB_NAME }, linkTitle = L.LAB_NAME }
    rows[#rows + 1] = { kind = "callout", style = "warn", text = L.LAB_NO_SAVE }
    rows[#rows + 1] = { kind = "sub", text = L.LAB_HOW_TITLE }
    for i, line in ipairs(L.LAB_HOW) do
        rows[#rows + 1] = { kind = "step", badge = tostring(i), badgeColor = { 0.55, 0.45, 0.95 }, text = line }
    end
    rows[#rows + 1] = { kind = "sub", text = L.LAB_REWARDS_TITLE }
    local widths = { 0.4, 0.6 }
    for _, r in ipairs(L.LAB_REWARDS) do
        rows[#rows + 1] = { kind = "tr", widths = widths, cols = { r[1], r[2] }, colors = { { 1, 0.82, 0 }, { 0.85, 0.85, 0.85 } } }
    end
    rows[#rows + 1] = { kind = "sub", text = L.LAB_RANKS_TITLE }
    local level = j and j.level or 0
    for i, line in ipairs(L.LAB_RANKS) do
        local done = i <= level
        rows[#rows + 1] = { kind = "step", badge = tostring(i), text = line,
                            badgeColor = done and { 0.4, 1, 0.4 } or (i == level + 1 and { 0.55, 0.45, 0.95 } or { 0.6, 0.6, 0.6 }),
                            color = done and { 0.6, 0.6, 0.6 } or nil }
    end
    rows[#rows + 1] = { kind = "note", text = L.LAB_SOURCE }
end

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
    local only = ns.db.onlyBountiful and true or false
    -- sezione: delve, labirinto, nemesis
    local section = ns.db.delveSection or "list"
    local sItems = {}
    for _, s in ipairs(self.SECTIONS) do
        sItems[#sItems + 1] = { label = L["DELVE_SEC_" .. s], selected = s == section,
                                onClick = function() ns.db.delveSection = s end }
    end
    rows[#rows + 1] = { kind = "pills", items = sItems }
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
        local maxW = shards.maxWeeklyQuantity or 0
        if maxW > 0 then
            local got = math.min(maxW, shards.quantityEarnedThisWeek or 0)
            rows[#rows + 1] = { kind = "bar", min = 0, max = maxW, value = got, color = { 1, 0.75, 0.3 },
                                label = L.SHARDS_WEEK:format(got, maxW),
                                right = got >= maxW and L.SHARDS_DONE or L.SHARDS_LEFT:format(maxW - got) }
        end
    end
    local cname, lvl, max = self:Companion()
    if cname then
        if max and max > 0 then
            rows[#rows + 1] = { kind = "bar", min = 0, max = max, value = lvl or 0, color = { 0.35, 0.85, 0.45 },
                                label = L.COMPANION:format(cname, lvl or 0, max),
                                tooltip = { cname, L.COMPANION:format(cname, lvl or 0, max) },
                                link = { search = cname }, linkTitle = cname }
        else
            rows[#rows + 1] = { text = L.COMPANION:format(cname, lvl, max), link = { search = cname }, linkTitle = cname }
        end
    end

    if section == "labyrinth" then
        self:LabyrinthRows(rows)
        return rows
    elseif section == "nemesis" then
        self:NemesisRows(rows)
        return rows
    end

    rows[#rows + 1] = { header = L.HDR_DELVES }
    rows[#rows + 1] = { kind = "pills", items = {
        { label = L.DELVE_FILTER_ALL, selected = not only, onClick = function() ns:Set("onlyBountiful", false) end },
        { label = L.ONLY_BOUNTIFUL, selected = only, onClick = function() ns:Set("onlyBountiful", true) end },
    } }
    local n = 0
    local widths, align = { 0.46, 0.34, 0.2 }, { "LEFT", "LEFT", "RIGHT" }
    for _, d in ipairs(self:List()) do
        if (d.bountiful or not only) and not IsLabyrinth(d.name) then
            if n == 0 then
                rows[#rows + 1] = { kind = "thead", widths = widths, align = align,
                                    cols = { L.DELVE_COL_NAME, L.DELVE_COL_ZONE, L.DELVE_COL_STATE } }
            end
            n = n + 1
            rows[#rows + 1] = {
                kind = "tr", widths = widths, align = align,
                cols = { d.name, d.zone or "", d.bountiful and L.DELVE_BOUNTIFUL or (d.locked and L.DELVE_LOCKED or "") },
                colors = { d.bountiful and { 1, 0.82, 0 } or (d.locked and { 0.5, 0.5, 0.5 } or nil), nil,
                           d.bountiful and { 1, 0.82, 0 } or { 0.6, 0.6, 0.6 } },
                tooltip = { d.name, d.zone, d.bountiful and L.DELVE_BOUNTIFUL or nil,
                            d.locked and L.DELVE_LOCKED or nil, d.description },
                waypoint = d.x and { d.mapID, d.x, d.y, d.name } or nil,
                link = { search = d.name }, linkTitle = d.name,
            }
        end
    end
    if n == 0 then rows[#rows + 1] = { kind = "callout", style = "info", text = L.NO_DELVES } end
    return rows
end

-- Riepilogo per la chat all'accesso
function D:Summary()
    local names = {}
    for _, d in ipairs(self:List()) do
        if d.bountiful and not IsLabyrinth(d.name) then names[#names + 1] = d.name end
    end
    local keys = self:Keys()
    return names, keys and keys.quantity
end
