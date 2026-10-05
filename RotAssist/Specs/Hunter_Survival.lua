-- RotAssist - Hunter: Survival (specID 255)
--
-- Fonte della priorita': Icy Veins, "Survival Hunter DPS Rotation, Cooldowns,
-- and Abilities - 12.1" (aggiornata il 30 ago 2026).
-- https://www.icy-veins.com/wow/survival-hunter-pve-dps-rotation-cooldowns-abilities
--
-- Hero talent: Sentinel (scelta consigliata) e Pack Leader.
-- Regola d'oro della guida: ogni abilita' va "Tipped" con Tip of the Spear.
-- Tip of the Spear (buff, segreto) e' ricostruito dai cast: Kill Command +1
-- (+1 con Primal Surge), massimo 3 (Wowhead); ogni abilita' potenziata -1.
-- Raptor Swipe: override di Raptor Strike (leggibile).
-- Howl of the Pack Leader pronto: si usa il glow di Kill Command come
-- indizio (VERIFICARE). Sentinel's Mark sul bersaglio: non leggibile.

local _, ns = ...
local L = ns.L

local S = {
    KILL_COMMAND    = 259489,   -- versione Survival
    RAPTOR_STRIKE   = 186270,
    RAPTOR_SWIPE    = 1259003,  -- upgrade di Raptor Strike
    WILDFIRE_BOMB   = 259495,
    TAKEDOWN        = 1250646,
    BOOMSTICK       = 1261193,
    MOONLIGHT_CHAKRAM = 1264902, -- Sentinel
    SENTINELS_MARK  = 1253601,
    HOWL_PACK_LEADER = 471876,  -- Pack Leader
    TWIN_FANGS      = 1272139,
    LETHAL_CALIBRATION = 1262409,
    PRIMAL_SURGE    = 1272154,
    HUNTERS_MARK    = 257284,
    PRIMAL_RAGE     = 264667,
    CALL_PET        = 883,
    REVIVE_PET      = 982,
    MEND_PET        = 136,
}

local KC, RS, SWIPE, WFB = S.KILL_COMMAND, S.RAPTOR_STRIKE, S.RAPTOR_SWIPE, S.WILDFIRE_BOMB
local TD, BOOM, CHAKRAM, TWIN, LETHAL = S.TAKEDOWN, S.BOOMSTICK, S.MOONLIGHT_CHAKRAM, S.TWIN_FANGS, S.LETHAL_CALIBRATION

local TIP_SPEND = { { type = "counter", key = "tip", add = -1 } }

local R = {
    kc_howl = { id = "kc_howl", spell = KC, pin = true,
                conds = { { "counterLT", "tip", 2 }, { "glow", KC } },
                note = "Kill Command sotto 2 Tip of the Spear con Howl of the Pack Leader pronto (glow)" },
    kc_pre_td = { id = "kc_pre_td", spell = KC, notTalent = TWIN,
                conds = { { "counterLT", "tip", 2 }, { "notReady", TD }, { "cdLT", TD, "gcd" } },
                note = "Kill Command sotto 2 Tip se Takedown sta per tornare" },
    td2     = { id = "td2", spell = TD, notTalent = TWIN, conds = { { "counterGE", "tip", 2 } },
                note = "Takedown con almeno 2 Tip of the Spear" },
    td0     = { id = "td0", spell = TD, talent = TWIN, conds = { { "counterLT", "tip", 1 } },
                note = "Takedown senza Tip of the Spear (Twin Fangs)" },
    boom    = { id = "boom", spell = BOOM, note = "Boomstick al cooldown" },
    swipe_tip = { id = "swipe_tip", spell = RS,
                conds = { { "overrideIs", RS, SWIPE }, { "counterGE", "tip", 1 } },
                note = "Raptor Swipe solo con Tip of the Spear" },
    raptor  = { id = "raptor", spell = RS, conds = { { "not", { "overrideIs", RS, SWIPE } } },
                note = "Raptor Strike" },
    kc_td   = { id = "kc_td", spell = KC, conds = { { "notReady", TD } },
                note = "Kill Command se Takedown e' in cooldown" },
    td      = { id = "td", spell = TD, note = "Takedown" },
    wfb     = { id = "wfb", spell = WFB, note = "Wildfire Bomb" },
    chakram = { id = "chakram", spell = CHAKRAM, note = "Moonlight Chakram" },
}

