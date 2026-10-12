-- RotAssist Companion - CraftBuilds
-- Build delle specializzazioni di Midnight per ogni professione: nome, a cosa
-- serve e come distribuire i punti conoscenza, fase per fase.
--
-- Riferimento: wow-professions.com, guide "<Profession> Specialization Guide &
-- Best Builds" (Midnight, ottobre 2026) e, per Skinning, la guida generale.
-- Testi riassunti con parole nostre; i nomi dei nodi sono quelli inglesi del
-- client (nel client italiano possono essere tradotti).
--
-- Formato: [professione] = { { nome, uso, { passi } }, ... }

local _, ns = ...

local B = { it = {}, en = {} }
ns.CraftBuilds = B

B.it.alchemy = {
    { "Durata dei flask", "raid e Mitiche+", {
        "15 punti nella radice di Fluent in Flasks: la durata di flask e fiale aumenta a 5 e a 15 punti.",
        "Poi prosegui con la build 'Consumabili da vendere', linea dei flask." } },
    { "Consumabili da vendere", "casa d'aste: pozioni (le piu' redditizie oggi), flask o fiale", {
        "Fase 1, Multicraft: 10 nella radice della linea, 10 nel sotto-ramo (flask: Sin'dorei Specialist; pozioni: Path of Void o Path of Light), 20 nel nodo Multicraft (Flask Abundance o Prolific Potioneer).",
        "Fase 2, Resourcefulness: 10 in Alchemical Mastery, poi 20 in Recycle (flask) o Reuse (pozioni).",
        "Fase 3, qualita' oro: porta a 30 i nodi gia' usati; a 30 punti nella radice si sblocca il calderone.",
        "Strumento con Multicraft e incantamento Multicraft." } },
    { "Trasmutazioni", "giornaliero e Mote", {
        "10 nella radice di Transmutation Authority: Synthesis Synergy insegna il giornaliero Wondrous Synergist.",
        "20 in Metamorphic Mastery (Multicraft), poi 20 in Synthesis Synergy: ricarica del giornaliero da 18 a circa 9 ore.",
        "10 nella radice di Alchemical Mastery e 20 in Reduce (Resourcefulness, utile su tutte le trasmutazioni).",
        "Le trasmutazioni di materiali (Bouquet of Herbs, Box of Rocks, School of Gems) non fanno Multicraft: per quelle serve Resourcefulness." } },
}
B.en.alchemy = {
    { "Extra Flask Duration", "raids and Mythic+", {
        "15 points in the Fluent in Flasks root: flask and phial duration goes up at 5 and at 15 points.",
        "Then continue with the 'Selling Consumables' build, flask line." } },
    { "Selling Consumables", "auction house: potions (the most profitable right now), flasks or phials", {
        "Phase 1, Multicraft: 10 in the line's root, 10 in the sub-branch (flasks: Sin'dorei Specialist; potions: Path of Void or Path of Light), 20 in the Multicraft node (Flask Abundance or Prolific Potioneer).",
        "Phase 2, Resourcefulness: 10 in Alchemical Mastery, then 20 in Recycle (flasks) or Reuse (potions).",
        "Phase 3, gold quality: bring the nodes you used to 30; 30 points in the root unlock the cauldron.",
        "Multicraft tool with a Multicraft enchant." } },
    { "Transmutes", "daily cooldown and Motes", {
        "10 in the Transmutation Authority root: Synthesis Synergy teaches the Wondrous Synergist daily.",
        "20 in Metamorphic Mastery (Multicraft), then 20 in Synthesis Synergy: daily cooldown from 18 to about 9 hours.",
        "10 in the Alchemical Mastery root and 20 in Reduce (Resourcefulness, good on every transmute).",
        "Material transmutes (Bouquet of Herbs, Box of Rocks, School of Gems) cannot Multicraft: they need Resourcefulness." } },
}

