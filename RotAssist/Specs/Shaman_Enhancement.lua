-- RotAssist - Shaman: Enhancement (specID 263)
--
-- Fonte della priorita': Icy Veins, "Enhancement Shaman DPS Rotation,
-- Cooldowns, and Abilities - 12.1" (aggiornata il 23 ago 2026).
-- https://www.icy-veins.com/wow/enhancement-shaman-pve-dps-rotation-cooldowns-abilities
-- Riepilogo e analisi dei segnali: docs/Shaman_12.1_riferimento.md
--
-- E' la spec con piu' segnali leggibili:
--   * stack di Maelstrom Weapon (aura 344179 in whitelist: leggibile anche in
--     combattimento; VERIFICARE con /rotassist probe);
--   * Windstrike = override di Stormstrike durante Ascendance;
--   * Tempest = override di Lightning Bolt (Stormbringer).
-- Stimati dai cast: Doom Winds (8 s), Ascendance (15 s), Flame Shock (18 s).
-- Hot Hand / Whirling Fire: si usa il glow di Lava Lash come indizio (VERIFICARE).

local _, ns = ...
local L = ns.L

local S = {
    STORMSTRIKE     = 17364,
    WINDSTRIKE      = 115356,   -- override di Stormstrike (Ascendance)
    LAVA_LASH       = 60103,
    CRASH_LIGHTNING = 187874,
    SUNDERING       = 197214,
    DOOM_WINDS      = 384352,
    PRIMORDIAL_STORM = 1218047,
    ASCENDANCE      = 114051,
    VOLTAIC_BLAZE   = 470057,
    FLAME_SHOCK     = 188389,
    SURGING_TOTEM   = 444995,   -- Totemic
    TEMPEST         = 454009,   -- override di Lightning Bolt (Stormbringer)
    SUPERCHARGE     = 455110,   -- Stormbringer
    LIGHTNING_BOLT  = 188196,
    CHAIN_LIGHTNING = 188443,
    MAELSTROM_WEAPON = 344179,  -- buff (stack)
    DEEPLY_ROOTED_ELEMENTS = 378270,
    SURGING_ELEMENTS = 382042,
    WINDFURY_WEAPON = 33757,
    FLAMETONGUE_WEAPON = 318038,
    LIGHTNING_SHIELD = 192106,
    EARTH_SHIELD    = 974,
    EARTH_SHIELD_SELF = 383648,
    ELEMENTAL_ORBIT = 383010,
    SKYFURY         = 462854,
    BLOODLUST       = 2825,
    HEROISM         = 32182,
}

local SS, WS, LL, CRASH, SUND = S.STORMSTRIKE, S.WINDSTRIKE, S.LAVA_LASH, S.CRASH_LIGHTNING, S.SUNDERING
local DW, PS, ASC, VB, FS = S.DOOM_WINDS, S.PRIMORDIAL_STORM, S.ASCENDANCE, S.VOLTAIC_BLAZE, S.FLAME_SHOCK
local LB, CL, TEMPEST, MW = S.LIGHTNING_BOLT, S.CHAIN_LIGHTNING, S.TEMPEST, S.MAELSTROM_WEAPON
local DRE, SE, ST = S.DEEPLY_ROOTED_ELEMENTS, S.SURGING_ELEMENTS, S.SURGING_TOTEM

-- Regole comuni
local R = {
    ps10  = { id = "ps10", spell = PS, talent = PS, pin = true, conds = { { "stacksGE", MW, 10 } },
              note = "Primordial Storm a 10 stack di Maelstrom Weapon" },
    crash = { id = "crash", spell = CRASH, note = "Crash Lightning" },
    asc   = { id = "asc", spell = ASC, talent = ASC, note = "Ascendance" },
    ws    = { id = "ws", spell = WS, note = "Windstrike durante Ascendance" },
    ss_dw = { id = "ss_dw", spell = SS, notTalent = DRE, conds = { { "timer", "doomWinds" } },
              note = "Stormstrike durante Doom Winds" },
    vb    = { id = "vb", spell = VB, note = "Voltaic Blaze al cooldown (set 2p)" },
    vb_nofs = { id = "vb_nofs", spell = VB, pin = true, conds = { { "noTimer", "flameShock" } },
              note = "Voltaic Blaze se Flame Shock non e' attivo (stima dai cast)" },
    surging = { id = "surging", spell = ST, note = "Surging Totem" },
    dw    = { id = "dw", spell = DW, conds = { { "not", { "known", ASC } }, { "not", { "known", DRE } } },
              note = "Doom Winds (senza Ascendance e Deeply Rooted Elements)" },
    ll_hh = { id = "ll_hh", spell = LL, pin = true, conds = { { "glow", LL } },
              note = "Lava Lash con Hot Hand / Whirling Fire (glow, da verificare)" },
    ll    = { id = "ll", spell = LL, note = "Lava Lash" },
    ss    = { id = "ss", spell = SS, note = "Stormstrike" },
}

