-- Scenario di smoke test
local ns = {}
for _, f in ipairs(FILES) do
    local chunk, err = load(f.src, "@" .. f.name)
    if not chunk then error(err) end
    chunk("RotAssist", ns)
end
local RA = RotAssist
RA.ReportError = function(self, e) print("!!! ERRORE: " .. tostring(e)); table.insert(MOCK.errors, tostring(e)) end

MOCK.names = { [34026] = "KillCommand", [217200] = "BarbedShot", [19574] = "BestialWrath", [193455] = "CobraShot",
    [1264359] = "WildThrash", [466930] = "BlackArrow", [392060] = "WailingArrow", [471876] = "Howl", [321530] = "Bloodshed" }
local KC, BS, BW, COBRA, WT, BA, WA = 34026, 217200, 19574, 193455, 1264359, 466930, 392060
for _, id in ipairs({ KC, BS, BW, COBRA, WT, 471876, 321530, 257284 }) do MOCK.known[id] = true end
MOCK.charges[BS] = { cur = 2, max = 2, dur = 12 }
MOCK.charges[KC] = { cur = 2, max = 2, dur = 6 }
MOCK.cdBase = { [BW] = 30, [WT] = 10, [BA] = 10, [321530] = 60, [WA] = 0 }

local function Cast(id)
    if MOCK.cdRemaining(61304) > 0 then return false end
    local c = MOCK.charges[id]
    if c then
        MOCK.advance(id)
        if c.cur < 1 then return false end
        if c.cur == c.max then c.start = MOCK.now end
        c.cur = c.cur - 1
    elseif (MOCK.cdBase[id] or 0) > 0 then
        if MOCK.cdRemaining(id) > 0 then return false end
        MOCK.cd[id] = { start = MOCK.now, dur = MOCK.cdBase[id] }
    end
    MOCK.cd[61304] = { start = MOCK.now, dur = 1.25 }
    if id == BW and MOCK.known[BA] then MOCK.override[BW] = WA; MOCK.wfEnd = MOCK.now + 15 end
    if id == WA then MOCK.override[BW] = nil end
    MOCK.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", id)
    return true
end

local function NativePick()
    MOCK.advance(KC)
    local nplates = 0 for _ in pairs(MOCK.plates) do nplates = nplates + 1 end
    if nplates >= 2 and MOCK.cdRemaining(WT) <= 0 then return WT end
    if MOCK.charges[KC].cur > 0 then return KC end
    return COBRA
end

