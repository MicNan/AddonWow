-- RotAssist Companion - CraftBuilds
-- Build delle specializzazioni di Midnight per ogni professione, divise in
-- fasi: ogni passo indica quanti punti conoscenza mettere e in quale nodo.
-- I nomi dei nodi sono quelli inglesi del client (nel client italiano possono
-- essere tradotti).
--
-- Formato di una build:
--   { name, short (etichetta del selettore), use (a cosa serve),
--     phases = { { titolo, { { punti | nil, testo }, ... } }, ... },
--     notes = { ... } }

local _, ns = ...

local B = { it = {}, en = {} }
ns.CraftBuilds = B

B.it.alchemy = {
    { name = "Durata dei flask", short = "Durata flask", use = "raid e Mitiche+",
      phases = {
        { "Durata", { { 15, "Fluent in Flasks (radice): la durata di flask e fiale sale a 5 e a 15 punti" } } },
      },
      notes = { "Poi prosegui con la build 'Flask da vendere'." } },
    { name = "Pozioni da vendere", short = "Pozioni", use = "oro: oggi la linea piu' redditizia",
      phases = {
        { "Multicraft", { { 10, "Potion Prowess (radice)" }, { 10, "Path of Void oppure Path of Light" },
                          { 20, "Prolific Potioneer (Void o Light)" } } },
        { "Resourcefulness", { { 10, "Alchemical Mastery (radice)" }, { 20, "Reuse" } } },
        { "Qualita' oro e calderone", { { 20, "Potion Prowess fino a 30: sblocca il Voidlight Potion Cauldron" },
                                         { 20, "Path of Void (o Light) fino a 30" }, { 20, "Alchemical Mastery fino a 30" } } },
      },
      notes = { "Strumento con Multicraft e incantamento Multicraft.", "Dopo 130 punti aggiungi una seconda linea (flask)." } },
    { name = "Flask da vendere", short = "Flask", use = "oro: domanda alta, margini oggi piu' bassi",
      phases = {
        { "Multicraft", { { 10, "Fluent in Flasks (radice)" }, { 10, "Sin'dorei Specialist" }, { 20, "Flask Abundance" } } },
        { "Resourcefulness", { { 10, "Alchemical Mastery (radice)" }, { 20, "Recycle" } } },
        { "Qualita' oro e calderone", { { 20, "Fluent in Flasks fino a 30: sblocca il Cauldron of Sin'dorei Flasks" },
                                         { 20, "Sin'dorei Specialist" }, { 20, "Alchemical Mastery" } } },
      },
      notes = { "Fiale: stessa struttura con Haranir Secrets e Phial Abundance; mercato piu' piccolo." } },
    { name = "Trasmutazioni", short = "Trasmutazioni", use = "giornaliero e Mote",
      phases = {
        { "Multicraft e giornaliero", { { 10, "Transmutation Authority (radice): Synthesis Synergy insegna Wondrous Synergist" },
                                        { 20, "Metamorphic Mastery" } } },
        { "Ricarica piu' breve", { { 20, "Synthesis Synergy: il giornaliero passa da 18 a circa 9 ore" } } },
        { "Resourcefulness", { { 10, "Alchemical Mastery (radice)" }, { 20, "Reduce" } } },
      },
      notes = { "Le trasmutazioni di materiali (Bouquet of Herbs, Box of Rocks, School of Gems) non fanno Multicraft: per quelle serve Resourcefulness." } },
}
B.en.alchemy = {
    { name = "Extra flask duration", short = "Flask duration", use = "raids and Mythic+",
      phases = {
        { "Duration", { { 15, "Fluent in Flasks (root): flask and phial duration goes up at 5 and at 15 points" } } },
      },
      notes = { "Then continue with the 'Flasks to sell' build." } },
    { name = "Potions to sell", short = "Potions", use = "gold: the most profitable line right now",
      phases = {
        { "Multicraft", { { 10, "Potion Prowess (root)" }, { 10, "Path of Void or Path of Light" },
                          { 20, "Prolific Potioneer (Void or Light)" } } },
        { "Resourcefulness", { { 10, "Alchemical Mastery (root)" }, { 20, "Reuse" } } },
        { "Gold quality and cauldron", { { 20, "Potion Prowess to 30: unlocks the Voidlight Potion Cauldron" },
                                          { 20, "Path of Void (or Light) to 30" }, { 20, "Alchemical Mastery to 30" } } },
      },
      notes = { "Multicraft tool with a Multicraft enchant.", "After 130 points add a second line (flasks)." } },
    { name = "Flasks to sell", short = "Flasks", use = "gold: high demand, thinner margins right now",
      phases = {
        { "Multicraft", { { 10, "Fluent in Flasks (root)" }, { 10, "Sin'dorei Specialist" }, { 20, "Flask Abundance" } } },
        { "Resourcefulness", { { 10, "Alchemical Mastery (root)" }, { 20, "Recycle" } } },
        { "Gold quality and cauldron", { { 20, "Fluent in Flasks to 30: unlocks the Cauldron of Sin'dorei Flasks" },
                                          { 20, "Sin'dorei Specialist" }, { 20, "Alchemical Mastery" } } },
      },
      notes = { "Phials: same structure with Haranir Secrets and Phial Abundance; smaller market." } },
    { name = "Transmutes", short = "Transmutes", use = "daily cooldown and Motes",
      phases = {
        { "Multicraft and daily", { { 10, "Transmutation Authority (root): Synthesis Synergy teaches Wondrous Synergist" },
                                    { 20, "Metamorphic Mastery" } } },
        { "Shorter cooldown", { { 20, "Synthesis Synergy: the daily goes from 18 to about 9 hours" } } },
        { "Resourcefulness", { { 10, "Alchemical Mastery (root)" }, { 20, "Reduce" } } },
      },
      notes = { "Material transmutes (Bouquet of Herbs, Box of Rocks, School of Gems) cannot Multicraft: they need Resourcefulness." } },
}