ns:RegisterSpec(263, {
    name = "Enhancement",
    class = "SHAMAN",
    spells = S,
    filler = SS,
    stackBar = { aura = MW, max = 10, full = 10 },
    whitelistedAuras = { [MW] = true },

    heroTalents = {
        { key = "SB",  spells = { TEMPEST, S.SUPERCHARGE }, name = "Stormbringer" },
        { key = "TOT", spells = { ST },                     name = "Totemic" },
    },
    defaultHero = "SB",

    aoeHints = { [CL] = true },
    overrideOf = { [WS] = SS, [TEMPEST] = LB },
    targetTimers = { "flameShock" },

    track = {
        cooldowns = { [LL] = true, [CRASH] = true, [SUND] = true, [DW] = true, [ASC] = true,
                      [VB] = true, [ST] = true },
        charges   = { SS },
    },
    base = {
        [SS] = { recharge = 7.5 }, [LL] = { cd = 18 }, [CRASH] = { cd = 15 }, [SUND] = { cd = 30 },
        [DW] = { cd = 60 }, [ASC] = { cd = 180 }, [VB] = { cd = 10 }, [ST] = { cd = 25 },
    },

    onCast = {
        [VB]  = { { type = "timer", key = "flameShock", duration = 18, pandemic = 0.3 } },
        [FS]  = { { type = "timer", key = "flameShock", duration = 18, pandemic = 0.3 } },
        [DW]  = { { type = "timer", key = "doomWinds", duration = 8 } },
        [ASC] = { { type = "timer", key = "doomWinds", duration = 8 },
                  { type = "timer", key = "ascendance", duration = 15 } },
    },
    calibrateAuras = {
        flameShock = { unit = "target", auras = { FS }, filter = "HARMFUL|PLAYER" },
    },

    majorCooldowns = {
        { spell = ASC },
        { spell = DW },
        { spell = ST },
        { spell = S.BLOODLUST },
        { spell = S.HEROISM },
    },

    alerts = {
        { type = "weaponImbueMissing", key = "imbue", spell = S.WINDFURY_WEAPON, offSpell = S.FLAMETONGUE_WEAPON,
          mainHand = true, offHand = true },
        { type = "playerAuraMissing", key = "ls", auras = { S.LIGHTNING_SHIELD }, spell = S.LIGHTNING_SHIELD },
        { type = "playerAuraMissing", key = "es", auras = { S.EARTH_SHIELD, S.EARTH_SHIELD_SELF },
          talent = S.ELEMENTAL_ORBIT, icon = S.EARTH_SHIELD, text = L.ES_SELF_MISSING },
        { type = "playerAuraMissing", key = "sky", auras = { S.SKYFURY }, spell = S.SKYFURY },
    },

    priorities = {
        -------------------------------------------------------------------
        -- STORMBRINGER
        -------------------------------------------------------------------
        SB = {
            ST = {
                R.ps10,
                { id = "sund_asc", spell = SUND, talent = SE, conds = { { "known", ASC } },
                  note = "Sundering (allineato con Ascendance)" },
                R.vb,
                { id = "sund_se", spell = SUND, talent = SE, notTalent = ASC, note = "Sundering (Surging Elements)" },
                R.crash, R.asc, R.ws, R.ss_dw,
                { id = "tempest10", spell = LB, pin = true, conds = { { "stacksGE", MW, 10 } },
                  note = "Tempest / Lightning Bolt a 10 stack di Maelstrom Weapon" },
                R.ss,
                { id = "sund", spell = SUND, notTalent = SE, note = "Sundering" },
                R.ll,
                { id = "lb5", spell = LB, conds = { { "stacksGE", MW, 5 } },
                  note = "Lightning Bolt con 5+ stack di Maelstrom Weapon" },
            },
            AOE = {
                R.vb,
                { id = "sund_se", spell = SUND, talent = SE, note = "Sundering (Surging Elements)" },
                R.asc, R.dw, R.ps10, R.crash, R.ws, R.ss_dw,
                { id = "tempest10", spell = TEMPEST, pin = true, conds = { { "stacksGE", MW, 10 } },
                  note = "Tempest a 10 stack di Maelstrom Weapon" },
                { id = "cl9", spell = CL, pin = true, conds = { { "stacksGE", MW, 9 } },
                  note = "Chain Lightning con 9+ stack di Maelstrom Weapon" },
                R.ss,
                { id = "sund", spell = SUND, note = "Sundering" },
                R.ll,
                { id = "cl5", spell = CL, conds = { { "stacksGE", MW, 5 } },
                  note = "Chain Lightning con 5+ stack di Maelstrom Weapon" },
            },
        },

        -------------------------------------------------------------------
        -- TOTEMIC
        -------------------------------------------------------------------
        TOT = {
            ST = {
                R.vb_nofs, R.surging,
                { id = "sund", spell = SUND, note = "Sundering (una volta su due insieme a Surging Totem)" },
                R.ll_hh, R.vb, R.dw, R.ps10, R.crash, R.asc, R.ws, R.ss_dw,
                { id = "lb10", spell = LB, pin = true, conds = { { "stacksGE", MW, 10 } },
                  note = "Lightning Bolt a 10 stack di Maelstrom Weapon" },
                R.ll, R.ss,
                { id = "lb5", spell = LB, conds = { { "stacksGE", MW, 5 } },
                  note = "Lightning Bolt con 5+ stack di Maelstrom Weapon" },
            },
            AOE = {
                R.vb_nofs, R.surging,
                { id = "sund", spell = SUND, note = "Sundering" },
                R.asc, R.dw, R.ll_hh, R.vb, R.ps10, R.crash, R.ws, R.ss_dw,
                { id = "cl10", spell = CL, pin = true, conds = { { "stacksGE", MW, 10 } },
                  note = "Chain Lightning a 10 stack di Maelstrom Weapon" },
                R.ll, R.ss,
                { id = "cl5", spell = CL, conds = { { "stacksGE", MW, 5 } },
                  note = "Chain Lightning con 5+ stack di Maelstrom Weapon" },
            },
        },
    },
})
