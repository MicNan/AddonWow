-- RotAssist Companion - Pets
-- Scheda Pet: pet da cacciatore rari e notevoli di Midnight e spirit beast
-- di tutte le espansioni (PetsData.lua), consigli su quale famiglia usare,
-- anteprima 3D del modello e percorso (con i portali) fino al punto in cui
-- si trovano.
--
-- Solo lettura: l'addon non doma e non seleziona bersagli. Usa
--  * C_StableInfo (alla stalla) e il pet evocato per sapere quali pet hai;
--  * C_VignetteInfo per accorgersi quando uno dei rari compare sulla
--    minimappa (avviso in chat con la posizione presa dal gioco).

local _, ns = ...
local A = ns.API

local Pets = { filter = "all", alerted = {}, lastScan = 0 }
ns.Pets = Pets

local BEAST_MASTERY = 253
local ALERT_AGAIN   = 600     -- stesso rare: nuovo avviso dopo 10 minuti
local SEEN_FRESH    = 1800    -- posizione vista di recente: 30 minuti
local SCAN_EVERY    = 2       -- secondi tra due letture delle vignette
local ZONE_ORDER    = { 2413, 2405, 2395, 2437 }   -- Harandar, Voidstorm, Eversong, Zul'Aman
local FILTERS       = { "all", "exotic", "spirit", "missing" }
Pets.FILTERS = FILTERS

local byNpc = {}
for _, pet in ipairs(ns.PetsData.pets) do byNpc[pet.npc] = pet end
Pets.byNpc = byNpc

local function FamilyName(pet)
    local fam = ns.PetsData.families[pet.family]
    return fam and fam.name or pet.family
end

-- ID della creatura da un GUID ("Creature-0-...-npcID-..." oppure "Pet-...")
local function NpcFromGUID(guid)
    if type(guid) ~= "string" then return nil end
    local kind, npc = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
    if kind == "Creature" or kind == "Vehicle" or kind == "Pet" then return tonumber(npc) end
    return nil
end
Pets.NpcFromGUID = NpcFromGUID

---------------------------------------------------------------------------
-- Il tuo personaggio
---------------------------------------------------------------------------
function Pets:IsHunter()
    local _, class = A.Call(UnitClass, "player")
    return class == "HUNTER"
end

function Pets:IsBeastMastery()
    local getSpec = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
    local getInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
    local index = A.Call(getSpec)
    if not index then return false end
    return A.Call(getInfo, index) == BEAST_MASTERY
end

function Pets:Owned(npc)
    local owned = ns.db and ns.db.ownedPets
    return owned and owned[npc] and true or false
end

-- Stalla aperta: elenco completo dei pet (sostituisce quello salvato).
function Pets:ScanStable()
    if not C_StableInfo then return end
    local found, n = {}, 0
    local function add(info)
        local id = type(info) == "table" and A.Plain(info.creatureID)
        if type(id) == "number" and id > 0 then found[id] = true; n = n + 1 end
    end
    for _, fn in ipairs({ C_StableInfo.GetActivePetList, C_StableInfo.GetStabledPetList }) do
        local list = A.Call(fn)
        if type(list) == "table" then for _, info in ipairs(list) do add(info) end end
    end
    if n == 0 and C_StableInfo.GetStablePetInfo then
        for i = 1, 205 do add(A.Call(C_StableInfo.GetStablePetInfo, i)) end
    end
    if n > 0 then
        ns.db.ownedPets = found
        ns:Log(("[pet] stalla letta: %d pet"):format(n))
    end
end

-- Pet evocato: lo aggiungiamo all'elenco (senza togliere gli altri).
function Pets:CheckSummoned()
    local npc = NpcFromGUID(A.Call(UnitGUID, "pet"))
    if npc and ns.db then
        ns.db.ownedPets = ns.db.ownedPets or {}
        ns.db.ownedPets[npc] = true
    end
end

