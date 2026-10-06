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
        "/rac delve | eventi | settimanale | levelling - apre la scheda",
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
        "/rac delves | events | weekly | leveling - open a tab",
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
