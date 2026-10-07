-- RotAssist Companion - PetsData
-- Pet da cacciatore rari e notevoli di Midnight, le spirit beast domabili di
-- tutte le espansioni, piu' i consigli d'uso.
--
-- Il gioco non fornisce agli addon l'elenco delle bestie domabili: questa
-- tabella e' curata a mano (ottobre 2026, patch 12.1). Fonti:
--  * elenchi dei pet unici, rari ed elite e note di posizione: wow-petopia.com
--    (per le spirit beast: liste Rare, Elite, Spawned e pagine dei modelli)
--  * coordinate: pagine degli NPC su Wowhead; rari Florafaun: guida di method.gg
--  * consigli sulle famiglie: Icy Veins, "Beast Mastery Hunter Pets Guide 12.1"
-- I testi sono riassunti con parole nostre. Coordinate assenti = solo la
-- sottozona: l'addon segnala comunque il rare quando appare sulla minimappa.
--
-- Campi: npc, name (inglese, come nel client), family (chiave di 'families'),
-- map (UiMapID), x, y (0-1, opzionali), where (sottozona/indicazione),
-- exotic (solo Beast Mastery), florafaun (bestia-pianta: serve il libro
-- "Trials of the Florafaun Hunter" o essere Haranir), tome (il rare puo'
-- lasciare il libro), unique (aspetto che ha solo lui), elite.
-- Spirit beast: group = "spirit", how = chiave del testo "come domarla",
-- tag = chiave dell'etichetta (facile, evocazione, missione, istanza, sblocco).
-- In Midnight non ci sono spirit beast domabili: Petopia segna gli Spirit
-- Pangos come non domabili.

local _, ns = ...

local EVERSONG, ZULAMAN, HARANDAR, VOIDSTORM = 2395, 2437, 2413, 2405
local STORMWIND, ORGRIMMAR, DUSKWOOD, HYJAL = 84, 85, 47, 198
local TWILIGHT, ABYSSAL_DEPTHS, GRIZZLY_HILLS = 241, 204, 116
local SHOLAZAR, STORM_PEAKS, ZULDRAK = 119, 120, 121
local JADE_FOREST, FOUR_WINDS, KUNLAI, ETERNAL_BLOSSOMS = 371, 376, 379, 390
local STORMHEIM, SURAMAR, SHADOWMOON_DRAENOR = 634, 680, 539
local OHNAHRAN, EMERALD_DREAM, ISLE_OF_DORN = 2023, 2200, 2248

