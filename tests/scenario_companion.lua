-- Scenario di RotAssist Companion
local ns = {}
for _, f in ipairs(FILES) do
    local chunk, err = load(f.src, "@" .. f.name)
    if not chunk then error(err) end
    chunk("RotAssist_Companion", ns)
end
local C = RotAssistCompanion
C.ReportError = function(self, e) print("!!! ERRORE: " .. tostring(e)); table.insert(MOCK.errors, tostring(e)) end

MOCK.fire("ADDON_LOADED", "RotAssist_Companion")
MOCK.fire("PLAYER_ENTERING_WORLD", true, false)
print("lingua:", C.lang)

local function Dump(tab)
    C.Panel:Show(tab)
    print(("=== scheda %s (stato: %s)"):format(tab, tostring(C.Panel.frame.status._text)))
    for i, row in ipairs(C.Panel.rows) do
        if row._shown and row.data then
            local d = row.data
            print(d.header and ("  # " .. d.header) or ("    " .. tostring(d.text) .. (d.right and ("  | " .. d.right) or "")
                .. (d.waypoint and "  [wp]" or "") .. (d.link and "  [link]" or "")))
        end
    end
end

-- il mock dei FontString non conserva il testo: aggiungiamolo
do
    local fs = CreateFrame("Frame"):CreateFontString()
    local mt = getmetatable(fs)
    local index = mt.__index
    mt.__index = function(t, k)
        if k == "SetText" then return function(self, v) self._text = v end end
        return index(t, k)
    end
end

C.Panel:Toggle()
for _, tab in ipairs({ "delves", "events", "weekly", "leveling" }) do Dump(tab) end

-- clic sulle righe: waypoint e link
print("--- clic ---")
C.Panel:Show("delves")
for _, row in ipairs(C.Panel.rows) do
    if row._shown and row.data and row.data.waypoint then
        row._scripts.OnClick(row, "LeftButton")
        row._scripts.OnClick(row, "RightButton")
        row._scripts.OnEnter(row)
        break
    end
end
print("waypoint impostato:", MOCK.waypoint and (MOCK.waypoint.m .. " " .. MOCK.waypoint.x) or "no")
TomTom = { AddWaypoint = function(self, m, x, y, opts) MOCK.tomtom = opts.title end }
for _, row in ipairs(C.Panel.rows) do
    if row._shown and row.data and row.data.waypoint then row._scripts.OnClick(row, "LeftButton") break end
end
print("TomTom:", tostring(MOCK.tomtom))

-- filtro solo abbondanti
C:Set("onlyBountiful", true)
local n = 0
for _, row in ipairs(C.Panel.rows) do if row._shown and row.data and row.data.waypoint then n = n + 1 end end
print("delve con filtro abbondanti:", n)

-- XP/ora
MOCK.now = MOCK.now + 600; MOCK.xp = 4000; MOCK.fire("PLAYER_XP_UPDATE", "player")
MOCK.now = MOCK.now + 600; MOCK.xp = 500; MOCK.xpMax = 12000; MOCK.fire("PLAYER_XP_UPDATE", "player")   -- level up
print("XP guadagnata nella sessione:", C.Leveling.session.gained, "(attesa 3000 + 6000 + 500 = 9500)")
Dump("leveling")

-- combattimento: niente aggiornamento
MOCK.restricted = true
C.Panel:Refresh()
print("in combattimento:", C.Panel.frame.status._text)
MOCK.restricted = false

-- comandi
for _, cmd in ipairs({ "", "eventi", "weekly", "riepilogo", "lang en", "lang xx", "minimap", "reset", "boh" }) do
    SlashCmdList.ROTASSISTCOMPANION(cmd)
end
RotAssistCompanion_OnAddonCompartmentClick("x", "LeftButton")
RotAssistCompanion_OnAddonCompartmentEnter("x", C.Panel.frame)

