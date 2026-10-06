-- RotAssist Companion - Locale (italiano / inglese)
-- Opzione 'language': "auto" (italiano con client itIT, altrimenti inglese),
-- "it" oppure "en". ns.L risolve ogni testo al momento dell'uso.

local _, ns = ...

local IT = {
    TITLE            = "RotAssist Companion",
    TAB_DELVES       = "Delve",
    TAB_EVENTS       = "Eventi",
    TAB_WEEKLY       = "Settimanale",
    TAB_LEVELING     = "Levelling",
    BTN_REFRESH      = "Aggiorna",
    UPDATED_AT       = "Aggiornato alle %s",
    IN_COMBAT        = "In combattimento: aggiornamento sospeso",
    HINT_WAYPOINT    = "Clic sinistro: waypoint",
    HINT_WOWHEAD     = "Clic destro: link Wowhead",

    -- Delve
    HDR_DELVES       = "Delve attive",
    HDR_DELVE_STATUS = "Chiavi e compagno",
    DELVE_BOUNTIFUL  = "Abbondante",
    DELVE_LOCKED     = "Bloccata",
    KEYS             = "Restored Coffer Key: %d",
    SHARDS           = "Coffer Key Shards: %d (questa settimana %d/%d)",
    COMPANION        = "%s: livello %d/%d",
    NO_DELVES        = "Nessuna delve trovata",
    ONLY_BOUNTIFUL   = "Solo abbondanti",

    -- Eventi
    HDR_EVENTS       = "Eventi sulla mappa",
    HDR_WORLD_QUESTS = "World quest - %s",
    HDR_HOLIDAYS     = "Festivita' di oggi",
    TIME_LEFT        = "%s rimasti",
    NO_EVENTS        = "Nessun evento attivo",
    NO_WORLD_QUESTS  = "Nessuna world quest su questo continente",
    NO_HOLIDAYS      = "Nessuna festivita' oggi",
    ELITE            = "elite",

    -- Settimanale
    HDR_VAULT        = "Great Vault",
    VAULT_READY      = "Ricompense da ritirare!",
    VAULT_DUNGEONS   = "Dungeon",
    VAULT_RAID       = "Raid",
    VAULT_WORLD      = "Delve e mondo",
    VAULT_SLOT       = "%d/%d",
    HDR_LOG          = "Traveler's Log",
    LOG_PROGRESS     = "%s: %d/%d attivita', %d punti",
    HDR_RESETS       = "Reset",
    RESET_DAILY      = "Giornaliero tra %s",
    RESET_WEEKLY     = "Settimanale tra %s",

    -- Levelling
    HDR_CHARACTER    = "Personaggio",
    LEVEL            = "Livello %d / %d",
    XP               = "XP %s / %s (%d%%)",
    RESTED           = "Riposo: %s XP",
    XP_RATE          = "XP/ora: %s - prossimo livello tra %s",
    XP_RATE_WAIT     = "XP/ora: in calcolo (gioca qualche minuto)",
    MAX_LEVEL        = "Livello massimo raggiunto",
    HDR_ZONE         = "Zona attuale",
    ZONE_LEVELS      = "%s (livelli %d-%d)",
    HDR_ZONES        = "Zone del continente adatte al tuo livello",
    NO_ZONES         = "Nessuna zona con livelli adatti su questo continente",
    QUEST_LOG        = "Missioni nel diario: %d/%d",

    -- Tempo
    T_DAYS           = "%dg %dh",
    T_HOURS          = "%dh %dm",
    T_MINUTES        = "%dm",

    -- Accesso
    LOGIN_BOUNTIFUL  = "Delve abbondanti: %d (%s)",
    LOGIN_VAULT      = "Great Vault: ricompense da ritirare",
    LOGIN_KEYS       = "Restored Coffer Key: %d",

    -- Viaggio
    HINT_ROUTE       = "Clic sinistro: percorso piu' veloce (Maiusc + clic: solo waypoint)",
    BTN_CANCEL_ROUTE = "Annulla",
    TRAVEL_FLY       = "Vola fino a %s (%s)",
    TRAVEL_NO_ROUTE  = "Nessun portale noto per arrivarci: vola o usa la Pietra del ritorno",
    TRAVEL_HEARTH    = "Usa la Pietra del ritorno per tornare a %s",
    TRAVEL_PORTAL    = "Prendi il portale per %s a %s (%.1f, %.1f)",
    TRAVEL_PORTAL_NOCOORD = "Prendi il portale per %s a %s",
    TRAVEL_PORTAL_TITLE = "Portale per %s",
    TRAVEL_HEADER    = "percorso per %s:",
    TRAVEL_NEXT      = "passo %d/%d: %s",
    TRAVEL_STEP      = "Percorso %d/%d: %s",
    TRAVEL_STOPPED   = "percorso annullato.",
    WHERE_SM_CAPITALS = "nell'edificio a destra della Wayfarer's Rest",
    WHERE_SM_HARANDAR = "nei Gardens of Remembrance, sotto un albero (lato ovest)",
    WHERE_SM_VOIDSTORM = "sopra i Gardens of Remembrance (lato ovest)",
    WHERE_SW_PORTALS = "nella sala dei portali",
    WHERE_OG_PORTALS = "nella sala dei portali (Pathfinder's Den)",
    WHERE_DG_CAPITALS = "nella Foundation Hall, a nord-est della citta' (posizione da verificare)",

    -- Oro
    TAB_GOLD         = "Oro",
    HDR_PROFESSIONS  = "Le tue professioni",
    PROF_LINE        = "%s (%d/%d)",
    PROF_RANK        = "Livello %d/%d",
    CONCENTRATION    = "Concentrazione %d/%d",
    CONC_FULL        = "Concentrazione piena: spendila, altrimenti la sprechi",
    CONC_FULL_IN     = "Concentrazione piena tra %s",
    CONC_UNKNOWN     = "Apri la professione una volta per leggere Concentrazione e conoscenza",
    KNOWLEDGE        = "Punti conoscenza da spendere: %d",
    NO_PROFESSIONS   = "Nessuna professione",
    HDR_GOLD_GENERAL = "Strategie generali - profilo %s",
    HDR_GOLD_PROF    = "%s",
    HDR_GOLD_NONE    = "Quali professioni prendere",
    PROFILE_casual   = "occasionale",
    PROFILE_medium   = "medio",
    PROFILE_hardcore = "assiduo",
    BTN_PROFILE      = "Profilo: %s",
    GOLD_DISCLAIMER  = "Prezzi e domanda cambiano da reame a reame: controlla sempre la casa d'aste prima di creare o vendere.",
    MSG_PROFILE      = "profilo per le strategie: %s",
    OPT_PROFILE      = "Profilo di gioco per le strategie sull'oro",

    -- Opzioni
    OPT_MINIMAP      = "Mostra l'icona sulla minimappa",
    OPT_NOTIFY       = "Riepilogo in chat all'accesso (delve abbondanti, Great Vault, chiavi)",
    OPT_ONLY_BOUNTIFUL = "Scheda Delve: mostra solo le abbondanti",
    OPT_LANGUAGE     = "Lingua (le etichette di questo pannello cambiano dopo /reload)",
    OPT_LANG_AUTO    = "Automatica (lingua del client)",
    OPT_LANG_IT      = "Italiano",
    OPT_LANG_EN      = "English",

    TT_LEFT          = "Clic sinistro: apri/chiudi",
    TT_RIGHT         = "Clic destro: opzioni",

    MSG_INTERNAL_ERROR = "errore interno:",
    MSG_NO_SETTINGS  = "pannello opzioni non disponibile: usa i comandi /rac.",
    MSG_LANG         = "lingua: %s (il pannello opzioni si aggiorna dopo /reload)",
    MSG_LANG_USAGE   = "uso: /rac lang auto|it|en",
    MSG_POS_RESET    = "posizione ripristinata.",
    MSG_WAYPOINT     = "waypoint: %s",
    MSG_NO_WAYPOINT  = "waypoint non disponibile su questa mappa.",
    WOWHEAD_POPUP    = "Wowhead - %s\n(Ctrl+C per copiare)",

    HELP = {
        "/rac - apre o chiude il pannello",
        "/rac delve | eventi | settimanale | levelling | oro - apre la scheda",
        "/rac profilo occasionale|medio|assiduo - profilo per le strategie sull'oro",
        "/rac stop - annulla il percorso in corso",
        "/rac aggiorna - aggiorna i dati",
        "/rac riepilogo - riepilogo in chat",
        "/rac config - pannello opzioni",
        "/rac minimap - mostra/nasconde l'icona sulla minimappa",
        "/rac lang auto|it|en - lingua",
        "/rac reset - riporta il pannello al centro",
    },
}

