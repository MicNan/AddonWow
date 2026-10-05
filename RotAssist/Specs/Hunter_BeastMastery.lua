-- RotAssist - Hunter: Beast Mastery (specID 253)
--
-- Fonte della priorita': Icy Veins, "Beast Mastery Hunter DPS Rotation,
-- Cooldowns, and Abilities - 12.1" (Azortharion, aggiornata il 7 set 2026).
-- https://www.icy-veins.com/wow/beast-mastery-hunter-pve-dps-rotation-cooldowns-abilities
--
-- COME AGGIORNARE A OGNI PATCH
--   * spellID: tabella S qui sotto.
--   * ordine/condizioni: tabelle in 'priorities' (una per hero talent e modalita').
--   * durate dei buff ricostruiti dai cast: 'onCast' (vengono comunque
--     ricalibrate fuori combattimento tramite 'calibrateAuras').
--   * durate base dei cooldown: 'base' (vengono comunque apprese in gioco).
--
-- 'pin = true' marca le finestre temporali della guida che Assisted Combat non
-- conosce (Barbed Shot prima di BW, Wild Thrash dopo BW, Withering Fire...):
-- in modalita' ibrida queste regole scavalcano il suggerimento nativo.
--
-- Le righe della guida che dipendono da dati NON leggibili in combattimento
-- (stack di Cobra Fang, buff Nature's Ally, Focus) sono presenti ma marcate
-- 'disabled' con il motivo, cosi' resta traccia della priorita' completa.

local _, ns = ...

local S = {
    KILL_COMMAND   = 34026,
    BARBED_SHOT    = 217200,
    BESTIAL_WRATH  = 19574,
    COBRA_SHOT     = 193455,
    WILD_THRASH    = 1264359,
    BLACK_ARROW    = 466930,
    WAILING_ARROW  = 392060,   -- override di Bestial Wrath (Dark Ranger)
    HUNTERS_MARK   = 257284,
    BLOODSHED      = 321530,
    CALL_OF_THE_WILD = 359844,
    PRIMAL_RAGE    = 264667,   -- abilita' del pet (Bloodlust)
    HOWL_PACK_LEADER = 471876, -- talento chiave Pack Leader
    BEAST_CLEAVE_BUFF = 268877,
    WITHERING_FIRE = 466990,   -- verificato su Wowhead (430715 non esiste piu')
    CALL_PET       = 883,
    REVIVE_PET     = 982,
    MEND_PET       = 136,
}

local KC, BS, BW, COBRA = S.KILL_COMMAND, S.BARBED_SHOT, S.BESTIAL_WRATH, S.COBRA_SHOT
local WT, BA, WA = S.WILD_THRASH, S.BLACK_ARROW, S.WAILING_ARROW

local CF_DISABLED = "stack di Cobra Fang (aura) non leggibili in combattimento"

ns:RegisterSpec(253, {
    name = "Beast Mastery",
    class = "HUNTER",
    spells = S,
    filler = COBRA,
    resource = (Enum and Enum.PowerType and Enum.PowerType.Focus) or 2,
    petBar = { threshold = 0.40 },

    -- Hero talent: il primo talento conosciuto determina la lista usata.
    heroTalents = {
        { key = "PL", spell = S.HOWL_PACK_LEADER, name = "Pack Leader" },
        { key = "DR", spell = BA,                 name = "Dark Ranger" },
    },
    defaultHero = "PL",

    -- Abilita' ad area: se Assisted Combat le suggerisce, ci sono piu' bersagli
    -- (nel test su un solo manichino non ha mai suggerito Wild Thrash).
    aoeHints = { [WT] = true },

    -- ID alternativi visti in gioco (glow/cast) ricondotti all'ID principale.
    aliases = { [259489] = KC },   -- Kill Command: secondo ID nel glow (registro 05/10)

    -- Abilita' che esistono solo come override di un'altra.
    overrideOf = { [WA] = BW },
    petSpells  = { [S.PRIMAL_RAGE] = true },

    -- Cosa tracciare.
    track = {
        cooldowns = { [BW] = true, [WT] = true, [BA] = true, [S.BLOODSHED] = true },
        charges   = { BS, KC },
    },
    -- Valori iniziali, sostituiti da quelli appresi in gioco (VERIFICARE).
    base = {
        [BW] = { cd = 30 },          -- Icy Veins 12.1: 30 s
        [BS] = { recharge = 18 },    -- Wowhead: 18 s, 2 cariche (base)
        [KC] = { recharge = 7.5 },   -- Wowhead: 7.5 s (base)
        [WT] = { cd = 8 },           -- Wowhead: 8 s (base)
    },

    -- Buff ricostruiti dai propri cast (il buff vero e' segreto in combattimento).
    onCast = {
        [BW] = {
            { type = "timer", key = "bestialWrath", duration = 15 },
            { type = "timer", key = "witheringFire", duration = 10, hero = "DR" },
            { type = "flag",  key = "howlReady", value = true, hero = "PL" },
        },
        [KC] = {
            { type = "flag", key = "howlReady", value = false },
        },
        [WT] = {
            { type = "timer", key = "beastCleave", duration = 6 },   -- durata da verificare
        },
        [BA] = {
            { type = "timer", key = "beastCleave", duration = 6, minTargets = 3 },
        },
    },
    -- Fuori combattimento leggiamo le aure vere per correggere le durate.
    calibrateAuras = {
        bestialWrath = { auras = { BW } },
        beastCleave  = { auras = { S.BEAST_CLEAVE_BUFF } },
        witheringFire = { auras = { S.WITHERING_FIRE } },
    },

    majorCooldowns = {
        { spell = BW },
        { spell = S.BLOODSHED },
        { spell = S.CALL_OF_THE_WILD },
        { spell = S.PRIMAL_RAGE, pet = true },
    },

    alerts = {
        { type = "petMissing", icon = S.CALL_PET, reviveIcon = S.REVIVE_PET },
        { type = "petNotAttacking", icon = KC, grace = 3 },
        { type = "petHealthLow", threshold = 0.40, icon = S.MEND_PET },
        { type = "targetAuraMissing", auras = { S.HUNTERS_MARK }, icon = S.HUNTERS_MARK,
          castSpell = S.HUNTERS_MARK, text = ns.L.HUNTERS_MARK_MISSING,
          classifications = { worldboss = true, elite = true, rareelite = true } },
    },

    priorities = {
        -------------------------------------------------------------------
        -- PACK LEADER
        -------------------------------------------------------------------
        PL = {
            ST = {
                { id = "bs_pre_bw", spell = BS, pin = true,
                  conds = { { "notReady", BW } },
                  any = { { "cdLT", BW, "gcd" }, { "chargesNearMax", BS, "gcd" } },
                  note = "Barbed Shot: Bestial Wrath quasi pronto o 2 cariche imminenti" },
                { id = "bw", spell = BW, pin = true,
                  note = "Bestial Wrath on cooldown" },
                { id = "wt_cleave", spell = WT, talent = WT,
                  conds = { { "targetsGE", 2 } },
                  note = "Wild Thrash con piu' di un bersaglio" },
                { id = "kc_howl", spell = KC, pin = true,
                  conds = { { "flag", "howlReady" } },
                  note = "Kill Command: Howl of the Pack Leader pronto (stimato dal cast di BW)" },
                { id = "kc", spell = KC, onUnknown = "match",
                  any = { { "not", { "cdLT", BW, 3 } }, { "atMaxCharges", KC } },
                  note = "Kill Command, tenendo una carica se Bestial Wrath arriva entro 3 s" },
                { id = "cobra_fang", spell = COBRA, disabled = CF_DISABLED,
                  note = "Cobra Shot a 4 stack di Cobra Fang" },
                { id = "bs", spell = BS,
                  note = "Barbed Shot on cooldown" },
                { id = "cobra", spell = COBRA, onUnknown = "match",
                  conds = { { "not", { "cdLT", BW, "gcd" } } },
                  note = "Cobra Shot, salvo Bestial Wrath a meno di un GCD" },
            },
            AOE = {
                { id = "wt_after_bw", spell = WT, talent = WT, pin = true,
                  any = { { "recentCast", BW, "gcd" }, { "noTimer", "beastCleave" } },
                  note = "Wild Thrash subito dopo Bestial Wrath o con Beast Cleave assente" },
                { id = "bs_max", spell = BS, pin = true,
                  conds = { { "chargesNearMax", BS, "gcd" } },
                  note = "Barbed Shot: 2 cariche imminenti" },
                { id = "bw_cleave", spell = BW, talent = WT, pin = true,
                  conds = { { "timer", "beastCleave" } },
                  note = "Bestial Wrath con Beast Cleave attivo" },
                { id = "bw", spell = BW, notTalent = WT, pin = true,
                  note = "Bestial Wrath on cooldown" },
                { id = "wt_hold", spell = WT, talent = WT, onUnknown = "match",
                  conds = { { "not", { "cdBeforeTimerEnds", BW, "beastCleave" } } },
                  note = "Wild Thrash, trattenuto se BW torna prima che scada Beast Cleave" },
                { id = "kc", spell = KC,
                  note = "Kill Command on cooldown" },
                { id = "cobra_fang_cleave", spell = COBRA, disabled = CF_DISABLED,
                  note = "Cobra Shot con Cobra Fang e Beast Cleave" },
                { id = "bs", spell = BS,
                  note = "Barbed Shot on cooldown" },
                { id = "cobra_wt", spell = COBRA, talent = WT, onUnknown = "match",
                  conds = { { "not", { "cdLT", WT, "gcd" } } },
                  note = "Cobra Shot, salvo Wild Thrash a meno di un GCD" },
                { id = "cobra", spell = COBRA,
                  note = "Cobra Shot" },
            },
        },

        -------------------------------------------------------------------
        -- DARK RANGER
        -------------------------------------------------------------------
        DR = {
            ST = {
                { id = "bs_pre_bw", spell = BS, pin = true,
                  conds = { { "notReady", BW }, { "cdLT", BW, "gcd" } },
                  note = "Barbed Shot: Bestial Wrath quasi pronto" },
                { id = "bw", spell = BW, pin = true,
                  conds = { { "not", { "overrideIs", BW, WA } } },
                  note = "Bestial Wrath on cooldown" },
                { id = "ba_wf", spell = BA, pin = true, onUnknown = "match",
                  conds = { { "timer", "witheringFire" }, { "not", { "chargesNearMax", KC, "gcd" } } },
                  note = "Black Arrow durante Withering Fire (KC non vicino a 2 cariche)" },
                { id = "kc", spell = KC, onUnknown = "match",
                  any = { { "not", { "cdLT", BW, 4 } }, { "atMaxCharges", KC } },
                  note = "Kill Command, tenendo una carica se Bestial Wrath arriva entro 4 s" },
                { id = "wa", spell = WA, pin = true,
                  conds = { { "timer", "witheringFire" }, { "timerLT", "witheringFire", "2gcd" } },
                  note = "Wailing Arrow a 2 GCD dalla fine di Withering Fire" },
                { id = "cobra_fang", spell = COBRA, disabled = CF_DISABLED,
                  note = "Cobra Shot a 4 stack di Cobra Fang" },
                { id = "ba", spell = BA,
                  note = "Black Arrow" },
                { id = "bs", spell = BS,
                  note = "Barbed Shot on cooldown" },
                { id = "cobra", spell = COBRA, onUnknown = "match",
                  conds = { { "not", { "cdLT", BW, "gcd" } } },
                  note = "Cobra Shot, salvo Bestial Wrath a meno di un GCD" },
            },
            AOE = {
                { id = "ba_pre_bw", spell = BA, talent = WT, pin = true,
                  conds = { { "cdLT", BW, "2gcd" }, { "timerLT", "beastCleave", "2gcd" } },
                  note = "Black Arrow: Beast Cleave in scadenza e Bestial Wrath quasi pronto" },
                { id = "ba_pre_bw_3", spell = BA, notTalent = WT, pin = true,
                  conds = { { "targetsGE", 3 }, { "cdLT", BW, "2gcd" } },
                  note = "Black Arrow su 3+ bersagli prima di Bestial Wrath" },
                { id = "bw_cleave", spell = BW, talent = WT, pin = true,
                  conds = { { "timer", "beastCleave" }, { "not", { "overrideIs", BW, WA } } },
                  note = "Bestial Wrath con Beast Cleave attivo" },
                { id = "bw", spell = BW, notTalent = WT, pin = true,
                  conds = { { "not", { "overrideIs", BW, WA } } },
                  note = "Bestial Wrath on cooldown" },
                { id = "wt", spell = WT, talent = WT, pin = true, onUnknown = "match",
                  any = { { "recentCast", BW, "gcd" }, { "noTimer", "beastCleave" },
                          { "not", { "cdBeforeTimerEnds", BW, "beastCleave" } } },
                  note = "Wild Thrash dopo BW o senza Beast Cleave, altrimenti trattenuto" },
                { id = "kc", spell = KC, onUnknown = "match",
                  any = { { "not", { "cdLT", BW, 5 } }, { "atMaxCharges", KC } },
                  note = "Kill Command, tenendo una carica se Bestial Wrath arriva entro 5 s" },
                { id = "bs_max", spell = BS, pin = true,
                  conds = { { "chargesNearMax", BS, "gcd" } },
                  note = "Barbed Shot: 2 cariche imminenti" },
                { id = "ba_wf", spell = BA,
                  conds = { { "timer", "witheringFire" } },
                  note = "Black Arrow durante Withering Fire" },
                { id = "wa", spell = WA, pin = true,
                  conds = { { "timerLT", "witheringFire", "gcd" } },
                  note = "Wailing Arrow a un GCD dalla fine di Withering Fire" },
                { id = "bs", spell = BS, note = "Barbed Shot" },
                { id = "ba", spell = BA, note = "Black Arrow" },
                { id = "wa_any", spell = WA, note = "Wailing Arrow" },
                { id = "cobra", spell = COBRA, note = "Cobra Shot" },
            },
        },
    },
})
