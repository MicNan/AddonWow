-- RotAssist - Locale
-- Testi dell'interfaccia in italiano e inglese. Le abilita' sono sempre
-- identificate per spellID: i loro nomi arrivano dal client.
--
-- Lingua: opzione 'language' = "auto" (italiano con client itIT, altrimenti
-- inglese), "it" oppure "en". ns.L risolve ogni testo al momento dell'uso,
-- quindi il cambio di lingua vale subito per avvisi e riquadri; le etichette
-- del pannello opzioni si aggiornano dopo /reload.
-- I messaggi di diagnostica (probe, why, verify, debug) restano in italiano.

local _, ns = ...

local IT = {
    MODE_AUTO        = "AUTO",
    MODE_ST          = "ST",
    MODE_AOE         = "AOE",
    MODE_CLEAVE      = "CLEAVE",
    SRC_NATIVE       = "N",
    SRC_RULE         = "R",
    DRAG_HINT        = "RotAssist - trascina",
    DRAG_COOLDOWNS   = "RotAssist - cooldown",
    DRAG_ALERTS      = "RotAssist - avvisi",

    PET_MISSING      = "Pet assente",
    PET_DEAD         = "Pet morto",
    PET_NOT_ATTACKING = "Pet non in attacco",
    PET_LOW          = "Pet sotto il %d%% di vita",
    HUNTERS_MARK_MISSING = "Hunter's Mark mancante",
    BUFF_MISSING     = "%s mancante",
    DEBUFF_MISSING   = "%s mancante sul bersaglio",
    DEBUFF_EXPIRING  = "%s in scadenza",
    ES_ALLY_MISSING  = "Earth Shield su nessun alleato",
    ES_SELF_MISSING  = "Earth Shield su di te mancante",
    IMBUE_MISSING    = "%s mancante sull'arma",
    FS_MISSING       = "Flame Shock mancante",
    FS_EXPIRING      = "Flame Shock in scadenza",

    -- Messaggi
    MSG_INTERNAL_ERROR = "si e' verificato un errore interno (ignorato). Usa /rotassist debug per i dettagli.",
    MSG_INTERNAL_ERROR_DETAIL = "|cffff5555errore interno:|r %s",
    MSG_DEBUG_HINT   = "debug attivo: /rotassist why per il dettaglio delle regole.",
    MSG_NO_SETTINGS  = "pannello opzioni non disponibile: usa i comandi /rotassist.",
    MSG_MODE         = "modalita': %s",
    MSG_SOURCE       = "fonte: %s",
    MSG_DEBUG_ON     = "debug attivo",
    MSG_DEBUG_OFF    = "debug disattivato",
    MSG_UNLOCKED     = "riquadri sbloccati: trascinali, poi /rotassist lock.",
    MSG_LOCKED       = "riquadri bloccati.",
    MSG_SCALE_USAGE  = "uso: /rotassist scale 0.5-2",
    MSG_SOURCE_USAGE = "uso: /rotassist source hybrid|native|rules",
    MSG_LANG_USAGE   = "uso: /rotassist lang auto|it|en",
    MSG_LANG         = "lingua: %s (il pannello opzioni si aggiorna dopo /reload)",
    MSG_LOG_CLEARED  = "registro svuotato.",
    MSG_LOG_STATUS   = "registro: %d righe. Fai /reload per scriverlo su disco. /rotassist log clear per svuotarlo.",
    MSG_NOTE         = "NOTA: %s",
    MSG_MINIMAP_SHOWN = "icona minimappa visibile",
    MSG_MINIMAP_HIDDEN = "icona minimappa nascosta (resta nel menu AddOns)",
    MSG_POS_RESET    = "posizioni ripristinate.",
    MSG_NO_SUGGESTION = "nessun suggerimento attivo: usa /rotassist wowhead <spellID>.",
    WOWHEAD_POPUP    = "Wowhead - %s\n(Ctrl+C per copiare)",

    HELP = {
        "/rotassist show | hide | toggle - mostra/nasconde",
        "/rotassist lock | unlock - blocca/sblocca i riquadri",
        "/rotassist scale <0.5-2> - scala",
        "/rotassist mode auto|st|aoe - modalita' bersagli (anche da tasto)",
        "/rotassist source hybrid|native|rules - fonte del suggerimento",
        "/rotassist lang auto|it|en - lingua dell'interfaccia",
        "/rotassist debug [on|off] - spiega in chat i suggerimenti",
        "/rotassist why - valutazione completa delle regole (ultimo aggiornamento)",
        "/rotassist probe - verifica quali API sono segrete adesso",
        "/rotassist verify - controlla gli spellID di tutti i moduli con i dati del client",
        "/rotassist config - apre il pannello opzioni",
        "/rotassist minimap - mostra/nasconde l'icona sulla minimappa",
        "/rotassist wowhead [spellID] - link Wowhead del suggerimento attuale (o dello spellID)",
        "/rotassist reset - riporta i riquadri al centro",
        "/rotassist info - versione, client, spec (utile nei log)",
        "/rotassist note <testo> - aggiunge una nota al registro",
        "/rotassist log [clear] - stato o svuotamento del registro (salvato al /reload)",
    },

    -- Opzioni
    OPT_SHOWN        = "Mostra RotAssist",
    OPT_LOCKED       = "Blocca i riquadri",
    OPT_SCALE        = "Scala",
    OPT_ONLYCOMBAT   = "Mostra solo in combattimento o con un bersaglio ostile",
    OPT_MODE         = "Modalita' bersagli",
    OPT_MODE_AUTO    = "Automatica (nameplate)",
    OPT_MODE_ST      = "Bersaglio singolo",
    OPT_MODE_AOE     = "AoE",
    OPT_THRESHOLD    = "Nemici per AoE (se la guida della spec non fissa una soglia; Elemental usa 4)",
    OPT_SOURCE       = "Fonte del suggerimento principale",
    OPT_SRC_HYBRID   = "Ibrida (Assisted Combat + regole)",
    OPT_SRC_NATIVE   = "Solo Assisted Combat",
    OPT_SRC_RULES    = "Solo regole RotAssist",
    OPT_COOLDOWNS    = "Mostra riquadro cooldown maggiori",
    OPT_ALERTS       = "Mostra avvisi",
    OPT_RESOURCE     = "Mostra barre risorsa e pet",
    OPT_KEYBINDS     = "Mostra il tasto assegnato sulle icone",
    OPT_SOUND        = "Suono quando compare un avviso",
    OPT_DEBUG        = "Modalita' debug (spiega i suggerimenti in chat)",
    OPT_MINIMAP      = "Mostra l'icona sulla minimappa",
    OPT_LANGUAGE     = "Lingua (le etichette di questo pannello cambiano dopo /reload)",
    OPT_LANG_AUTO    = "Automatica (lingua del client)",
    OPT_LANG_IT      = "Italiano",
    OPT_LANG_EN      = "English",

    -- Tooltip icona minimappa / menu AddOns
    TT_SPEC          = "Spec",
    TT_HERO          = "Hero talent",
    TT_MODE          = "Modalita'",
    TT_SOURCE        = "Fonte",
    TT_SHOWN         = "Visibile",
    TT_LOCKED        = "Riquadri bloccati",
    TT_YES           = "si'",
    TT_NO            = "no",
    TT_LEFT          = "Clic sinistro: opzioni",
    TT_SHIFT         = "Maiusc + clic: mostra/nascondi",
    TT_RIGHT         = "Clic destro: blocca/sblocca riquadri",
    TT_MIDDLE        = "Clic centrale: cambia modalita'",

    BINDING_TOGGLEMODE = "Cambia modalita' (Auto / ST / AoE)",
}

