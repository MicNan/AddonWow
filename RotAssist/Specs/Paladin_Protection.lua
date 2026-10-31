-- RotAssist - Paladin: Protection (specID 66)
--
-- Fonte: Icy Veins, "Protection Paladin Tank Rotation, Cooldowns, and
-- Abilities - 12.1.5" (Panthea, rivista il 12 ott 2026).
-- https://www.icy-veins.com/wow/protection-paladin-pve-tank-rotation-cooldowns-abilities
--
-- Hero talent: Templar (Hammer of Light) e Lightsmith (Holy Armaments /
-- Sacred Weapon). Le due liste della guida sono uguali a parte l'abilita'
-- dell'hero talent.
--
-- Holy Power e' segreto in combattimento: Shield of the Righteous e Word of
-- Glory (3 Holy Power) si suggeriscono quando IsSpellUsable dice che sono
-- lanciabili (leggibile). Shining Light (Word of Glory gratis, ogni 3 Shield
-- of the Righteous) e Vanguard (Avenger's Shield potenziato) si riconoscono
-- dal glow del pulsante (VERIFICARE in gioco).
--
-- Difese in base alla vita (spec.defensives, gestite da Core\Defensives.lua):
-- "cura" = Word of Glory sotto la soglia (50%), "salva" = Ardent Defender,
-- Guardian of Ancient Kings, Divine Shield, Lay on Hands sotto la soglia
-- (35%). Spell ID da confermare con /rotassist verify.

local _, ns = ...

local S = {
    SHIELD_OF_THE_RIGHTEOUS = 53600,
    WORD_OF_GLORY   = 85673,
    CONSECRATION    = 26573,
    JUDGMENT        = 275779,   -- versione Protection
    AVENGERS_SHIELD = 31935,
    HAMMER_OF_WRATH = 24275,
    BLESSED_HAMMER  = 204019,
    HAMMER_OF_THE_RIGHTEOUS = 53595,
    AVENGING_WRATH  = 31884,
    SENTINEL        = 389539,   -- sostituisce Avenging Wrath
    DIVINE_TOLL     = 375576,
    EYE_OF_TYR      = 387174,
    HAMMER_OF_LIGHT = 427453,   -- Templar
    LIGHTS_GUIDANCE = 427445,   -- Templar (talento)
    HOLY_ARMAMENTS  = 432459,   -- Lightsmith (Holy Bulwark / Sacred Weapon)
    SACRED_WEAPON   = 432472,   -- Lightsmith
    ARCANE_TORRENT  = 155145,   -- razziale (Blood Elf)
    ARDENT_DEFENDER = 31850,
    GUARDIAN_OF_ANCIENT_KINGS = 86659,
    DIVINE_SHIELD   = 642,
    LAY_ON_HANDS    = 633,
    BLESSING_OF_SPELLWARDING = 204018,
    BLESSING_OF_PROTECTION = 1022,
    HAND_OF_RECKONING = 62124,
    REBUKE          = 96231,
}

local SOTR, WOG, CONS, JUD, AS = S.SHIELD_OF_THE_RIGHTEOUS, S.WORD_OF_GLORY, S.CONSECRATION, S.JUDGMENT, S.AVENGERS_SHIELD
local HOW, BH, HOTR, AW, SENT = S.HAMMER_OF_WRATH, S.BLESSED_HAMMER, S.HAMMER_OF_THE_RIGHTEOUS, S.AVENGING_WRATH, S.SENTINEL
local DT, HOL, SW, AT = S.DIVINE_TOLL, S.HAMMER_OF_LIGHT, S.SACRED_WEAPON, S.ARCANE_TORRENT

-- Regole comuni
local R = {
    -- interrupt: il bersaglio sta lanciando (Core\Interrupts.lua); Avenger's
    -- Shield interrompe anche lui, utile se Rebuke e' in ricarica
    kick    = { id = "kick", spell = S.REBUKE, pin = true, conds = { { "targetCasting" } },
                note = "Rebuke: il bersaglio sta lanciando" },
    kick_as = { id = "kick_as", spell = AS, pin = true,
                conds = { { "targetCasting" }, { "notReady", S.REBUKE } },
                note = "Avenger's Shield per interrompere (Rebuke in ricarica)" },
    aw      = { id = "aw", spell = AW, notTalent = SENT, note = "Avenging Wrath al cooldown" },
    sent    = { id = "sent", spell = SENT, talent = SENT, note = "Sentinel al cooldown" },
    sw      = { id = "sw", spell = SW, hero = "LS", conds = { { "noTimer", "aw" } },
                note = "Sacred Weapon se Avenging Wrath non e' attivo" },
    dt      = { id = "dt", spell = DT, note = "Divine Toll" },
    hol     = { id = "hol", spell = HOL, hero = "TEMP", pin = true, note = "Hammer of Light disponibile" },
    cons    = { id = "cons", spell = CONS, pin = true, conds = { { "noTimer", "consecration" } },
                note = "Consecration: non ci sei dentro (stima dal tuo ultimo cast)" },
    as_van  = { id = "as_van", spell = AS, pin = true, conds = { { "glow", AS } },
                note = "Avenger's Shield con Vanguard attivo (glow)" },
    sotr    = { id = "sotr", spell = SOTR, pin = true, needsResource = true,
                conds = { { "timerLT", "sotr", "gcd" } },
                note = "Shield of the Righteous: 3+ Holy Power e scudo in scadenza" },
    sotr2   = { id = "sotr2", spell = SOTR, needsResource = true,
                note = "Shield of the Righteous con 3+ Holy Power (non sprecare oltre 5)" },
    how     = { id = "how", spell = HOW, note = "Hammer of Wrath" },
    jud     = { id = "jud", spell = JUD, note = "Judgment" },
    bh      = { id = "bh", spell = BH, talent = BH, note = "Blessed Hammer" },
    hotr    = { id = "hotr", spell = HOTR, notTalent = BH, note = "Hammer of the Righteous" },
    as      = { id = "as", spell = AS, note = "Avenger's Shield" },
    at      = { id = "at", spell = AT, note = "Arcane Torrent (Blood Elf)" },
    wog_sl  = { id = "wog_sl", spell = WOG, conds = { { "glow", WOG } },
                note = "Word of Glory gratis con Shining Light (glow)" },
    cons_re = { id = "cons_re", spell = CONS, conds = { { "timerLT", "consecration", 4 } },
                note = "Consecration per rinnovarla se tutto il resto e' in cooldown" },
}

local function List(aoe)
    local l = { R.kick, R.kick_as, R.aw, R.sent, R.sw, R.dt, R.hol, R.cons, R.as_van, R.sotr, R.sotr2 }
    if aoe then l[#l + 1] = R.as end
    for _, r in ipairs({ R.how, R.jud, R.bh, R.hotr }) do l[#l + 1] = r end
    if not aoe then l[#l + 1] = R.as end
    for _, r in ipairs({ R.at, R.wog_sl, R.cons_re }) do l[#l + 1] = r end
    return l
end

ns:RegisterSpec(66, {
    name = "Protection",
    class = "PALADIN",
    spells = S,
    filler = CONS,
    resource = (Enum and Enum.PowerType and Enum.PowerType.HolyPower) or 9,

    heroTalents = {
        { key = "TEMP", spells = { S.LIGHTS_GUIDANCE, HOL }, name = "Templar" },
        { key = "LS",   spells = { S.HOLY_ARMAMENTS, SW },    name = "Lightsmith" },
    },
    defaultHero = "LS",

    -- Hammer of Light e Sacred Weapon compaiono al posto di un'altra abilita'
    overrideOf = { [HOL] = S.EYE_OF_TYR, [SW] = S.HOLY_ARMAMENTS },

    track = {
        cooldowns = { [S.REBUKE] = true, [AW] = true, [SENT] = true, [DT] = true, [AS] = true, [CONS] = true, [HOW] = true,
                      [S.ARDENT_DEFENDER] = true, [S.GUARDIAN_OF_ANCIENT_KINGS] = true, [S.DIVINE_SHIELD] = true,
                      [S.LAY_ON_HANDS] = true, [S.EYE_OF_TYR] = true, [AT] = true },
        charges   = { BH, JUD, HOTR },
    },
    base = {
        [S.REBUKE] = { cd = 15 }, [AS] = { cd = 15 }, [CONS] = { cd = 9 }, [DT] = { cd = 60 }, [AW] = { cd = 120 },
        [BH] = { recharge = 6 }, [JUD] = { recharge = 6 }, [HOTR] = { recharge = 6 },
        [S.ARDENT_DEFENDER] = { cd = 90 }, [S.GUARDIAN_OF_ANCIENT_KINGS] = { cd = 180 },
        [S.DIVINE_SHIELD] = { cd = 300 }, [S.LAY_ON_HANDS] = { cd = 600 },
    },
    onCast = {
        [CONS] = { { type = "timer", key = "consecration", duration = 12 } },
        -- ogni Shield of the Righteous allunga lo scudo di 4,5 s
        [SOTR] = { { type = "timer", key = "sotr", duration = 4.5, pandemic = 3 } },
        [AW]   = { { type = "timer", key = "aw", duration = 20 } },
        [SENT] = { { type = "timer", key = "aw", duration = 20 } },
    },

    alerts = {
        { type = "interrupt", spells = { S.REBUKE, AS } },
    },

    majorCooldowns = {
        { spell = AW }, { spell = SENT }, { spell = DT },
        { spell = S.ARDENT_DEFENDER }, { spell = S.GUARDIAN_OF_ANCIENT_KINGS },
        { spell = S.DIVINE_SHIELD }, { spell = S.LAY_ON_HANDS },
    },

    -- Difese in base alla vita del giocatore: per ogni livello la prima abilita'
    -- conosciuta e pronta; la soglia viene dalle opzioni (chiave in 'threshold').
    defensives = {
        { key = "heal", threshold = "defHeal", spells = { WOG },
          noteKey = "DEF_HEAL" },
        { key = "save", threshold = "defSave", emergency = true,
          spells = { S.ARDENT_DEFENDER, S.GUARDIAN_OF_ANCIENT_KINGS, S.DIVINE_SHIELD, S.LAY_ON_HANDS },
          noteKey = "DEF_SAVE" },
    },

    priorities = {
        default = { ST = List(false), AOE = List(true) },
    },
})