local EN = {
    TITLE            = "RotAssist Companion",
    TAB_DELVES       = "Delves",
    TAB_EVENTS       = "Events",
    TAB_WEEKLY       = "Weekly",
    TAB_LEVELING     = "Leveling",
    BTN_REFRESH      = "Refresh",
    UPDATED_AT       = "Updated at %s",
    IN_COMBAT        = "In combat: updates paused",
    HINT_WAYPOINT    = "Left click: waypoint",
    HINT_WOWHEAD     = "Right click: Wowhead link",

    HDR_DELVES       = "Active delves",
    HDR_DELVE_STATUS = "Keys and companion",
    DELVE_BOUNTIFUL  = "Bountiful",
    DELVE_LOCKED     = "Locked",
    KEYS             = "Restored Coffer Keys: %d",
    SHARDS           = "Coffer Key Shards: %d (this week %d/%d)",
    COMPANION        = "%s: level %d/%d",
    NO_DELVES        = "No delves found",
    ONLY_BOUNTIFUL   = "Bountiful only",

    HDR_EVENTS       = "Map events",
    HDR_WORLD_QUESTS = "World quests - %s",
    HDR_HOLIDAYS     = "Today's holidays",
    TIME_LEFT        = "%s left",
    NO_EVENTS        = "No active events",
    NO_WORLD_QUESTS  = "No world quests on this continent",
    NO_HOLIDAYS      = "No holidays today",
    ELITE            = "elite",

    HDR_VAULT        = "Great Vault",
    VAULT_READY      = "Rewards ready to claim!",
    VAULT_DUNGEONS   = "Dungeons",
    VAULT_RAID       = "Raid",
    VAULT_WORLD      = "Delves and world",
    VAULT_SLOT       = "%d/%d",
    HDR_LOG          = "Traveler's Log",
    LOG_PROGRESS     = "%s: %d/%d activities, %d points",
    HDR_RESETS       = "Resets",
    RESET_DAILY      = "Daily in %s",
    RESET_WEEKLY     = "Weekly in %s",

    HDR_CHARACTER    = "Character",
    LEVEL            = "Level %d / %d",
    XP               = "XP %s / %s (%d%%)",
    RESTED           = "Rested: %s XP",
    XP_RATE          = "XP/hour: %s - next level in %s",
    XP_RATE_WAIT     = "XP/hour: measuring (play for a few minutes)",
    MAX_LEVEL        = "Maximum level reached",
    HDR_ZONE         = "Current zone",
    ZONE_LEVELS      = "%s (levels %d-%d)",
    HDR_ZONES        = "Continent zones for your level",
    NO_ZONES         = "No zones for your level on this continent",
    QUEST_LOG        = "Quests in log: %d/%d",

    T_DAYS           = "%dd %dh",
    T_HOURS          = "%dh %dm",
    T_MINUTES        = "%dm",

    LOGIN_BOUNTIFUL  = "Bountiful delves: %d (%s)",
    LOGIN_VAULT      = "Great Vault: rewards ready to claim",
    LOGIN_KEYS       = "Restored Coffer Keys: %d",

    HINT_ROUTE       = "Left click: fastest route (Shift + click: waypoint only)",
    BTN_CANCEL_ROUTE = "Cancel",
    TRAVEL_FLY       = "Fly to %s (%s)",
    TRAVEL_NO_ROUTE  = "No known portal to get there: fly or use your Hearthstone",
    TRAVEL_HEARTH    = "Use your Hearthstone to return to %s",
    TRAVEL_PORTAL    = "Take the portal to %s in %s (%.1f, %.1f)",
    TRAVEL_PORTAL_NOCOORD = "Take the portal to %s in %s",
    TRAVEL_PORTAL_TITLE = "Portal to %s",
    TRAVEL_HEADER    = "route to %s:",
    TRAVEL_NEXT      = "step %d/%d: %s",
    TRAVEL_STEP      = "Route %d/%d: %s",
    TRAVEL_STOPPED   = "route cancelled.",
    WHERE_SM_CAPITALS = "inside the building to the right of the Wayfarer's Rest",
    WHERE_SM_HARANDAR = "in the Gardens of Remembrance, under a tree (west side)",
    WHERE_SM_VOIDSTORM = "above the Gardens of Remembrance (west side)",
    WHERE_SW_PORTALS = "in the portal room",
    WHERE_OG_PORTALS = "in the portal room (Pathfinder's Den)",
    WHERE_DG_CAPITALS = "in the Foundation Hall, north-east of the city (location to be verified)",

    TAB_GOLD         = "Gold",
    HDR_PROFESSIONS  = "Your professions",
    PROF_LINE        = "%s (%d/%d)",
    PROF_RANK        = "Skill %d/%d",
    CONCENTRATION    = "Concentration %d/%d",
    CONC_FULL        = "Concentration full: spend it or it goes to waste",
    CONC_FULL_IN     = "Concentration full in %s",
    CONC_UNKNOWN     = "Open the profession once to read Concentration and knowledge",
    KNOWLEDGE        = "Knowledge points to spend: %d",
    NO_PROFESSIONS   = "No professions",
    HDR_GOLD_GENERAL = "General strategies - %s profile",
    HDR_GOLD_PROF    = "%s",
    HDR_GOLD_NONE    = "Which professions to pick",
    PROFILE_casual   = "casual",
    PROFILE_medium   = "regular",
    PROFILE_hardcore = "dedicated",
    BTN_PROFILE      = "Profile: %s",
    GOLD_DISCLAIMER  = "Prices and demand differ between realms: always check the auction house before crafting or selling.",
    MSG_PROFILE      = "strategy profile: %s",
    OPT_PROFILE      = "Play style for gold strategies",

    OPT_MINIMAP      = "Show the minimap icon",
    OPT_NOTIFY       = "Chat summary at login (bountiful delves, Great Vault, keys)",
    OPT_ONLY_BOUNTIFUL = "Delves tab: bountiful only",
    OPT_LANGUAGE     = "Language (this panel's labels change after /reload)",
    OPT_LANG_AUTO    = "Automatic (client language)",
    OPT_LANG_IT      = "Italiano",
    OPT_LANG_EN      = "English",

    TT_LEFT          = "Left click: open/close",
    TT_RIGHT         = "Right click: options",

    MSG_INTERNAL_ERROR = "internal error:",
    MSG_NO_SETTINGS  = "options panel unavailable: use the /rac commands.",
    MSG_LANG         = "language: %s (the options panel updates after /reload)",
    MSG_LANG_USAGE   = "usage: /rac lang auto|it|en",
    MSG_POS_RESET    = "position reset.",
    MSG_WAYPOINT     = "waypoint: %s",
    MSG_NO_WAYPOINT  = "waypoint not available on this map.",
    WOWHEAD_POPUP    = "Wowhead - %s\n(Ctrl+C to copy)",

    HELP = {
        "/rac - open or close the panel",
        "/rac delves | events | weekly | leveling | gold - open a tab",
        "/rac profile casual|regular|dedicated - play style for gold strategies",
        "/rac stop - cancel the current route",
        "/rac refresh - refresh the data",
        "/rac summary - chat summary",
        "/rac config - options panel",
        "/rac minimap - show/hide the minimap icon",
        "/rac lang auto|it|en - language",
        "/rac reset - move the panel back to the center",
    },
}

ns.locales = { it = IT, en = EN }
ns.lang = (GetLocale and GetLocale() == "itIT") and "it" or "en"

ns.L = setmetatable({}, {
    __index = function(_, key)
        local t = ns.locales[ns.lang]
        local v = (t and t[key]) or IT[key]
        if v == nil then return key end
        return v
    end,
})

function ns:SetLanguage(setting)
    if setting == "it" or setting == "en" then
        self.lang = setting
    else
        self.lang = (GetLocale and GetLocale() == "itIT") and "it" or "en"
    end
end
