-- RotAssist Companion - Core
-- Caricamento delle impostazioni, creazione dell'interfaccia, riepilogo
-- all'accesso e aggiornamento del pannello quando cambiano i dati.

local _, ns = ...

ns:On("ADDON_LOADED", function(_, name)
    if name ~= ns.name then return end
    RotAssistCompanionDB = RotAssistCompanionDB or {}
    ns.ApplyDefaults(RotAssistCompanionDB, ns.defaults)
    ns.db = RotAssistCompanionDB
    ns:SetLanguage(ns.db.language)

    ns.Panel:Create()
    ns.Launcher:Create()
    local ok, err = pcall(ns.RegisterSettings, ns)
    if not ok then ns:ReportError(err) end
end)

ns:On("PLAYER_ENTERING_WORLD", function(_, isInitialLogin, isReloadingUi)
    ns.Leveling:StartSession()
    ns.Events:RequestCalendar()
    if isInitialLogin and ns.db.notifyLogin then
        -- qualche secondo per lasciare caricare mappe e valute
        ns:After(8, function() ns:PrintSummary() end)
    end
end)

-- navigatore: passa al passo successivo quando cambia la zona
for _, ev in ipairs({ "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "PLAYER_ENTERING_WORLD" }) do
    ns:On(ev, function() ns.Travel:Advance() end)
end

-- professione aperta: ricordiamo Concentrazione e conoscenza (scheda Oro)
ns:On("TRADE_SKILL_SHOW", function() ns.Gold:OnTradeSkillShow(); ns.Panel:RequestRefresh() end)

ns:On("PLAYER_XP_UPDATE", function(_, unit)
    if unit == nil or unit == "player" then ns.Leveling:OnXPUpdate() end
end)

-- dati cambiati: aggiorniamo il pannello se aperto (e fuori combattimento)
for _, ev in ipairs({ "PLAYER_REGEN_ENABLED", "ZONE_CHANGED_NEW_AREA", "WEEKLY_REWARDS_UPDATE",
                      "CURRENCY_DISPLAY_UPDATE", "CALENDAR_UPDATE_EVENT_LIST", "QUEST_LOG_UPDATE" }) do
    ns:On(ev, function() ns.Panel:RequestRefresh() end)
end
