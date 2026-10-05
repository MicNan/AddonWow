-- RotAssist - Hunter: Marksmanship (specID 254)
--
-- Fonte della priorita': Icy Veins, "Marksmanship Hunter DPS Rotation,
-- Cooldowns, and Abilities - 12.1" (Azortharion, aggiornata il 31 ago 2026).
-- https://www.icy-veins.com/wow/marksmanship-hunter-pve-dps-rotation-cooldowns-abilities
--
-- Hero talent: Sentinel (scelta consigliata) e Dark Ranger.
-- Segnali:
--   * Precise Shots: attivato da Aimed Shot, consumato da Arcane Shot /
--     Multi-Shot / Kill Shot (stima dai cast) + glow di Arcane Shot come indizio;
--   * Trick Shots: Multi-Shot su 3+ bersagli, consumato da Aimed Shot / Rapid Fire;
--   * Trueshot: 15 s dal cast (Wowhead);
--   * Lock and Load: glow di Aimed Shot (indizio, da verificare).
-- NON leggibili: Sentinel's Mark / Spotter's Mark sui bersagli, stack di
-- Bullseye, durata di Bulletstorm -> le condizioni relative sono omesse.
-- Senza il talento Trick Shots la guida usa la lista ST anche in AoE.

local _, ns = ...
local L = ns.L

local S = {
    AIMED_SHOT      = 19434,
    ARCANE_SHOT     = 185358,
    MULTI_SHOT      = 257620,
    KILL_SHOT       = 53351,
    RAPID_FIRE      = 257044,
    TRUESHOT        = 288613,
    EXPLOSIVE_SHOT  = 212431,
    VOLLEY          = 260243,
    STEADY_SHOT     = 56641,
    BLACK_ARROW     = 466932,   -- versione Marksmanship (Dark Ranger)
    WAILING_ARROW   = 392060,
    MOONLIGHT_CHAKRAM = 1264902, -- Sentinel
    SENTINELS_MARK  = 1253601,
    LUNAR_STORM     = 1253732,
    HUNTERS_MARK    = 257284,
    UNSTABLE_TRIGGER = 473520,
    TACTICAL_RELOAD = 1301406,
    TRICK_SHOTS     = 257621,
    ASPECT_OF_THE_HYDRA = 470945,
}

local AIMED, ARCANE, MULTI, KS, RF = S.AIMED_SHOT, S.ARCANE_SHOT, S.MULTI_SHOT, S.KILL_SHOT, S.RAPID_FIRE
local TS, EXP, VOLLEY, STEADY = S.TRUESHOT, S.EXPLOSIVE_SHOT, S.VOLLEY, S.STEADY_SHOT
local BA, WA, CHAKRAM, TRICK, HYDRA = S.BLACK_ARROW, S.WAILING_ARROW, S.MOONLIGHT_CHAKRAM, S.TRICK_SHOTS, S.ASPECT_OF_THE_HYDRA

-- Precise Shots attivo (stima dai cast) oppure Arcane Shot illuminato
local PRECISE = { "or", { "flag", "precise" }, { "glow", ARCANE } }

local R = {
    exp    = { id = "exp", spell = EXP, talent = EXP,
               conds = { { "or", { "not", { "known", S.TACTICAL_RELOAD } }, { "not", { "glow", AIMED } } } },
               note = "Explosive Shot al cooldown (con Tactical Reload: non se Lock and Load e' attivo)" },
    volley = { id = "volley", spell = VOLLEY, talent = VOLLEY, note = "Volley al cooldown" },
    ts     = { id = "ts", spell = TS,
               note = "Trueshot (prima cambia bersaglio se il marchio e' gia' applicato: non leggibile)" },
    chakram_ts = { id = "chakram_ts", spell = CHAKRAM, pin = true,
               conds = { { "timer", "trueshot" }, { "timerLT", "trueshot", 5 } },
               note = "Moonlight Chakram negli ultimi 5 s di Trueshot" },
    rf     = { id = "rf", spell = RF, note = "Rapid Fire al cooldown" },
    ks_ps  = { id = "ks_ps", spell = KS, talent = KS, conds = { PRECISE },
               note = "Kill Shot per spendere Precise Shots" },
    ms_hydra = { id = "ms_hydra", spell = MULTI, talent = HYDRA, conds = { { "targetsGE", 2 }, PRECISE },
               note = "Multi-Shot al posto di Arcane Shot con Precise Shots su 2+ bersagli" },
    as_ps  = { id = "as_ps", spell = ARCANE, conds = { PRECISE }, note = "Arcane Shot per spendere Precise Shots" },
    aimed  = { id = "aimed", spell = AIMED, note = "Aimed Shot al cooldown" },
    chakram = { id = "chakram", spell = CHAKRAM, note = "Moonlight Chakram" },
    ba     = { id = "ba", spell = BA, note = "Black Arrow" },
    ba_ps  = { id = "ba_ps", spell = BA, pin = true, conds = { PRECISE },
               note = "Black Arrow con Precise Shots" },
    wa     = { id = "wa", spell = WA, note = "Wailing Arrow al cooldown" },
    steady = { id = "steady", spell = STEADY, note = "Steady Shot" },
    -- AoE (Trick Shots)
    ms_trick = { id = "ms_trick", spell = MULTI, talent = TRICK, pin = true,
               any = { PRECISE, { "not", { "flag", "trickShots" } } },
               note = "Multi-Shot per Precise Shots o per attivare Trick Shots" },
    rf_trick = { id = "rf_trick", spell = RF, talent = TRICK, conds = { { "flag", "trickShots" } },
               note = "Rapid Fire con Trick Shots attivo" },
    aimed_trick = { id = "aimed_trick", spell = AIMED, talent = TRICK, conds = { { "flag", "trickShots" } },
               note = "Aimed Shot con Trick Shots attivo" },
}