---------------------------------------------------------------------------
-- Rari sulla minimappa (vignette)
---------------------------------------------------------------------------
function Pets:ScanVignettes(force)
    if not (C_VignetteInfo and C_VignetteInfo.GetVignettes) or not ns.db then return end
    local now = GetTime()
    if not force and now - self.lastScan < SCAN_EVERY then return end
    self.lastScan = now
    local list = A.Call(C_VignetteInfo.GetVignettes)
    if type(list) ~= "table" then return end
    for _, vguid in ipairs(list) do
        local info = A.Call(C_VignetteInfo.GetVignetteInfo, vguid)
        local pet = type(info) == "table" and byNpc[NpcFromGUID(A.Plain(info.objectGUID)) or 0]
        if pet then self:OnSpotted(pet, vguid) end
    end
end

function Pets:OnSpotted(pet, vguid)
    local L = ns.L
    local map = A.PlayerMap() or pet.map
    local x, y
    local pos = A.Call(C_VignetteInfo.GetVignettePosition, vguid, map)
    if type(pos) == "table" then x, y = A.Plain(pos.x), A.Plain(pos.y) end
    if type(x) ~= "number" or type(y) ~= "number" then x, y = nil, nil end
    ns.db.petSeen = ns.db.petSeen or {}
    ns.db.petSeen[pet.npc] = { map = map, x = x, y = y, t = time() }

    local last = self.alerted[pet.npc]
    if last and GetTime() - last < ALERT_AGAIN then return end
    self.alerted[pet.npc] = GetTime()
    if not ns.db.petAlerts or self:Owned(pet.npc) then return end
    local where = x and L.PET_AT_COORDS:format(A.ZoneName(map), x * 100, y * 100) or A.ZoneName(map)
    ns:Print(L.PET_SPOTTED, pet.name, FamilyName(pet), where)
    if PlaySound then pcall(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959) end
    if ns.Panel then ns.Panel:RequestRefresh() end
end

-- Posizione vista di recente (o nil)
function Pets:Seen(npc)
    local s = ns.db and ns.db.petSeen and ns.db.petSeen[npc]
    if type(s) ~= "table" or not s.t then return nil end
    local age = time() - s.t
    if age < 0 or age > SEEN_FRESH then return nil end
    return s, age
end

---------------------------------------------------------------------------
-- Anteprima 3D
---------------------------------------------------------------------------
local PREVIEW_W, PREVIEW_H, MODEL_H = 260, 360, 240

function Pets:CreatePreview()
    local panel = ns.Panel.frame
    if not panel then return nil end
    local L = ns.L
    local f = CreateFrame("Frame", "RotAssistCompanionPetPreview", panel, "BackdropTemplate")
    f:SetSize(PREVIEW_W, PREVIEW_H)
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
    end

    local m = CreateFrame("PlayerModel", nil, f)
    m:SetPoint("TOPLEFT", 8, -8)
    m:SetPoint("TOPRIGHT", -8, -8)
    m:SetHeight(MODEL_H)
    m:EnableMouse(true)
    m:EnableMouseWheel(true)
    -- trascina per ruotare, rotellina per lo zoom
    m:SetScript("OnMouseDown", function(self) self.dragX = GetCursorPosition() end)
    m:SetScript("OnMouseUp", function(self) self.dragX = nil end)
    m:SetScript("OnHide", function(self) self.dragX = nil end)
    m:SetScript("OnUpdate", function(self)
        if not self.dragX then return end
        local x = GetCursorPosition()
        self.facing = (self.facing or 0) + (x - self.dragX) * 0.02
        self.dragX = x
        pcall(self.SetFacing, self, self.facing)
    end)
    m:SetScript("OnMouseWheel", function(self, delta)
        self.zoom = math.min(2.5, math.max(0.5, (self.zoom or 1) - delta * 0.1))
        pcall(self.SetCamDistanceScale, self, self.zoom)
    end)
    pcall(m.SetScript, m, "OnModelLoaded", function() f.missing:Hide() end)
    f.model = m

    f.missing = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.missing:SetPoint("CENTER", m, "CENTER", 0, 0)
    f.missing:SetWidth(PREVIEW_W - 40)
    f.missing:SetText(L.PET_NO_MODEL)
    f.missing:Hide()

    f.name = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.name:SetPoint("TOPLEFT", m, "BOTTOMLEFT", 2, -6)
    f.name:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    f.name:SetJustifyH("LEFT")

    f.info = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.info:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", 0, -4)
    f.info:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    f.info:SetJustifyH("LEFT")
    f.info:SetJustifyV("TOP")
    if f.info.SetWordWrap then f.info:SetWordWrap(true) end

    f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.hint:SetPoint("BOTTOMLEFT", 10, 8)
    f.hint:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    f.hint:SetJustifyH("LEFT")
    f.hint:SetText(L.PET_PREVIEW_HINT)

    f:Hide()
    self.preview = f
    return f