B.it.leatherworking = {
    { "Standard", "equip di rango massimo per te", {
        "30 nella radice della specializzazione del tuo tipo di armatura: Lasting Leather (cuoio) o Safeguarding Scales (maglia).",
        "30 nel lato che ti serve: sinistro (testa, petto, spalle, polsi) o destro (gambe, mani, vita, piedi); sblocca 4 ricette.",
        "30 nell'altro lato per le ricette restanti.",
        "Poi: l'altro tipo di armatura (alt e amici) o Learned Leatherworker per Multicraft, Ingenuity e Resourcefulness." } },
    { "Ordini di lavoro", "creare armature per gli altri (chat commercio)", {
        "Meglio le armature degli attrezzi da professione: la domanda dura tutta la stagione, quella degli attrezzi cala presto.",
        "30 nella radice, 30 nel lato con lo slot che vuoi, 20 per portare lo slot al massimo: circa uno slot nuovo a settimana." } },
    { "Casa d'aste", "produzione in serie", {
        "Consumabili (kit per armature, tamburi): 10 in Flawless Fortes, scegli Commanding Commodities e poi Crucial Consumables.",
        "5 nella radice di Learned Leatherworker, 30 in Mastering Multicraft, 10 per il secondo sotto-ramo, 30 in Waning Waste.",
        "Poi torna in Flawless Fortes e completa il percorso fino al tuo ramo (reagenti: Brimming Basics; opzionali: Overwhelming Optionals)." } },
}
B.en.leatherworking = {
    { "Standard", "max-rank gear for yourself", {
        "30 in the root of your armor type's specialization: Lasting Leather (leather) or Safeguarding Scales (mail).",
        "30 in the side you need: left (head, chest, shoulders, wrists) or right (legs, hands, waist, feet); unlocks 4 recipes.",
        "30 in the other side for the remaining recipes.",
        "Then: the other armor type (alts and friends) or Learned Leatherworker for Multicraft, Ingenuity and Resourcefulness." } },
    { "Crafting Orders", "crafting armor for others (trade chat)", {
        "Armor rather than profession tools: armor demand lasts all season, tool demand drops early.",
        "30 in the root, 30 in the side with the slot you want, 20 to max that slot: about one new slot a week." } },
    { "Auction House", "mass production", {
        "Consumables (armor kits, drums): 10 in Flawless Fortes, pick Commanding Commodities then Crucial Consumables.",
        "5 in the Learned Leatherworker root, 30 in Mastering Multicraft, 10 for the second sub-branch, 30 in Waning Waste.",
        "Then go back to Flawless Fortes and finish the path to your branch (reagents: Brimming Basics; optionals: Overwhelming Optionals)." } },
}

B.it.blacksmithing = {
    { "Standard", "equip di rango massimo per te", {
        "Decidi armi o armature: le armi di solito sono l'upgrade maggiore, le armature danno piu' slot.",
        "Armorsmithing: 30 nella radice, poi 30 nel ramo con i tuoi slot (Articulating: vita, polsi, mani; Sculpted: elmo, spalle, piedi; Large Plate: petto, gambe, scudi). Meglio iniziare dagli slot che non competono con il set.",
        "Weaponsmithing: 30 nella radice, poi 25 in Hafted Weapons (asce, armi ad asta, mazze) o Blades (spade, pugnali, glaive)." } },
    { "Ordini di lavoro", "armi e armature per gli altri", {
        "Armi o armature, non attrezzi: la domanda con le Spark dura tutta la stagione.",
        "30 nella radice di Armorsmithing o Weaponsmithing, 30 nel sotto-ramo dello slot, 20 o piu' nel nodo dell'oggetto." } },
    { "Casa d'aste", "leghe, Tool Stones, pietre per armi", {
        "Leghe (consigliate, servono in quasi tutte le ricette di alto livello): 40 nella radice di The Old Ways, 20 in Prolific Worker (Multicraft).",
        "Poi Resourcefulness, oppure qualita' oro se hai 3 attrezzi blu e abilita' 100.",
        "In seguito: 30 nella radice di Craftsmithing e 25 in Tool Stones, o 30 in Weaponsmithing e 25 in Weaponstones." } },
}
B.en.blacksmithing = {
    { "Standard", "max-rank gear for yourself", {
        "Pick weapons or armor: weapons are usually the bigger upgrade, armor gives more slots.",
        "Armorsmithing: 30 in the root, then 30 in the branch with your slots (Articulating: waist, wrists, hands; Sculpted: helm, shoulders, feet; Large Plate: chest, legs, shields). Start with slots that do not compete with tier.",
        "Weaponsmithing: 30 in the root, then 25 in Hafted Weapons (axes, polearms, maces) or Blades (swords, daggers, warglaives)." } },
    { "Crafting Orders", "weapons and armor for others", {
        "Weapons or armor, not tools: with Sparks the demand lasts all season.",
        "30 in the Armorsmithing or Weaponsmithing root, 30 in the slot's sub-branch, 20 or more in the item node." } },
    { "Auction House", "alloys, Tool Stones, weapon stones", {
        "Alloys (recommended, used in almost every high-end recipe): 40 in The Old Ways root, 20 in Prolific Worker (Multicraft).",
        "Then Resourcefulness, or gold quality if you have 3 blue tools and 100 skill.",
        "Later: 30 in the Craftsmithing root and 25 in Tool Stones, or 30 in Weaponsmithing and 25 in Weaponstones." } },
}

