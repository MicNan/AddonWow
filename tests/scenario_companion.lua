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

-- Una riga del pannello in forma di testo, secondo il tipo
local function RowText(d)
    if d.header then return "  # " .. d.header end
    local k = d.kind
    if k == "pills" then
        local t = {}
        for _, it in ipairs(d.items) do t[#t + 1] = it.selected and ("[" .. it.label .. "]") or it.label end
        return "    < " .. table.concat(t, " | ") .. " >"
    elseif k == "callout" then
        return "    {" .. (d.style or "info") .. "} " .. (d.title and (d.title .. ": ") or "") .. tostring(d.text)
    elseif k == "sub" then return "   ## " .. tostring(d.text)
    elseif k == "phase" then return "   >> " .. tostring(d.text)
    elseif k == "step" then return "    (" .. tostring(d.badge) .. ") " .. tostring(d.text)
    elseif k == "thead" then return "    || " .. table.concat(d.cols, " | ")
    elseif k == "tr" then
        return "    :: " .. table.concat(d.cols, " | ") .. (d.link and "  [link]" or "")
    elseif k == "bar" then
        return ("    [bar %s/%s%s%s] %s%s"):format(tostring(d.value or "-"), tostring(d.max),
            d.marker and (" marker " .. d.marker) or "", d.ticks and (" soglie " .. table.concat(d.ticks, ",")) or "",
            tostring(d.label), d.right and ("  | " .. d.right) or "")
    elseif k == "note" then return "    ~ " .. tostring(d.text)
    end
    return "    " .. tostring(d.text) .. (d.right and ("  | " .. d.right) or "")
        .. (d.badge and ("  <" .. tostring(d.badge[1]) .. ">") or "")
        .. (d.waypoint and "  [wp]" or "") .. (d.dest and (d.dest.x and "  [dest]" or "  [zona]") or "")
        .. (d.link and "  [link]" or "")
end

local function Dump(tab)
    C.Panel:Show(tab)
    print(("=== scheda %s (stato: %s)"):format(tab, tostring(C.Panel.frame.status._text)))
    for i, row in ipairs(C.Panel.rows) do
        if row._shown and row.data then print(RowText(row.data)) end
    end
end

-- Clic su un selettore del pannello (per etichetta)
local function ClickPill(label)
    for _, row in ipairs(C.Panel.rows) do
        if row._shown and row.data and row.data.kind == "pills" then
            for i, it in ipairs(row.data.items) do
                if it.label == label then row.pills[i]._scripts.OnClick(row.pills[i]) return end
            end
        end
    end
    print("!!! selettore non trovato: " .. label)
    table.insert(MOCK.errors, "selettore " .. label)
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
Route("Stormwind -> Harandar senza coordinate", 84, "Alliance",
      { mapID = 2413, name = "Ancient Devilsaptor", note = "Nordrassil Roots" })
-- espansioni precedenti: portali delle capitali ed Earthshrine
Route("Silvermoon (Alleanza) -> Sholazar Basin", 2393, "Alliance", { mapID = 119, name = "Loque'nahak" })
Route("Silvermoon (Orda) -> Abyssal Depths", 2393, "Horde", { mapID = 204, name = "Ghostcrawler", note = "Abandoned Reef" })
Route("Orgrimmar -> Mount Hyjal", 85, "Horde", { mapID = 198, name = "Magria" })
Route("Stormwind -> Suramar", 84, "Alliance", { mapID = 680, x = 0.5, y = 0.5, name = "Mana Saber" })
Route("Orgrimmar -> Draenor", 85, "Horde", { mapID = 539, name = "Gara" })
Route("Voidstorm (Orda) -> Emerald Dream", 2405, "Horde", { mapID = 2200, name = "Sul'raka" })

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
ClickPill(C.L.PROFILE_medium)
print("profilo dal selettore:", C.db.playerType)
MOCK.profs = {}
Dump("gold")
MOCK.profs = { 1, 2 }
print("--- professioni prima della scansione dei prezzi")
C.db.craftSection = "make"
Dump("craft")

-- ===================== Asta =====================
local function Pump()
    local w = C.Prices.worker
    local guard = 0
    while w and w._scripts.OnUpdate and guard < 100 do w._scripts.OnUpdate(w, 0.016); guard = guard + 1 end
end
C:Set("playerType", "medium")
print("--- asta prima della scansione")
Dump("market")
SlashCmdList.ROTASSISTCOMPANION("scan")            -- casa d'aste chiusa
MOCK.fire("AUCTION_HOUSE_SHOW")
SlashCmdList.ROTASSISTCOMPANION("scan")
Pump()
print("oggetti nel database:", (function() local n = 0 for _ in pairs(C.Prices:DB().items) do n = n + 1 end return n end)(),
      "| prezzo Sunbloom:", C.Prices:Get(1001), "| indice farm:", (function() local n = 0 for _ in pairs(C.Prices:DB().farmIndex) do n = n + 1 end return n end)())
SlashCmdList.ROTASSISTCOMPANION("scan")            -- entro 15 minuti: limite
for _, prof in ipairs({ "occasionale", "medio", "assiduo" }) do
    SlashCmdList.ROTASSISTCOMPANION("profilo " .. prof)
    Dump("market")
end

print("--- sessione di farm")
SlashCmdList.ROTASSISTCOMPANION("farm")
MOCK.bags[0][1][2] = 70                              -- +30 Sunbloom
MOCK.fire("BAG_UPDATE_DELAYED")
MOCK.now = MOCK.now + 600
Dump("market")
ClickPill(C.L.GOLD_SEC_farm)
Dump("gold")
SlashCmdList.ROTASSISTCOMPANION("farm")
print("resa salvata Sunbloom:", C.db.farmRates and C.db.farmRates[1001] and C.db.farmRates[1001].rate)
SlashCmdList.ROTASSISTCOMPANION("profilo assiduo")
Dump("market")

print("--- tooltip")
local lines = {}
local tip = { AddDoubleLine = function(_, a, b) lines[#lines + 1] = a .. " = " .. b end,
              AddLine = function(_, a) lines[#lines + 1] = a end }
for _, fn in ipairs(MOCK.tooltipHooks) do fn(tip, { id = 1001 }); fn(tip, { id = 1009 }); fn(tip, { id = 99999 }) end
for _, l in ipairs(lines) do print("   " .. l) end

print("--- scansione con dati in ritardo (dopo il timeout)")
MOCK.now = MOCK.now + 1000                          -- limite dei 15 minuti scaduto
local realReplicate = C_AuctionHouse.ReplicateItems
C_AuctionHouse.ReplicateItems = function() end      -- la casa d'aste non risponde subito
print("pulsante prima:", C.Prices.button and C.Prices.button._text)
SlashCmdList.ROTASSISTCOMPANION("scan")             -- i timer del mock scattano subito: timeout
print("in attesa dopo il timeout:", tostring(C.Prices.waiting), "| scanning:", tostring(C.Prices.scanning))
MOCK.auctions[#MOCK.auctions + 1] = { 1003, 50, 50 * 15000.0 }   -- nuova asta piu' economica
MOCK.fire("REPLICATE_ITEM_LIST_UPDATE")             -- i dati arrivano in ritardo
local w = C.Prices.worker
while w and w._scripts.OnUpdate do w._scripts.OnUpdate(w, 0.016) end
print("prezzo Sunfire Silk dopo i dati in ritardo:", C.Prices:Get(1003), "| pulsante:", C.Prices.button._text)
C_AuctionHouse.ReplicateItems = realReplicate
local before = #C.db.log
for _ = 1, 50 do MOCK.fire("REPLICATE_ITEM_LIST_UPDATE") end   -- raffica di eventi dopo la fine
local w2 = C.Prices.worker
print("eventi ripetuti -> nuova elaborazione avviata:", tostring(w2 and w2._scripts.OnUpdate ~= nil),
      "| righe di registro aggiunte:", #C.db.log - before)
print("ultime righe del registro:")
for i = math.max(1, #C.db.log - 5), #C.db.log do print("   " .. C.db.log[i]) end

print("--- Auctionator come riserva (scansione vecchia)")
C.Prices:DB().time = time() - 5 * 86400
Auctionator = { API = { v1 = {
    GetAuctionPriceByItemID = function(_, id) if id == 1003 then return 33333 end end,
    GetAuctionAgeByItemID = function() return 1 end } } }
print("Sunfire Silk:", C.Prices:Get(1003))
print("Sunbloom (solo scansione vecchia):", C.Prices:Get(1001))
MOCK.fire("AUCTION_HOUSE_CLOSED")

-- ===================== Professioni =====================
print("--- professioni")
SlashCmdList.ROTASSISTCOMPANION("professioni")
C.db.craft = nil
Dump("craft")                                         -- prima della lettura: invito ad aprire la professione
MOCK.bank = { [1004] = 3 }                            -- 3 Mycobloom in banca
MOCK.fire("TRADE_SKILL_SHOW")
local scan = C.db.craft and C.db.craft[171]
print("ricette lette:", scan and #scan.recipes, "(attese 5: le 3 per salire, una grigia e una grigia vendibile)")
Dump("craft")
for _, sec in ipairs({ "level", "sell", "specs", "knowledge" }) do
    ClickPill(C.L["CRAFT_SEC_" .. sec])
    Dump("craft")
end
do
    local res = C.Craft:Profits(171)
    for _, e in ipairs(res.list) do
        print("   guadagno", e.recipe.name, "oggetto", e.item, "prezzo", e.price, "costo", e.cost, "guadagno", e.profit, "parziale", e.partial)
    end
    print("   senza prezzo d'asta:", res.noPrice)
    for _, e in ipairs(res.locked) do
        print("   da imparare", e.recipe.name, "guadagno", e.profit, "fonte", table.concat(e.recipe.source or {}, " / "))
    end
    print("   ricette da imparare lette:", #C.db.craft[171].locked)
end
-- ordini di lavoro: prima del tavolo, poi letti al tavolo
ClickPill(C.L.CRAFT_SEC_orders)
Dump("craft")
MOCK.fire("CRAFTINGORDERS_SHOW_CRAFTER")
MOCK.fire("CRAFTINGORDERS_HIDE_CRAFTER")
print("ordini salvati:", C.db.orders and C.db.orders[171] and #C.db.orders[171].list)
Dump("craft")
-- liquidita': seconda scansione un giorno dopo, con meno pezzi in vendita
do
    local db = C.Prices:DB()
    local acc = {}
    for id, e in pairs(db.items) do acc[id] = { p = e.p, q = e.q } end
    acc[1012].q = 1                                   -- pozione: 2 vendute in un giorno, 1 in vendita -> alta
    acc[1015].q = 28                                  -- flask rango 2: 2 al giorno, 28 in vendita -> bassa
    db.time = time() - 86400
    C.Prices:FinishScan(acc, 10)
    for _, id in ipairs({ 1012, 1015, 1014 }) do
        print("   liquidita'", id, C.Prices:LiquidityText(C.Prices:Liquidity(id)))
    end
    -- con TSM: dati di vendita della regione
    TSM_API = { GetCustomPriceValue = function(src, item)
        if item == "i:1014" and src == "dbregionsoldperday*1000" then return 5000 end
        if item == "i:1014" and src == "dbregionsalerate*1000" then return 300 end
    end }
    print("   liquidita' TSM 1014", C.Prices:LiquidityText(C.Prices:Liquidity(1014)))
    TSM_API = nil
    ClickPill(C.L.CRAFT_SEC_sell)
    Dump("craft")
end
ClickPill(C.L.CRAFT_SEC_specs)
ClickPill("Transmutes")                               -- un'altra build dal selettore
print("build scelta per Alchemy:", C.db.craftBuild.alchemy)
Dump("craft")
ClickPill("Herbalism 100/100")                        -- l'altra professione (raccolta: niente 'Cosa creare')
Dump("craft")
ClickPill("Alchemy 37/100")
ClickPill(C.L.CRAFT_SEC_make)
local plan = C.Craft:Plan(171)
print("migliore:", plan.best[1].recipe.name, "| a punto:", plan.best[1].perPoint, "| creazioni per 10 punti:", plan.topCrafts)
for _, s in ipairs(plan.shopping) do print("   compra", s.itemID, "servono", s.need, "hai", s.have, "mancano", s.missing, "costo", s.cost) end
-- tooltip della ricetta migliore
tipLines = {}
GameTooltip.AddLine = function(_, t) tipLines[#tipLines + 1] = t end
for _, row in ipairs(C.Panel.rows) do
    if row._shown and row.data and row.data.link and row.data.link.spell == 7003 then row._scripts.OnEnter(row) break end
end
GameTooltip.AddLine = nil
print("tooltip:")
for _, l in ipairs(tipLines) do print("   " .. l) end
-- professione di un altro giocatore: ignorata
C.db.craft = nil
MOCK.tsLinked = true; MOCK.fire("TRADE_SKILL_SHOW"); MOCK.tsLinked = nil
print("professione collegata -> lettura:", tostring(C.db.craft))
-- scheda di un'altra espansione aperta
MOCK.tsChild = 2823; MOCK.fire("TRADE_SKILL_SHOW")
print("altra espansione:", C.Craft.otherExpansion and C.Craft.otherExpansion.name, "| lettura:", tostring(C.db.craft))
MOCK.tsChild = nil; MOCK.fire("TRADE_SKILL_SHOW")
-- specializzazione consigliata: cacciatore con Leatherworking, guerriero con Blacksmithing, mago con Inscription
local realProf, realClass = MOCK.profInfo[1], UnitClass
MOCK.profInfo[1] = { "Leatherworking", 101, 72, 100, 0, 0, 165 }
C.db.craftSection, C.db.craftProf = "specs", 165
Dump("craft")
C.db.craftSection = "level"
Dump("craft")
C.db.craftSection = "specs"
local realSpec = MOCK.specID
UnitClass = function() return "Warrior", "WARRIOR" end
MOCK.specID = 71
MOCK.profInfo[1] = { "Blacksmithing", 101, 55, 100, 0, 0, 164 }
C.db.craftProf = 164
Dump("craft")
UnitClass = function() return "Mage", "MAGE" end
MOCK.specID = 63
MOCK.profInfo[1] = { "Inscription", 101, 100, 100, 0, 0, 773 }
C.db.craftProf = 773
Dump("craft")
-- consiglio per ogni specializzazione e professione: chiavi esistenti nei testi
do
    local classOf = {}
    for _, e in ipairs({ { "WARRIOR", 71, 72, 73 }, { "PALADIN", 65, 66, 70 }, { "DEATHKNIGHT", 250, 251, 252 },
                         { "ROGUE", 259, 260, 261 }, { "DEMONHUNTER", 577, 581, 1480 }, { "MONK", 268, 269, 270 },
                         { "DRUID", 102, 103, 104, 105 }, { "HUNTER", 253, 254, 255 }, { "MAGE", 62, 63, 64 },
                         { "PRIEST", 256, 257, 258 }, { "SHAMAN", 262, 263, 264 }, { "WARLOCK", 265, 266, 267 },
                         { "EVOKER", 1467, 1468, 1473 } }) do
        for i = 2, #e do classOf[e[i]] = e[1] end
    end
    local n, bad, sample = 0, {}, {}
    for specID, class in pairs(classOf) do
        if not C.CraftGuide.WIELD[specID] then bad[#bad + 1] = "arma " .. specID end
        for _, prof in ipairs({ "blacksmithing", "inscription", "engineering", "leatherworking", "tailoring" }) do
            local keys = C.CraftGuide:Advice(prof, class, specID)
            for _, k in ipairs(keys) do
                n = n + 1
                if not (C.L[k] and C.L[k] ~= k) then bad[#bad + 1] = k end
            end
        end
    end
    -- senza specializzazione
    for _, class in ipairs({ "WARRIOR", "HUNTER", "PRIEST", "SHAMAN" }) do
        if #C.CraftGuide:Advice("blacksmithing", class, nil) == 0 then bad[#bad + 1] = "senza spec " .. class end
    end
    print("consigli per specializzazione:", n, "| errati:", #bad == 0 and "nessuno" or table.concat(bad, ","))
    if #bad > 0 then table.insert(MOCK.errors, "consigli errati") end
    for _, spec in ipairs({ 73, 260, 1480, 255, 65, 264, 253 }) do
        print("  fabbro/inscription", spec, table.concat(C.CraftGuide:Advice("blacksmithing", classOf[spec], spec), "+"),
              "|", table.concat(C.CraftGuide:Advice("inscription", classOf[spec], spec), "+"))
    end
end
MOCK.profInfo[1], UnitClass, MOCK.bank, MOCK.specID = realProf, realClass, nil, realSpec
-- Cucina e Pesca (professioni secondarie)
MOCK.profInfo[4] = { "Fishing", 104, 140, 300, 0, 0, 356 }
MOCK.profInfo[5] = { "Cooking", 105, 30, 100, 0, 0, 185 }
MOCK.profs[4], MOCK.profs[5] = 4, 5
C.db.craftProf, C.db.craftSection = 356, "specs"
Dump("craft")
C.db.craftProf = 185
Dump("craft")
MOCK.profs[4], MOCK.profs[5] = nil, nil
C.db.craftProf, C.db.craftSection = nil, "level"

-- ===================== Attivita' =====================
print("--- attivita'")
SlashCmdList.ROTASSISTCOMPANION("oggi")
ClickPill(C.L.ACT_GOAL_summary)
Dump("today")                                         -- riepilogo
ClickPill(C.L.ACT_GOAL_gear)
Dump("today")                                         -- equipaggiamento, Beast Mastery (Mitiche+)
ClickPill(C.L.ACT_CONTENT_raid)
print("priorita' raid:", table.concat(C.StatPriority:Current().order, " > "))
for _, g in ipairs({ "vault", "rep", "gold" }) do
    ClickPill(C.L["ACT_GOAL_" .. g])
    Dump("activities")
end
-- sciamano Enhancement con talento eroico Totemic, poi Stormbringer
ClickPill(C.L.ACT_GOAL_gear)
MOCK.specID, MOCK.heroTree = 263, 54
print("Enhancement Totemic:", table.concat(C.StatPriority:Current().order, " > "), "|", C.StatPriority:Current().heroName)
MOCK.heroTree = 55
print("Enhancement Stormbringer:", table.concat(C.StatPriority:Current().order, " > "))
-- tutte le specializzazioni: un ordine con le 4 secondarie, oppure "nessuna priorita' fissa"
do
    local n, bad = 0, {}
    for specID, entry in pairs(C.StatPriority.SPECS) do
        MOCK.specID, MOCK.heroTree = specID, nil
        local p = C.StatPriority:Current()
        n = n + 1
        if not (p.flat or (p.order and #p.order == 4)) then bad[#bad + 1] = specID end
        if entry.hero and not p.heroChoice then bad[#bad + 1] = specID .. "(eroe)" end
    end
    print("specializzazioni con priorita':", n, "| errate:", #bad == 0 and "nessuna" or table.concat(bad, ","))
    if #bad > 0 then table.insert(MOCK.errors, "priorita' errate") end
end
MOCK.specID, MOCK.heroTree = 72, nil                  -- Fury: Critico = Versatilita'
Dump("activities")
MOCK.specID, MOCK.heroTree = 250, 31                  -- Blood San'layn (riconosciuto dal nome)
print("Blood San'layn:", table.concat(C.StatPriority:Current().order, " > "), "|", C.StatPriority:Current().heroName)
MOCK.heroTree = 990                                   -- nome tradotto: selettore
C.Panel:Refresh()
ClickPill("Deathbringer")
print("Blood scelto a mano:", table.concat(C.StatPriority:Current().order, " > "), "|", C.StatPriority:Current().heroKey)
Dump("activities")
MOCK.specID, MOCK.heroTree = 103, nil                 -- Feral: nessuna priorita' fissa
Dump("activities")
MOCK.specID = 9999                                    -- specializzazione sconosciuta
Dump("activities")
MOCK.specID, MOCK.heroTree = 253, nil
-- ricompense non ancora arrivate dal server
MOCK.wqLoading = { [9002] = true }
C.API.ClearCache()
C.Panel:Refresh()
print("ricompense in attesa:", C.Activities.pending, "| richieste al server:", MOCK.preload)
MOCK.wqLoading = nil
MOCK.fire("QUEST_LOG_UPDATE")
C.Panel:Refresh()
print("dopo QUEST_LOG_UPDATE in attesa:", C.Activities.pending)

-- ===================== Pet =====================
print("--- pet da cacciatore")
MOCK.playerMap, MOCK.faction = 84, "Alliance"
SlashCmdList.ROTASSISTCOMPANION("pet")
Dump("pets")
local function PetRow(npc)
    for _, row in ipairs(C.Panel.rows) do
        if row._shown and row.data and row.data.preview and (not npc or row.data.preview.npc == npc) then return row end
    end
end
-- anteprima 3D al passaggio del mouse
local r = PetRow(248741)
r._scripts.OnEnter(r)
local pv = C.Pets.preview
print("anteprima visibile:", pv and pv._shown, "| npc:", pv and pv.npc, "| testo 'modello non disponibile':", pv and pv.missing._shown)
local tipLines = {}
GameTooltip.AddLine = function(_, t) tipLines[#tipLines + 1] = t end
r._scripts.OnEnter(PetRow(252851))
print("tooltip di Ancient Devilsaptor:")
for _, l in ipairs(tipLines) do print("   " .. l) end
GameTooltip.AddLine = nil
-- clic: rare senza coordinate (Harandar, portale da Silvermoon) e link Wowhead
r = PetRow(252851)
r._scripts.OnClick(r, "LeftButton")
print("percorso verso Ancient Devilsaptor:", C.Travel.route and #C.Travel.route or 0, "| ultimo passo:", C.Travel.route and C.Travel.route[#C.Travel.route].text)
r._scripts.OnClick(r, "RightButton")
C.Travel:Stop()
-- Maiusc + clic su un rare con coordinate: solo waypoint
MOCK.shift = true
r = PetRow(255348)
r._scripts.OnClick(r, "LeftButton")
MOCK.shift = false
print("waypoint Dame Bloodshed:", MOCK.tomtom)

-- stalla e pet evocato
C_StableInfo = {
    GetActivePetList = function() return { { creatureID = 248741, name = "Rhazul" }, { creatureID = 99999 } } end,
    GetStabledPetList = function() return { { creatureID = 255348 } } end,
}
MOCK.fire("PET_STABLE_SHOW")
UnitGUID = function(u) if u == "pet" then return "Pet-0-3110-0-0-250086-0100ABCDEF" end end
MOCK.fire("UNIT_PET", "player")
print("posseduti: Rhazul", C.Pets:Owned(248741), "| Dame Bloodshed", C.Pets:Owned(255348), "| Stumpy (evocato)", C.Pets:Owned(250086), "| Terrinor", C.Pets:Owned(250876))

-- rare sulla minimappa
C_VignetteInfo = {
    GetVignettes = function() return { "vg1", "vg2", "vg3" } end,
    GetVignetteInfo = function(g)
        if g == "vg1" then return { objectGUID = "Creature-0-3110-2552-1234-250582-00001ABCD", name = "Bloated Snapdragon" } end
        if g == "vg2" then return { objectGUID = "GameObject-0-3110-2552-1234-555555-0000" } end
        return nil
    end,
    GetVignettePosition = function(g, m) return { x = 0.31, y = 0.62 } end,
}
MOCK.playerMap = 2395
MOCK.now = MOCK.now + 10
local logBefore = #C.db.log
MOCK.fire("VIGNETTES_UPDATED")
MOCK.fire("VIGNETTES_UPDATED")                       -- entro 2 s: ignorato
MOCK.now = MOCK.now + 3
MOCK.fire("VIGNETTE_MINIMAP_UPDATED", "vg1", true)   -- gia' segnalato: niente secondo avviso
local alerts = 0
for i = logBefore + 1, #C.db.log do if C.db.log[i]:find("Bloated Snapdragon (Lizard)", 1, true) then alerts = alerts + 1 end end
print("avvisi in chat:", alerts, "(atteso 1) | posizione salvata:", C.db.petSeen[250582] and C.db.petSeen[250582].x)
Dump("pets")
print("destinazione Bloated Snapdragon (vista):", C.Pets:Destination(C.Pets.byNpc[250582]).x)

-- filtri (tutti -> esotici -> spirit beast -> non domati -> tutti)
for _, key in ipairs({ "exotic", "spirit", "missing", "all" }) do
    ClickPill(C.L["PET_FILTER_" .. key])
    local n = 0
    for _, row in ipairs(C.Panel.rows) do if row._shown and row.data and row.data.preview then n = n + 1 end end
    print("filtro", C.Pets.filter, "->", n, "pet")
    if C.Pets.filter == "spirit" then Dump("pets") end
end

-- spirit beast: tooltip con le istruzioni e percorso verso il martello di Aradan
C.Pets.filter = "spirit"
MOCK.playerMap, MOCK.faction = 2393, "Alliance"
C.Panel:Refresh()
local aradan = PetRow(213428)
tipLines = {}
GameTooltip.AddLine = function(_, t) tipLines[#tipLines + 1] = t end
aradan._scripts.OnEnter(aradan)
GameTooltip.AddLine = nil
print("tooltip di Aradan:")
for _, l in ipairs(tipLines) do print("   " .. l) end
print("altezza anteprima:", C.Pets.preview._h)
aradan._scripts.OnClick(aradan, "LeftButton")
C.Travel:Stop()
C.Pets.filter = "all"

-- non cacciatore / cacciatore non Beast Mastery
local realClass = UnitClass
UnitClass = function() return "Mage", "MAGE" end
Dump("pets")
UnitClass = realClass
MOCK.specID = 254
C.Panel:Refresh()
for _, row in ipairs(C.Panel.rows) do
    if row._shown and row.data and row.data.text and row.data.text:find("Beast Mastery", 1, true) then print("avviso non BM:", row.data.text) break end
end
MOCK.specID = 253
-- cambiando scheda l'anteprima si chiude
C.Panel:Show("delves")
print("anteprima dopo il cambio di scheda:", C.Pets.preview._shown)

-- API assenti (client diverso / patch futura): nessun errore
C_VignetteInfo, C_StableInfo, UnitGUID = nil
MOCK.fire("VIGNETTES_UPDATED"); MOCK.fire("PET_STABLE_SHOW"); MOCK.fire("UNIT_PET", "player")
C_AreaPoiInfo, C_TaskQuest, C_WeeklyRewards, C_PerksActivities, C_DelvesUI, C_Calendar, C_CurrencyInfo = nil
C.API.ClearCache()
C_TradeSkillUI, C_ProfSpecs, GetProfessions = nil
C_AuctionHouse, C_Item, TooltipDataProcessor = nil
C_MajorFactions, C_ClassTalents, C_Traits, GetNumQuestLogRewards, HaveQuestRewardData = nil
for _, tab in ipairs({ "delves", "events", "weekly", "activities", "leveling", "gold", "craft", "market", "pets" }) do Dump(tab) end
MOCK.playerMap = 84
C.Travel:Start(delve)

print("ERRORI TOTALI:", #MOCK.errors)
