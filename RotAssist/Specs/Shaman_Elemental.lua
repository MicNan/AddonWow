-- RotAssist - Shaman: Elemental (specID 262)
--
-- Fonte della priorita': Icy Veins, "Elemental Shaman DPS Rotation, Cooldowns,
-- and Abilities - 12.1" (Stormy, aggiornata il 10 ago 2026).
-- https://www.icy-veins.com/wow/elemental-shaman-pve-dps-rotation-cooldowns-abilities
-- Riepilogo e analisi dei segnali: docs/Shaman_12.1_riferimento.md
--
-- Bersagli: la guida distingue 1, 2, 3 e 4+ bersagli. Qui: ST = 1,
-- CLEAVE = 2-3 (liste da 2 e 3 bersagli unite), AOE = 4+.
--
-- Cosa e' leggibile in combattimento e cosa no:
--   * Maelstrom (risorsa primaria): SEGRETO. Gli spender usano 'needsResource'
--     (IsSpellUsable, leggibile) e le regole di overcap restano ad Assisted Combat.
--   * Flame Shock: timer ricostruito dai propri cast (18 s, pandemic 30%),
--     azzerato al cambio bersaglio, riallineato fuori combattimento.
--   * Master of the Elements: attivato da Lava Burst, consumato dal cast successivo.
--   * Stormkeeper: 2 cariche (Wowhead), contate sui cast di Lightning Bolt / Chain Lightning.
--   * Tempest: override di Lightning Bolt (leggibile).
--   * Lava Surge: glow di Lava Burst.
--   * Antenati (Farseer): 8 s dal cast di Ancestral Swiftness (Wowhead).
--   * Buff del set 4p e stack di Tempest: NON leggibili -> righe 'disabled'.
-- VERIFICARE in gioco: Fire Elemental raddoppia la durata di Flame Shock
-- (non modellato) e il rilevamento dell'hero talent.

local _, ns = ...

local S = {
    LIGHTNING_BOLT  = 188196,
    CHAIN_LIGHTNING = 188443,
    LAVA_BURST      = 51505,
    FLAME_SHOCK     = 188389,
    VOLTAIC_BLAZE   = 470057,
    EARTH_SHOCK     = 8042,
    EARTHQUAKE      = 61882,
    ELEMENTAL_BLAST = 117014,
    TEMPEST         = 454009,   -- override di Lightning Bolt (Stormbringer)
    STORMKEEPER     = 191634,
    ASCENDANCE      = 114050,
    ANCESTRAL_SWIFTNESS = 443454,
    FIRE_ELEMENTAL  = 198067,
    MASTER_OF_THE_ELEMENTS = 16166,
    PURGING_FLAMES  = 1259471,
    CALL_OF_THE_ANCESTORS = 467646, -- Farseer
    SUPERCHARGE     = 455110,   -- Stormbringer
    LIGHTNING_SHIELD = 192106,
    EARTH_SHIELD    = 974,
    EARTH_SHIELD_SELF = 383648,
    ELEMENTAL_ORBIT = 383010,
    SKYFURY         = 462854,
    BLOODLUST       = 2825,
    HEROISM         = 32182,
}

local LB, CL, LVB, FS, VB = S.LIGHTNING_BOLT, S.CHAIN_LIGHTNING, S.LAVA_BURST, S.FLAME_SHOCK, S.VOLTAIC_BLAZE
local ES, EQ, EB, TEMPEST = S.EARTH_SHOCK, S.EARTHQUAKE, S.ELEMENTAL_BLAST, S.TEMPEST
local SK, ASC, AS, MOTE = S.STORMKEEPER, S.ASCENDANCE, S.ANCESTRAL_SWIFTNESS, S.MASTER_OF_THE_ELEMENTS

local TIER_DISABLED = "buff del set 4p (Flowing Elements, Overcharge) non leggibili in combattimento"

