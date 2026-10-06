-- RotAssist - Shaman: Restoration (specID 264) - SUPPORTO, non rotazione
--
-- Fonte: Icy Veins, "Restoration Shaman Healing Rotation, Cooldowns, and
-- Abilities - 12.1" (Seksi, aggiornata il 10 ago 2026).
-- https://www.icy-veins.com/wow/restoration-shaman-pve-healing-rotation-cooldowns-abilities
--
-- Un guaritore non segue una rotazione di danno: il riquadro principale mostra
-- PROMEMORIA di abilita' pronte da non sprecare (Assisted Combat e' disattivato
-- per questa spec perche' suggerirebbe danni). Cosa curare e quando resta una
-- scelta del giocatore.
--
-- Dalla 12.1 le aure dei guaritori sono SEGRETE in combattimento: Earth Shield,
-- Water Shield ed Earthliving si controllano fuori dal combattimento.

local _, ns = ...

local S = {
    RIPTIDE         = 61295,
    HEALING_STREAM_TOTEM = 5394,
    STORMSTREAM_TOTEM = 1267016,   -- proc dell'apex: override di Healing Stream Totem
    UNLEASH_LIFE    = 73685,
    NATURES_SWIFTNESS = 378081,
    ANCESTRAL_SWIFTNESS = 443454,
    HEALING_RAIN    = 73920,
    CHAIN_HEAL      = 1064,
    HEALING_WAVE    = 77472,
    SURGING_TOTEM   = 444995,      -- Totemic
    CALL_OF_THE_ANCESTORS = 467646, -- Farseer
    ANCESTRAL_AWAKENING = 382309,
    SPIRIT_LINK_TOTEM = 98008,
    HEALING_TIDE_TOTEM = 108280,
    ASCENDANCE      = 114052,
    WATER_SHIELD    = 52127,
    EARTH_SHIELD    = 974,
    EARTH_SHIELD_SELF = 383648,
    EARTHLIVING_WEAPON = 382021,
    SKYFURY         = 462854,
    BLOODLUST       = 2825,
    HEROISM         = 32182,
}

local RT, HST, SST, UL = S.RIPTIDE, S.HEALING_STREAM_TOTEM, S.STORMSTREAM_TOTEM, S.UNLEASH_LIFE
local NS, AS, HR, SURGING = S.NATURES_SWIFTNESS, S.ANCESTRAL_SWIFTNESS, S.HEALING_RAIN, S.SURGING_TOTEM
local ASC = S.ASCENDANCE

ns:RegisterSpec(264, {
    name = "Restoration",
    class = "SHAMAN",
    spells = S,
    nativeMode = "off",            -- niente suggerimenti di danno di Assisted Combat
    filler = nil,
    resource = (Enum and Enum.PowerType and Enum.PowerType.Mana) or 0,

    heroTalents = {
        { key = "FAR", spells = { S.CALL_OF_THE_ANCESTORS, AS }, name = "Farseer" },
        { key = "TOT", spells = { SURGING },                     name = "Totemic" },
    },
    defaultHero = "TOT",

    overrideOf = { [SST] = HST },

    track = {
        cooldowns = { [UL] = true, [NS] = true, [AS] = true, [HR] = true, [SURGING] = true,
                      [S.SPIRIT_LINK_TOTEM] = true, [S.HEALING_TIDE_TOTEM] = true, [ASC] = true },
        charges   = { HST, RT },
    },
    base = {
        [HST] = { recharge = 30 }, [RT] = { recharge = 6 }, [UL] = { cd = 20 }, [NS] = { cd = 60 },
        [HR] = { cd = 12 }, [AS] = { cd = 30 },
    },
    onCast = {
        [ASC] = { { type = "timer", key = "ascendance", duration = 15 } },
    },

    majorCooldowns = {
        { spell = S.SPIRIT_LINK_TOTEM },
        { spell = S.HEALING_TIDE_TOTEM },
        { spell = ASC },
        { spell = NS },
        { spell = S.BLOODLUST },
        { spell = S.HEROISM },
    },

    alerts = {
        { type = "playerAuraMissing", key = "ws", auras = { S.WATER_SHIELD }, spell = S.WATER_SHIELD },
        { type = "playerAuraMissing", key = "es", auras = { S.EARTH_SHIELD, S.EARTH_SHIELD_SELF },
          spell = S.EARTH_SHIELD, icon = S.EARTH_SHIELD, textKey = "ES_SELF_MISSING" },
        { type = "groupAuraMissing", key = "esally", auras = { S.EARTH_SHIELD }, spell = S.EARTH_SHIELD,
          icon = S.EARTH_SHIELD, textKey = "ES_ALLY_MISSING" },
        { type = "weaponImbueMissing", key = "imbue", spell = S.EARTHLIVING_WEAPON, mainHand = true },
        { type = "playerAuraMissing", key = "sky", auras = { S.SKYFURY }, spell = S.SKYFURY },
    },

    priorities = {
        -- Promemoria in ordine di importanza (le regole 'hero' valgono solo
        -- per il relativo hero talent).
        default = {
            ST = {
                { id = "sst", spell = SST, pin = true,
                  note = "Stormstream Totem disponibile (proc): usalo prima che HST arrivi a 2 cariche" },
                { id = "hst_max", spell = HST, pin = true, conds = { { "atMaxCharges", HST } },
                  note = "Healing Stream Totem a cariche piene: non sprecarle" },
                { id = "hst_asc", spell = HST, notTalent = S.ANCESTRAL_AWAKENING,
                  conds = { { "timer", "ascendance" } }, note = "Healing Stream Totem durante Ascendance" },
                { id = "as", spell = AS, hero = "FAR",
                  note = "Ancestral Swiftness: evoca un Antenato e proc di Stormstream" },
                { id = "ul", spell = UL, note = "Unleash Life sul prossimo Chain Heal o Healing Wave" },
                { id = "ns", spell = NS, hero = "TOT", note = "Nature's Swiftness, meglio su Chain Heal" },
                { id = "surging", spell = SURGING, hero = "TOT",
                  note = "Surging Totem dove colpisce piu' alleati e nemici" },
                { id = "hr", spell = HR, notTalent = SURGING,
                  note = "Healing Rain se piu' alleati restano nell'area" },
                { id = "rt", spell = RT, note = "Riptide al cooldown" },
            },
        },
    },
})