B.it.tailoring = {
    { "Standard", "cooldown giornalieri dei tessuti ed equip abbellito", {
        "20 nella radice di Nimble Needlework: sblocca entrambi i cooldown (Arcanoweave e Sunfire Silk).",
        "Scegli un sotto-ramo, poi 15 nel secondo nodo (mantello epico a 10 punti).",
        "20 nell'ultimo nodo: ricarica da circa 17 a 8 ore e mezza e bracciali epici." } },
    { "Produzione di tessuti", "Multicraft e Resourcefulness", {
        "20 in Nimble Needlework per i cooldown, poi 30 in Creative Efficiency (Fiber Arts) per il Multicraft.",
        "10 nella radice di Fiber Arts e 30 in Textile Utilization (Resourcefulness).",
        "Per la qualita' oro senza Concentrazione servono molti piu' punti che nelle altre professioni." } },
    { "Raccolta di stoffa", "chi farma nel mondo, nei dungeon e nelle delve", {
        "30 nella radice di Fabric Specialist (piu' stoffa e piu' qualita' oro in tutte le zone).",
        "20 nella radice di Nimble Needlework: i mob lasciano anche Sunfire Silk e Arcanoweave.",
        "25 nel sotto-ramo della zona dove farmi (Harandar/Voidstorm o Eversong/Zul'Aman): solo l'ultimo nodo aumenta i drop." } },
    { "Armature di stoffa", "equip per te o ordini", {
        "5 nella radice di Sin'dorei Finery, 10 nel sotto-ramo dello slot che vuoi (prima ricetta).",
        "Riempi il sotto-ramo centrale e la radice, poi 30 nella radice di Fiber Arts (abilita' per tutte le ricette)." } },
}
B.en.tailoring = {
    { "Standard", "daily bolt cooldowns and embellished gear", {
        "20 in the Nimble Needlework root: unlocks both cooldowns (Arcanoweave and Sunfire Silk).",
        "Pick a sub-branch, then 15 in the second node (epic cloak at 10 points).",
        "20 in the last node: cooldown from about 17 to 8 and a half hours, and epic bracers." } },
    { "Bolt Crafting", "Multicraft and Resourcefulness", {
        "20 in Nimble Needlework for the cooldowns, then 30 in Creative Efficiency (Fiber Arts) for Multicraft.",
        "10 in the Fiber Arts root and 30 in Textile Utilization (Resourcefulness).",
        "Gold quality without Concentration takes many more points than in other professions." } },
    { "Farming", "for players farming the world, dungeons and delves", {
        "30 in the Fabric Specialist root (more cloth and more gold quality in every zone).",
        "20 in the Nimble Needlework root: mobs also drop Sunfire Silk and Arcanoweave.",
        "25 in the sub-branch for the zone you farm (Harandar/Voidstorm or Eversong/Zul'Aman): only the last node raises drops." } },
    { "Armor Crafting", "gear for yourself or orders", {
        "5 in the Sin'dorei Finery root, 10 in the sub-branch for the slot you want (first recipe).",
        "Fill the middle sub-branch and the root, then 30 in the Fiber Arts root (skill for every recipe)." } },
}