-- Regole comuni a tutte le liste
local R = {
    sk  = { id = "sk", spell = SK, onUnknown = "match",
            any = { { "not", { "cdLT", ASC, 6 } }, { "ready", ASC }, { "not", { "known", ASC } } },
            note = "Stormkeeper al cooldown (trattenuto se Ascendance arriva a breve)" },
    as  = { id = "as", spell = AS, hero = "FAR", note = "Ancestral Swiftness al cooldown" },
    asc = { id = "asc", spell = ASC, note = "Ascendance (sincronizzala con trinket e Bloodlust)" },
    fs_refresh = { id = "fs_refresh", spell = FS, notTalent = VB, pin = true,
            conds = { { "timerLT", "flameShock", 6 } },
            note = "Flame Shock: rinnovo a 6 s o meno (stima dai cast)" },
    vb_refresh = { id = "vb_refresh", spell = VB, talent = VB, pin = true,
            conds = { { "timerLT", "flameShock", 6 } },
            note = "Voltaic Blaze: Flame Shock a 6 s o meno (stima dai cast)" },
    vb  = { id = "vb", spell = VB, talent = VB, note = "Voltaic Blaze al cooldown" },
    lvb_mote = { id = "lvb_mote", spell = LVB, talent = MOTE,
            conds = { { "timer", "flameShock" }, { "not", { "flag", "motE" } } },
            note = "Lava Burst con Flame Shock attivo e Master of the Elements non attivo (overcap: Assisted Combat)" },
    tempest_mote = { id = "tempest_mote", spell = LB, hero = "SB", talent = MOTE, pin = true,
            conds = { { "flag", "motE" } },
            any = { { "overrideIs", LB, TEMPEST }, { "counterGE", "stormkeeper", 1 } },
            note = "Tempest o Lightning Bolt con Stormkeeper durante Master of the Elements" },
    lvb_fs = { id = "lvb_fs", spell = LVB, hero = "FAR", notTalent = MOTE,
            conds = { { "timer", "flameShock" } },
            note = "Lava Burst con Flame Shock attivo" },
    lvb_surge = { id = "lvb_surge", spell = LVB, hero = "SB", notTalent = MOTE,
            conds = { { "glow", LVB } },
            note = "Lava Burst SOLO con Lava Surge (glow)" },
    tempest = { id = "tempest", spell = TEMPEST, hero = "SB", notTalent = MOTE,
            note = "Tempest" },
}

