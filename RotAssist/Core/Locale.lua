-- RotAssist - Locale
-- Testi dell'interfaccia. Le abilita' sono sempre identificate per spellID:
-- i nomi mostrati arrivano dal client (C_Spell.GetSpellName), quindi sono
-- corretti in qualsiasi lingua del client.

local _, ns = ...

local L = {
    MODE_AUTO        = "AUTO",
    MODE_ST          = "ST",
    MODE_AOE         = "AOE",
    SRC_NATIVE       = "N",
    SRC_RULE         = "R",
    DRAG_HINT        = "RotAssist - trascina",

    PET_MISSING      = "Pet assente",
    PET_DEAD         = "Pet morto",
    PET_NOT_ATTACKING = "Pet non in attacco",
    PET_LOW          = "Pet sotto il %d%% di vita",
    HUNTERS_MARK_MISSING = "Hunter's Mark mancante",
    BUFF_MISSING     = "%s mancante",
    DEBUFF_MISSING   = "%s mancante sul bersaglio",
    DEBUFF_EXPIRING  = "%s in scadenza",

    -- Settings
    OPT_SHOWN        = "Mostra RotAssist",
    OPT_LOCKED       = "Blocca i riquadri",
    OPT_SCALE        = "Scala",
    OPT_ONLYCOMBAT   = "Mostra solo in combattimento o con un bersaglio ostile",
    OPT_MODE         = "Modalita' bersagli",
    OPT_MODE_AUTO    = "Automatica (nameplate)",
    OPT_MODE_ST      = "Bersaglio singolo",
    OPT_MODE_AOE     = "AoE",
    OPT_THRESHOLD    = "Nemici per AoE (modalita' automatica)",
    OPT_SOURCE       = "Fonte del suggerimento principale",
    OPT_SRC_HYBRID   = "Ibrida (Assisted Combat + regole)",
    OPT_SRC_NATIVE   = "Solo Assisted Combat",
    OPT_SRC_RULES    = "Solo regole RotAssist",
    OPT_COOLDOWNS    = "Mostra riquadro cooldown maggiori",
    OPT_ALERTS       = "Mostra avvisi",
    OPT_RESOURCE     = "Mostra barre risorsa e pet",
    OPT_SOUND        = "Suono quando compare un avviso",
    OPT_DEBUG        = "Modalita' debug (spiega i suggerimenti in chat)",
    OPT_MINIMAP      = "Mostra l'icona sulla minimappa",

    -- Tooltip icona minimappa / menu AddOns
    TT_SPEC          = "Spec",
    TT_HERO          = "Hero talent",
    TT_MODE          = "Modalita'",
    TT_SOURCE        = "Fonte",
    TT_SHOWN         = "Visibile",
    TT_LOCKED        = "Riquadri bloccati",
    TT_LEFT          = "Clic sinistro: opzioni",
    TT_SHIFT         = "Maiusc + clic: mostra/nascondi",
    TT_RIGHT         = "Clic destro: blocca/sblocca riquadri",
    TT_MIDDLE        = "Clic centrale: cambia modalita'",

    BINDING_TOGGLEMODE = "Cambia modalita' (Auto / ST / AoE)",
}

ns.L = L

BINDING_HEADER_ROTASSIST = "RotAssist"
BINDING_NAME_ROTASSIST_TOGGLEMODE = L.BINDING_TOGGLEMODE
