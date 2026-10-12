-- RotAssist Companion - GoldStrategies
-- Strategie per fare oro in Midnight 12.1 (Season 2), per professione e per
-- profilo:
--   casual   = giocatore occasionale (poche ore a settimana)
--   medium   = giocatore medio (qualche sessione a settimana)
--   hardcore = giocatore assiduo (ogni giorno, piu' personaggi)
--
-- Testi scritti per RotAssist Companion, riassumendo (ottobre 2026):
--  * Icy Veins, "Best Professions to Make Gold in Midnight" (aggiornata per
--    il lancio della Season 2, agosto 2026): fasce S/A/B e consigli
--  * guide pubbliche sulle novita' della 12.1
-- Niente cifre in oro: i prezzi cambiano da reame a reame, quindi si
-- rimanda sempre alla casa d'aste.
--
-- Chiavi delle professioni: skillLine base (GetProfessionInfo).

local _, ns = ...

local S = {}
ns.GoldStrategies = S

-- skillLine -> chiave interna
S.PROFESSIONS = {
    [171] = "alchemy", [164] = "blacksmithing", [333] = "enchanting", [202] = "engineering",
    [182] = "herbalism", [773] = "inscription", [755] = "jewelcrafting", [165] = "leatherworking",
    [186] = "mining", [393] = "skinning", [197] = "tailoring", [185] = "cooking", [356] = "fishing",
}

-- Fascia per fare oro (Icy Veins, Season 2)
S.TIER = {
    it = {
        alchemy = "S con le pozioni, A con i flask", inscription = "S", jewelcrafting = "S", tailoring = "S",
        enchanting = "A", blacksmithing = "A", engineering = "A", leatherworking = "A (equip su ordinazione)",
        mining = "B", herbalism = "B", skinning = "B", cooking = "B", fishing = "B",
    },
    en = {
        alchemy = "S with potions, A with flasks", inscription = "S", jewelcrafting = "S", tailoring = "S",
        enchanting = "A", blacksmithing = "A", engineering = "A", leatherworking = "A (gear on order)",
        mining = "B", herbalism = "B", skinning = "B", cooking = "B", fishing = "B",
    },
}

S.it = {
    general = {
        casual = {
            "Una volta a settimana: ritira la Great Vault e vendi gli oggetti legati all'equip (BoE) che non usi.",
            "Fai le world quest con ricompensa in oro o materiali mentre giochi le altre attivita'.",
            "Vendi grigi e vecchio equipaggiamento: piccolo ma costante.",
        },
        medium = {
            "Abbina una professione di raccolta a una di creazione: rivendi i materiali quando non ti servono.",
            "Usa la Concentrazione ogni 3-4 giorni (si ricarica di 240 al giorno, massimo 1000): non lasciarla piena.",
            "Consumabili: vendi nei giorni di raid del tuo reame (di solito martedi', mercoledi' e domenica) e compra i materiali quando costano meno.",
        },
        hardcore = {
            "Ordini di lavoro: i compensi migliori arrivano a meta'-fine settimana e prima o dopo le serate di raid; tieni la Concentrazione per quei momenti.",
            "Controlla l'andamento dei prezzi (sito The Undermine Exchange) e calcola i margini con CraftSim prima di creare in serie.",
            "Piu' personaggi con professioni diverse: ogni personaggio ha la sua Concentrazione da spendere.",
            "Se hai scelto male la specializzazione, la 12.1 offre un reset unico della conoscenza (Theremis, Bazaar di Silvermoon).",
        },
    },
    alchemy = {
        casual = {
            "Quando la Concentrazione e' piena, crea pozioni partendo da erbe di rango 1: le erbe di rango 2 costano molto di piu', quindi la pozione di qualita' oro rende bene.",
            "Novita' 12.1: Concentrated Silvermoon Health Potion, la nuova pozione di cura migliore per raid e Mitiche+ (ricetta da Jan'sari the Watchful, Coiled Isle, Renown 5 con Zul'jarra's Forces).",
        },
        medium = {
            "Punta sulle pozioni con la build 'Consumabili da vendere': prima Multicraft, poi Resourcefulness; strumento con Multicraft.",
            "I flask oggi rendono meno: gran parte del costo sono materiali senza qualita' (Petrified Root, Nocturnal Lotus), quindi la Concentrazione aiuta poco.",
            "Vendi nei giorni di raid e tieni scorte prima del reset settimanale.",
        },
        hardcore = {
            "Trasmutazioni: il giornaliero Wondrous Synergist (ricarica ridotta a circa 9 ore con Synthesis Synergy) e le trasmutazioni dei Mote con Multicraft.",
            "Altre ricette 12.1: Liquid Luster (pozione di Versatilita', dal venditore Skull of Er'inye nelle Vaults of Atal'Utek) e Alluring Nostrum.",
            "Se hai speso i punti sui flask, valuta il reset unico da Theremis per spostarli sulle pozioni.",
        },
    },
    blacksmithing = {
        casual = { "Build Standard: crea per te armi o armature di rango massimo, senza pagare ordini e mance." },
        medium = { "Season 2: buona domanda di armi e armature create; le armi di solito sono l'upgrade piu' richiesto.",
                   "Casa d'aste: le leghe (Alloys, specializzazione The Old Ways) servono in quasi tutte le ricette di alto livello." },
        hardcore = { "Ordini di lavoro per armi e armature con le Spark: domanda costante per tutta la stagione.",
                     "Novita' 12.1: abbellimento per armi Hunter's Ritual Stone (Construct V'anore, Silvermoon, Preyhunter's Journey rank 2)." },
    },
    enchanting = {
        casual = { "Build Concentrazione: quando e' piena crea un solo incantamento di qualita' alta e vendilo; basta entrare ogni pochi giorni.",
                   "Disincanta l'equipaggiamento che non usi e vendi i materiali." },
        medium = { "Vendi gli incantamenti piu' richiesti (arma, anello, petto; elmo, spalle, stivali) su Enchanting Vellum.",
                   "Oggi rende meno del solito: molti costi sono materiali senza qualita'. Dovrebbe migliorare con i nuovi contenuti di alto livello." },
        hardcore = { "Build Disincanto: i materiali valgono molto a inizio stagione e restano richiesti.",
                     "Novita' 12.1: Enchant Weapon - Rite Of The Hash'ey (Jan'sari the Watchful, Renown 5 con Zul'jarra's Forces)." },
    },
    engineering = {
        casual = { "Crea per te occhiali, bracciali, stivali o pistole (Combat Analytics) invece di comprarli." },
        medium = { "Ordini di lavoro per l'equip da combattimento: buona domanda in Season 2.",
                   "Riciclo: reagenti di qualita' oro per chi crea equip di alto livello, ed Emergency Soul Link." },
        hardcore = { "Attrezzi da professione: rendono soprattutto a inizio stagione, poi la domanda cala.",
                     "Novita' 12.1: abbellimento per pistole Coiled Snake-Eye (drop dalle creature del mondo)." },
    },
    herbalism = {
        casual = { "Raccogli le erbe lungo il percorso delle altre attivita' e vendile in blocco." },
        medium = { "Oggi c'e' molta offerta di erbe: vendi nei giorni di raid, quando gli alchimisti comprano.",
                   "Specializzazione: se non sei druido prima 40 punti in Botany (raccolta in sella), poi 40 in Bountiful Harvests." },
        hardcore = { "Novita' 12.1: Neutralized Venom Clot e Cursebound Globe dai nodi maledetti della Coiled Isle, solo mentre la zona e' maledetta.",
                     "Abbina Mining sullo stesso personaggio, meglio se druido: e' il reddito piu' costante a meta' stagione." },
    },
    inscription = {
        casual = { "Missive: il prodotto con piu' volume, servono a ogni artigiano per gli ordini." },
        medium = { "Build Missive e contratti o Reagenti (inchiostri): prima Calm Hands per Multicraft e Resourcefulness.",
                   "Season 2: bastoni a due mani Intelletto/Agilita' molto richiesti (specializzazione Blueprints)." },
        hardcore = { "Catena completa: macina le erbe, crea pigmenti, inchiostri e prodotti finiti, vendi ogni passaggio con margine.",
                     "Treatise per tutte le professioni: ogni artigiano ne vuole uno a settimana." },
    },
    jewelcrafting = {
        casual = { "Taglia le gemme che usi e vendi quelle in eccesso: ogni pezzo con incastonatura ne ha bisogno." },
        medium = { "Build Taglio delle gemme o Reagenti (Sunglass Vial, Sin'dorei Lens, Kaleidoscopic Prism): domanda costante.",
                   "Season 2: anelli e collane creati molto richiesti (Alluring Accessories)." },
        hardcore = { "Prospezione e frantumazione: gemme e Glimmering Gemdust servono a ogni gioielliere.",
                     "Novita' 12.1: Refine Crystalline Glass e Refine Duskshrouded Stone dal trainer (50), abbellimento Polished Ammolite (drop dal mondo)." },
    },
    leatherworking = {
        casual = { "Build Standard: crea per te i pezzi del tuo tipo di armatura al rango massimo (per la maglia Safeguarding Scales)." },
        medium = { "Season 2: la domanda di equip creato e' alta. Riempi gli ordini personali e pubblici delle armature che sai creare: il cliente porta i materiali, il compenso e' quasi tutto guadagno.",
                   "Casa d'aste: kit per armature e tamburi (Crucial Consumables in Flawless Fortes)." },
        hardcore = { "Build Ordini di lavoro: meglio le armature degli attrezzi (domanda per tutta la stagione), circa uno slot nuovo al rango massimo ogni settimana.",
                     "Novita' 12.1: abbellimento Adorned Fang (drop da The Twin Fangs nella Venomous Abyss): se hai la ricetta, crealo su ordinazione." },
    },
    mining = {
        casual = { "Estrai lungo il percorso e vendi i minerali in blocco." },
        medium = { "Oggi c'e' molta offerta: vendi quando i fabbri e i gioiellieri comprano (inizio stagione, nuove ricette).",
                   "Specializzazione: 40 punti in Meticulous Mining per estrarre in sella, poi 50 in Plentiful Ores." },
        hardcore = { "Novita' 12.1: Neutralized Venom Clot e Cursebound Globe dai nodi maledetti della Coiled Isle.",
                     "Abbina Herbalism sullo stesso personaggio: due materiali a ogni giro." },
    },
    skinning = {
        casual = { "Scuoia cio' che uccidi durante world quest e missioni: e' oro quasi gratis." },
        medium = { "Cerca le High Value Beast (coltello sulla minimappa): danno molto piu' cuoio.",
                   "Build Farming puro: 10 in Thorough Tanning e 40 in Lasting Leather (cuoio) o Superb Scales (scaglie)." },
        hardcore = { "Esche di zona e bestie rinomate (Talented Tracker) per i Majestic Materials, i piu' preziosi.",
                     "I nodi maledetti della Coiled Isle (12.1) possono dare i nuovi materiali anche scuoiando." },
    },
    tailoring = {
        casual = { "Usa ogni giorno i cooldown dei tessuti (Arcanoweave e Sunfire Silk): servono a quasi tutte le ricette di alto livello." },
        medium = { "Build Standard: entrambi i cooldown sbloccati e ricarica ridotta a circa 8 ore e mezza.",
                   "Season 2: equip di stoffa creato molto richiesto (Sin'dorei Finery)." },
        hardcore = { "Build Produzione di tessuti (Multicraft e Resourcefulness) o Raccolta di stoffa se farmi molto nel mondo.",
                     "Novita' 12.1: abbellimento Snakeskin Lining (tesoro Altar of Fangs)." },
    },
    cooking = {
        casual = { "Cucina i piatti che usi e vendi l'eccesso: i margini sono bassi perche' tutti possono cucinare." },
        medium = { "Banchetti per raid: vendi il giorno del reset e prima delle serate di raid.",
                   "Novita' 12.1: banchetti Amani Cornucopia (trainer, 85), Loa's Gathering e Feast of Knowledge." },
        hardcore = { "Abbina Fishing: materia prima tua, margine pieno sul prodotto finito." },
    },
    fishing = {
        casual = { "Pesca mentre aspetti la coda: i pesci si vendono ai cuochi, ma la concorrenza e' alta." },
        medium = { "Pesce per banchetti: domanda costante; le Thalassian Recipe in a Bottle possono insegnare ricette 12.1 da rivendere." },
        hardcore = { "Fornisci i cuochi in quantita' oppure cucina tu stesso per il margine pieno." },
    },
    none = {
        casual = { "Senza professioni: per poche ore a settimana prendi due professioni di raccolta (es. Herbalism + Mining)." },
        medium = { "Senza professioni: oggi rendono di piu' Inscription, Jewelcrafting, Tailoring e Alchemy con le pozioni (Icy Veins, Season 2)." },
        hardcore = { "Senza professioni: una coppia raccolta/creazione per personaggio, coprendo mercati diversi." },
    },
}

S.en = {
    general = {
        casual = {
            "Once a week: claim the Great Vault and sell bind-on-equip (BoE) items you don't need.",
            "Do world quests rewarding gold or materials while you play your usual content.",
            "Sell greys and old gear: small but steady.",
        },
        medium = {
            "Pair a gathering profession with a crafting one: sell the materials you don't use.",
            "Spend Concentration every 3-4 days (it regenerates 240 per day, cap 1000): don't leave it full.",
            "Consumables: sell on your realm's raid days (usually Tuesday, Wednesday and Sunday) and buy materials when they are cheapest.",
        },
        hardcore = {
            "Crafting orders: the best commissions come mid-to-late week and before or after raid nights; save Concentration for those moments.",
            "Check price history (The Undermine Exchange website) and work out margins with CraftSim before mass crafting.",
            "Several characters with different professions: each one has its own Concentration to spend.",
            "If you picked the wrong specialization, 12.1 offers a one-time knowledge reset (Theremis, Silvermoon Bazaar).",
        },
    },
    alchemy = {
        casual = {
            "When Concentration is full, craft potions from rank 1 herbs: rank 2 herbs cost much more, so the gold-quality potion pays off.",
            "New in 12.1: Concentrated Silvermoon Health Potion, the new best healing potion for raids and Mythic+ (recipe from Jan'sari the Watchful, Coiled Isle, Renown 5 with Zul'jarra's Forces).",
        },
        medium = {
            "Focus on potions with the 'Selling Consumables' build: Multicraft first, then Resourcefulness; use a Multicraft tool.",
            "Flasks earn less right now: most of their cost is materials without quality (Petrified Root, Nocturnal Lotus), so Concentration helps little.",
            "Sell on raid days and stock up before the weekly reset.",
        },
        hardcore = {
            "Transmutes: the Wondrous Synergist daily (cooldown cut to about 9 hours with Synthesis Synergy) and Mote transmutes with Multicraft.",
            "Other 12.1 recipes: Liquid Luster (Versatility potion, from the vendor Skull of Er'inye in the Vaults of Atal'Utek) and Alluring Nostrum.",
            "If you spent your points on flasks, consider the one-time reset at Theremis to move them to potions.",
        },
    },
    blacksmithing = {
        casual = { "Standard build: craft max-rank weapons or armor for yourself, no orders or tips to pay." },
        medium = { "Season 2: good demand for crafted weapons and armor; weapons are usually the most requested upgrade.",
                   "Auction house: Alloys (The Old Ways specialization) go into almost every high-end recipe." },
        hardcore = { "Crafting orders for weapons and armor with Sparks: steady demand all season.",
                     "New in 12.1: the Hunter's Ritual Stone weapon embellishment (Construct V'anore, Silvermoon, Preyhunter's Journey rank 2)." },
    },
    enchanting = {
        casual = { "Concentration build: when it is full craft a single high-quality enchant and sell it; logging in every few days is enough.",
                   "Disenchant the gear you don't use and sell the materials." },
        medium = { "Sell the most requested enchants (weapon, ring, chest; helm, shoulders, boots) on Enchanting Vellum.",
                   "It earns less than usual right now: many costs are materials without quality. It should improve with new high-end content." },
        hardcore = { "Disenchanting build: materials are worth a lot early in the season and stay in demand.",
                     "New in 12.1: Enchant Weapon - Rite Of The Hash'ey (Jan'sari the Watchful, Renown 5 with Zul'jarra's Forces)." },
    },
    engineering = {
        casual = { "Craft your own goggles, bracers, boots or guns (Combat Analytics) instead of buying them." },
        medium = { "Crafting orders for combat gear: good demand in Season 2.",
                   "Recycling: gold-quality reagents for players crafting high-end gear, and Emergency Soul Link." },
        hardcore = { "Profession tools: they sell mostly early in the season, then demand drops.",
                     "New in 12.1: the Coiled Snake-Eye gun embellishment (world creature drop)." },
    },
    herbalism = {
        casual = { "Gather herbs along the path of your other activities and sell them in bulk." },
        medium = { "There are a lot of herbs on the market right now: sell on raid days, when alchemists buy.",
                   "Specialization: unless you are a druid, first 40 points in Botany (mounted gathering), then 40 in Bountiful Harvests." },
        hardcore = { "New in 12.1: Neutralized Venom Clot and Cursebound Globe from cursed nodes on the Coiled Isle, only while the area is cursed.",
                     "Pair it with Mining on the same character, ideally a druid: the most steady income mid-season." },
    },
    inscription = {
        casual = { "Missives: the highest-volume product, every crafter needs them for orders." },
        medium = { "Missives & Contracts or Reagents (inks) build: Calm Hands first for Multicraft and Resourcefulness.",
                   "Season 2: two-handed Intellect/Agility staves are in high demand (Blueprints specialization)." },
        hardcore = { "Full chain: mill herbs, make pigments, inks and finished goods, sell each step at a margin.",
                     "Treatises for every profession: every crafter wants one a week." },
    },
    jewelcrafting = {
        casual = { "Cut the gems you use and sell the surplus: every socketed piece needs them." },
        medium = { "Gemcutting or Reagents build (Sunglass Vial, Sin'dorei Lens, Kaleidoscopic Prism): steady demand.",
                   "Season 2: crafted rings and necklaces are in high demand (Alluring Accessories)." },
        hardcore = { "Prospecting and crushing: gems and Glimmering Gemdust are needed by every jewelcrafter.",
                     "New in 12.1: Refine Crystalline Glass and Refine Duskshrouded Stone from the trainer (50), Polished Ammolite embellishment (world drop)." },
    },
    leatherworking = {
        casual = { "Standard build: craft max-rank pieces of your armor type for yourself (Safeguarding Scales for mail)." },
        medium = { "Season 2: crafted gear is in high demand. Fill personal and public orders for the armor you can craft: the customer brings the materials, so the commission is almost all profit.",
                   "Auction house: armor kits and drums (Crucial Consumables in Flawless Fortes)." },
        hardcore = { "Crafting Orders build: armor rather than tools (demand all season), about one new max-rank slot a week.",
                     "New in 12.1: the Adorned Fang embellishment (drop from The Twin Fangs in the Venomous Abyss): if you have the recipe, craft it on order." },
    },
    mining = {
        casual = { "Mine along your path and sell ore in bulk." },
        medium = { "There is a lot of ore on the market right now: sell when blacksmiths and jewelcrafters buy (season start, new recipes).",
                   "Specialization: 40 points in Meticulous Mining for mounted mining, then 50 in Plentiful Ores." },
        hardcore = { "New in 12.1: Neutralized Venom Clot and Cursebound Globe from cursed nodes on the Coiled Isle.",
                     "Pair it with Herbalism on the same character: two materials on every route." },
    },
    skinning = {
        casual = { "Skin what you kill during world quests and quests: almost free gold." },
        medium = { "Look for High Value Beasts (knife on the minimap): they give much more leather.",
                   "Pure Farming build: 10 in Thorough Tanning and 40 in Lasting Leather (leather) or Superb Scales (scales)." },
        hardcore = { "Zone lures and renowned beasts (Talented Tracker) for Majestic Materials, the most valuable.",
                     "Cursed areas on the Coiled Isle (12.1) can give the new materials while skinning too." },
    },
    tailoring = {
        casual = { "Use the daily bolt cooldowns (Arcanoweave and Sunfire Silk) every day: almost every high-end recipe needs them." },
        medium = { "Standard build: both cooldowns unlocked and the cooldown cut to about 8 and a half hours.",
                   "Season 2: crafted cloth gear is in high demand (Sin'dorei Finery)." },
        hardcore = { "Bolt Crafting build (Multicraft and Resourcefulness), or the Farming build if you farm a lot in the world.",
                     "New in 12.1: the Snakeskin Lining embellishment (Altar of Fangs treasure)." },
    },
    cooking = {
        casual = { "Cook the food you use and sell the surplus: margins are thin because anyone can cook." },
        medium = { "Raid feasts: sell on reset day and before raid nights.",
                   "New in 12.1: Amani Cornucopia (trainer, 85), Loa's Gathering and Feast of Knowledge feasts." },
        hardcore = { "Pair with Fishing: your own raw material, full margin on the finished product." },
    },
    fishing = {
        casual = { "Fish while waiting in queue: fish sell to cooks, but competition is high." },
        medium = { "Fish for feasts: steady demand; Thalassian Recipes in a Bottle can teach 12.1 recipes to resell." },
        hardcore = { "Supply cooks in bulk or cook yourself for the full margin." },
    },
    none = {
        casual = { "No professions: with few hours a week pick two gathering professions (e.g. Herbalism + Mining)." },
        medium = { "No professions: right now Inscription, Jewelcrafting, Tailoring and Alchemy with potions earn the most (Icy Veins, Season 2)." },
        hardcore = { "No professions: one gathering/crafting pair per character, covering different markets." },
    },
}

-- Perche' la professione e' in quella fascia (una frase)
S.WHY = {
    it = {
        alchemy = "Rendono le pozioni create con Concentrazione: le erbe di rango 2 costano molto piu' di quelle di rango 1. I flask rendono meno, perche' gran parte del costo sono materiali senza qualita'.",
        inscription = "Ottime build di Concentrazione per i consumabili; in Season 2 i bastoni a due mani sono molto richiesti.",
        jewelcrafting = "Le gemme servono sempre e le build di Concentrazione funzionano bene; in Season 2 anelli e collane sono molto richiesti.",
        tailoring = "I cooldown giornalieri dei tessuti rendono bene; in Season 2 l'equip di stoffa e' molto richiesto.",
        enchanting = "Finora debole: molti costi sono materiali senza qualita'. Dovrebbe crescere con i nuovi contenuti di alto livello.",
        blacksmithing = "Ottimo per l'equip su ordinazione in Season 2, meno per chi non vuole fare ordini: pochi consumabili da Concentrazione.",
        engineering = "Ottimo per l'equip su ordinazione in Season 2, meno per chi non vuole fare ordini: pochi consumabili da Concentrazione.",
        leatherworking = "Ottimo per l'equip su ordinazione in Season 2: il cliente porta i materiali. Meno adatto a chi non vuole fare ordini.",
        mining = "C'e' molta offerta di materiali e i margini sono bassi; dovrebbero risalire con la Season 2.",
        herbalism = "C'e' molta offerta di materiali e i margini sono bassi; dovrebbero risalire con la Season 2.",
        skinning = "C'e' molta offerta di materiali e i margini sono bassi; dovrebbero risalire con la Season 2.",
        cooking = "Tutti possono farlo e non c'e' qualita': margini minimi.",
        fishing = "Tutti possono farlo e non c'e' qualita': margini minimi.",
    },
    en = {
        alchemy = "Potions crafted with Concentration earn: rank 2 herbs cost much more than rank 1. Flasks earn less, because most of their cost is materials without quality.",
        inscription = "Great Concentration builds for consumables; in Season 2 two-handed staves are in high demand.",
        jewelcrafting = "Gems are always needed and Concentration builds work well; in Season 2 rings and necklaces are in high demand.",
        tailoring = "The daily bolt cooldowns earn well; in Season 2 cloth gear is in high demand.",
        enchanting = "Weak so far: many costs are materials without quality. It should grow with new high-end content.",
        blacksmithing = "Great for gear on order in Season 2, less so if you don't want to do orders: few Concentration consumables.",
        engineering = "Great for gear on order in Season 2, less so if you don't want to do orders: few Concentration consumables.",
        leatherworking = "Great for gear on order in Season 2: the customer brings the materials. Less suited if you don't want to do orders.",
        mining = "There is a lot of material on the market and margins are low; they should recover with Season 2.",
        herbalism = "There is a lot of material on the market and margins are low; they should recover with Season 2.",
        skinning = "There is a lot of material on the market and margins are low; they should recover with Season 2.",
        cooking = "Anyone can do it and there is no quality: minimal margins.",
        fishing = "Anyone can do it and there is no quality: minimal margins.",
    },
}

function S:Why(key)
    local t = (ns.lang == "it") and self.WHY.it or self.WHY.en
    return t[key]
end

-- Testi per lingua, profilo e chiave ("general", professione o "none")
function S:Get(key, profile)
    local lang = (ns.lang == "it") and self.it or self.en
    local entry = lang[key]
    return entry and entry[profile] or {}
end

-- Fascia per fare oro della professione (nil se non nota)
function S:Tier(key)
    local t = (ns.lang == "it") and self.TIER.it or self.TIER.en
    return t[key]
end
