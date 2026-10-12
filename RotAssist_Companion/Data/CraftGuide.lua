-- RotAssist Companion - CraftGuide
-- Guida statica alle professioni di Midnight: fasi per salire da 1 a 100 nel
-- minor tempo, fonti di conoscenza e specializzazioni (con quella consigliata
-- per l'equipaggiamento del tuo personaggio).
--
-- Testi scritti per questo addon a partire da guide pubbliche sulle
-- professioni di Midnight (ottobre 2026, patch 12.1). La parte "cosa creare
-- adesso e cosa comprare" non e' qui: la calcola Data\Craft.lua dalle ricette
-- che conosci (finestra della professione). Le build sono in CraftBuilds.lua.

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
-- Professioni secondarie (Cucina, Pesca): niente specializzazioni ne' conoscenza
G.SECONDARY = { [185] = true, [356] = true }
-- Senza la sezione "cosa creare": raccolta e Pesca
G.NO_MAKE = { [182] = true, [186] = true, [393] = true, [356] = true }

-- Armatura per classe (UnitClass, secondo valore)
G.ARMOR = {
    MAGE = "cloth", PRIEST = "cloth", WARLOCK = "cloth",
    ROGUE = "leather", DRUID = "leather", MONK = "leather", DEMONHUNTER = "leather",
    HUNTER = "mail", SHAMAN = "mail", EVOKER = "mail",
    WARRIOR = "plate", PALADIN = "plate", DEATHKNIGHT = "plate",
}

-- Armi usate da ogni specializzazione di classe. Chi le crea in Midnight:
-- Blacksmithing (Weaponsmithing: Hafted Weapons = asce, mazze, armi ad asta;
-- Blades = spade, pugnali, warglaive; anche con Intelletto; scudi nel ramo
-- Large Plate di Armorsmithing), Inscription (bastoni, off-hand, archi),
-- Engineering (fucili).
--   TWOHAND   arma a due mani con Forza
--   DUAL      due armi, a due mani o a una mano secondo i talenti
--   SHIELD    arma a una mano e scudo (tank)
--   DAGGERS   pugnali
--   ONEHAND   armi a una mano con Agilita' (asce, mazze, spade, pugni)
--   GLAIVES   warglaive
--   POLE      bastone o arma ad asta con Agilita'
--   RANGED    arco, fucile o balestra
--   CASTER    bastone, oppure arma a una mano con Intelletto e off-hand
--   CASTER_SH arma a una mano con Intelletto e scudo (o off-hand)
G.WIELD = {
    [71] = "TWOHAND", [72] = "DUAL", [73] = "SHIELD",
    [65] = "CASTER_SH", [66] = "SHIELD", [70] = "TWOHAND",
    [250] = "TWOHAND", [251] = "DUAL", [252] = "TWOHAND",
    [259] = "DAGGERS", [260] = "ONEHAND", [261] = "DAGGERS",
    [577] = "GLAIVES", [581] = "GLAIVES", [1480] = "GLAIVES",
    [268] = "POLE", [269] = "POLE", [270] = "CASTER",
    [102] = "CASTER", [103] = "POLE", [104] = "POLE", [105] = "CASTER",
    [253] = "RANGED", [254] = "RANGED", [255] = "POLE",
    [62] = "CASTER", [63] = "CASTER", [64] = "CASTER",
    [256] = "CASTER", [257] = "CASTER", [258] = "CASTER",
    [262] = "CASTER_SH", [263] = "ONEHAND", [264] = "CASTER_SH",
    [265] = "CASTER", [266] = "CASTER", [267] = "CASTER",
    [1467] = "CASTER", [1468] = "CASTER", [1473] = "CASTER",
}
-- Senza specializzazione (personaggi di basso livello): la piu' comune della classe
G.CLASS_WIELD = {
    WARRIOR = "TWOHAND", PALADIN = "TWOHAND", DEATHKNIGHT = "TWOHAND", ROGUE = "DAGGERS",
    DEMONHUNTER = "GLAIVES", MONK = "POLE", DRUID = "CASTER", HUNTER = "RANGED",
    MAGE = "CASTER", PRIEST = "CASTER", SHAMAN = "CASTER_SH", WARLOCK = "CASTER", EVOKER = "CASTER",
}
-- Consiglio di Blacksmithing per tipo di arma
local BS_WEAPON = {
    TWOHAND = "ADV_BS_2H", DUAL = "ADV_BS_DUAL", SHIELD = "ADV_BS_SHIELD", DAGGERS = "ADV_BS_DAGGERS",
    ONEHAND = "ADV_BS_1H", GLAIVES = "ADV_BS_GLAIVES", POLE = "ADV_BS_POLE",
    CASTER = "ADV_BS_CASTER", CASTER_SH = "ADV_BS_CASTER",
}
-- Consiglio di Inscription per tipo di arma
local INSC_WEAPON = {
    RANGED = "ADV_INSC_BOW", CASTER = "ADV_INSC_STAFF", CASTER_SH = "ADV_INSC_OFFHAND", POLE = "ADV_INSC_AGI",
}

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
    -- Cucina e Pesca: professioni secondarie, senza specializzazioni ne' conoscenza
    cooking = {
        trainer = "Sylann (Wayfarer's Rest, la locanda di Silvermoon City); materiali base dal venditore accanto",
        phases = {
            { 1, 25, "Spiced Biscuits con burro e spezie del venditore: circa 50 creazioni, finche' la ricetta diventa verde." },
            { 25, 35, "Nuove ricette dal trainer: circa 10 Felberry Figs. Plant Protein dall'asta, il resto dal venditore." },
            { 35, 100, "A 35 si sblocca Hearty: alterna Spiced Biscuits e la loro versione Hearty (o Hearty Felberry Figs). Piu' sali, piu' porzioni rende ogni creazione, quindi conviene alternare invece di creare tutto subito. Gli ultimi 25 punti sono verdi: servono molte creazioni, ma bastano i materiali del venditore." },
        },
        tips = "Cucina e Pesca non hanno specializzazioni ne' punti conoscenza. Darkmoon Faire: una missione di Stamp Thunderhorn da' 2 punti, tienila per ultima.",
        extra = {
            title = "Cosa cucinare",
            lines = {
                "Banchetti (Stamina per tutto il gruppo): Blooming Feast e Quel'dorei Medley danno la statistica secondaria piu' alta, Harandar Celebration e Silvermoon Parade la statistica primaria.",
                "Cibo migliore: Royal Roast e Impossibly Royal Roast (statistica primaria), Champion's Bento e Flora Frenzy (secondaria piu' alta). Flora Frenzy si impara con la missione Gomphusta a Harandar, le altre ricette dal trainer.",
                "Cibo economico: Arcano Cutlets e simili danno una sola secondaria (Critico, Celerita', Maestria o Versatilita') e costano meno.",
                "Il pesce va prima lavorato in Thalassian Fillet: con Pesca hai la materia prima gratis.",
                "Attrezzi: matterello da Inscription e cappello da cuoco da Tailoring. Verdi e blu all'asta, gli epici solo su ordinazione (vincolati al personaggio).",
            },
        },
    },
    fishing = {
        trainer = "Drathen, vicino al laghetto al centro di Silvermoon City; dal venditore accanto l'Angler's Guide, che mostra i banchi sulla minimappa",
        phases = {
            { 1, 75, "Acqua libera a Eversong Woods o a Silvermoon City: a questo livello i banchi non conviene cercarli." },
            { 75, 150, "Ancora Eversong Woods. Resta in una zona finche' peschi oggetti grigi solo di rado: i livelli consigliati delle zone sono ottimisti." },
            { 150, 225, "Zul'Aman, oppure le zone precedenti. Da qui i banchi rendono piu' dell'acqua libera." },
            { 225, 300, "Harandar, oppure le zone precedenti. Eversong ha i banchi piu' vicini tra loro, lungo i fiumi centrali." },
        },
        tips = "Pesca arriva a 300 e non ha specializzazioni ne' punti conoscenza. Punti extra: Abyss Angler's Fishlog (+3) dal tesoro Bait and Tackle all'ingresso di una grotta di Zul'Aman (circa 21.1, 67.1), una volta per personaggio ma spedibile agli alt; missione della Darkmoon Faire (+3, tienila per ultima); An Angler's Deep Dive (+10) dai forzieri Patient Treasure.",
        extra = {
            title = "Cosa pescare e attrezzatura",
            lines = {
                "Banchetti: Eversong Trout e Restored Songfish (Quel'dorei Medley), Lynxfish e Arcane Wyrmfish (Silvermoon Parade).",
                "Esche per Skinning: Arcane Wyrmfish, Lynxfish, Gore Guppy, Fungalskin Pike, Tender Lumifin, Ominous Octopus e Null Voidfish. Probabilmente i pesci che valgono di piu' all'asta.",
                "Banchi del tesoro (Careless Cargo, Lost Treasures): compaiono ovunque e danno le ricette delle esche, che per 30 minuti aumentano la probabilita' di un pesce preciso.",
                "Canna: Farstrider Hobbyist Rod e Sin'dorei Angler's Rod si comprano all'asta; l'epica Sin'dorei Reeler's Rod la crea un ingegnere su ordinazione (serve Fused Vitality).",
                "Midnight Angler's Grand Line raddoppia i tesori pescati: si crea con i frammenti Bloomline e Glimmerline pescati, senza abilita' di professione.",
                "Amani Angler's Ward: per 30 minuti niente Blood Hunter Spirits.",
                "Voidstorm ha poca acqua libera: due punti in acque profonde intorno a 35.9, 47.1 e 35.2, 46.0.",
            },
        },
    },
    -- fonti dei punti conoscenza: { fonte, punti, quando }
    knowledge = {
        { "Prime creazioni", "1 ciascuna", "una volta per ricetta" },
        { "Tesori della professione", "3 x 8", "una volta" },
        { "Libro della reputazione", "10", "una volta" },
        { "Ordini dei Patron", "circa 12", "ogni settimana" },
        { "Missione del trainer", "2-3", "ogni settimana" },
        { "Oggetti dai tesori di zona", "circa 4", "ogni settimana" },
        { "Treatise (Inscription)", "1", "ogni settimana" },
        { "Darkmoon Faire", "3 (+2 abilita')", "ogni mese" },
    },
    knowledgeNotes = {
        "Missione del trainer: per Blacksmithing, Leatherworking e Jewelcrafting prima serve la catena 'Crafters Needed' di Captain Flaresworn.",
        "Treatise: e' legato al personaggio, quindi va chiesto con un ordine pubblico, oppure creato da un tuo personaggio con Inscription.",
        "Enchanting: invece della missione degli ordini, punti dal disincanto (circa 9 a settimana). Herbalism e Mining: 1 punto per ogni nuovo tipo di nodo raccolto; per la raccolta i drop settimanali recuperano le settimane perse.",
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
    -- Cooking and Fishing: secondary professions, no specializations or knowledge
    cooking = {
        trainer = "Sylann (Wayfarer's Rest, the inn in Silvermoon City); basic materials from the vendor next to them",
        phases = {
            { 1, 25, "Spiced Biscuits with butter and spices from the vendor: about 50 crafts, until the recipe turns green." },
            { 25, 35, "New recipes from the trainer: about 10 Felberry Figs. Plant Protein from the auction house, the rest from the vendor." },
            { 35, 100, "Hearty unlocks at 35: alternate Spiced Biscuits and their Hearty version (or Hearty Felberry Figs). The higher your skill, the more servings each craft gives, so alternate instead of crafting everything at once. The last 25 points are green: many crafts, but vendor materials are enough." },
        },
        tips = "Cooking and Fishing have no specializations or knowledge points. Darkmoon Faire: a quest from Stamp Thunderhorn gives 2 points, keep it for last.",
        extra = {
            title = "What to cook",
            lines = {
                "Feasts (Stamina for the whole group): Blooming Feast and Quel'dorei Medley give your highest secondary stat, Harandar Celebration and Silvermoon Parade your primary stat.",
                "Best food: Royal Roast and Impossibly Royal Roast (primary stat), Champion's Bento and Flora Frenzy (highest secondary). Flora Frenzy comes from the Gomphusta quest in Harandar, the other recipes from the trainer.",
                "Cheap food: Arcano Cutlets and similar dishes give a single secondary (Crit, Haste, Mastery or Versatility) for less.",
                "Fish must first be processed into Thalassian Fillet: with Fishing you get the raw material for free.",
                "Tools: rolling pin from Inscription and chef's hat from Tailoring. Green and blue ones on the auction house, epic ones only through crafting orders (soulbound).",
            },
        },
    },
    fishing = {
        trainer = "Drathen, by the pond in the center of Silvermoon City; the vendor next to them sells the Angler's Guide, which shows pools on the minimap",
        phases = {
            { 1, 75, "Open water in Eversong Woods or Silvermoon City: at this level pools are not worth looking for." },
            { 75, 150, "Still Eversong Woods. Stay in a zone until you rarely fish grey items: the zones' recommended levels are optimistic." },
            { 150, 225, "Zul'Aman, or the earlier zones. From here pools are better than open water." },
            { 225, 300, "Harandar, or the earlier zones. Eversong has the pools closest together, along the central rivers." },
        },
        tips = "Fishing goes to 300 and has no specializations or knowledge points. Extra points: Abyss Angler's Fishlog (+3) from the Bait and Tackle treasure at a cave entrance in Zul'Aman (about 21.1, 67.1), once per character but mailable to alts; the Darkmoon Faire quest (+3, keep it for last); An Angler's Deep Dive (+10) from Patient Treasure chests.",
        extra = {
            title = "What to fish and gear",
            lines = {
                "Feasts: Eversong Trout and Restored Songfish (Quel'dorei Medley), Lynxfish and Arcane Wyrmfish (Silvermoon Parade).",
                "Skinning lures: Arcane Wyrmfish, Lynxfish, Gore Guppy, Fungalskin Pike, Tender Lumifin, Ominous Octopus and Null Voidfish. Likely the most valuable fish on the auction house.",
                "Treasure pools (Careless Cargo, Lost Treasures): they appear anywhere and give lure recipes, which raise the chance of a specific fish for 30 minutes.",
                "Rod: Farstrider Hobbyist Rod and Sin'dorei Angler's Rod are on the auction house; the epic Sin'dorei Reeler's Rod is made by an engineer through a crafting order (needs Fused Vitality).",
                "Midnight Angler's Grand Line doubles fished treasure: craft it from fished Bloomline and Glimmerline fragments, no profession skill needed.",
                "Amani Angler's Ward: no Blood Hunter Spirits for 30 minutes.",
                "Voidstorm has little open water: two deep-water spots around 35.9, 47.1 and 35.2, 46.0.",
            },
        },
    },
    knowledge = {
        { "First crafts", "1 each", "once per recipe" },
        { "Profession treasures", "3 x 8", "once" },
        { "Renown book", "10", "once" },
        { "Patron orders", "about 12", "every week" },
        { "Trainer quest", "2-3", "every week" },
        { "Zone treasure items", "about 4", "every week" },
        { "Treatise (Inscription)", "1", "every week" },
        { "Darkmoon Faire", "3 (+2 skill)", "every month" },
    },
    knowledgeNotes = {
        "Trainer quest: Blacksmithing, Leatherworking and Jewelcrafting first need Captain Flaresworn's 'Crafters Needed' questline.",
        "Treatise: it is soulbound, so request it with a public order, or craft it on one of your characters with Inscription.",
        "Enchanting: instead of the orders quest, points from disenchanting (about 9 a week). Herbalism and Mining: 1 point for every new node type gathered; for gathering, weekly drops catch up on missed weeks.",
        "Patch 12.1: Theremis, in the Silvermoon Bazaar near the crafting order table, refunds your spent points once per profession.",
    },
}

---------------------------------------------------------------------------
-- Specializzazione consigliata per l'equipaggiamento del personaggio
---------------------------------------------------------------------------
-- Restituisce le chiavi di localizzazione dei consigli e l'indice della build
-- (CraftBuilds.lua) da mostrare per prima.
function G:Advice(key, class, specID)
    local armor = self.ARMOR[class]
    local wield = (specID and self.WIELD[specID]) or self.CLASS_WIELD[class]
    local out, build = {}, 1
    local function add(k) out[#out + 1] = k end
    if key == "leatherworking" then
        if armor == "mail" then add("ADV_LW_MAIL")
        elseif armor == "leather" then add("ADV_LW_LEATHER")
        else add("ADV_LW_OTHER"); build = 3 end
    elseif key == "blacksmithing" then
        local weapon = wield and BS_WEAPON[wield]
        if weapon then add(weapon) end
        if armor == "plate" then add("ADV_BS_PLATE"); if not weapon then build = 2 end end
        if #out == 0 then add("ADV_BS_OTHER"); build = 3 end
    elseif key == "tailoring" then
        if armor == "cloth" then add("ADV_TAILOR_CLOTH"); build = 4 end
        add("ADV_TAILOR_CLOAK")
    elseif key == "jewelcrafting" then
        add("ADV_JC"); build = 2
    elseif key == "engineering" then
        add(wield == "RANGED" and "ADV_ENG_GUN" or "ADV_ENG")
    elseif key == "inscription" then
        local weapon = wield and INSC_WEAPON[wield]
        if weapon then add(weapon) else add("ADV_INSC_OTHER"); build = 2 end
    elseif key == "alchemy" then
        add("ADV_ALCH"); build = 2
    elseif key == "enchanting" then
        add("ADV_ENCH")
    elseif key == "herbalism" then
        build = (class == "DRUID") and 1 or 2
    end
    return out, build
end

function G:Text(key)
    local t = self[ns.lang] or self.it
    return t[key] or self.it[key]
end