-- ===================== Viaggio =====================
local function Route(label, playerMap, faction, dest)
    MOCK.playerMap, MOCK.faction = playerMap, faction
    local steps = C.Travel:Plan(dest)
    print(("--- percorso: %s (%d passi)"):format(label, #steps))
    for i, st in ipairs(steps) do
        print(("   %d. [%s] %s%s"):format(i, tostring(st.region), st.text, st.waypoint and "  [wp]" or ""))
    end
    return steps
end
local delve = { mapID = 2395, x = 0.4, y = 0.5, name = "Shadowguard Point" }
local harandar = { mapID = 2413, x = 0.5, y = 0.5, name = "Evento Harandar" }
MOCK.hearthCD = 999
Route("Eversong -> Eversong", 2395, "Alliance", delve)
Route("Stormwind -> Eversong", 84, "Alliance", delve)
Route("Orgrimmar -> Harandar", 85, "Horde", harandar)
MOCK.hearthCD = 0
Route("Dornogal -> Eversong, pietra pronta", 2339, "Alliance", delve)
MOCK.hearthCD = 999
Route("Dornogal -> Eversong, pietra in ricarica", 2339, "Alliance", delve)
Route("Voidstorm -> Eversong", 2405, "Horde", delve)
Route("Thunder Bluff (Alleanza) -> Eversong", 88, "Alliance", delve)

print("--- navigatore")
MOCK.playerMap, MOCK.faction = 85, "Horde"
C.Travel:Start(harandar)
print("passo iniziale:", C.Travel.step, "waypoint:", MOCK.waypoint and (MOCK.waypoint.m .. " " .. MOCK.waypoint.x) or "-")
MOCK.playerMap = 2393; MOCK.fire("ZONE_CHANGED_NEW_AREA")
print("a Silvermoon -> passo:", C.Travel.step, "waypoint:", MOCK.waypoint and (MOCK.waypoint.m .. " " .. MOCK.waypoint.x) or "-")
MOCK.playerMap = 2413; MOCK.fire("ZONE_CHANGED_NEW_AREA")
print("a Harandar -> passo:", C.Travel.step, "testo pannello:", C.Panel.frame.route._text)
SlashCmdList.ROTASSISTCOMPANION("stop")
print("dopo stop:", tostring(C.Travel.route), "| testo:", C.Panel.frame.route._text)

-- clic su una delve dal pannello = percorso
MOCK.playerMap, MOCK.faction = 84, "Alliance"
C.API.ClearCache()
C.Panel:Show("delves")
for _, row in ipairs(C.Panel.rows) do
    if row._shown and row.data and row.data.waypoint then row._scripts.OnClick(row, "LeftButton") break end
end
print("clic sulla delve da Stormwind -> passi:", C.Travel.route and #C.Travel.route or 0)
C.Travel:Stop()

-- ===================== Oro =====================
MOCK.fire("TRADE_SKILL_SHOW")
for _, prof in ipairs({ "occasionale", "assiduo" }) do
    SlashCmdList.ROTASSISTCOMPANION("profilo " .. prof)
    Dump("gold")
end
SlashCmdList.ROTASSISTCOMPANION("profilo")
print("profilo dopo il ciclo:", C.db.playerType)
MOCK.profs = {}
Dump("gold")
MOCK.profs = { 1, 2 }

-- API assenti (client diverso / patch futura): nessun errore
C_AreaPoiInfo, C_TaskQuest, C_WeeklyRewards, C_PerksActivities, C_DelvesUI, C_Calendar, C_CurrencyInfo = nil
C.API.ClearCache()
C_TradeSkillUI, C_ProfSpecs, GetProfessions = nil
for _, tab in ipairs({ "delves", "events", "weekly", "leveling", "gold" }) do Dump(tab) end
MOCK.playerMap = 84
C.Travel:Start(delve)

print("ERRORI TOTALI:", #MOCK.errors)
