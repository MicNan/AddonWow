-- RotAssist Companion - Travel
-- Indicazioni per raggiungere una destinazione nel modo piu' rapido.
--
-- WoW non offre agli addon un'API di calcolo del percorso: il percorso e'
-- stimato con una tabella di portali curata a mano (fonti sotto) e un grafo
-- di "regioni" (continenti, piu' Harandar e Voidstorm che sono zone separate
-- raggiungibili solo con portali). All'interno di una regione si vola.
-- Il navigatore imposta il waypoint del passo attuale e passa da solo al
-- passo successivo quando il giocatore arriva nella regione giusta.
--
-- Fonti (ottobre 2026, patch 12.1):
--  * UiMapID: tabella UiMap su wago.tools (build 12.1.5)
--  * portali di Silvermoon: guida "Portal Locations In Silvermoon City" (method.gg)
--  * portali di Stormwind / Orgrimmar / Voidstorm: pagine degli oggetti su Wowhead
-- DA VERIFICARE in gioco; da aggiornare se Blizzard sposta i portali.

local _, ns = ...
local A = ns.API

local T = { route = nil, step = 0 }
ns.Travel = T

-- Regioni ---------------------------------------------------------------
local QUELTHALAS, EASTERN_KINGDOMS, KALIMDOR, KHAZ_ALGAR = 2537, 13, 12, 2274
local HARANDAR, VOIDSTORM = 2413, 2405

-- Zone che formano una regione a se' (raggiungibili solo via portale)
local SEPARATE_ZONES = { [HARANDAR] = "harandar", [VOIDSTORM] = "voidstorm" }

-- Regione di una mappa: zona separata, altrimenti il suo continente.
function T:RegionOf(mapID)
    local info, guard = A.MapInfo(mapID), 0
    while info and guard < 12 do
        if SEPARATE_ZONES[info.mapID] then return SEPARATE_ZONES[info.mapID] end
        if info.mapType == ((Enum and Enum.UIMapType and Enum.UIMapType.Continent) or 2) then
            return info.mapID
        end
        if not info.parentMapID or info.parentMapID == 0 then break end
        info = A.MapInfo(info.parentMapID)
        guard = guard + 1
    end
    return nil
end

-- Centri con portali -----------------------------------------------------
local HUBS = {
    silvermoon = { map = 2393, region = QUELTHALAS },
    stormwind  = { map = 84,   region = EASTERN_KINGDOMS, faction = "Alliance" },
    orgrimmar  = { map = 85,   region = KALIMDOR,         faction = "Horde" },
    dornogal   = { map = 2339, region = KHAZ_ALGAR },
    harandar   = { map = HARANDAR,  region = "harandar" },
    voidstorm  = { map = VOIDSTORM, region = "voidstorm" },
}
T.HUBS = HUBS

-- Portali: da (mappa, x, y) verso un centro. 'where' = descrizione testuale.
local PORTALS = {
    { from = "silvermoon", map = 2393, x = 0.5333, y = 0.6624, to = "stormwind", faction = "Alliance", where = "SM_CAPITALS" },
    { from = "silvermoon", map = 2393, x = 0.5333, y = 0.6624, to = "orgrimmar", faction = "Horde",    where = "SM_CAPITALS" },
    { from = "silvermoon", map = 2393, x = 0.3670, y = 0.6857, to = "harandar",  where = "SM_HARANDAR" },
    { from = "silvermoon", map = 2393, x = 0.3528, y = 0.6565, to = "voidstorm", where = "SM_VOIDSTORM" },
    { from = "voidstorm",  map = 2405, x = 0.5160, y = 0.7020, to = "silvermoon" },
    { from = "stormwind",  map = 84,   x = 0.4840, y = 0.9450, to = "silvermoon", faction = "Alliance", where = "SW_PORTALS" },
    { from = "orgrimmar",  map = 85,   x = 0.5650, y = 0.8900, to = "silvermoon", faction = "Horde",    where = "OG_PORTALS" },
    { from = "stormwind",  map = 84,   x = 0.4750, y = 0.9220, to = "dornogal",   faction = "Alliance", where = "SW_PORTALS" },
    { from = "orgrimmar",  map = 85,   x = 0.5740, y = 0.8930, to = "dornogal",   faction = "Horde",    where = "OG_PORTALS" },
    -- coordinate non verificate: solo indicazione testuale
    { from = "dornogal",   map = 2339, to = "stormwind", faction = "Alliance", where = "DG_CAPITALS" },
    { from = "dornogal",   map = 2339, to = "orgrimmar", faction = "Horde",    where = "DG_CAPITALS" },
}
T.PORTALS = PORTALS

local HEARTHSTONE = 6948

-- Pietra del ritorno: centro di destinazione (se riconosciuto) e se e' pronta.
function T:Hearth()
    local bind = A.Call(GetBindLocation)
    if not bind or bind == "" then return nil end
    local hubKey
    for key, hub in pairs(HUBS) do
        local name = A.ZoneName(hub.map)
        if name and (bind == name or bind:find(name, 1, true) or name:find(bind, 1, true)) then
            hubKey = key
            break
        end
    end
    local ready = true
    local getCD = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
    local start, duration = A.Call(getCD, HEARTHSTONE)
    if start and duration and start > 0 and duration > 1.5 then
        ready = (start + duration - GetTime()) <= 0
    end
    return hubKey, ready, bind
end

---------------------------------------------------------------------------
-- Calcolo del percorso: Dijkstra sulle regioni (pochi nodi)
---------------------------------------------------------------------------
local COST_PORTAL, COST_HEARTH = 1, 1.5