B.it.leatherworking = {
    { name = "Equip per te", short = "Equip", use = "armature di rango massimo, senza ordini",
      phases = {
        { "Base", { { 30, "Radice della tua armatura: Lasting Leather (cuoio) o Safeguarding Scales (maglia)" } } },
        { "Primi 4 slot", { { 30, "Lato sinistro (testa, petto, spalle, polsi) oppure destro (gambe, mani, vita, piedi)" } } },
        { "Tutti gli slot", { { 30, "L'altro lato" } } },
      },
      notes = { "Poi: l'altro tipo di armatura (alt e amici) o Learned Leatherworker per Multicraft, Ingenuity e Resourcefulness." } },
    { name = "Ordini di lavoro", short = "Ordini", use = "creare armature per gli altri",
      phases = {
        { "Base", { { 30, "Radice della specializzazione dell'armatura" } } },
        { "Lo slot richiesto", { { 30, "Il lato con lo slot che vuoi" }, { 20, "Lo slot, fino al massimo" } } },
      },
      notes = { "Meglio le armature degli attrezzi da professione: la domanda dura tutta la stagione.",
                "Circa uno slot nuovo al rango massimo ogni settimana." } },
    { name = "Casa d'aste", short = "Asta", use = "kit per armature, tamburi e reagenti in serie",
      phases = {
        { "Sblocco", { { 10, "Flawless Fortes: scegli Commanding Commodities, poi Crucial Consumables" },
                       { 5, "Learned Leatherworker (radice)" } } },
        { "Multicraft e Resourcefulness", { { 30, "Mastering Multicraft" }, { 10, "Learned Leatherworker: secondo sotto-ramo" },
                                             { 30, "Waning Waste" } } },
        { "Piu' abilita'", { { nil, "Torna in Flawless Fortes e completa il percorso fino al tuo ramo" } } },
      },
      notes = { "Rami: Crucial Consumables (kit e tamburi), Brimming Basics (reagenti), Overwhelming Optionals (reagenti opzionali)." } },
}
B.en.leatherworking = {
    { name = "Gear for yourself", short = "Gear", use = "max-rank armor, no orders",
      phases = {
        { "Base", { { 30, "Root of your armor type: Lasting Leather (leather) or Safeguarding Scales (mail)" } } },
        { "First 4 slots", { { 30, "Left side (head, chest, shoulders, wrists) or right side (legs, hands, waist, feet)" } } },
        { "Every slot", { { 30, "The other side" } } },
      },
      notes = { "Then: the other armor type (alts and friends) or Learned Leatherworker for Multicraft, Ingenuity and Resourcefulness." } },
    { name = "Crafting orders", short = "Orders", use = "crafting armor for others",
      phases = {
        { "Base", { { 30, "Root of the armor specialization" } } },
        { "The requested slot", { { 30, "The side with the slot you want" }, { 20, "That slot, maxed" } } },
      },
      notes = { "Armor rather than profession tools: demand lasts all season.", "About one new max-rank slot a week." } },
    { name = "Auction house", short = "Auction", use = "armor kits, drums and reagents in bulk",
      phases = {
        { "Unlock", { { 10, "Flawless Fortes: pick Commanding Commodities, then Crucial Consumables" },
                      { 5, "Learned Leatherworker (root)" } } },
        { "Multicraft and Resourcefulness", { { 30, "Mastering Multicraft" }, { 10, "Learned Leatherworker: second sub-branch" },
                                              { 30, "Waning Waste" } } },
        { "More skill", { { nil, "Go back to Flawless Fortes and finish the path to your branch" } } },
      },
      notes = { "Branches: Crucial Consumables (kits and drums), Brimming Basics (reagents), Overwhelming Optionals (optional reagents)." } },
}