ns:RegisterSpec(262, {
    name = "Elemental",
    class = "SHAMAN",
    spells = S,
    filler = LB,
    resource = (Enum and Enum.PowerType and Enum.PowerType.Maelstrom) or 11,
    resourceWarn = 0.85,       -- barra arancione da 85% di Maelstrom

    heroTalents = {
        { key = "FAR", spells = { S.CALL_OF_THE_ANCESTORS, AS }, name = "Farseer" },
        { key = "SB",  spells = { TEMPEST, S.SUPERCHARGE },        name = "Stormbringer" },
    },
    defaultHero = "FAR",

    cleaveAt = 2,
    aoeAt = 4,
    -- Assisted Combat che suggerisce queste abilita' indica piu' bersagli
    aoeHints = { [CL] = 2, [EQ] = 3 },

    overrideOf = { [TEMPEST] = LB },
    targetTimers = { "flameShock" },

    track = {
        cooldowns = { [SK] = true, [ASC] = true, [S.FIRE_ELEMENTAL] = true, [VB] = true, [AS] = true, [EB] = true },
        charges   = { LVB },
    },
    base = {
        [LVB] = { recharge = 8 },   -- Wowhead (base)
        [VB]  = { cd = 10 },
        [SK]  = { cd = 60 },
        [ASC] = { cd = 180 },
        [AS]  = { cd = 30 },
        [EB]  = { cd = 12 },
    },

    onAnyCast = {
        -- Master of the Elements si consuma con il cast successivo (Nature/Fisico/Gelo)
        { type = "flag", key = "motE", value = false,
          except = { [LVB] = true, [FS] = true, [SK] = true, [AS] = true, [ASC] = true, [S.FIRE_ELEMENTAL] = true } },
    },
    onCast = {
        [LVB] = { { type = "flag", key = "motE", value = true, talent = MOTE } },
        [FS]  = { { type = "timer", key = "flameShock", duration = 18, pandemic = 0.3 } },
        [VB]  = { { type = "timer", key = "flameShock", duration = 18, pandemic = 0.3 } },
        [ASC] = { { type = "timer", key = "flameShock", duration = 18, pandemic = 0.3 },
                  { type = "timer", key = "ascendance", duration = 15 } },
        [SK]  = { { type = "counter", key = "stormkeeper", set = 2 } },
        [LB]  = { { type = "counter", key = "stormkeeper", add = -1 } },
        [CL]  = { { type = "counter", key = "stormkeeper", add = -1 } },
        [AS]  = { { type = "timer", key = "ancestors", duration = 8, hero = "FAR" } },
    },
    calibrateAuras = {
        flameShock = { unit = "target", auras = { FS }, filter = "HARMFUL|PLAYER" },
    },

    majorCooldowns = {
        { spell = SK },
        { spell = ASC },
        { spell = S.FIRE_ELEMENTAL },
        { spell = AS },
        { spell = S.BLOODLUST },
        { spell = S.HEROISM },
    },

    alerts = {
        { type = "timerExpiring", key = "flameShock", spell = FS, within = 5.4,
          needsTarget = true, inCombatOnly = true,
          textMissingKey = "FS_MISSING", textExpiringKey = "FS_EXPIRING" },
        { type = "playerAuraMissing", key = "ls", auras = { S.LIGHTNING_SHIELD }, spell = S.LIGHTNING_SHIELD },
        { type = "playerAuraMissing", key = "es", auras = { S.EARTH_SHIELD, S.EARTH_SHIELD_SELF },
          talent = S.ELEMENTAL_ORBIT, icon = S.EARTH_SHIELD, textKey = "ES_SELF_MISSING" },
        { type = "playerAuraMissing", key = "sky", auras = { S.SKYFURY }, spell = S.SKYFURY },
    },

    priorities = {
        -- Farseer e Stormbringer condividono le liste: le regole specifiche
        -- di un hero talent hanno il campo 'hero'.
        default = {
            ST = {
                R.sk, R.as, R.asc, R.fs_refresh, R.vb_refresh,
                { id = "tier4", spell = EB, disabled = TIER_DISABLED, note = "Elemental Blast / Earth Shock con i buff del 4p" },
                R.lvb_mote, R.tempest_mote,
                { id = "es", spell = ES, talent = ES, needsResource = true, note = "Earth Shock" },
                { id = "eb", spell = EB, talent = EB, notTalent = MOTE, needsResource = true, note = "Elemental Blast" },
                { id = "eb_mote", spell = EB, talent = EB, needsResource = true,
                  conds = { { "known", MOTE }, { "flag", "motE" } },
                  note = "Elemental Blast con Master of the Elements (overcap: Assisted Combat)" },
                R.tempest, R.lvb_fs, R.lvb_surge,
                { id = "lb", spell = LB, note = "Lightning Bolt / Tempest come filler" },
            },
            CLEAVE = {
                R.sk, R.as, R.vb, R.asc, R.fs_refresh,
                R.lvb_mote, R.tempest_mote,
                { id = "eq_anc", spell = EQ, hero = "FAR", talent = ES, needsResource = true,
                  conds = { { "timer", "ancestors" } }, note = "Earthquake con gli Antenati attivi" },
                { id = "es_noanc", spell = ES, hero = "FAR", talent = ES, needsResource = true,
                  conds = { { "noTimer", "ancestors" } }, note = "Earth Shock senza Antenati" },
                { id = "es_sb", spell = ES, hero = "SB", talent = ES, needsResource = true, note = "Earth Shock" },
                { id = "eb", spell = EB, talent = EB, needsResource = true,
                  note = "Elemental Blast (con Lightning Rod alterna i bersagli)" },
                R.tempest,
                { id = "lb_sk", spell = LB, hero = "SB", notTalent = MOTE,
                  conds = { { "counterGE", "stormkeeper", 1 } }, note = "Lightning Bolt potenziato da Stormkeeper" },
                R.lvb_fs, R.lvb_surge,
                { id = "cl", spell = CL, note = "Chain Lightning" },
            },
            AOE = {
                R.sk, R.as, R.vb, R.asc,
                { id = "eb_sb", spell = EB, hero = "SB", talent = EB,
                  disabled = "richiede buff di Elemental Blast e stack di Tempest, non leggibili" },
                { id = "eq_sb", spell = EQ, hero = "SB", needsResource = true,
                  note = "Earthquake (la condizione sugli stack di Tempest non e' leggibile)" },
                { id = "tempest_aoe", spell = TEMPEST, hero = "SB", note = "Tempest" },
                { id = "cl_sk", spell = CL, hero = "SB", conds = { { "counterGE", "stormkeeper", 1 } },
                  note = "Chain Lightning con Stormkeeper (overcap: Assisted Combat)" },
                { id = "eb_far", spell = EB, hero = "FAR", talent = EB, needsResource = true,
                  conds = { { "noTimer", "ancestors" }, { "targetsLT", 6 } },
                  note = "Elemental Blast senza Antenati e fino a 5 bersagli" },
                { id = "eq_far", spell = EQ, hero = "FAR", needsResource = true,
                  any = { { "timer", "ancestors" }, { "targetsGE", 6 } },
                  note = "Earthquake con gli Antenati o oltre 5 bersagli" },
                { id = "eq_es", spell = EQ, talent = ES, needsResource = true, note = "Earthquake" },
                { id = "lvb_pf", spell = LVB, talent = S.PURGING_FLAMES,
                  note = "Lava Burst (meglio con Lava Surge) per consumare Purging Flames" },
                { id = "cl", spell = CL, note = "Chain Lightning" },
            },
        },
    },
})
