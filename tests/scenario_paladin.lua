-- Scenario di RotAssist Companion con un personaggio non cacciatore e non
-- sciamano (paladino): il Companion deve caricarsi e ogni scheda aprirsi
-- senza errori, per ogni specializzazione.
UnitClass = function() return "Paladin", "PALADIN" end
MOCK.specID = 70
MOCK.profInfo = {
    [1] = { "Blacksmithing", 101, 40, 100, 0, 0, 164 },
    [2] = { "Mining", 102, 12, 100, 0, 0, 186 },
}

local ns = {}
for _, f in ipairs(FILES) do
    local chunk, err = load(f.src, "@" .. f.name)
    if not chunk then error(err) end
    chunk("RotAssist_Companion", ns)
end
local C = RotAssistCompanion
C.ReportError = function(self, e) print("!!! ERRORE: " .. tostring(e)); table.insert(MOCK.errors, tostring(e)) end

MOCK.fire("ADDON_LOADED", "RotAssist_Companion")
MOCK.fire("PLAYER_LOGIN")
MOCK.fire("PLAYER_ENTERING_WORLD", true, false)
print("caricato:", C ~= nil, "| pannello:", C.Panel and C.Panel.frame ~= nil, "| minimappa:", C.db and C.db.showMinimap)

SlashCmdList.ROTASSISTCOMPANION("")
print("pannello aperto:", C.Panel.frame and C.Panel.frame:IsShown())
for _, spec in ipairs({ 70, 66, 65 }) do
    MOCK.specID = spec
    for _, tab in ipairs({ "today", "week", "delves", "leveling", "craft", "gold", "pets" }) do
        C.Panel:Show(tab)
        local n = 0
        for _, row in ipairs(C.Panel.rows) do if row._shown and row.data then n = n + 1 end end
        print(("spec %d, scheda %-8s righe %d"):format(spec, tab, n))
    end
end
-- gli obiettivi di Oggi e le sezioni delle Professioni
C.Panel:Show("today")
for _, g in ipairs(C.Activities.GOALS) do C.db.actGoal = g; C.Panel:Refresh() end
C.Panel:Show("craft")
for _, s in ipairs({ "level", "make", "sell", "orders", "specs", "knowledge" }) do C.db.craftSection = s; C.Panel:Refresh() end
print("ERRORI TOTALI:", #MOCK.errors)