B.it.blacksmithing = {
    { name = "Armi per te", short = "Armi", use = "di solito l'upgrade piu' grande",
      phases = {
        { "Base", { { 30, "Weaponsmithing (radice): sblocca i 3 sotto-rami" } } },
        { "Il tuo tipo di arma", { { 25, "Hafted Weapons (asce, armi ad asta, mazze) oppure Blades (spade, pugnali, glaive)" },
                                   { 20, "Il nodo della tua arma" } } },
      },
      notes = {} },
    { name = "Armature per te", short = "Armature", use = "piastre di rango massimo",
      phases = {
        { "Base", { { 30, "Armorsmithing (radice): sblocca i 3 sotto-rami" } } },
        { "I tuoi slot", { { 30, "Articulating (vita, polsi, mani), Sculpted (elmo, spalle, piedi) o Large Plate (petto, gambe, scudi)" } } },
        { "Tutti gli slot", { { nil, "Da 60 a 120 punti: gli altri rami, nell'ordine che ti serve" } } },
      },
      notes = { "Inizia dagli slot che non competono con il set: polsi, vita, piedi." } },
    { name = "Casa d'aste", short = "Asta", use = "leghe, Tool Stones, pietre per armi",
      phases = {
        { "Leghe", { { 40, "The Old Ways (radice)" }, { 20, "Prolific Worker (Multicraft)" } } },
        { "Margini o qualita'", { { nil, "Resourcefulness, oppure qualita' oro se hai 3 attrezzi blu e abilita' 100" } } },
        { "Consumabili", { { 30, "Craftsmithing (radice)" }, { 25, "Tool Stones (oppure Weaponsmithing 30 e Weaponstones 25)" } } },
      },
      notes = { "Le leghe servono in quasi tutte le ricette di alto livello: sono la scelta piu' sicura." } },
}
B.en.blacksmithing = {
    { name = "Weapons for yourself", short = "Weapons", use = "usually the biggest upgrade",
      phases = {
        { "Base", { { 30, "Weaponsmithing (root): unlocks the 3 sub-branches" } } },
        { "Your weapon type", { { 25, "Hafted Weapons (axes, polearms, maces) or Blades (swords, daggers, warglaives)" },
                                { 20, "Your weapon's node" } } },
      },
      notes = {} },
    { name = "Armor for yourself", short = "Armor", use = "max-rank plate",
      phases = {
        { "Base", { { 30, "Armorsmithing (root): unlocks the 3 sub-branches" } } },
        { "Your slots", { { 30, "Articulating (waist, wrists, hands), Sculpted (helm, shoulders, feet) or Large Plate (chest, legs, shields)" } } },
        { "Every slot", { { nil, "From 60 to 120 points: the other branches, in the order you need" } } },
      },
      notes = { "Start with slots that do not compete with tier: wrists, waist, feet." } },
    { name = "Auction house", short = "Auction", use = "alloys, Tool Stones, weapon stones",
      phases = {
        { "Alloys", { { 40, "The Old Ways (root)" }, { 20, "Prolific Worker (Multicraft)" } } },
        { "Margins or quality", { { nil, "Resourcefulness, or gold quality if you have 3 blue tools and 100 skill" } } },
        { "Consumables", { { 30, "Craftsmithing (root)" }, { 25, "Tool Stones (or Weaponsmithing 30 and Weaponstones 25)" } } },
      },
      notes = { "Alloys go into almost every high-end recipe: the safest pick." } },
}