end

-- A destra del pannello, oppure a sinistra se non c'e' spazio.
local function PlacePreview(f, panel)
    f:ClearAllPoints()
    local right = panel.GetRight and panel:GetRight()
    local screen = UIParent and UIParent.GetWidth and UIParent:GetWidth()
    if type(right) == "number" and type(screen) == "number" and right + PREVIEW_W + 8 > screen then
        f:SetPoint("TOPRIGHT", panel, "TOPLEFT", -4, 0)
    else
        f:SetPoint("TOPLEFT", panel, "TOPRIGHT", 4, 0)
    end
end

function Pets:ShowPreview(pet)
    local f = self.preview or self:CreatePreview()
    if not (f and pet) then return end
    local L = ns.L
    PlacePreview(f, ns.Panel.frame)
    f:Show()
    if f.npc ~= pet.npc then
        f.npc = pet.npc
        local m = f.model
        m.facing, m.zoom = 0, 1
        pcall(m.ClearModel, m)
        f.missing:Hide()
        local ok = pcall(m.SetCreature, m, pet.npc)
        pcall(m.SetFacing, m, 0)
        pcall(m.SetCamDistanceScale, m, 1)
        -- se il client non conosce ancora la creatura il modello resta vuoto
        local npc = pet.npc
        ns:After(1.5, function()
            if f.npc ~= npc then return end
            local loaded = ok and m.GetModelFileID and A.Call(m.GetModelFileID, m)
            if not loaded then f.missing:Show() end
        end)
    end
    f.name:SetText(pet.name)
    f.info:SetText(table.concat(self:Details(pet, true), "\n"))
    -- il riquadro cresce con il testo (le spirit beast hanno istruzioni lunghe)
    local h = f.info:GetStringHeight()
    if type(h) == "number" and h > 0 then f:SetHeight(math.max(PREVIEW_H, MODEL_H + 70 + h)) end
end

function Pets:HidePreview()
    if self.preview then self.preview:Hide() end
end