local function Edges(region, faction, hearthHub)
    local out = {}
    for _, p in ipairs(PORTALS) do
        if HUBS[p.from].region == region and (not p.faction or p.faction == faction) then
            out[#out + 1] = { to = HUBS[p.to].region, cost = COST_PORTAL, kind = "portal", portal = p }
        end
    end
    if hearthHub and HUBS[hearthHub].region ~= region then
        out[#out + 1] = { to = HUBS[hearthHub].region, cost = COST_HEARTH, kind = "hearth", hub = hearthHub }
    end
    return out
end

local function ShortestPath(startRegion, goalRegion, faction, hearthHub)
    local dist, prev, done = { [startRegion] = 0 }, {}, {}
    for _ = 1, 20 do
        local best, bestD
        for r, d in pairs(dist) do
            if not done[r] and (not bestD or d < bestD) then best, bestD = r, d end
        end
        if not best then break end
        if best == goalRegion then break end
        done[best] = true
        -- la pietra del ritorno si usa al massimo una volta, all'inizio
        local hub = (best == startRegion) and hearthHub or nil
        for _, e in ipairs(Edges(best, faction, hub)) do
            local nd = bestD + e.cost
            if dist[e.to] == nil or nd < dist[e.to] then
                dist[e.to] = nd
                prev[e.to] = { from = best, edge = e }
            end
        end
    end
    if dist[goalRegion] == nil then return nil end
    local path, r = {}, goalRegion
    while prev[r] do
        table.insert(path, 1, prev[r].edge)
        r = prev[r].from
    end
    return path
end

-- Passi del percorso verso { mapID, x, y, name, note }.
-- x e y sono facoltativi: senza coordinate l'ultimo passo indica solo la zona
-- (piu' 'note', per esempio la sottozona) e non imposta un waypoint.
-- Ogni passo: { text, region = regione in cui si esegue, waypoint = {...} | nil }
function T:Plan(dest)
    local L = ns.L
    local steps = {}
    local here = A.PlayerMap()
    local startRegion, goalRegion = self:RegionOf(here), self:RegionOf(dest.mapID)
    local destZone = A.ZoneName(dest.mapID)
    local final = { region = goalRegion }
    if dest.x and dest.y then
        final.text = L.TRAVEL_FLY:format(dest.name or "?", destZone)
        final.waypoint = { dest.mapID, dest.x, dest.y, dest.name }
    else
        final.text = L.TRAVEL_ZONE:format(destZone, dest.name or "?")
    end
    if dest.note then final.text = final.text .. " - " .. dest.note end
    if not startRegion or not goalRegion or startRegion == goalRegion then
        steps[1] = final
        return steps
    end
    local faction = A.Call(UnitFactionGroup, "player")
    local hearthHub, hearthReady = self:Hearth()
    local path = ShortestPath(startRegion, goalRegion, faction, hearthReady and hearthHub or nil)
    if not path then
        steps[1] = { text = L.TRAVEL_NO_ROUTE, region = startRegion }
        steps[2] = final
        return steps
    end
    local region = startRegion
    for _, e in ipairs(path) do
        if e.kind == "hearth" then
            steps[#steps + 1] = { text = L.TRAVEL_HEARTH:format(A.ZoneName(HUBS[e.hub].map)), region = region }
        else
            local p = e.portal
            local hubName = A.ZoneName(HUBS[p.from].map)
            local toName = A.ZoneName(HUBS[p.to].map)
            local where = p.where and L["WHERE_" .. p.where] or nil
            local text
            if p.x then
                text = L.TRAVEL_PORTAL:format(toName, hubName, p.x * 100, p.y * 100)
            else
                text = L.TRAVEL_PORTAL_NOCOORD:format(toName, hubName)
            end
            if where then text = text .. " - " .. where end
            steps[#steps + 1] = {
                text = text, region = region,
                waypoint = p.x and { p.map, p.x, p.y, L.TRAVEL_PORTAL_TITLE:format(toName) } or nil,
            }
        end
        region = e.to
    end
    steps[#steps + 1] = final
    return steps
end

---------------------------------------------------------------------------
-- Navigatore
---------------------------------------------------------------------------
function T:Start(dest)
    local L = ns.L
    self.route = self:Plan(dest)
    self.dest = dest
    self.step = 0
    ns:Print(L.TRAVEL_HEADER, dest.name or "?")
    for i, s in ipairs(self.route) do ns:Print("  %d. %s", i, s.text) end
    self:Advance(true)
end

function T:Stop()
    if self.route then ns:Print(ns.L.TRAVEL_STOPPED) end
    self.route, self.dest, self.step = nil, nil, 0
    if ns.Panel then ns.Panel:UpdateRoute() end
end

-- Sceglie il passo da eseguire in base alla regione attuale.
function T:Advance(force)
    if not self.route then return end
    local region = self:RegionOf(A.PlayerMap())
    local target = 1
    for i, s in ipairs(self.route) do
        if s.region == region then target = i end
    end
    if target ~= self.step or force then
        self.step = target
        local s = self.route[target]
        if s.waypoint then
            local w = s.waypoint
            ns:SetWaypoint(w[1], w[2], w[3], w[4])
        end
        if not force then ns:Print(ns.L.TRAVEL_NEXT, target, #self.route, s.text) end
    end
    if ns.Panel then ns.Panel:UpdateRoute() end
end

function T:CurrentText()
    if not self.route then return nil end
    local s = self.route[self.step]
    return s and ns.L.TRAVEL_STEP:format(self.step, #self.route, s.text) or nil
end