B.it.tailoring = {
    { name = "Cooldown dei tessuti", short = "Cooldown", use = "tessuti giornalieri ed equip abbellito",
      phases = {
        { "Sblocco", { { 20, "Nimble Needlework (radice): entrambi i cooldown, Arcanoweave e Sunfire Silk" } } },
        { "Mantello epico", { { 15, "Secondo nodo del sotto-ramo scelto (mantello epico a 10 punti)" } } },
        { "Ricarica piu' breve", { { 20, "Ultimo nodo: da circa 17 a 8 ore e mezza, e bracciali epici" } } },
      },
      notes = {} },
    { name = "Produzione di tessuti", short = "Tessuti", use = "Multicraft e Resourcefulness",
      phases = {
        { "Cooldown e Multicraft", { { 20, "Nimble Needlework (radice)" }, { 30, "Creative Efficiency (Fiber Arts)" } } },
        { "Resourcefulness", { { 10, "Fiber Arts (radice)" }, { 30, "Textile Utilization" } } },
      },
      notes = { "Per la qualita' oro senza Concentrazione servono molti piu' punti che nelle altre professioni." } },
    { name = "Raccolta di stoffa", short = "Farming", use = "chi farma mondo, dungeon e delve",
      phases = {
        { "Piu' stoffa", { { 30, "Fabric Specialist (radice)" }, { 20, "Nimble Needlework (radice): i mob lasciano anche i tessuti rari" } } },
        { "La tua zona", { { 25, "Sotto-ramo Harandar/Voidstorm oppure Eversong/Zul'Aman: solo l'ultimo nodo aumenta i drop" } } },
      },
      notes = {} },
    { name = "Armature di stoffa", short = "Armature", use = "equip per te o ordini",
      phases = {
        { "Prima ricetta", { { 5, "Sin'dorei Finery (radice)" }, { 10, "Sotto-ramo dello slot che vuoi" } } },
        { "Abilita'", { { nil, "Riempi il sotto-ramo centrale e la radice" }, { 30, "Fiber Arts (radice): abilita' per tutte le ricette" } } },
      },
      notes = {} },
}
B.en.tailoring = {
    { name = "Bolt cooldowns", short = "Cooldowns", use = "daily bolts and embellished gear",
      phases = {
        { "Unlock", { { 20, "Nimble Needlework (root): both cooldowns, Arcanoweave and Sunfire Silk" } } },
        { "Epic cloak", { { 15, "Second node of your sub-branch (epic cloak at 10 points)" } } },
        { "Shorter cooldown", { { 20, "Last node: from about 17 to 8 and a half hours, and epic bracers" } } },
      },
      notes = {} },
    { name = "Bolt crafting", short = "Bolts", use = "Multicraft and Resourcefulness",
      phases = {
        { "Cooldowns and Multicraft", { { 20, "Nimble Needlework (root)" }, { 30, "Creative Efficiency (Fiber Arts)" } } },
        { "Resourcefulness", { { 10, "Fiber Arts (root)" }, { 30, "Textile Utilization" } } },
      },
      notes = { "Gold quality without Concentration takes many more points than in other professions." } },
    { name = "Cloth farming", short = "Farming", use = "for players farming the world, dungeons and delves",
      phases = {
        { "More cloth", { { 30, "Fabric Specialist (root)" }, { 20, "Nimble Needlework (root): mobs also drop the rare bolts" } } },
        { "Your zone", { { 25, "Harandar/Voidstorm or Eversong/Zul'Aman sub-branch: only the last node raises drops" } } },
      },
      notes = {} },
    { name = "Cloth armor", short = "Armor", use = "gear for yourself or orders",
      phases = {
        { "First recipe", { { 5, "Sin'dorei Finery (root)" }, { 10, "Sub-branch for the slot you want" } } },
        { "Skill", { { nil, "Fill the middle sub-branch and the root" }, { 30, "Fiber Arts (root): skill for every recipe" } } },
      },
      notes = {} },
}