ns:RegisterSpec(255, {
    name = "Survival",
    class = "HUNTER",
    spells = S,
    filler = RS,
    resource = (Enum and Enum.PowerType and Enum.PowerType.Focus) or 2,
    petBar = { threshold = 0.40 },

    heroTalents = {
        { key = "SEN", spells = { CHAKRAM, S.SENTINELS_MARK }, name = "Sentinel" },
        { key = "PL",  spells = { S.HOWL_PACK_LEADER },        name = "Pack Leader" },
    },
    defaultHero = "SEN",

    aliases = { [SWIPE] = RS },
    petSpells = { [S.PRIMAL_RAGE] = true },

    track = {
        cooldowns = { [TD] = true, [BOOM] = true, [CHAKRAM] = true },
        charges   = { KC, WFB },
    },
    base = {
        [KC] = { recharge = 5 },   -- Wowhead (base)
    },

    onCast = {
        [KC] = { { type = "counter", key = "tip", add = 1, max = 3 },
                 { type = "counter", key = "tip", add = 1, max = 3, talent = S.PRIMAL_SURGE } },
        [RS] = TIP_SPEND, [WFB] = TIP_SPEND, [TD] = TIP_SPEND, [BOOM] = TIP_SPEND, [CHAKRAM] = TIP_SPEND,
    },

    majorCooldowns = {
        { spell = TD },
        { spell = BOOM },
        { spell = S.PRIMAL_RAGE, pet = true },
    },

    alerts = {
        { type = "petMissing", icon = S.CALL_PET, reviveIcon = S.REVIVE_PET },
        { type = "petNotAttacking", icon = KC, grace = 3 },
        { type = "petHealthLow", threshold = 0.40, icon = S.MEND_PET },
        { type = "targetAuraMissing", key = "hm", auras = { S.HUNTERS_MARK }, icon = S.HUNTERS_MARK,
          castSpell = S.HUNTERS_MARK, text = L.HUNTERS_MARK_MISSING,
          classifications = { worldboss = true, elite = true, rareelite = true } },
    },

    priorities = {
        PL = {
            ST = {
                R.kc_howl, R.kc_pre_td, R.td2, R.td0,
                { id = "wfb", spell = WFB, notTalent = LETHAL, note = "Wildfire Bomb al cooldown" },
                { id = "wfb_lc", spell = WFB, talent = LETHAL, conds = { { "chargesNearMax", WFB, 5 } },
                  note = "Wildfire Bomb entro 5 s dalle 2 cariche (Lethal Calibration)" },
                R.boom, R.swipe_tip, R.raptor,
                { id = "wfb_lc2", spell = WFB, talent = LETHAL, note = "Wildfire Bomb al cooldown" },
                R.kc_td, R.td,
            },
            AOE = {
                R.kc_howl, R.kc_pre_td, R.td2, R.td0,
                { id = "wfb_max", spell = WFB, conds = { { "chargesNearMax", WFB, "gcd" } },
                  note = "Wildfire Bomb vicino a 2 cariche" },
                R.boom, R.wfb, R.swipe_tip, R.raptor, R.kc_td, R.td,
            },
        },
        SEN = {
            ST = {
                { id = "kc0", spell = KC, notTalent = TWIN, conds = { { "counterLT", "tip", 1 } },
                  note = "Kill Command senza Tip of the Spear" },
                { id = "kc0_tf", spell = KC, talent = TWIN, conds = { { "counterLT", "tip", 1 }, { "notReady", TD } },
                  note = "Kill Command senza Tip e con Takedown in cooldown" },
                R.boom,
                { id = "wfb_max", spell = WFB, conds = { { "chargesNearMax", WFB, 4 } },
                  note = "Wildfire Bomb entro 4 s dalle 2 cariche (Sentinel's Mark non leggibile)" },
                R.kc_pre_td, R.td2, R.td0, R.chakram, R.raptor, R.swipe_tip,
                { id = "kc_fill", spell = KC, conds = { { "notReady", TD } },
                  note = "Kill Command come filler (meglio Takedown se pronto)" },
                R.wfb, R.td,
            },
            AOE = {
                { id = "kc0", spell = KC, conds = { { "counterLT", "tip", 1 } },
                  note = "Kill Command senza Tip of the Spear" },
                R.boom, R.wfb, R.kc_pre_td, R.td2, R.td0, R.chakram, R.swipe_tip, R.raptor,
                { id = "kc", spell = KC, note = "Kill Command" },
            },
        },
    },
})