local function Run(label, seconds)
    local seq = {}
    local stop = MOCK.now + seconds
    while MOCK.now < stop do
        MOCK.now = MOCK.now + 0.1
        if MOCK.wfEnd and MOCK.now > MOCK.wfEnd then MOCK.override[BW] = nil; MOCK.wfEnd = nil end
        MOCK.native = NativePick()
        RA:Tick()
        MOCK.modes = MOCK.modes or {}; local m = RA.lastCtx and RA.lastCtx.mode or "?"; MOCK.modes[m] = (MOCK.modes[m] or 0) + 1
        local r = RA.lastResult
        if MOCK.cdRemaining(61304) <= 0 and r and r.primary then
            local p = r.primary
            if Cast(p.spell) then
                local nx = {}
                for _, e in ipairs(r.next) do nx[#nx + 1] = MOCK.names[e.spell] or e.spell end
                seq[#seq + 1] = ("%5.1f %-13s %-6s %-30s | next: %s"):format(MOCK.now - 1000, MOCK.names[p.spell] or p.spell,
                    p.source, (p.rule and p.rule.id or p.reason or ""):sub(1, 30), table.concat(nx, ","))
            end
        end
    end
    local ms = "" for k, v in pairs(MOCK.modes or {}) do ms = ms .. k .. "=" .. v .. " " end MOCK.modes = {}
    print("tick per modo: " .. ms)
    print("=== " .. label .. " ===  modo finale: " .. tostring(RA.lastCtx and RA.lastCtx.mode) .. " via " .. tostring(RA.lastCtx and RA.lastCtx.modeSource))
    for i = 1, math.min(#seq, 28) do print(seq[i]) end
end

MOCK.fire("ADDON_LOADED", "RotAssist")
MOCK.fire("PLAYER_LOGIN")
RA.db.debug = false
print("spec:", RA.activeSpec and RA.activeSpec.name, "hero:", RA.hero)

-- fuori combattimento: un Barbed Shot per far imparare la ricarica
Cast(BS); MOCK.now = MOCK.now + 1; RA:Tick()
print("ricarica BS appresa:", RA.db.learned[BS] and RA.db.learned[BS].recharge)
MOCK.now = MOCK.now + 20

MOCK.restricted = true
MOCK.fire("PLAYER_REGEN_DISABLED")
Run("Pack Leader ST, combattimento (dati segreti)", 45)

-- AoE con nameplate
for i = 1, 4 do MOCK.plates["nameplate" .. i] = true; MOCK.fire("NAME_PLATE_UNIT_ADDED", "nameplate" .. i) end
Run("Pack Leader AoE (4 nameplate)", 30)

-- Dark Ranger
MOCK.known[471876] = nil; MOCK.known[BA] = true
MOCK.fire("TRAIT_CONFIG_UPDATED")
print("hero ora:", RA.hero)
Run("Dark Ranger AoE", 30)
for i = 1, 4 do MOCK.plates["nameplate" .. i] = nil; MOCK.fire("NAME_PLATE_UNIT_REMOVED", "nameplate" .. i) end
Run("Dark Ranger ST", 30)

-- comandi e avvisi
MOCK.pet.dead = true
RA:Tick()
local al = RA.Alerts:Collect(RA.activeSpec)
for _, a in ipairs(al) do print("avviso:", a.text) end
MOCK.restricted = false; MOCK.fire("PLAYER_REGEN_ENABLED"); MOCK.pet.dead = false; MOCK.pet.hp = 30
MOCK.auras.target = {}
RA:Tick()
for _, a in ipairs(RA.Alerts:Collect(RA.activeSpec)) do print("avviso OOC:", a.text) end
SlashCmdList.ROTASSIST("mode")
SlashCmdList.ROTASSIST("scale 1.3")
SlashCmdList.ROTASSIST("debug on")
RA:Tick()
SlashCmdList.ROTASSIST("why")
MOCK.restricted = true
SlashCmdList.ROTASSIST("probe")
SlashCmdList.ROTASSIST("bogus")

-- cambio spec verso una senza modulo
MOCK.specID = 254
MOCK.fire("PLAYER_SPECIALIZATION_CHANGED", "player")
RA:Tick()
print("spec generica:", RA.activeSpec and RA.activeSpec.name, "primary:", RA.lastResult and RA.lastResult.primary and RA.lastResult.primary.spell)
-- nessuna spec (livello basso)
MOCK.specID = nil
MOCK.fire("PLAYER_SPECIALIZATION_CHANGED", "player")
RA:Tick()
-- API AssistedCombat assente
MOCK.specID = 253; MOCK.fire("PLAYER_SPECIALIZATION_CHANGED", "player")
C_AssistedCombat = nil
RA:Tick()
print("senza AssistedCombat primary:", RA.lastResult.primary and MOCK.names[RA.lastResult.primary.spell], RA.lastResult.nativeWhy)

print("ERRORI TOTALI:", #MOCK.errors)
print("--- launcher ---")
local btn = RotAssistMinimapButton
print("pulsante creato:", btn ~= nil, "visibile:", btn and btn:IsShown())
btn._scripts.OnEnter(btn)
btn._scripts.OnClick(btn, "RightButton"); print("locked:", RA.db.locked)
btn._scripts.OnClick(btn, "RightButton"); print("locked:", RA.db.locked)
btn._scripts.OnClick(btn, "MiddleButton"); print("mode:", RA.db.mode)
MOCK.shift = true; btn._scripts.OnClick(btn, "LeftButton"); MOCK.shift = false; print("shown:", RA.db.shown)
btn._scripts.OnClick(btn, "LeftButton")
btn._scripts.OnDragStart(btn); btn._scripts.OnUpdate(btn); btn._scripts.OnDragStop(btn); print("angolo dopo drag:", RA.db.minimapAngle)
RotAssist_OnAddonCompartmentClick("RotAssist", "RightButton"); print("locked via compartment:", RA.db.locked)
RotAssist_OnAddonCompartmentEnter("RotAssist", btn); RotAssist_OnAddonCompartmentLeave()
SlashCmdList.ROTASSIST("minimap"); print("minimap visibile:", btn:IsShown())
GetMinimapShape = function() return "SQUARE" end; SlashCmdList.ROTASSIST("minimap"); print("minimap visibile (quadrata):", btn:IsShown())

print("--- wowhead ---")
RA:Tick()
SlashCmdList.ROTASSIST("wowhead")
GetLocale = function() return "itIT" end
SlashCmdList.ROTASSIST("wh 191634")
StaticPopup_Show = nil
SlashCmdList.ROTASSIST("wowhead 19574")

print("--- probe shaman ---")
UnitClass = function() return "Shaman", "SHAMAN" end
C_UnitAuras.GetPlayerAuraBySpellID = function(id) if id == 344179 then return { applications = 7 } end end
GetTotemInfo = function() return true, "Healing Stream Totem" end
SlashCmdList.ROTASSIST("probe")

print("--- log ---")
SlashCmdList.ROTASSIST("log clear")
SlashCmdList.ROTASSIST("info")
SlashCmdList.ROTASSIST("note test manichino")
SlashCmdList.ROTASSIST("log")
for i, l in ipairs(RA.db.log) do print("LOG", l) end
print("ERRORI TOTALI FINALI:", #MOCK.errors)
-- lingua e tasti assegnati
print("--- lingua ---")
SlashCmdList.ROTASSIST("lang en")
print("avviso EN:", RA.L.PET_DEAD, "| aiuto:", RA.L.HELP[1])
SlashCmdList.ROTASSIST("lang it")
print("avviso IT:", RA.L.PET_DEAD)
SlashCmdList.ROTASSIST("lang xx")
print("--- keybind ---")
GetBindingKey = function(cmd) if cmd == "ACTIONBUTTON3" then return "SHIFT-3" end end
C_ActionBar = { FindSpellActionButtons = function(id) if id == 34026 then return { 3 } end return {} end }
RA.Keybinds.dirty = true
print("tasto Kill Command:", RA.Keybinds:Get(34026), "| Cobra:", tostring(RA.Keybinds:Get(193455)))