ns:RegisterSpec(254, {
    name = "Marksmanship",
    class = "HUNTER",
    spells = S,
    filler = STEADY,
    resource = (Enum and Enum.PowerType and Enum.PowerType.Focus) or 2,

    heroTalents = {
        { key = "SEN", spells = { CHAKRAM, S.SENTINELS_MARK, S.LUNAR_STORM }, name = "Sentinel" },
        { key = "DR",  spells = { BA },                                     name = "Dark Ranger" },
    },
    defaultHero = "SEN",

    aoeRequires = TRICK,
    aoeHints = { [MULTI] = 3 },

    track = {
        cooldowns = { [TS] = true, [RF] = true, [EXP] = true, [VOLLEY] = true, [BA] = true,
                      [CHAKRAM] = true, [WA] = true },
        charges   = { AIMED },
    },
    base = {
        [AIMED] = { recharge = 15 }, [RF] = { cd = 16 }, [EXP] = { cd = 30 }, [VOLLEY] = { cd = 45 },
    },

    onCast = {
        [AIMED]  = { { type = "flag", key = "precise", value = true },
                     { type = "flag", key = "trickShots", value = false } },
        [ARCANE] = { { type = "flag", key = "precise", value = false } },
        [KS]     = { { type = "flag", key = "precise", value = false } },
        [MULTI]  = { { type = "flag", key = "precise", value = false },
                     { type = "flag", key = "trickShots", value = true, minTargets = 3 } },
        [RF]     = { { type = "flag", key = "trickShots", value = false } },
        [TS]     = { { type = "timer", key = "trueshot", duration = 15 } },
    },

    majorCooldowns = {
        { spell = TS },
        { spell = VOLLEY },
    },

    alerts = {
        { type = "targetAuraMissing", key = "hm", auras = { S.HUNTERS_MARK }, icon = S.HUNTERS_MARK,
          castSpell = S.HUNTERS_MARK, text = L.HUNTERS_MARK_MISSING,
          classifications = { worldboss = true, elite = true, rareelite = true } },
    },

    priorities = {
        SEN = {
            ST = {
                R.exp, R.volley, R.ts, R.chakram_ts, R.rf, R.ks_ps, R.ms_hydra, R.as_ps,
                R.aimed, R.chakram, R.steady,
            },
            AOE = {
                R.exp, R.volley, R.ts, R.chakram_ts, R.ms_trick, R.rf_trick, R.aimed_trick,
                R.chakram, R.steady,
            },
        },
        DR = {
            ST = {
                R.ba_ps, R.exp, R.volley,
                { id = "aimed_ts", spell = AIMED,
                  any = { { "and", { "timer", "trueshot" }, { "not", PRECISE }, { "ready", BA } },
                          { "chargesNearMax", AIMED, "gcd" } },
                  note = "Aimed Shot in Trueshot senza Precise Shots con Black Arrow pronto, o vicino a 2 cariche" },
                R.ts, R.rf, R.wa, R.ms_hydra, R.as_ps, R.aimed, R.ba, R.steady,
            },
            AOE = {
                R.exp, R.volley,
                { id = "aimed_max", spell = AIMED, talent = TRICK,
                  conds = { { "flag", "trickShots" }, { "chargesNearMax", AIMED, "gcd" } },
                  note = "Aimed Shot con Trick Shots vicino a 2 cariche" },
                R.ba_ps,
                { id = "ms_trick_down", spell = MULTI, talent = TRICK, pin = true,
                  conds = { { "not", { "flag", "trickShots" } } },
                  note = "Multi-Shot per attivare Trick Shots" },
                R.ts, R.rf_trick,
                { id = "wa_noba", spell = WA, conds = { { "notReady", BA } },
                  note = "Wailing Arrow se Black Arrow non e' pronto" },
                { id = "ms_ps", spell = MULTI, conds = { PRECISE }, note = "Multi-Shot per spendere Precise Shots" },
                R.aimed_trick, R.ba, R.steady,
            },
        },
    },
})