---------------------------------------------------------------------------
-- Testi
---------------------------------------------------------------------------
-- Righe descrittive di un pet (tooltip e anteprima)
function Pets:Details(pet, short)
    local L = ns.L
    local fam = ns.PetsData.families[pet.family]
    local out = {}
    out[#out + 1] = L.PET_FAMILY:format(FamilyName(pet),
        fam and L["PET_ABILITY_" .. fam.ability] or "?")
    local place = A.ZoneName(pet.map) .. (pet.where and (" - " .. pet.where) or "")
    if pet.x then place = place .. (" (%.1f, %.1f)"):format(pet.x * 100, pet.y * 100) end
    out[#out + 1] = place
    local seen, age = self:Seen(pet.npc)
    if seen and seen.x then
        out[#out + 1] = L.PET_SEEN_AT:format(A.TimeText(math.max(60, age)), seen.x * 100, seen.y * 100)
    end
    if pet.exotic then out[#out + 1] = L.PET_REQ_EXOTIC end
    if pet.florafaun then out[#out + 1] = L.PET_REQ_FLORAFAUN end
    if pet.tome then out[#out + 1] = L.PET_DROPS_TOME end
    if pet.unique then out[#out + 1] = L.PET_UNIQUE end
    if pet.elite then out[#out + 1] = L.PET_ELITE end
    if pet.how then out[#out + 1] = L[pet.how] end
    if self:Owned(pet.npc) then out[#out + 1] = L.PET_OWNED end
    if not short then
        -- percorso dalla posizione attuale
        local steps = ns.Travel:Plan(self:Destination(pet))
        if #steps > 1 then
            out[#out + 1] = L.PET_ROUTE
            for i, st in ipairs(steps) do out[#out + 1] = ("%d. %s"):format(i, st.text) end
        end
    end
    return out
end

function Pets:Destination(pet)
    local seen = self:Seen(pet.npc)
    if seen and seen.x and seen.map then
        return { mapID = seen.map, x = seen.x, y = seen.y, name = pet.name, note = pet.where }
    end
    return { mapID = pet.map, x = pet.x, y = pet.y, name = pet.name, note = pet.where }
end

local function Tags(pet)
    local L, t = ns.L, {}
    if pet.tag then t[#t + 1] = L["PET_TAG_" .. pet.tag] end
    -- le spirit beast sono tutte esotiche: l'etichetta sarebbe ripetuta
    if pet.exotic and pet.group ~= "spirit" then t[#t + 1] = L.PET_TAG_EXOTIC end
    if pet.florafaun then t[#t + 1] = L.PET_TAG_FLORAFAUN end
    if pet.tome then t[#t + 1] = L.PET_TAG_TOME end
    if pet.unique then t[#t + 1] = L.PET_TAG_UNIQUE end
    return table.concat(t, ", ")
end

function Pets:Passes(pet)
    if self.filter == "exotic" then return pet.exotic and true or false end
    if self.filter == "spirit" then return pet.group == "spirit" end
    if self.filter == "missing" then return not self:Owned(pet.npc) end
    return true
end

function Pets:CycleFilter()
    local nextKey = FILTERS[1]
    for i, key in ipairs(FILTERS) do
        if key == self.filter then nextKey = FILTERS[i % #FILTERS + 1] end
    end
    self.filter = nextKey
    if ns.Panel then ns.Panel:Refresh() end
end

---------------------------------------------------------------------------
-- Righe della scheda
---------------------------------------------------------------------------
-- Zona dell'elenco in cui si trova il giocatore (anche da una sottozona,
-- per esempio Silvermoon dentro Eversong)
local function PlayerZone()
    local info, guard = A.MapInfo(A.PlayerMap()), 0
    while info and guard < 8 do
        for _, id in ipairs(ZONE_ORDER) do
            if info.mapID == id then return id end
        end
        if not info.parentMapID or info.parentMapID == 0 then break end
        info = A.MapInfo(info.parentMapID)
        guard = guard + 1
    end
    return nil
end

-- Riga di un pet: clic = percorso, mouse sopra = anteprima, clic destro = Wowhead
function Pets:PetRow(pet, label)
    local L = ns.L
    local isOwned = self:Owned(pet.npc)
    local seen = self:Seen(pet.npc)
    local tip = { pet.name }
    for _, line in ipairs(self:Details(pet)) do tip[#tip + 1] = line end
    tip[#tip + 1] = L.PET_HINT_PREVIEW
    return {
        text = ("%s - %s"):format(pet.name, label),
        right = seen and L.PET_SEEN_NOW or (isOwned and L.PET_TAG_OWNED or Tags(pet)),
        icon = "Interface\\Icons\\Ability_Hunter_BeastTaming",
        color = seen and { 1, 0.82, 0 } or (isOwned and { 0.5, 0.9, 0.5 }) or nil,
        tooltip = tip,
        dest = self:Destination(pet),
        preview = pet,
        link = { npc = pet.npc }, linkTitle = pet.name,
    }
end

function Pets:Rows()
    local L = ns.L
    local rows = {}
    local function add(r) rows[#rows + 1] = r end

    -- il tuo cacciatore
    add({ header = L.HDR_PET_YOU })
    if not self:IsHunter() then
        add({ text = L.PET_NOT_HUNTER, dim = true, wrap = true })
    elseif not self:IsBeastMastery() then
        add({ text = L.PET_NOT_BM, color = { 1, 0.82, 0 }, wrap = true })
    end
    local owned = 0
    for _ in pairs(ns.db.ownedPets or {}) do owned = owned + 1 end
    add({ text = owned > 0 and L.PET_OWNED_COUNT:format(owned) or L.PET_OWNED_UNKNOWN, dim = owned == 0, wrap = true })

    -- quale pet usare
    add({ header = L.HDR_PET_ADVICE })
    for _, adv in ipairs(ns.PetsData.advice) do
        add({ text = L[adv.key], wrap = true, tooltip = { L[adv.key], L.PET_SOURCE_ICY },
              link = adv.search and { search = adv.search } or nil, linkTitle = adv.search })
    end
    add({ text = L.PET_FLORAFAUN_INFO, wrap = true, color = { 0.6, 1, 0.6 },
          tooltip = { ns.PetsData.tome, L.PET_FLORAFAUN_INFO, L.PET_SOURCE_METHOD },
          link = { search = ns.PetsData.tome }, linkTitle = ns.PetsData.tome })

    -- pet per zona (prima la zona in cui ti trovi)
    local order, hereZone = {}, PlayerZone()
    if hereZone then order[1] = hereZone end
    for _, id in ipairs(ZONE_ORDER) do if id ~= hereZone then order[#order + 1] = id end end

    local shown = 0
    for _, zone in ipairs(order) do
        local list = {}
        for _, pet in ipairs(ns.PetsData.pets) do
            if pet.map == zone and not pet.group and self:Passes(pet) then list[#list + 1] = pet end
        end
        if #list > 0 then
            add({ header = L.HDR_PET_ZONE:format(A.ZoneName(zone), #list) })
            for _, pet in ipairs(list) do
                add(self:PetRow(pet, FamilyName(pet)))
                shown = shown + 1
            end
        end
    end

    -- spirit beast di tutte le espansioni, divise per continente
    local groups, continents = {}, {}
    for _, pet in ipairs(ns.PetsData.pets) do
        if pet.group == "spirit" and self:Passes(pet) then
            local _, continent = A.ContinentOf(pet.map)
            continent = continent or A.ZoneName(pet.map)
            if not groups[continent] then
                groups[continent] = {}
                continents[#continents + 1] = continent
            end
            table.insert(groups[continent], pet)
        end
    end
    if #continents > 0 then
        add({ header = L.HDR_PET_SPIRIT })
        add({ text = L.PET_SPIRIT_INFO, wrap = true, color = { 0.6, 0.85, 1 },
              tooltip = { L.HDR_PET_SPIRIT, L.PET_SPIRIT_INFO }, link = { search = "Spirit Beast" },
              linkTitle = "Spirit Beast" })
        table.sort(continents)
        for _, continent in ipairs(continents) do
            add({ header = L.HDR_PET_SPIRIT_IN:format(continent, #groups[continent]) })
            for _, pet in ipairs(groups[continent]) do
                add(self:PetRow(pet, A.ZoneName(pet.map)))
                shown = shown + 1
            end
        end
    end
    if shown == 0 then add({ text = L.PET_NONE_FILTER, dim = true }) end

    add({ header = L.HDR_PET_NOTES })
    add({ text = L.PET_RARE_NOTE, dim = true, wrap = true })
    add({ text = L.PET_SOURCES, dim = true, wrap = true })
    return rows
end
