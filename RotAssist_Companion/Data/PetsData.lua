-- RotAssist Companion - PetsData
-- Pet da cacciatore rari e notevoli di Midnight, piu' i consigli d'uso.
--
-- Il gioco non fornisce agli addon l'elenco delle bestie domabili: questa
-- tabella e' curata a mano (ottobre 2026, patch 12.1). Fonti:
--  * elenchi dei pet unici, rari ed elite e note di posizione: wow-petopia.com
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

local _, ns = ...

local EVERSONG, ZULAMAN, HARANDAR, VOIDSTORM = 2395, 2437, 2413, 2405

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