B.it.jewelcrafting = {
    { name = "Taglio delle gemme", short = "Gemme", use = "gemme per la casa d'aste",
      phases = {
        { "Multicraft", { { 5, "Thoughtful Throughput: scegli Outrageous Output" }, { 30, "Outrageous Output" } } },
        { "Resourcefulness o qualita' oro", { { 30, "Skilled Savings (Resourcefulness)" },
                                              { nil, "oppure 25 nel colore, 30 nella radice di Glamorous Gems e 15 nella gemma" } } },
      },
      notes = { "Scegli il primo colore guardando le statistiche piu' richieste nelle guide delle classi." } },
    { name = "Gioielli e accessori", short = "Gioielli", use = "anelli e collane per tutte le classi",
      phases = {
        { "Prime ricette", { { 30, "Alluring Accessories (radice)" }, { 40, "Sotto-ramo scelto: anelli o collane sono i piu' sicuri" } } },
        { "Dopo", { { 40, "Un secondo sotto-ramo" }, { nil, "oppure 30 in Skilled Savings: i gioielli non fanno Multicraft" } } },
      },
      notes = {} },
    { name = "Reagenti", short = "Reagenti", use = "Sunglass Vial, Sin'dorei Lens, Kaleidoscopic Prism",
      phases = {
        { "Multicraft", { { 5, "Thoughtful Throughput" }, { 30, "Outrageous Output" } } },
        { "Resourcefulness o qualita' oro", { { 30, "Skilled Savings" },
                                              { nil, "oppure Proficient Processor: Material Manufacturer e il ramo dei reagenti" } } },
      },
      notes = {} },
    { name = "Prospezione e frantumazione", short = "Prospezione", use = "gemme e Glimmering Gemdust",
      phases = {
        { "Prospezione", { { 10, "Proficient Processor" }, { 30, "Prospecting Pro: l'ultimo nodo da' gemme extra" },
                           { 1, "Un punto per tipo di minerale" } } },
        { "Resourcefulness e qualita' oro", { { 35, "Skilled Savings" }, { 20, "Proficient Processor" } } },
      },
      notes = {} },
}
B.en.jewelcrafting = {
    { name = "Gemcutting", short = "Gems", use = "gems for the auction house",
      phases = {
        { "Multicraft", { { 5, "Thoughtful Throughput: pick Outrageous Output" }, { 30, "Outrageous Output" } } },
        { "Resourcefulness or gold quality", { { 30, "Skilled Savings (Resourcefulness)" },
                                               { nil, "or 25 in the color, 30 in the Glamorous Gems root and 15 in the gem" } } },
      },
      notes = { "Pick your first color from the stats most requested in class guides." } },
    { name = "Jewelry and accessories", short = "Jewelry", use = "rings and necklaces for every class",
      phases = {
        { "First recipes", { { 30, "Alluring Accessories (root)" }, { 40, "Your sub-branch: rings or necklaces are the safest" } } },
        { "Then", { { 40, "A second sub-branch" }, { nil, "or 30 in Skilled Savings: jewelry cannot Multicraft" } } },
      },
      notes = {} },
    { name = "Reagents", short = "Reagents", use = "Sunglass Vial, Sin'dorei Lens, Kaleidoscopic Prism",
      phases = {
        { "Multicraft", { { 5, "Thoughtful Throughput" }, { 30, "Outrageous Output" } } },
        { "Resourcefulness or gold quality", { { 30, "Skilled Savings" },
                                               { nil, "or Proficient Processor: Material Manufacturer and the reagent branch" } } },
      },
      notes = {} },
    { name = "Prospecting and crushing", short = "Prospecting", use = "gems and Glimmering Gemdust",
      phases = {
        { "Prospecting", { { 10, "Proficient Processor" }, { 30, "Prospecting Pro: the last node gives extra gems" },
                           { 1, "One point per ore type" } } },
        { "Resourcefulness and gold quality", { { 35, "Skilled Savings" }, { 20, "Proficient Processor" } } },
      },
      notes = {} },
}