B.it.jewelcrafting = {
    { "Taglio delle gemme", "gemme per la casa d'aste", {
        "Scegli il primo colore guardando le statistiche piu' richieste nelle guide BiS.",
        "5 in Thoughtful Throughput e 30 in Outrageous Output (Multicraft).",
        "Poi Resourcefulness (10 e 30 in Skilled Savings) oppure qualita' oro (25 nel colore, 30 nella radice di Glamorous Gems, 15 nella gemma)." } },
    { "Gioielli e accessori", "anelli, collane, accessori da professione", {
        "30 nella radice di Alluring Accessories, 40 nel sotto-ramo scelto (anelli o collane sono i piu' sicuri).",
        "Poi un secondo sotto-ramo, oppure 30 in Skilled Savings: i gioielli non fanno Multicraft." } },
    { "Reagenti", "Sunglass Vial, Sin'dorei Lens, Kaleidoscopic Prism", {
        "5 in Thoughtful Throughput e 30 in Outrageous Output (Multicraft).",
        "Poi Resourcefulness (30 in Skilled Savings) o qualita' oro in Proficient Processor (Material Manufacturer e il ramo dei reagenti)." } },
    { "Prospezione e frantumazione", "gemme e Glimmering Gemdust", {
        "10 in Proficient Processor, 30 in Prospecting Pro (l'ultimo nodo da' gemme extra), 1 punto per tipo di minerale.",
        "5 e 30 in Skilled Savings, poi 20 in Proficient Processor per la qualita' oro." } },
}
B.en.jewelcrafting = {
    { "Gemcutting", "gems for the auction house", {
        "Pick your first color from the stats most requested in BiS guides.",
        "5 in Thoughtful Throughput and 30 in Outrageous Output (Multicraft).",
        "Then Resourcefulness (10 and 30 in Skilled Savings) or gold quality (25 in the color, 30 in the Glamorous Gems root, 15 in the gem)." } },
    { "Jewelry & Accessories", "rings, necklaces, profession accessories", {
        "30 in the Alluring Accessories root, 40 in your sub-branch (rings or necklaces are the safest).",
        "Then a second sub-branch, or 30 in Skilled Savings: jewelry cannot Multicraft." } },
    { "Reagent Crafter", "Sunglass Vial, Sin'dorei Lens, Kaleidoscopic Prism", {
        "5 in Thoughtful Throughput and 30 in Outrageous Output (Multicraft).",
        "Then Resourcefulness (30 in Skilled Savings) or gold quality in Proficient Processor (Material Manufacturer and the reagent branch)." } },
    { "Prospecting & Crushing", "gems and Glimmering Gemdust", {
        "10 in Proficient Processor, 30 in Prospecting Pro (the last node gives extra gems), 1 point per ore type.",
        "5 and 30 in Skilled Savings, then 20 in Proficient Processor for gold quality." } },
}

B.it.engineering = {
    { "Attrezzi da professione", "attrezzi e accessori da vendere", {
        "10 in Mandatory Tools o Finishing Touches (3 ricette), 25 nella radice di Market Mobility.",
        "30 in Recycling: grande bonus di abilita' per tutto Engineering.",
        "30 nel sotto-ramo dell'attrezzo per il rango massimo senza Concentrazione (abilita' 100 e attrezzi blu)." } },
    { "Equip da combattimento", "occhiali, bracciali, stivali, pistole", {
        "25 nella radice di Combat Analytics (sblocca i 4 sotto-rami), 35 nello slot scelto.",
        "30 in Recycling per l'abilita'; poi, se vuoi, 30 in Resourcefulness (vale anche sugli ordini)." } },
    { "Riciclo", "reagenti di qualita' oro", {
        "30 in Recycling e 10 in Bits and Bots: con attrezzi verdi ricicli gia' reagenti di base di qualita' oro.",
        "Poi Resourcefulness (e Multicraft se crei reagenti); per Soul Sprocket ed Emergency Soul Link d'oro 20 in Bits and Bots e 30 in Bits o Bots." } },
}
B.en.engineering = {
    { "Profession Gear", "tools and accessories to sell", {
        "10 in Mandatory Tools or Finishing Touches (3 recipes), 25 in the Market Mobility root.",
        "30 in Recycling: a big skill bonus for all of Engineering.",
        "30 in the tool's sub-branch for max rank without Concentration (100 skill and blue tools)." } },
    { "Combat Gear", "goggles, bracers, boots, guns", {
        "25 in the Combat Analytics root (unlocks the 4 sub-branches), 35 in your slot.",
        "30 in Recycling for skill; then, if you want, 30 in Resourcefulness (it works on orders too)." } },
    { "Recycling", "gold-quality reagents", {
        "30 in Recycling and 10 in Bits and Bots: with green tools you already recycle gold-quality base reagents.",
        "Then Resourcefulness (and Multicraft if you craft reagents); for gold Soul Sprocket and Emergency Soul Link 20 in Bits and Bots and 30 in Bits or Bots." } },
}

