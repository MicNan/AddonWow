-- RotAssist Companion - CraftGuide
-- Guida statica alle professioni di Midnight: fasi per salire da 1 a 100 nel
-- minor tempo, fonti di conoscenza e specializzazioni (con quella consigliata
-- per l'equipaggiamento del tuo personaggio).
--
-- Testi scritti per questo addon, riassumendo (ottobre 2026, patch 12.1):
--  * wow-professions.com: guide "Leveling 1-100", "Recipes & Knowledge Points"
--    e "Specialization Guide & Best Builds" di ogni professione
--  * method.gg: "All profession knowledge point sources in Midnight"
-- La parte "cosa creare adesso e cosa comprare" non e' qui: la calcola
-- Data\Craft.lua dalle ricette che conosci (finestra della professione).

local _, ns = ...

local G = {}
ns.CraftGuide = G

-- Professione base -> professione di Midnight (SkillLine su wago.tools)
G.MIDNIGHT = {
    [171] = 2906, [164] = 2907, [185] = 2908, [333] = 2909, [202] = 2910, [356] = 2911,
    [182] = 2912, [773] = 2913, [755] = 2914, [165] = 2915, [186] = 2916, [393] = 2917, [197] = 2918,
}

-- Professioni di raccolta: niente ricette, solo la guida
G.GATHERING = { [182] = true, [186] = true, [393] = true }

-- Armatura per classe (UnitClass, secondo valore)
G.ARMOR = {
    MAGE = "cloth", PRIEST = "cloth", WARLOCK = "cloth",
    ROGUE = "leather", DRUID = "leather", MONK = "leather", DEMONHUNTER = "leather",
    HUNTER = "mail", SHAMAN = "mail", EVOKER = "mail",
    WARRIOR = "plate", PALADIN = "plate", DEATHKNIGHT = "plate",
}

-- Classi che usano armi da mischia fatte dal fabbro (spade, asce, mazze,
-- pugnali, armi ad asta, glaive). Il cacciatore solo in Survival (255).
G.MELEE = { WARRIOR = true, PALADIN = true, DEATHKNIGHT = true, ROGUE = true,
            DEMONHUNTER = true, MONK = true, SHAMAN = true }
-- Bastoni e off-hand (Inscription)
G.STAFF = { MAGE = true, PRIEST = true, WARLOCK = true, DRUID = true, EVOKER = true }

---------------------------------------------------------------------------
-- Testi
---------------------------------------------------------------------------
-- phases: { da, a, testo }; trainer = dove si impara (Silvermoon City)
-- specs: specializzazioni (nomi inglesi del client) e cosa sbloccano
G.it = {
    leatherworking = {
        trainer = "Talmar (Silvermoon City)",
        phases = {
            { 1, 7, "Crea una volta le due ricette iniziali, poi vai dal trainer." },
            { 7, 60, "Ogni 5-10 punti il trainer insegna nuove ricette: imparale e crea ognuna una volta (filtro 'First Craft Bonus'). Con l'ultimo gruppo a 50 arrivi intorno a 61." },
            { 60, 91, "Crea una delle ricette di livello medio (arancioni fino a 80, gialle fino a 90): servono circa 35 creazioni. L'elenco qui sotto sceglie la piu' economica." },
            { 91, 100, "Le ultime 9: armature epiche, anche tramite ordini di lavoro (3 punti l'una, arancioni fino a 100). Le ricette epiche vengono dalle specializzazioni, dai venditori e dai drop." },
        },
        specs = {
            "Learned Leatherworker: statistiche di creazione (Multicraft, Resourcefulness, Ingenuity).",
            "Lasting Leather: armature di cuoio per tutti gli 8 slot e il set epico Silvermoon Agent's.",
            "Safeguarding Scales: armature di maglia per tutti gli 8 slot e il set epico Farstrider's.",
            "Flawless Fortes: kit per armature, attrezzi e accessori per altri artigiani, reagenti opzionali.",
        },
        unlock = "Le specializzazioni si aprono a 25, 50, 60 e 75.",
    },
    blacksmithing = {
        trainer = "Bemarrin (Silvermoon City); flux e martello dal venditore accanto",
        phases = {
            { 1, 15, "Fondi il minerale di rame in lingotti (Refulgent Copper Ingot) e crea le prime ricette." },
            { 15, 50, "Crea una volta ognuna delle 28 ricette del trainer (filtro 'First Craft Bonus'): bastano ad arrivare a 50." },
            { 50, 70, "Sterling Alloy: verde negli ultimi 10 punti, quindi qualche creazione in piu'." },
            { 70, 100, "Equipaggiamento da professione raro (specializzazione Craftsmithing, 1 punto, giallo a 90 e verde a 95) oppure epico (3 punti, arancione fino a 100; ricette a 150 Moxie, serve Fused Vitality che arriva a tempo), oppure ordini di lavoro per armi e armature epiche (3 punti)." },
        },
        specs = {
            "Armorsmithing: armature a piastre per tutti i 9 slot. Rami: Articulating (vita, polsi, mani), Sculpted (elmo, spalle, piedi), Large Plate (petto, gambe, scudi).",
            "Weaponsmithing: tutte le armi da mischia a una e due mani (spade, asce, mazze, pugnali, armi ad asta, glaive) e le pietre per armi.",
            "Craftsmithing: attrezzi per le altre professioni e Tool Stones.",
            "The Old Ways: statistiche di creazione e leghe (Alloys).",
        },
        unlock = "Prima specializzazione a 25.",
    },
    tailoring = {
        trainer = "Galana (Silvermoon City); filo dal venditore accanto",
        phases = {
            { 1, 25, "Bright Linen Bolt: tienili tutti (circa 66), servono dopo per le armature e gli Imbued Bolt." },
            { 25, 40, "Imbued Bright Linen Bolt." },
            { 40, 50, "Crea una volta tutto quello che manca (conoscenza) e alcune Courtly Shoulders." },
            { 50, 100, "Lento e redditizio: 5 punti conoscenza in Nimble Needlework per il cooldown giornaliero di un tessuto, piu' gli ordini dei Patron. Veloce e costoso: Bright Linen Spellthread (50-65) e le ricette successive. Dal 90 servono ricette epiche, spesso tramite ordini dei Patron." },
        },
        specs = {
            "Sin'dorei Finery: armature di stoffa per tutti i 9 slot.",
            "Nimble Needlework: cooldown giornalieri dei tessuti (Arcanoweave, Sunfire Silk) e mantelli, calzari e bracciali abbelliti.",
            "Fabric Specialist: piu' stoffa dai mob delle zone di Midnight.",
            "Fiber Arts: statistiche di creazione.",
        },
        unlock = "Prima specializzazione a 25.",
    },
    jewelcrafting = {
        trainer = "Amin (Silvermoon City); Jeweler's Toolset dal venditore accanto",
        phases = {
            { 1, 14, "Prospetta minerale economico (Midnight Prospecting) e crea Sin'dorei Lens." },
            { 14, 50, "Ogni 5 punti nuove ricette dal trainer: creane una di ognuna (filtro 'First Craft Bonus')." },
            { 50, 65, "Monologuer's Chalice: costa poco, crealo finche' diventa grigio." },
            { 65, 100, "Taglia gli Eversong Diamond (2 punti, arancioni fino a 80; ricette dai dungeon o dall'asta), equipaggiamento da professione, oppure ordini per i gioielli epici (servono Spark)." },
        },
        specs = {
            "Alluring Accessories: anelli, collane e accessori da professione.",
            "Glamorous Gems: gemme di tutti i colori.",
            "Proficient Processor: reagenti, Prospecting e Crushing.",
            "Thoughtful Throughput: statistiche di creazione.",
        },
        unlock = "Prima specializzazione a 25.",
    },
    engineering = {
        trainer = "Danwe (Silvermoon City); Malleable Wireframe e Pile of Junk dal venditore accanto",
        phases = {
            { 1, 16, "Song Gear e Recycling dei materiali economici." },
            { 16, 25, "Crea una volta gli oggetti Evercore (filtro 'First Craft Bonus')." },
            { 25, 45, "Scegli Recycling come prima specializzazione e mettici 10 punti: sblocca la scoperta delle ricette, indispensabile per salire. Poi le prime creazioni." },
            { 45, 80, "Ricicla i materiali piu' economici finche' scopri le ricette Quel'dorei, poi creale (grigie a 80)." },
            { 80, 100, "Decorazioni per la casa scoperte con il Recycling (gialle fino a 92, grigie a 100), equipaggiamento da professione raro (Market Mobility), oppure attrezzi epici tramite ordini." },
        },
        specs = {
            "Combat Analytics: occhiali, bracciali, stivali e pistole: tutto l'equipaggiamento da combattimento.",
            "Market Mobility: attrezzi e accessori per Engineering, Tailoring, Jewelcrafting, Fishing e Mining.",
            "Recycling: rese del riciclo, statistiche di creazione e molta abilita'.",
            "Bits and Bots: robot, gadget e oggetti utili.",
        },
        unlock = "Prima specializzazione a 25: per salire conviene Recycling.",
    },
    inscription = {
        trainer = "Zantasia (Silvermoon City)",
        phases = {
            { 1, 20, "Midnight Milling sulle erbe economiche (Tranquility Bloom e le altre)." },
            { 20, 30, "Crea gli inchiostri nell'ordine del trainer." },
            { 30, 45, "A 25 scegli Calm Hands: insegna il Thalassian Treatise on Inscription. Crea una volta tutte le ricette (filtro 'First Craft Bonus') e qualche Treatise." },
            { 45, 100, "Crea Treatise fino a 100: scoprirai anche quelli delle altre professioni (10 in tutto), da creare una volta. Gli ultimi punti si possono fare con ordini per armi (3 punti)." },
        },
        specs = {
            "Blueprints: bastoni, off-hand e archi, piu' attrezzi per Cooking, Alchemy e Inscription.",
            "Calm Hands: statistiche di creazione, la ricetta del Treatise e un punto in piu' dal Treatise settimanale.",
            "Perfected Products: qualita' di inchiostri, cifrari, missive, contratti e rune Vantus.",
            "Darkmoon Curiosity: carte e monili Darkmoon.",
        },
        unlock = "Prima specializzazione a 25: per salire conviene Calm Hands.",
    },
    alchemy = {
        trainer = "Camberon (Silvermoon City); fiale dal venditore Melaris accanto",
        phases = {
            { 1, 20, "Silvermoon Health Potion, poi Recycle Potions sulle pozioni appena create." },
            { 20, 27, "Usa il Camberon's Cauldron accanto al trainer per sbloccare ricette con il Moxie, poi le prime creazioni (crea la Primal Philosopher's Stone prima delle trasmutazioni)." },
            { 27, 50, "Entropic Extract e Silvermoon Health Potion." },
            { 50, 100, "Light's Potential (dal Cauldron, 50 Moxie): circa 80 creazioni fino a 100. In alternativa flask (2 punti fino a 90) o trasmutazioni; pozioni e trasmutazioni diventano gialle a 80 e verdi a 90." },
        },
        specs = {
            "Fluent in Flasks: flask e fiale, bonus di durata dei flask e calderone dei flask.",
            "Potion Prowess: pozioni (rami Void e Light) e calderone delle pozioni.",
            "Transmutation Authority: trasmutazioni, conversione dei materiali e il monile Alchemist Stone.",
            "Alchemical Mastery: statistiche di creazione.",
        },
        unlock = "Prima specializzazione a 25.",
    },
    enchanting = {
        trainer = "Dolothos (Silvermoon City); Vellum e Refulgent Copper Rod dal venditore Lyna accanto",
        phases = {
            { 1, 25, "Disincanta l'equipaggiamento che non usi (da' punti fino a 25), crea Runed Refulgent Copper Rod e disincantale." },
            { 25, 55, "Crea una volta ogni incantamento (mettili su Enchanting Vellum per venderli); tra 40 e 52 Thalassian Spellweaver's Wand da' 3 punti. Le Gleeful Glamours, da un altro trainer, valgono 24 punti conoscenza come prime creazioni." },
            { 55, 62, "Enchant Ring - Amani Mastery (gialla: qualcuna in piu')." },
            { 62, 90, "Incantamenti per elmo, arma e spalle (arancioni fino a 90)." },
            { 90, 100, "Solo gli incantamenti per arma restano arancioni: uno si impara dal trainer." },
        },
        specs = {
            "Elevating Equipment: tutti gli incantamenti per equipaggiamento e attrezzi.",
            "Transitories, Tonics, and Tools: oli di mana, bacchette, verghe e illusioni.",
            "Disenchanting Delegate: materiali migliori dal disincanto.",
            "Spellbound Shatterer: statistiche di creazione.",
        },
        unlock = "Tre specializzazioni entro 60, la quarta a 75: non serve sceglierle subito.",
    },
    herbalism = {
        trainer = "Botanist Nathera (Silvermoon City)",
        phases = {
            { 1, 30, "Raccogli tutto: quasi ogni erba da' punti." },
            { 30, 60, "Sanguithorn, Azeroot, Argentleaf e Mana Lily (gialle da 30, grigie a 60), piu' le varianti Lush e Infused." },
            { 60, 100, "Solo le erbe Lush e Infused danno punti: compaiono a caso al posto di quelle normali, continua a raccogliere. Inizia da Eversong Woods (terreno semplice, pochi mob)." },
        },
        tips = "La prima raccolta di ogni nuovo tipo di erba da' un punto conoscenza.",
    },
    mining = {
        trainer = "Belil (Silvermoon City)",
        phases = {
            { 1, 30, "Estrai tutto: quasi ogni giacimento da' punti." },
            { 30, 60, "I giacimenti normali sono gialli da 30 e grigi a 60; danno punti anche i Rich, i Seam e gli Infused." },
            { 60, 100, "Solo Rich, Seam e Infused danno punti: compaiono a caso al posto dei normali. Inizia da Eversong Woods." },
        },
        tips = "La prima estrazione di ogni nuovo tipo di giacimento da' un punto conoscenza.",
    },
    skinning = {
        trainer = "Tyn (Silvermoon City)",
        phases = {
            { 1, 100, "Scuoia tutte le bestie che uccidi. Le High Value Beast (icona del coltello sulla minimappa) danno molto piu' cuoio; i Diffuser lanciati sui mob danno Mote; le esche di zona (specializzazione Talented Tracker) richiamano le bestie rinomate." },
        },
        tips = "Fonti settimanali: missione del trainer e drop durante la scuoiatura (con recupero se salti settimane).",
    },
    knowledge = {
        "Prime creazioni: ogni ricetta creata per la prima volta da' 1 punto conoscenza (filtro 'First Craft Bonus').",
        "Tesori: 8 per professione, 3 punti ciascuno (24 in tutto).",
        "Libro della reputazione: una delle quattro fazioni vende un libro da 10 punti (750 Voidlight Marl e 75 Artisan's Moxie), una sola volta.",
        "Ogni settimana: ordini dei Patron (la fonte principale), missione del trainer (3 ordini = 2-3 punti; per Blacksmithing, Leatherworking e Jewelcrafting prima serve la catena 'Crafters Needed' di Captain Flaresworn), due oggetti dai tesori delle zone (circa 4 punti) e il Treatise di Inscription (1 punto, va chiesto con un ordine pubblico).",
        "Ogni mese: missione della Darkmoon Faire (3 punti e 2 di abilita').",
        "Enchanting: al posto della missione degli ordini, punti dal disincanto (circa 9 a settimana). Raccolta: drop settimanali con recupero automatico.",
        "Patch 12.1: Theremis, nel Bazaar di Silvermoon vicino al tavolo degli ordini, azzera una volta per professione i punti spesi.",
    },
}

G.en = {
    leatherworking = {
        trainer = "Talmar (Silvermoon City)",
        phases = {
            { 1, 7, "Craft the two starting recipes once, then visit the trainer." },
            { 7, 60, "The trainer teaches new recipes every 5-10 points: learn them and craft each once ('First Craft Bonus' filter). With the last batch at 50 you end up around 61." },
            { 60, 91, "Craft one of the mid-level recipes (orange to 80, yellow to 90): about 35 crafts. The list below picks the cheapest." },
            { 91, 100, "The last 9: epic armor, also through crafting orders (3 points each, orange to 100). Epic recipes come from specializations, vendors and drops." },
        },
        specs = {
            "Learned Leatherworker: crafting stats (Multicraft, Resourcefulness, Ingenuity).",
            "Lasting Leather: leather armor for all 8 slots and the epic Silvermoon Agent's set.",
            "Safeguarding Scales: mail armor for all 8 slots and the epic Farstrider's set.",
            "Flawless Fortes: armor kits, tools and accessories for other crafters, optional reagents.",
        },
        unlock = "Specializations open at 25, 50, 60 and 75.",
    },
    blacksmithing = {
        trainer = "Bemarrin (Silvermoon City); flux and hammer from the vendor next to him",
        phases = {
            { 1, 15, "Smelt copper ore into Refulgent Copper Ingots and craft the first recipes." },
            { 15, 50, "Craft each of the 28 trainer recipes once ('First Craft Bonus' filter): that is enough to reach 50." },
            { 50, 70, "Sterling Alloy: green for the last 10 points, so a few extra crafts." },
            { 70, 100, "Rare profession equipment (Craftsmithing, 1 point, yellow at 90 and green at 95) or epic (3 points, orange to 100; recipes for 150 Moxie, needs time-gated Fused Vitality), or crafting orders for epic weapons and armor (3 points)." },
        },
        specs = {
            "Armorsmithing: plate armor for all 9 slots. Branches: Articulating (waist, wrists, hands), Sculpted (helm, shoulders, feet), Large Plate (chest, legs, shields).",
            "Weaponsmithing: every one- and two-handed melee weapon (swords, axes, maces, daggers, polearms, warglaives) and weapon stones.",
            "Craftsmithing: tools for the other professions and Tool Stones.",
            "The Old Ways: crafting stats and Alloys.",
        },
        unlock = "First specialization at 25.",
    },
    tailoring = {
        trainer = "Galana (Silvermoon City); thread from the vendor next to her",
        phases = {
            { 1, 25, "Bright Linen Bolts: keep all of them (about 66), you need them later for armor and Imbued Bolts." },
            { 25, 40, "Imbued Bright Linen Bolts." },
            { 40, 50, "Craft everything you have not made yet once (knowledge) and a few Courtly Shoulders." },
            { 50, 100, "Slow and profitable: 5 knowledge points in Nimble Needlework for a daily bolt cooldown, plus Patron orders. Fast and expensive: Bright Linen Spellthread (50-65) and the following recipes. From 90 you need epic recipes, often through Patron orders." },
        },
        specs = {
            "Sin'dorei Finery: cloth armor for all 9 slots.",
            "Nimble Needlework: daily bolt cooldowns (Arcanoweave, Sunfire Silk) and embellished cloaks, treads and bracers.",
            "Fabric Specialist: more cloth from mobs in the Midnight zones.",
            "Fiber Arts: crafting stats.",
        },
        unlock = "First specialization at 25.",
    },
    jewelcrafting = {
        trainer = "Amin (Silvermoon City); Jeweler's Toolset from the vendor next to him",
        phases = {
            { 1, 14, "Prospect cheap ore (Midnight Prospecting) and craft Sin'dorei Lenses." },
            { 14, 50, "New trainer recipes every 5 points: craft one of each ('First Craft Bonus' filter)." },
            { 50, 65, "Monologuer's Chalice: cheap, craft it until it turns grey." },
            { 65, 100, "Cut Eversong Diamonds (2 points, orange to 80; recipes from dungeons or the auction house), profession equipment, or orders for epic jewelry (needs Sparks)." },
        },
        specs = {
            "Alluring Accessories: rings, necklaces and profession accessories.",
            "Glamorous Gems: gems of every color.",
            "Proficient Processor: reagents, Prospecting and Crushing.",
            "Thoughtful Throughput: crafting stats.",
        },
        unlock = "First specialization at 25.",
    },
    engineering = {
        trainer = "Danwe (Silvermoon City); Malleable Wireframe and Pile of Junk from the vendor next to him",
        phases = {
            { 1, 16, "Song Gears and Recycling of cheap materials." },
            { 16, 25, "Craft the Evercore items once ('First Craft Bonus' filter)." },
            { 25, 45, "Pick Recycling as your first specialization and put 10 points in it: it unlocks recipe discovery, which you need to level. Then the first crafts." },
            { 45, 80, "Recycle the cheapest materials until you discover the Quel'dorei recipes, then craft them (grey at 80)." },
            { 80, 100, "Housing decor discovered through Recycling (yellow to 92, grey at 100), rare profession equipment (Market Mobility), or epic tools through orders." },
        },
        specs = {
            "Combat Analytics: goggles, bracers, boots and guns: all the combat gear.",
            "Market Mobility: tools and accessories for Engineering, Tailoring, Jewelcrafting, Fishing and Mining.",
            "Recycling: recycling yield, crafting stats and a lot of skill.",
            "Bits and Bots: bots, gadgets and utility items.",
        },
        unlock = "First specialization at 25: Recycling is the one for leveling.",
    },
    inscription = {
        trainer = "Zantasia (Silvermoon City)",
        phases = {
            { 1, 20, "Midnight Milling on cheap herbs (Tranquility Bloom and the others)." },
            { 20, 30, "Craft the inks in the trainer's order." },
            { 30, 45, "At 25 pick Calm Hands: it teaches the Thalassian Treatise on Inscription. Craft every recipe once ('First Craft Bonus' filter) and a few Treatises." },
            { 45, 100, "Craft Treatises up to 100: you will also discover the other professions' ones (10 in total), craft each once. The last points can come from weapon orders (3 points)." },
        },
        specs = {
            "Blueprints: staves, off-hands and bows, plus tools for Cooking, Alchemy and Inscription.",
            "Calm Hands: crafting stats, the Treatise recipe and one extra point from the weekly Treatise.",
            "Perfected Products: quality of inks, ciphers, missives, contracts and Vantus runes.",
            "Darkmoon Curiosity: Darkmoon cards and trinkets.",
        },
        unlock = "First specialization at 25: Calm Hands is the one for leveling.",
    },
    alchemy = {
        trainer = "Camberon (Silvermoon City); vials from the vendor Melaris next to him",
        phases = {
            { 1, 20, "Silvermoon Health Potions, then Recycle Potions on the potions you just made." },
            { 20, 27, "Use Camberon's Cauldron next to the trainer to unlock recipes with Moxie, then the first crafts (make the Primal Philosopher's Stone before transmutes)." },
            { 27, 50, "Entropic Extract and Silvermoon Health Potions." },
            { 50, 100, "Light's Potential (from the Cauldron, 50 Moxie): about 80 crafts up to 100. Otherwise flasks (2 points up to 90) or transmutes; potions and transmutes turn yellow at 80 and green at 90." },
        },
        specs = {
            "Fluent in Flasks: flasks and phials, flask duration bonus and the flask cauldron.",
            "Potion Prowess: potions (Void and Light branches) and the potion cauldron.",
            "Transmutation Authority: transmutes, material conversions and the Alchemist Stone trinket.",
            "Alchemical Mastery: crafting stats.",
        },
        unlock = "First specialization at 25.",
    },
    enchanting = {
        trainer = "Dolothos (Silvermoon City); Vellum and Refulgent Copper Rods from the vendor Lyna next to him",
        phases = {
            { 1, 25, "Disenchant the gear you do not use (gives points up to 25), craft Runed Refulgent Copper Rods and disenchant them." },
            { 25, 55, "Craft each enchant once (put them on Enchanting Vellum to sell them); between 40 and 52 the Thalassian Spellweaver's Wand gives 3 points. The Gleeful Glamours, from another trainer, are worth 24 knowledge points as first crafts." },
            { 55, 62, "Enchant Ring - Amani Mastery (yellow: a few extra)." },
            { 62, 90, "Helm, weapon and shoulder enchants (orange up to 90)." },
            { 90, 100, "Only weapon enchants stay orange: one comes from the trainer." },
        },
        specs = {
            "Elevating Equipment: every enchant for gear and tools.",
            "Transitories, Tonics, and Tools: mana oils, wands, rods and illusions.",
            "Disenchanting Delegate: better materials from disenchanting.",
            "Spellbound Shatterer: crafting stats.",
        },
        unlock = "Three specializations by 60, the fourth at 75: no need to pick right away.",
    },
    herbalism = {
        trainer = "Botanist Nathera (Silvermoon City)",
        phases = {
            { 1, 30, "Gather everything: almost every herb gives points." },
            { 30, 60, "Sanguithorn, Azeroot, Argentleaf and Mana Lily (yellow from 30, grey at 60), plus the Lush and Infused variants." },
            { 60, 100, "Only Lush and Infused herbs give points: they replace normal herbs at random, keep gathering. Start in Eversong Woods (easy terrain, few mobs)." },
        },
        tips = "The first time you gather each new herb type you get a knowledge point.",
    },
    mining = {
        trainer = "Belil (Silvermoon City)",
        phases = {
            { 1, 30, "Mine everything: almost every deposit gives points." },
            { 30, 60, "Normal deposits are yellow from 30 and grey at 60; Rich, Seam and Infused deposits also give points." },
            { 60, 100, "Only Rich, Seam and Infused deposits give points: they replace normal ones at random. Start in Eversong Woods." },
        },
        tips = "The first time you mine each new deposit type you get a knowledge point.",
    },
    skinning = {
        trainer = "Tyn (Silvermoon City)",
        phases = {
            { 1, 100, "Skin every beast you kill. High Value Beasts (knife icon on the minimap) give much more leather; Diffusers thrown at mobs give Motes; zone lures (Talented Tracker specialization) summon renowned beasts." },
        },
        tips = "Weekly sources: trainer quest and drops while skinning (with catch-up if you skip weeks).",
    },
    knowledge = {
        "First crafts: every recipe crafted for the first time gives 1 knowledge point ('First Craft Bonus' filter).",
        "Treasures: 8 per profession, 3 points each (24 in total).",
        "Renown book: one of the four factions sells a 10-point book (750 Voidlight Marl and 75 Artisan's Moxie), once.",
        "Every week: Patron orders (the main source), the trainer quest (3 orders = 2-3 points; Blacksmithing, Leatherworking and Jewelcrafting first need Captain Flaresworn's 'Crafters Needed' questline), two items from zone treasures (about 4 points) and the Inscription Treatise (1 point, request it with a public order).",
        "Every month: the Darkmoon Faire quest (3 points and 2 skill).",
        "Enchanting: instead of the orders quest, points from disenchanting (about 9 a week). Gathering: weekly drops with automatic catch-up.",
        "Patch 12.1: Theremis, in the Silvermoon Bazaar near the crafting order table, refunds your spent points once per profession.",
    },
}

---------------------------------------------------------------------------
-- Specializzazione consigliata per l'equipaggiamento del personaggio
---------------------------------------------------------------------------
-- Restituisce un elenco di righe (chiavi di localizzazione + argomenti).
function G:Advice(key, class, specID)
    local armor = self.ARMOR[class]
    local hunterRanged = class == "HUNTER" and specID ~= 255
    local melee = self.MELEE[class] or (class == "HUNTER" and specID == 255)
    local out = {}
    local function add(k) out[#out + 1] = k end
    if key == "leatherworking" then
        if armor == "mail" then add("ADV_LW_MAIL")
        elseif armor == "leather" then add("ADV_LW_LEATHER")
        else add("ADV_LW_OTHER") end
    elseif key == "blacksmithing" then
        if melee then add("ADV_BS_WEAPON") end
        if armor == "plate" then add("ADV_BS_PLATE") end
        if #out == 0 then add("ADV_BS_OTHER") end
    elseif key == "tailoring" then
        if armor == "cloth" then add("ADV_TAILOR_CLOTH") end
        add("ADV_TAILOR_CLOAK")
    elseif key == "jewelcrafting" then
        add("ADV_JC")
    elseif key == "engineering" then
        add(hunterRanged and "ADV_ENG_GUN" or "ADV_ENG")
    elseif key == "inscription" then
        if hunterRanged then add("ADV_INSC_BOW")
        elseif self.STAFF[class] then add("ADV_INSC_STAFF")
        else add("ADV_INSC_OTHER") end
    elseif key == "alchemy" then
        add("ADV_ALCH")
    elseif key == "enchanting" then
        add("ADV_ENCH")
    end
    return out
end

function G:Text(key)
    local t = self[ns.lang] or self.it
    return t[key] or self.it[key]
end