ns.PetsData = {
    pets = {
        -- Whiptail: nuova famiglia esotica di Midnight (migliore per il PvP)
        { npc = 248741, name = "Rhazul", family = "whiptail", map = HARANDAR, x = 0.514, y = 0.452,
          where = "north of The Den", exotic = true, unique = true },
        { npc = 256770, name = "Bilemaw the Gluttonous", family = "whiptail", map = VOIDSTORM, x = 0.355, y = 0.500,
          where = "The Molt", exotic = true },
        -- Rari di Harandar che possono lasciare il libro dei Florafaun
        { npc = 249962, name = "Queen Lashtongue", family = "hopper", map = HARANDAR, x = 0.5986, y = 0.4702,
          where = "Vale of Mists", tome = true },
        { npc = 250317, name = "Oro'ohna", family = "carrionbird", map = HARANDAR, x = 0.2810, y = 0.8183,
          where = "The Blinding Bloom", tome = true, elite = true },
        { npc = 250231, name = "Dracaena", family = "serpent", map = HARANDAR, x = 0.4065, y = 0.4313,
          where = "south of the Vale of Secrets", tome = true },
        { npc = 249849, name = "Ha'kalawe", family = "sporebat", map = HARANDAR, x = 0.6903, y = 0.5995,
          where = "high ground west of The Grudge Pit", tome = true },
        { npc = 250321, name = "Pterrock", family = "ray", map = HARANDAR, x = 0.2738, y = 0.7139,
          where = "cave on the north edge of The Blinding Bloom", tome = true },
        -- Esotici Devilsaur: i Devilsaptor sono la versione vegetale (Florafaun)
        { npc = 250086, name = "Stumpy", family = "devilsaur", map = HARANDAR, x = 0.655, y = 0.325,
          where = "south of Har'kuai", exotic = true, florafaun = true, elite = true },
        { npc = 252851, name = "Ancient Devilsaptor", family = "devilsaur", map = HARANDAR,
          where = "Nordrassil Roots", exotic = true, florafaun = true, elite = true, unique = true },
        { npc = 237635, name = "Lightfrenzy Tyrannosaptor", family = "devilsaur", map = EVERSONG,
          where = "Lightbloom Lash'Ra", exotic = true, elite = true, unique = true },
        -- Aspetti unici e rari
        { npc = 255348, name = "Dame Bloodshed", family = "cat", map = EVERSONG, x = 0.449, y = 0.382,
          where = "south of North Sanctum", unique = true },
        { npc = 256923, name = "Bane of the Vilebloods", family = "bloodbeast", map = VOIDSTORM, x = 0.470, y = 0.805,
          where = "Den of Predaxus", unique = true },
        { npc = 250876, name = "Terrinor", family = "bat", map = EVERSONG, x = 0.403, y = 0.854,
          where = "Ruins of Deatholme" },
        { npc = 250826, name = "Banuran", family = "hopper", map = EVERSONG, x = 0.565, y = 0.774,
          where = "Zeb'Nowa" },
        { npc = 250582, name = "Bloated Snapdragon", family = "lizard", map = EVERSONG,
          where = "Daggerspine Landing" },
        { npc = 255302, name = "Duskburn", family = "serpent", map = EVERSONG,
          where = "Sanctum of the Moon" },
        { npc = 242034, name = "Voidtouched Crustacean", family = "crab", map = ZULAMAN, x = 0.214, y = 0.705,
          where = "Broken Throne, north-west" },
        { npc = 242032, name = "Oophaga", family = "hopper", map = ZULAMAN, x = 0.464, y = 0.513,
          where = "The Stump" },
        { npc = 242024, name = "The Snapping Scourge", family = "lizard", map = ZULAMAN,
          where = "Temple of Jan'alai" },
        { npc = 242035, name = "The Devouring Invader", family = "ray", map = ZULAMAN,
          where = "Witherbark Bluffs" },
        { npc = 242028, name = "Lightwood Borer", family = "wasp", map = ZULAMAN,
          where = "Zeb'Alar Lumberyard" },
        { npc = 245044, name = "Nightbrood", family = "wasp", map = VOIDSTORM,
          where = "Night Trench" },

        -- Spirit beast (esotiche) -------------------------------------------
        -- sempre presenti: le piu' facili da domare
        { npc = 103326, name = "Mana Saber", family = "spiritbeast", map = SURAMAR, group = "spirit",
          where = "Moon Guard Stronghold", exotic = true, tag = "EASY", how = "PET_HOW_EASY" },
        { npc = 112068, name = "Leyline Prowler", family = "spiritbeast", map = SURAMAR, group = "spirit",
          where = "Leystation Moonfall", exotic = true, tag = "EASY", how = "PET_HOW_EASY" },
        { npc = 113201, name = "Thicket Manahunter", family = "spiritbeast", map = SURAMAR, group = "spirit",
          where = "Crimson Thicket", exotic = true, tag = "EASY", how = "PET_HOW_EASY" },
        -- rari dall'aspetto unico
        { npc = 32517, name = "Loque'nahak", family = "spiritbeast", map = SHOLAZAR, group = "spirit",
          exotic = true, unique = true },
        { npc = 33776, name = "Gondria", family = "spiritbeast", map = ZULDRAK, group = "spirit",
          exotic = true, unique = true },
        { npc = 35189, name = "Skoll", family = "spiritbeast", map = STORM_PEAKS, group = "spirit",
          exotic = true, unique = true },
        { npc = 38453, name = "Arcturis", family = "spiritbeast", map = GRIZZLY_HILLS, group = "spirit",
          exotic = true, unique = true },
        { npc = 54318, name = "Ankha", family = "spiritbeast", map = HYJAL, group = "spirit",
          exotic = true, unique = true, how = "PET_HOW_NOARMOR" },
        { npc = 54319, name = "Magria", family = "spiritbeast", map = HYJAL, group = "spirit",
          exotic = true, unique = true, how = "PET_HOW_MAGRIA" },
        { npc = 54320, name = "Ban'thalos", family = "spiritbeast", map = HYJAL, group = "spirit",
          exotic = true, unique = true, how = "PET_HOW_BANTHALOS" },
        { npc = 50138, name = "Karoma", family = "spiritbeast", map = TWILIGHT, group = "spirit",
          exotic = true, unique = true },
        { npc = 50051, name = "Ghostcrawler", family = "spiritbeast", map = ABYSSAL_DEPTHS, group = "spirit",
          where = "Abandoned Reef", exotic = true, unique = true },
        { npc = 118244, name = "Lightning Paw", family = "spiritbeast", map = DUSKWOOD, group = "spirit",
          exotic = true, unique = true, how = "PET_HOW_LIGHTNINGPAW" },
        { npc = 111463, name = "Bulvinkel", family = "spiritbeast", map = STORMHEIM, group = "spirit",
          where = "cliffs south-east of the Halls of Valor", exotic = true, unique = true, how = "PET_HOW_BULVINKEL" },
        -- altri rari
        { npc = 110340, name = "Myonix", family = "spiritbeast", map = SURAMAR, group = "spirit",
          where = "north of Anora Hollow, east of Moonwhisper Gulch", exotic = true },
        { npc = 113694, name = "Pashya", family = "spiritbeast", map = SURAMAR, group = "spirit",
          where = "Crimson Thicket, south of Nighteyes", exotic = true, how = "PET_HOW_PASHYA" },
        -- elite
        { npc = 69943, name = "Gumi", family = "spiritbeast", map = KUNLAI, group = "spirit",
          exotic = true, elite = true, unique = true, how = "PET_HOW_PORCUPINE" },
        { npc = 69946, name = "Hutia", family = "spiritbeast", map = JADE_FOREST, group = "spirit",
          exotic = true, elite = true, unique = true, how = "PET_HOW_PORCUPINE" },
        { npc = 69947, name = "Degu", family = "spiritbeast", map = FOUR_WINDS, group = "spirit",
          where = "southern cliff edge, from south-east of Stormstout Brewery to above Thunder Cleft",
          exotic = true, elite = true, unique = true, how = "PET_HOW_PORCUPINE" },
        { npc = 193254, name = "Bloodgullet", family = "spiritbeast", map = OHNAHRAN, group = "spirit",
          x = 0.66, y = 0.43, where = "meadows south-east of Maruukai", exotic = true, elite = true,
          unique = true, how = "PET_HOW_BLOODGULLET" },
        { npc = 210868, name = "Sul'raka", family = "spiritbeast", map = EMERALD_DREAM, group = "spirit",
          exotic = true, elite = true, unique = true, how = "PET_HOW_SULRAKA" },
        { npc = 210908, name = "Nah'qi", family = "spiritbeast", map = EMERALD_DREAM, group = "spirit",
          where = "flies around Amirdrassil, just below the canopy", exotic = true, elite = true,
          unique = true, tag = "UNLOCK", how = "PET_HOW_NAHQI" },
        { npc = 60410, name = "Elegon", family = "spiritbeast", map = ETERNAL_BLOSSOMS, group = "spirit",
          where = "Mogu'shan Vaults (raid)", exotic = true, unique = true, tag = "INSTANCE", how = "PET_HOW_ELEGON" },
        -- da evocare o legate a missioni
        { npc = 213428, name = "Aradan", family = "spiritbeast", map = ISLE_OF_DORN, group = "spirit",
          x = 0.291, y = 0.362, where = "Void-Scarred Stormhammer under the sea, then The Rookery (dungeon)",
          exotic = true, unique = true, tag = "INSTANCE", how = "PET_HOW_ARADAN" },
        { npc = 121571, name = "Gon", family = "spiritbeast", map = ORGRIMMAR, group = "spirit",
          where = "Valley of Spirits, by Shadow-Walker Zuru", exotic = true, unique = true,
          tag = "SUMMON", how = "PET_HOW_GON" },
        { npc = 121567, name = "Lost Spectral Gryphon", family = "spiritbeast", map = STORMWIND, group = "spirit",
          where = "by the gryphon mount vendor", exotic = true, unique = true, tag = "SUMMON", how = "PET_HOW_GRYPHON" },
        { npc = 151144, name = "Hati", family = "spiritbeast", map = STORM_PEAKS, group = "spirit",
          where = "Temple of Storms", exotic = true, tag = "QUEST", how = "PET_HOW_HATI" },
        { npc = 88708, name = "Gara", family = "spiritbeast", map = SHADOWMOON_DRAENOR, group = "spirit",
          exotic = true, unique = true, tag = "QUEST", how = "PET_HOW_GARA" },
    },

    -- Famiglie: nome inglese (come nel client) e abilita' speciale di famiglia
    -- (chiave PET_ABILITY_*), dalla tabella delle famiglie di Icy Veins.
    families = {
        whiptail    = { name = "Whiptail",     ability = "heal" },
        devilsaur   = { name = "Devilsaur",    ability = "heal" },
        carrionbird = { name = "Carrion Bird", ability = "heal" },
        lizard      = { name = "Lizard",       ability = "heal" },
        wasp        = { name = "Wasp",         ability = "heal" },
        cat         = { name = "Cat",          ability = "dodge" },
        hopper      = { name = "Hopper",       ability = "dodge" },
        serpent     = { name = "Serpent",      ability = "dodge" },
        bat         = { name = "Bat",          ability = "dispel" },
        ray         = { name = "Ray",          ability = "dispel" },
        sporebat    = { name = "Sporebat",     ability = "dispel" },
        bloodbeast  = { name = "Blood Beast",  ability = "slow" },
        crab        = { name = "Crab",         ability = "slow" },
        spiritbeast = { name = "Spirit Beast", ability = "spirit" },
    },

    -- Consigli per contenuto (chiavi di localizzazione); 'search' = famiglia
    -- da cercare su Wowhead con il clic destro.
    advice = {
        { key = "PET_ADV_RAID",  search = "Aqiri" },
        { key = "PET_ADV_MPLUS", search = "Aqiri" },
        { key = "PET_ADV_HEAL",  search = "Whiptail" },
        { key = "PET_ADV_SOLO",  search = "Clefthoof" },
        { key = "PET_ADV_PVP",   search = "Whiptail" },
        { key = "PET_ADV_UTIL",  search = "Feathermane" },
        { key = "PET_ADV_SPEC" },
    },

    -- Libro per domare le bestie-pianta di Harandar
    tome = "Trials of the Florafaun Hunter",
}