B.it.engineering = {
    { name = "Equip da combattimento", short = "Equip", use = "occhiali, bracciali, stivali, pistole",
      phases = {
        { "Sblocco", { { 25, "Combat Analytics (radice): i 4 sotto-rami" }, { 35, "Lo slot che vuoi" } } },
        { "Abilita'", { { 30, "Recycling: grande bonus per tutto Engineering" } } },
      },
      notes = { "Facoltativo: 30 in Resourcefulness, vale anche sugli ordini." } },
    { name = "Attrezzi da professione", short = "Attrezzi", use = "attrezzi e accessori da vendere",
      phases = {
        { "Ricette e abilita'", { { 10, "Mandatory Tools o Finishing Touches" }, { 25, "Market Mobility (radice)" },
                                  { 30, "Recycling" } } },
        { "Rango massimo", { { 30, "Sotto-ramo dell'attrezzo (abilita' 100 e attrezzi blu)" } } },
      },
      notes = { "Rendono soprattutto a inizio stagione." } },
    { name = "Riciclo", short = "Riciclo", use = "reagenti di qualita' oro",
      phases = {
        { "Reagenti d'oro", { { 30, "Recycling" }, { 10, "Bits and Bots" } } },
        { "Statistiche", { { nil, "Resourcefulness, e Multicraft se crei reagenti" } } },
        { "Tutto d'oro", { { 20, "Bits and Bots" }, { 30, "Bits (Soul Sprocket) o Bots (Emergency Soul Link)" } } },
      },
      notes = {} },
}
B.en.engineering = {
    { name = "Combat gear", short = "Gear", use = "goggles, bracers, boots, guns",
      phases = {
        { "Unlock", { { 25, "Combat Analytics (root): the 4 sub-branches" }, { 35, "The slot you want" } } },
        { "Skill", { { 30, "Recycling: a big bonus for all of Engineering" } } },
      },
      notes = { "Optional: 30 in Resourcefulness, it works on orders too." } },
    { name = "Profession tools", short = "Tools", use = "tools and accessories to sell",
      phases = {
        { "Recipes and skill", { { 10, "Mandatory Tools or Finishing Touches" }, { 25, "Market Mobility (root)" },
                                 { 30, "Recycling" } } },
        { "Max rank", { { 30, "The tool's sub-branch (100 skill and blue tools)" } } },
      },
      notes = { "They sell mostly early in the season." } },
    { name = "Recycling", short = "Recycling", use = "gold-quality reagents",
      phases = {
        { "Gold reagents", { { 30, "Recycling" }, { 10, "Bits and Bots" } } },
        { "Stats", { { nil, "Resourcefulness, and Multicraft if you craft reagents" } } },
        { "Gold everything", { { 20, "Bits and Bots" }, { 30, "Bits (Soul Sprocket) or Bots (Emergency Soul Link)" } } },
      },
      notes = {} },
}

