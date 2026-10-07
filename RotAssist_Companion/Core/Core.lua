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
    ns.Market:HookTooltips()
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

-- casa d'aste: pulsante di scansione e dati della scansione completa
ns:On("AUCTION_HOUSE_SHOW", function() ns.Prices:OnAuctionHouseShow() end)
ns:On("AUCTION_HOUSE_CLOSED", function() ns.Prices:OnAuctionHouseClosed() end)
ns:On("REPLICATE_ITEM_LIST_UPDATE", function() ns.Prices:OnReplicateReady() end)

-- borse cambiate: sessione di farm e consigli asta/vendor
ns:On("BAG_UPDATE_DELAYED", function()
    ns.Market:OnBagUpdate()
    ns.Panel:RequestRefresh()
end)
-- dati degli oggetti arrivati dal server: i nomi mancanti si completano
ns:On("GET_ITEM_INFO_RECEIVED", function() ns.Panel:RequestRefresh(5) end)

-- scheda Pet: stalla, pet evocato e rari sulla minimappa
for _, ev in ipairs({ "PET_STABLE_SHOW", "PET_STABLE_UPDATE" }) do
    ns:On(ev, function() ns.Pets:ScanStable(); ns.Panel:RequestRefresh() end)
end
ns:On("UNIT_PET", function(_, unit) if unit == "player" then ns.Pets:CheckSummoned() end end)
ns:On("PLAYER_ENTERING_WORLD", function() ns.Pets:CheckSummoned(); ns.Pets:ScanVignettes(true) end)
for _, ev in ipairs({ "VIGNETTE_MINIMAP_UPDATED", "VIGNETTES_UPDATED" }) do
    ns:On(ev, function() ns.Pets:ScanVignettes() end)
end

ns:On("PLAYER_XP_UPDATE", function(_, unit)
    if unit == nil or unit == "player" then ns.Leveling:OnXPUpdate() end
end)

-- dati cambiati: aggiorniamo il pannello se aperto (e fuori combattimento)
for _, ev in ipairs({ "PLAYER_REGEN_ENABLED", "ZONE_CHANGED_NEW_AREA", "WEEKLY_REWARDS_UPDATE",
                      "CURRENCY_DISPLAY_UPDATE", "CALENDAR_UPDATE_EVENT_LIST", "QUEST_LOG_UPDATE" }) do
    ns:On(ev, function() ns.Panel:RequestRefresh() end)
end