local EN = {
    MODE_AUTO        = "AUTO",
    MODE_ST          = "ST",
    MODE_AOE         = "AOE",
    MODE_CLEAVE      = "CLEAVE",
    SRC_NATIVE       = "N",
    SRC_RULE         = "R",
    DRAG_HINT        = "RotAssist - drag",
    DRAG_COOLDOWNS   = "RotAssist - cooldowns",
    DRAG_ALERTS      = "RotAssist - alerts",

    PET_MISSING      = "Pet missing",
    PET_DEAD         = "Pet dead",
    PET_NOT_ATTACKING = "Pet not attacking",
    PET_LOW          = "Pet below %d%% health",
    HUNTERS_MARK_MISSING = "Hunter's Mark missing",
    BUFF_MISSING     = "%s missing",
    DEBUFF_MISSING   = "%s missing on target",
    DEBUFF_EXPIRING  = "%s expiring",
    ES_ALLY_MISSING  = "Earth Shield on no ally",
    ES_SELF_MISSING  = "Earth Shield missing on you",
    IMBUE_MISSING    = "%s missing on weapon",
    FS_MISSING       = "Flame Shock missing",
    FS_EXPIRING      = "Flame Shock expiring",

    MSG_INTERNAL_ERROR = "an internal error occurred (ignored). Use /rotassist debug for details.",
    MSG_INTERNAL_ERROR_DETAIL = "|cffff5555internal error:|r %s",
    MSG_DEBUG_HINT   = "debug on: /rotassist why shows the full rule evaluation.",
    MSG_NO_SETTINGS  = "options panel unavailable: use the /rotassist commands.",
    MSG_MODE         = "mode: %s",
    MSG_SOURCE       = "source: %s",
    MSG_DEBUG_ON     = "debug on",
    MSG_DEBUG_OFF    = "debug off",
    MSG_UNLOCKED     = "frames unlocked: drag them, then /rotassist lock.",
    MSG_LOCKED       = "frames locked.",
    MSG_SCALE_USAGE  = "usage: /rotassist scale 0.5-2",
    MSG_SOURCE_USAGE = "usage: /rotassist source hybrid|native|rules",
    MSG_LANG_USAGE   = "usage: /rotassist lang auto|it|en",
    MSG_LANG         = "language: %s (the options panel updates after /reload)",
    MSG_LOG_CLEARED  = "log cleared.",
    MSG_LOG_STATUS   = "log: %d lines. /reload writes it to disk. /rotassist log clear empties it.",
    MSG_NOTE         = "NOTE: %s",
    MSG_MINIMAP_SHOWN = "minimap icon shown",
    MSG_MINIMAP_HIDDEN = "minimap icon hidden (still in the AddOns menu)",
    MSG_POS_RESET    = "positions reset.",
    MSG_NO_SUGGESTION = "no active suggestion: use /rotassist wowhead <spellID>.",
    WOWHEAD_POPUP    = "Wowhead - %s\n(Ctrl+C to copy)",

    HELP = {
        "/rotassist show | hide | toggle - show/hide",
        "/rotassist lock | unlock - lock/unlock the frames",
        "/rotassist scale <0.5-2> - scale",
        "/rotassist mode auto|st|aoe - target mode (also via keybinding)",
        "/rotassist source hybrid|native|rules - suggestion source",
        "/rotassist lang auto|it|en - interface language",
        "/rotassist debug [on|off] - explain suggestions in chat",
        "/rotassist why - full rule evaluation (last update)",
        "/rotassist probe - check which APIs are secret right now",
        "/rotassist verify - check every module's spellIDs against client data",
        "/rotassist config - open the options panel",
        "/rotassist minimap - show/hide the minimap icon",
        "/rotassist wowhead [spellID] - Wowhead link of the current suggestion (or spellID)",
        "/rotassist reset - move the frames back to the center",
        "/rotassist info - version, client, spec (useful in logs)",
        "/rotassist note <text> - add a note to the log",
        "/rotassist log [clear] - log status or clear (saved on /reload)",
    },

    OPT_SHOWN        = "Show RotAssist",
    OPT_LOCKED       = "Lock frames",
    OPT_SCALE        = "Scale",
    OPT_ONLYCOMBAT   = "Show only in combat or with a hostile target",
    OPT_MODE         = "Target mode",
    OPT_MODE_AUTO    = "Automatic (nameplates)",
    OPT_MODE_ST      = "Single target",
    OPT_MODE_AOE     = "AoE",
    OPT_THRESHOLD    = "Enemies for AoE (when the spec guide sets no threshold; Elemental uses 4)",
    OPT_SOURCE       = "Main suggestion source",
    OPT_SRC_HYBRID   = "Hybrid (Assisted Combat + rules)",
    OPT_SRC_NATIVE   = "Assisted Combat only",
    OPT_SRC_RULES    = "RotAssist rules only",
    OPT_COOLDOWNS    = "Show major cooldowns frame",
    OPT_ALERTS       = "Show alerts",
    OPT_RESOURCE     = "Show resource and pet bars",
    OPT_KEYBINDS     = "Show the keybinding on icons",
    OPT_SOUND        = "Play a sound when an alert appears",
    OPT_DEBUG        = "Debug mode (explain suggestions in chat)",
    OPT_MINIMAP      = "Show the minimap icon",
    OPT_LANGUAGE     = "Language (this panel's labels change after /reload)",
    OPT_LANG_AUTO    = "Automatic (client language)",
    OPT_LANG_IT      = "Italiano",
    OPT_LANG_EN      = "English",

    TT_SPEC          = "Spec",
    TT_HERO          = "Hero talent",
    TT_MODE          = "Mode",
    TT_SOURCE        = "Source",
    TT_SHOWN         = "Shown",
    TT_LOCKED        = "Frames locked",
    TT_YES           = "yes",
    TT_NO            = "no",
    TT_LEFT          = "Left click: options",
    TT_SHIFT         = "Shift + click: show/hide",
    TT_RIGHT         = "Right click: lock/unlock frames",
    TT_MIDDLE        = "Middle click: change mode",

    BINDING_TOGGLEMODE = "Change mode (Auto / ST / AoE)",
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

-- Applica l'opzione di lingua ("auto" | "it" | "en").
function ns:SetLanguage(setting)
    if setting == "it" or setting == "en" then
        self.lang = setting
    else
        self.lang = (GetLocale and GetLocale() == "itIT") and "it" or "en"
    end
    BINDING_HEADER_ROTASSIST = "RotAssist"
    BINDING_NAME_ROTASSIST_TOGGLEMODE = self.L.BINDING_TOGGLEMODE
end

ns:SetLanguage("auto")