B.it.inscription = {
    { name = "Armi e attrezzi", short = "Armi", use = "bastoni, off-hand, archi",
      phases = {
        { "Prima ricetta", { { nil, "Vai subito in Blueprints e sblocca l'arma che vuoi (bastone, lampada, arco)" } } },
      },
      notes = { "Bastoni Agilita'/Intelletto molto richiesti; archi in concorrenza con Engineering.",
                "Gli attrezzi rendono a inizio stagione, le armi nel lungo periodo." } },
    { name = "Missive e contratti", short = "Missive", use = "il volume piu' alto in asta",
      phases = {
        { "Calm Hands", { { 10, "Calm Hands (radice)" }, { 20, "Dextrous Diligence (Multicraft)" }, { 20, "Keen Eye (Resourcefulness)" } } },
        { "Pergamene", { { nil, "Perfected Products: il nodo Parchment" } } },
      },
      notes = { "Rune Vantus solo quando apre il raid." } },
    { name = "Reagenti", short = "Inchiostri", use = "macinatura e inchiostri",
      phases = {
        { "Calm Hands", { { 50, "Come per le missive" } } },
        { "Pigmenti d'oro", { { 90, "Perfected Products > Processing > Perfect Milling (tutti e tre al massimo)" } } },
        { "Inchiostri", { { 30, "Perfect Inks" }, { 30, "Perfect Ciphers (oggi servono meno)" } } },
      },
      notes = {} },
    { name = "Carte Darkmoon", short = "Darkmoon", use = "carte, mazzi e monili",
      phases = {
        { "Inizio", { { 20, "Darkmoon Curiosity (radice); ogni seme e' un sotto-ramo" } } },
      },
      notes = { "Aspetta i dati di mercato prima di investire molto." } },
}
B.en.inscription = {
    { name = "Weapons and tools", short = "Weapons", use = "staves, off-hands, bows",
      phases = {
        { "First recipe", { { nil, "Go straight into Blueprints and unlock the weapon you want (staff, lamp, bow)" } } },
      },
      notes = { "Agility/Intellect staves are in high demand; bows compete with Engineering.",
                "Tools sell early in the season, weapons in the long run." } },
    { name = "Missives and contracts", short = "Missives", use = "the highest volume on the auction house",
      phases = {
        { "Calm Hands", { { 10, "Calm Hands (root)" }, { 20, "Dextrous Diligence (Multicraft)" }, { 20, "Keen Eye (Resourcefulness)" } } },
        { "Parchment", { { nil, "Perfected Products: the Parchment node" } } },
      },
      notes = { "Vantus runes only once the raid opens." } },
    { name = "Reagents", short = "Inks", use = "milling and inks",
      phases = {
        { "Calm Hands", { { 50, "As for missives" } } },
        { "Gold pigments", { { 90, "Perfected Products > Processing > Perfect Milling (all three maxed)" } } },
        { "Inks", { { 30, "Perfect Inks" }, { 30, "Perfect Ciphers (needed less now)" } } },
      },
      notes = {} },
    { name = "Darkmoon cards", short = "Darkmoon", use = "cards, decks and trinkets",
      phases = {
        { "Start", { { 20, "Darkmoon Curiosity (root); each suit is a sub-branch" } } },
      },
      notes = { "Wait for market data before investing heavily." } },
}

B.it.enchanting = {
    { name = "Concentrazione", short = "Concentrazione", use = "poco tempo: un incantamento ogni pochi giorni",
      phases = {
        { "Base", { { 20, "Spellbound Shatterer (i bonus di Concentrazione si fermano a 20)" }, { 30, "Infinite Ingenuity" } } },
      },
      notes = { "Attrezzo con Ingenuity: gli incantamenti non fanno Multicraft.", "Molte ricette si comprano dai venditori o all'asta." } },
    { name = "Vendita di incantamenti", short = "Incantamenti", use = "produzione in serie",
      phases = {
        { "Base", { { 30, "Elevating Equipment (radice)" }, { 20, "Sotto-ramo scelto: arma/anello/petto o elmo/spalle/stivali" } } },
        { "Dopo", { { nil, "Se l'argento rende gia': Resourcefulness in Spellbound Shatterer; altrimenti verso la qualita' oro" } } },
      },
      notes = {} },
    { name = "Disincanto", short = "Disincanto", use = "vendere i materiali",
      phases = {
        { "Base", { { 30, "Disenchanting Delegate (radice)" } } },
        { "Cosa disincanti", { { 30, "Dust Deliverer (verdi), Shard Supplier (blu) o Crystal Collector (epici)" } } },
      },
      notes = { "Conta solo l'abilita': bastano verga e accessori blu." } },
}
B.en.enchanting = {
    { name = "Concentration", short = "Concentration", use = "little time: one enchant every few days",
      phases = {
        { "Base", { { 20, "Spellbound Shatterer (Concentration bonuses stop at 20)" }, { 30, "Infinite Ingenuity" } } },
      },
      notes = { "Tool with Ingenuity: enchants cannot Multicraft.", "Many recipes come from vendors or the auction house." } },
    { name = "Selling enchants", short = "Enchants", use = "mass production",
      phases = {
        { "Base", { { 30, "Elevating Equipment (root)" }, { 20, "Your sub-branch: weapon/ring/chest or helm/shoulders/boots" } } },
        { "Then", { { nil, "If silver already sells: Resourcefulness in Spellbound Shatterer; otherwise toward gold quality" } } },
      },
      notes = {} },
    { name = "Disenchanting", short = "Disenchanting", use = "selling the materials",
      phases = {
        { "Base", { { 30, "Disenchanting Delegate (root)" } } },
        { "What you disenchant", { { 30, "Dust Deliverer (green), Shard Supplier (blue) or Crystal Collector (epic)" } } },
      },
      notes = { "Only skill matters: a blue rod and blue accessories are enough." } },
}