B.it.inscription = {
    { "Armi e attrezzi", "bastoni, off-hand, archi e attrezzi", {
        "Vai subito in Blueprints (non in Calm Hands): conta sbloccare la prima ricetta.",
        "Bastoni Agilita'/Intelletto (molto richiesti), lampade off-hand, archi (in concorrenza con Engineering); attrezzi per Inscription, Alchemy e Cooking.",
        "Gli attrezzi rendono a inizio stagione, le armi nel lungo periodo." } },
    { "Missive e contratti", "casa d'aste", {
        "Calm Hands: 10 nella radice, 20 in Dextrous Diligence (Multicraft), 20 in Keen Eye (Resourcefulness).",
        "Poi il nodo Parchment in Perfected Products. Le missive sono il volume piu' alto; le rune Vantus solo quando apre il raid." } },
    { "Reagenti", "macinatura e inchiostri", {
        "Calm Hands come sopra (50 punti).",
        "Perfected Products > Processing > Perfect Milling: 90 punti in tutto per i pigmenti d'oro.",
        "Poi Perfect Inks e Perfect Ciphers (i cifrari oggi servono meno)." } },
    { "Carte Darkmoon", "carte, mazzi e monili", {
        "20 nella radice di Darkmoon Curiosity; ogni seme (Rot, Blood, Hunt, Void) e' un sotto-ramo.",
        "Aspetta i dati di mercato prima di investire molto." } },
}
B.en.inscription = {
    { "Weapons & Tools", "staves, off-hands, bows and tools", {
        "Go straight into Blueprints (not Calm Hands): unlocking the first recipe matters most.",
        "Agility/Intellect staves (high demand), off-hand lamps, bows (shared market with Engineering); tools for Inscription, Alchemy and Cooking.",
        "Tools sell early in the season, weapons in the long run." } },
    { "Missives & Contracts", "auction house", {
        "Calm Hands: 10 in the root, 20 in Dextrous Diligence (Multicraft), 20 in Keen Eye (Resourcefulness).",
        "Then the Parchment node in Perfected Products. Missives have the highest volume; Vantus runes only once the raid opens." } },
    { "Reagents", "milling and inks", {
        "Calm Hands as above (50 points).",
        "Perfected Products > Processing > Perfect Milling: 90 points in total for gold pigments.",
        "Then Perfect Inks and Perfect Ciphers (ciphers are needed less now)." } },
    { "Darkmoon Cards", "cards, decks and trinkets", {
        "20 in the Darkmoon Curiosity root; each suit (Rot, Blood, Hunt, Void) is a sub-branch.",
        "Wait for market data before investing heavily." } },
}