B.it.herbalism = {
    { name = "Druido", short = "Druido", use = "raccolta in sella gia' disponibile",
      phases = { { "Raccolto", { { 40, "Bountiful Harvests: piu' erbe per nodo e piu' qualita' oro" } } } },
      notes = {} },
    { name = "Altre classi", short = "Altre classi", use = "prima la raccolta in sella",
      phases = {
        { "Raccolta in sella", { { 40, "Botany" } } },
        { "Raccolto", { { 40, "Bountiful Harvests" } } },
      },
      notes = { "Non sono punti sprecati: danno anche Deftness e molta Finesse." } },
}
B.en.herbalism = {
    { name = "Druid", short = "Druid", use = "mounted gathering already available",
      phases = { { "Harvest", { { 40, "Bountiful Harvests: more herbs per node and more gold quality" } } } },
      notes = {} },
    { name = "Other classes", short = "Other classes", use = "mounted gathering first",
      phases = {
        { "Mounted gathering", { { 40, "Botany" } } },
        { "Harvest", { { 40, "Bountiful Harvests" } } },
      },
      notes = { "Not wasted points: they also give Deftness and a lot of Finesse." } },
}

B.it.mining = {
    { name = "Standard", short = "Standard", use = "estrazione in sella e qualita' oro",
      phases = {
        { "Estrazione in sella", { { 40, "Meticulous Mining (radice)" } } },
        { "Abilita' sui minerali", { { 50, "Plentiful Ores (radice): tutti i minerali, in tutte le zone" } } },
        { "Completamento", { { nil, "I singoli minerali (prima il piu' caro), un sotto-ramo Over-LODED dove farmi di piu', Rich Deposits" } } },
      },
      notes = {} },
}
B.en.mining = {
    { name = "Standard", short = "Standard", use = "mounted mining and gold quality",
      phases = {
        { "Mounted mining", { { 40, "Meticulous Mining (root)" } } },
        { "Ore skill", { { 50, "Plentiful Ores (root): every ore, in every zone" } } },
        { "Finishing", { { nil, "The individual ores (most expensive first), one Over-LODED sub-branch where you farm most, Rich Deposits" } } },
      },
      notes = {} },
}

B.it.skinning = {
    { name = "Farming puro", short = "Farming", use = "cuoio o scaglie dai mob",
      phases = {
        { "Il tuo materiale", { { 10, "Thorough Tanning (radice)" }, { 40, "Lasting Leather (cuoio) o Superb Scales (scaglie)" },
                                { 30, "Thorough Tanning" } } },
        { "Quantita'", { { 10, "Gainful Gathering (radice)" }, { 40, "Careful Carving (Finesse) o Trophy Taker (Perception)" } } },
      },
      notes = {} },
    { name = "Esche e bestie rinomate", short = "Esche", use = "Majestic Materials",
      phases = {
        { "Esche", { { 40, "Talented Tracker (radice): tutte le esche di zona e la Grand Beast Lure" } } },
        { "Materiali", { { nil, "Sotto-ramo Majestic Materials, poi Gainful Gathering" } } },
      },
      notes = {} },
}
B.en.skinning = {
    { name = "Pure farming", short = "Farming", use = "leather or scales from mobs",
      phases = {
        { "Your material", { { 10, "Thorough Tanning (root)" }, { 40, "Lasting Leather (leather) or Superb Scales (scales)" },
                             { 30, "Thorough Tanning" } } },
        { "Quantity", { { 10, "Gainful Gathering (root)" }, { 40, "Careful Carving (Finesse) or Trophy Taker (Perception)" } } },
      },
      notes = {} },
    { name = "Lures and renowned beasts", short = "Lures", use = "Majestic Materials",
      phases = {
        { "Lures", { { 40, "Talented Tracker (root): every zone lure and the Grand Beast Lure" } } },
        { "Materials", { { nil, "Majestic Materials sub-branch, then Gainful Gathering" } } },
      },
      notes = {} },
}

function B:Get(key)
    local t = self[ns.lang] or self.it
    return t[key] or self.it[key]
end