B.it.enchanting = {
    { "Concentrazione", "poco tempo: un incantamento di qualita' alta ogni pochi giorni", {
        "20 in Spellbound Shatterer (i bonus di Concentrazione si fermano a 20) e 30 in Infinite Ingenuity.",
        "Attrezzo con Ingenuity: gli incantamenti non fanno Multicraft.",
        "Ricette: molte si comprano dai venditori o all'asta, non serve spendere punti per sbloccarle." } },
    { "Vendita di incantamenti", "produzione in serie", {
        "30 nella radice di Elevating Equipment e 20 nel sotto-ramo scelto (arma/anello/petto o elmo/spalle/stivali sono i piu' richiesti).",
        "Se le versioni argento rendono gia', passa a Resourcefulness in Spellbound Shatterer; altrimenti continua verso la qualita' oro." } },
    { "Disincanto", "vendere i materiali", {
        "30 in Disenchanting Delegate, poi 30 nel sotto-ramo di cio' che disincanti: Dust Deliverer (verdi), Shard Supplier (blu), Crystal Collector (epici).",
        "Conta solo l'abilita': bastano verga e accessori blu. Con il tempo sblocca tutti e tre i sotto-rami." } },
}
B.en.enchanting = {
    { "Concentration", "little time: one high-quality enchant every few days", {
        "20 in Spellbound Shatterer (Concentration bonuses stop at 20) and 30 in Infinite Ingenuity.",
        "Tool with Ingenuity: enchants cannot Multicraft.",
        "Recipes: many come from vendors or the auction house, no need to spend points to unlock them." } },
    { "Selling Enchants", "mass production", {
        "30 in the Elevating Equipment root and 20 in your sub-branch (weapon/ring/chest or helm/shoulders/boots are the most requested).",
        "If silver versions already sell, move to Resourcefulness in Spellbound Shatterer; otherwise keep going toward gold quality." } },
    { "Disenchanting", "selling the materials", {
        "30 in Disenchanting Delegate, then 30 in the sub-branch for what you disenchant: Dust Deliverer (green), Shard Supplier (blue), Crystal Collector (epic).",
        "Only skill matters: a blue rod and blue accessories are enough. Over time unlock all three sub-branches." } },
}

B.it.herbalism = {
    { "Druido", "raccolta in sella gia' disponibile", {
        "40 in Bountiful Harvests: piu' erbe per nodo e piu' qualita' oro." } },
    { "Altre classi", "prima la raccolta in sella", {
        "40 in Botany per raccogliere senza scendere dalla cavalcatura, poi 40 in Bountiful Harvests.",
        "Non sono punti sprecati: danno anche Deftness e molta Finesse." } },
}
B.en.herbalism = {
    { "Druid", "mounted gathering already available", {
        "40 in Bountiful Harvests: more herbs per node and more gold quality." } },
    { "Other classes", "mounted gathering first", {
        "40 in Botany to gather without dismounting, then 40 in Bountiful Harvests.",
        "Not wasted points: they also give Deftness and a lot of Finesse." } },
}

B.it.mining = {
    { "Standard", "estrazione in sella e qualita' oro", {
        "40 nella radice di Meticulous Mining: estrazione senza scendere dalla cavalcatura.",
        "50 nella radice di Plentiful Ores: abilita' per tutti i minerali, che si trovano in tutte le zone.",
        "Poi distribuisci sui singoli minerali (prima il piu' caro), un sotto-ramo Over-LODED dove farmi di piu' e Rich Deposits." } },
}
B.en.mining = {
    { "Standard", "mounted mining and gold quality", {
        "40 in the Meticulous Mining root: mine without dismounting.",
        "50 in the Plentiful Ores root: skill for every ore, found in every zone.",
        "Then spread points over the individual ores (most expensive first), one Over-LODED sub-branch where you farm most, and Rich Deposits." } },
}

B.it.skinning = {
    { "Farming puro", "cuoio o scaglie dai mob", {
        "10 in Thorough Tanning, poi 40 in Lasting Leather (cuoio) o Superb Scales (scaglie), poi 30 in Thorough Tanning.",
        "10 in Gainful Gathering e 40 in Careful Carving (Finesse) o Trophy Taker (Perception, se i drop specifici valgono di piu')." } },
    { "Esche e bestie rinomate", "Majestic Materials", {
        "40 nella radice di Talented Tracker: tutte le esche di zona e la Grand Beast Lure.",
        "Poi il sotto-ramo Majestic Materials; Gainful Gathering come seconda scelta." } },
}
B.en.skinning = {
    { "Pure Farming", "leather or scales from mobs", {
        "10 in Thorough Tanning, then 40 in Lasting Leather (leather) or Superb Scales (scales), then 30 in Thorough Tanning.",
        "10 in Gainful Gathering and 40 in Careful Carving (Finesse) or Trophy Taker (Perception, if species drops are worth more)." } },
    { "Lures & Renowned Beasts", "Majestic Materials", {
        "40 in the Talented Tracker root: every zone lure and the Grand Beast Lure.",
        "Then the Majestic Materials sub-branch; Gainful Gathering second." } },
}

function B:Get(key)
    local t = self[ns.lang] or self.it
    return t[key] or self.it[key]
end
