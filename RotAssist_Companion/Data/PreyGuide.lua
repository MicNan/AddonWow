-- RotAssist Companion - PreyGuide
-- Guida statica alla Caccia (Prey) di Midnight Season 2 e al gear in solo:
-- sblocco, come funziona una caccia, difficolta' e affissi, limiti
-- settimanali, Preyhunter's Journey con il catch-up della 12.1.5, Ral'kala,
-- fasce di equipaggiamento e dove trovarle giocando da soli, routine
-- settimanale. La mostra la scheda Oggi, obiettivo "Caccia" (Activities.lua).
--
-- Testi scritti per questo addon a partire da guide pubbliche (Method,
-- Playnews, Zygor, Icy Veins, Warcraft Wiki; ottobre 2026, patch 12.1.5).
-- Alcuni valori della Season 2 venivano dal PTR: in caso di dubbio fa fede
-- il gioco.

local _, ns = ...

local G = {}
ns.PreyGuide = G

-- Astalor's Sanctum: Silvermoon City (solo la zona, senza coordinate)
G.SANCTUM_MAP = 2393

-- Colori delle fasce di equipaggiamento
G.TIER_COLORS = {
    { 0.4, 1, 0.4 },        -- Adventurer
    { 0.35, 0.65, 1 },      -- Veteran
    { 0.75, 0.45, 1 },      -- Champion
    { 1, 0.6, 0.2 },        -- Hero
    { 1, 0.82, 0 },         -- Myth
}

-- Gradi del Preyhunter's Journey che contano per il gear
G.KEY_RANKS = { [4] = true, [9] = true, [10] = true }

---------------------------------------------------------------------------
-- Testi
---------------------------------------------------------------------------
G.it = {
    H_WHAT       = "Caccia (Prey): cosa sono",
    H_HOW        = "Sblocco e come funziona una caccia",
    H_DIFF       = "Difficolta', affissi e ricompense",
    H_JOURNEY    = "Preyhunter's Journey, catch-up e Ral'kala",
    H_GEAR       = "Gear in solo: le fasce e dove trovarle",
    H_OTHER      = "LFR, dungeon in coda e altre fonti",
    H_ROUTINE    = "Routine settimanale consigliata",
    intro = "L'attivita' open world principale di Midnight: scegli un bersaglio potente e gli dai la caccia in una zona, in solo, per equipaggiamento, crest e cosmetici. Con le Delve e' la fonte di gear piu' importante per chi gioca da solo.",
    facts = {
        "Tutto quello che fai nella zona del bersaglio (world quest, rari, tesori, attivita' della caccia) fa avanzare la caccia.",
        "Danno crediti per la Great Vault (riga Mondo) in base alla difficolta', come le Delve.",
        "La difficolta' scelta vale per tutta la zona finche' la caccia e' attiva: i mob intorno a te diventano piu' forti.",
    },
    sanctum = "Astalor's Sanctum, Silvermoon City (Astalor Bloodsworn)",
    sanctumTip = { "Astalor's Sanctum", "Silvermoon City: quartier generale della Caccia, gestito da Astalor Bloodsworn. Qui scegli il bersaglio dal tavolo delle cacce." },
    -- unlock: { missione (nome inglese del client), nota }
    S_UNLOCK     = "Sblocco (una volta per tutto l'account)",
    unlock = {
        { "Prey: Astalor's Initiative" },
        { "The Power of Anguish" },
        { "When Predator Becomes Prey" },
        { "Prey: Preferential Killing", "al livello 90" },
        { "Hunt: A Creeping Threat", "Season 2: sblocca il nuovo percorso di ricompense" },
    },
    S_HUNT       = "Una caccia, passo per passo",
    hunt = {
        "All'Astalor's Sanctum scegli un bersaglio dal tavolo delle cacce: ogni zona ne offre tre.",
        "Scegli la difficolta': Normal, Hard o Nightmare.",
        "Vai nella zona e gioca normalmente (world quest, rari, tesori). In piu': disinnescare trappole, uccidere i mob Coalesced Anguish, world quest della caccia.",
        "Ogni attivita' riempie la barra di localizzazione: il bersaglio si sposta e ti avvicini.",
        "Scontro finale: a Normal e' all'aperto e altri giocatori possono aiutarti; a Hard e Nightmare e' in una fase personale, solo tu e il tuo gruppo.",
        "Dopo l'uccisione, dal grado 1 del percorso Astalor ti apre un portale per tornare al Sanctum.",
    },
    huntNote = "I progressi si seguono nella scheda Journeys/Excursions dell'Adventure Guide (Maiusc+J).",
    diffIntro = "Piu' sali di difficolta', piu' sale la fascia del gear: per chi gioca da solo conta la Nightmare, che da' gear Champion e crest alte.",
    COL_DIFF = "Difficolta'", COL_GEAR = "Gear dalla caccia", COL_CREST = "Crest",
    difficulty = {
        { "Normal", "Adventurer", "Adventurer" },
        { "Hard", "Veteran", "Veteran" },
        { "Nightmare", "Champion (2 pezzi a settimana)", "Champion e Hero" },
    },
    noHero = "La caccia in se' non da' mai gear Hero: quello arriva dalla Great Vault, sbloccata dalle cacce completate.",
    S_AFFIX      = "Affissi della Season 2",
    affixes = {
        { "Normal", "Ambush: il bersaglio ti attacca a sorpresa mentre combatti altro o fai scattare una trappola." },
        { "Hard+", "Torment: +2% di danno subito per stack man mano che avanzi, fino al 100%. Non perdere tempo." },
        { "Hard+", "Pack Ambush: un gruppo di esploratori ti salta addosso mentre sei gia' in combattimento." },
        { "Hard+", "Exploding Corpse Snakes: dai cadaveri escono serpenti che esplodono e ti avvelenano." },
        { "Hard+", "Toxic Snare: cerchi a terra che fanno molto danno e ti rallentano o radicano." },
    },
    S_LIMITS     = "Limiti settimanali",
    limits = {
        "Massimo 15 cacce a settimana.",
        "Solo le prime 4 danno 1.000 punti di progresso ciascuna, le altre 50. Ogni grado del percorso richiede 4.000 punti.",
        "In pratica: 4 cacce a settimana bastano per il progresso, le altre servono solo per bottino, valute e imprese.",
        "Dalla 12.1 una caccia completata a una difficolta' conta anche per le imprese delle difficolta' inferiori.",
    },
    root = "Bonus per l'oro: le cacce ad alta difficolta' possono dare Petrified Root dal forziere finale, uno dei reagenti piu' cari del gioco.",
    journeyIntro = "Il Preyhunter's Journey ha 10 gradi; per il gear contano il 4 e il 9, che sbloccano le anime per un pezzo extra Champion e poi Hero ogni settimana.",
    catchupTitle = "Catch-up attivo dalla 12.1.5 (14 ottobre)",
    catchup = "Sotto il grado 4 ogni caccia vale 4.000 punti, cioe' un grado intero. Tra il grado 4 e il 9 le prime 4 cacce della settimana valgono 2.000 punti ciascuna: due gradi a settimana. Se parti adesso e' il momento migliore.",
    ranks = {
        { 1, "Portale per tornare al Sanctum dopo ogni caccia; +50% bottino da Ral'kala se aiuti a evocarlo" },
        { 2, "Cacce scelte a caso da Astalor; tre ricette di professione" },
        { 3, "Piu' fonti di Ossified Relics" },
        { 4, "Afflicted Souls nei forzieri delle Bountiful Delve 6+: usate in Nightmare danno un pezzo Champion extra a settimana" },
        { 6, "Set di armatura transmog" },
        { 7, "Ensemble transmog della caccia" },
        { 8, "Due famigli da compagnia" },
        { 9, "Tormented Souls negli stessi forzieri: un pezzo Hero extra a settimana" },
        { 10, "Cacce personalizzate, titolo e cavalcatura Preyhunter's Fury" },
    },
    souls = "Dalla 12.1.5 Afflicted e Tormented Souls vanno attivate tra una caccia e l'altra, non durante.",
    S_RALKALA    = "Ral'kala, il boss della Coiled Isle",
    ralkala = {
        "Si evoca bruciando 100 Ossified Relics in un braciere della Coiled Isle, durante una caccia Nightmare o nella fase Curse of the Isle.",
        "La fase si sblocca con la catena Prey: A Slithering Threat: serve una delle 4 cacce Nightmare della Coiled Isle e la campagna 12.1 fino al capitolo 2.",
        "Ossified Relics: dai teschi sull'isola, dai mob (dal grado 3) e da una missione giornaliera che ne da' 100.",
        "Le relics sono condivise tra i giocatori, ma contribuire con le tue aumenta molto le probabilita' di bottino.",
        "Fa sempre cadere crest Hero e Champion; puo' dare anche una cavalcatura rara, un famiglio e un giocattolo.",
    },
    corrosive = "Corrosive Souls: da cacce e Delve; all'Altar of Corrosion aggiungono un potere casuale a cintura o bracciali. Funzionano solo in open world e Delve, non in dungeon e raid: ottime per il gioco in solo.",
    gearIntro = "In solo puoi superare il livello oggetto 321 (l'ingresso nella fascia Myth) combinando Delve, Prey, crafting e Great Vault.",
    gearTip = "Non perdere tempo a completare la fascia Adventurer: punta subito alla Veteran.",
    tiers = {
        { "Adventurer", "fino a 282. Fonti: rari, world quest, tesori, Prey Normal, Delve 1-4, dungeon Heroic.", "Crest: Prey Normal, Delve 1-4, dungeon Heroic." },
        { "Veteran", "Fonti: Prey Hard, Bountiful Delve 5-6, LFR, Renown delle fazioni, venditore War Mode, crafting, Great Vault.", "Crest: Prey Hard, Delve 5-6, dungeon Heroic, LFR." },
        { "Champion", "Fonti: Prey Nightmare, Bountiful Delve 7-11, Nemesis delle Delve dal 7, venditore Conquest, Great Vault.", "Crest: Prey Nightmare, Delve 7-10." },
        { "Hero", "Fonti: Delve 8-11 con Trovehunter's Bounty, bonus del Journey al grado 9, crafting, Great Vault.", "Crest: Delve 11, Prey Nightmare, Ral'kala, missione settimanale dell'housing." },
        { "Myth", "Fonti: solo crafting con crest Myth e BoE mitici.", "Crest: Gilded Stashes delle Delve 11 (massimo 4 a settimana), Nemesis." },
    },
    S_MUSTDO     = "Tre cose da non perdere",
    mustDo = {
        "Crafting: con le crest crei pezzi di fascia Hero e Myth della tua armatura. In solo e' l'unica strada per il Myth: spendi le crest Myth sui pezzi piu' importanti, arma e pezzi con abbellimenti.",
        "Cracked Keystone: una Delve 11 ti da' una chiave per una sola Mitica+ con crest Hero e Myth senza limite settimanale. Vale la pena farla anche cercando un gruppo.",
        "Nemesis delle Delve: alla difficolta' massima da' 30 crest Hero fuori dal limite.",
    },
    otherIntro = "LFR e dungeon Heroic sono utili ma non sono il cuore del gearing in solo: il vero motore resta la Great Vault, alimentata da Delve e Prey.",
    other = {
        "Great Vault: la riga Mondo si riempie con Delve e Prey. A inizio stagione arrivava al massimo a Champion 3/6, piu' avanti fino a Hero 1/6.",
        "LFR (Raid Finder): gear e crest Veteran, coda automatica senza gilda. Buono per i pezzi mancanti nelle prime settimane.",
        "Dungeon Heroic in coda: gear Adventurer ma crest Veteran, e a volte Petrified Root dai boss finali.",
        "Vaults of Atal'utek: ruotano Strikes, Incursions e Ancient Foes, un modo rilassato per fare crest e qualche pezzo. Le Ritual Sites 5-6 danno crest Veteran.",
        "Ancient Foe e Purifying the Vaults: un frammento a settimana ciascuna per un pezzo Champion fisso.",
        "Renown: le quattro fazioni iniziali e Zul'jarra's Forces vendono pezzi Veteran; al Renown 9 di Zul'jarra anche Champion.",
        "Cursed Surges: gear e crest, ma sono a tempo: usale quando capitano, senza pianificarci la settimana.",
    },
    routineIntro = "Con il catch-up attivo, 4 cacce e qualche Delve a settimana bastano per salire di grado in fretta e riempire la Great Vault.",
    routineHunter = "Cacciatore Beast Mastery: il famiglio che tanka rende il BM una delle classi piu' comode per Hard e Nightmare in solo.",
    P_START      = "Prime settimane (appena arrivato al 90)",
    routineStart = {
        "Completa la catena di sblocco Prey e Hunt: A Creeping Threat.",
        "4 cacce a Normal o Hard a settimana: col catch-up ognuna vale un grado intero finche' sei sotto il 4.",
        "Delve fino al livello che completi senza morire, salendo man mano.",
        "LFR per riempire gli slot vuoti con pezzi Veteran.",
        "Ritira la Great Vault ogni mercoledi'.",
    },
    P_VETERAN    = "Quando hai tutto Veteran",
    routineVeteran = {
        "Passa alle cacce Nightmare: i 2 pezzi Champion a settimana sono la tua spina dorsale.",
        "Bountiful Delve 6+ per le Afflicted Souls (dal grado 4) e poi le Tormented Souls (dal grado 9).",
        "Attiva le anime prima di iniziare la caccia successiva, mai durante.",
        "Usa le crest per creare i tuoi pezzi con la professione.",
    },
    S_TIPS       = "Consigli per Hard e Nightmare",
    tips = {
        "Con Torment il danno subito cresce durante la caccia: falla tutta d'un fiato, senza pause lunghe.",
        "Esci subito dai cerchi di Toxic Snare: radicato in mezzo a un'imboscata e' il modo piu' comune di morire.",
    },
    hunterTips = {
        "Contro Pack Ambush usa Misdirection sul famiglio appena compaiono e lascia che tanki lui.",
        "Tieni pronti Exhilaration e Survival of the Fittest per lo scontro finale, che a Hard e Nightmare e' solo tuo.",
    },
    note = "Guida alla Caccia: Method, Playnews, Zygor, Icy Veins, Warcraft Wiki (patch 12.1.5). Alcuni valori venivano dal PTR: in caso di dubbio fa fede il gioco. Clic destro sulle righe: Wowhead.",
}

G.en = {
    H_WHAT       = "The Hunt (Prey): what it is",
    H_HOW        = "Unlock and how a hunt works",
    H_DIFF       = "Difficulty, affixes and rewards",
    H_JOURNEY    = "Preyhunter's Journey, catch-up and Ral'kala",
    H_GEAR       = "Solo gearing: tracks and where to find them",
    H_OTHER      = "LFR, queued dungeons and other sources",
    H_ROUTINE    = "Suggested weekly routine",
    intro = "Midnight's main open world activity: pick a powerful target and hunt it down in a zone, solo, for gear, crests and cosmetics. Together with Delves it is the most important gear source for solo players.",
    facts = {
        "Everything you do in the target's zone (world quests, rares, treasures, hunt activities) advances the hunt.",
        "They give Great Vault credit (World row) based on difficulty, like Delves.",
        "The chosen difficulty applies to the whole zone while the hunt is active: mobs around you get stronger.",
    },
    sanctum = "Astalor's Sanctum, Silvermoon City (Astalor Bloodsworn)",
    sanctumTip = { "Astalor's Sanctum", "Silvermoon City: headquarters of the Hunt, run by Astalor Bloodsworn. Pick your target at the hunt table here." },
    S_UNLOCK     = "Unlock (once for the whole account)",
    unlock = {
        { "Prey: Astalor's Initiative" },
        { "The Power of Anguish" },
        { "When Predator Becomes Prey" },
        { "Prey: Preferential Killing", "at level 90" },
        { "Hunt: A Creeping Threat", "Season 2: unlocks the new reward track" },
    },
    S_HUNT       = "A hunt, step by step",
    hunt = {
        "At Astalor's Sanctum pick a target from the hunt table: each zone offers three.",
        "Pick the difficulty: Normal, Hard or Nightmare.",
        "Go to the zone and play normally (world quests, rares, treasures). On top: disarm traps, kill Coalesced Anguish mobs, hunt world quests.",
        "Every activity fills the tracking bar: the target moves and you close in.",
        "Final fight: on Normal it is out in the open and other players can help; on Hard and Nightmare it is in a personal phase, just you and your group.",
        "After the kill, from rank 1 of the track Astalor opens a portal back to the Sanctum.",
    },
    huntNote = "Track progress in the Journeys/Excursions tab of the Adventure Guide (Shift+J).",
    diffIntro = "The higher the difficulty, the higher the gear track: for solo players Nightmare is what matters, with Champion gear and high crests.",
    COL_DIFF = "Difficulty", COL_GEAR = "Gear from the hunt", COL_CREST = "Crests",
    difficulty = {
        { "Normal", "Adventurer", "Adventurer" },
        { "Hard", "Veteran", "Veteran" },
        { "Nightmare", "Champion (2 pieces a week)", "Champion and Hero" },
    },
    noHero = "The hunt itself never gives Hero gear: that comes from the Great Vault, unlocked by completed hunts.",
    S_AFFIX      = "Season 2 affixes",
    affixes = {
        { "Normal", "Ambush: the target attacks you by surprise while you fight something else or trigger a trap." },
        { "Hard+", "Torment: +2% damage taken per stack as you progress, up to 100%. Do not waste time." },
        { "Hard+", "Pack Ambush: a group of scouts jumps you while you are already in combat." },
        { "Hard+", "Exploding Corpse Snakes: snakes burst out of corpses, explode and poison you." },
        { "Hard+", "Toxic Snare: ground circles that hit hard and slow or root you." },
    },
    S_LIMITS     = "Weekly limits",
    limits = {
        "At most 15 hunts a week.",
        "Only the first 4 give 1,000 progress points each, the rest give 50. Each rank of the track needs 4,000 points.",
        "In short: 4 hunts a week are enough for progress, the rest are only for loot, currencies and achievements.",
        "Since 12.1 a hunt completed on a difficulty also counts for the achievements of the lower difficulties.",
    },
    root = "Gold bonus: high difficulty hunts can drop Petrified Root from the final chest, one of the most expensive reagents in the game.",
    journeyIntro = "The Preyhunter's Journey has 10 ranks; for gear ranks 4 and 9 matter, unlocking souls for an extra Champion and then Hero piece every week.",
    catchupTitle = "Catch-up active since 12.1.5 (October 14)",
    catchup = "Below rank 4 every hunt is worth 4,000 points, a whole rank. Between rank 4 and 9 the first 4 hunts of the week are worth 2,000 points each: two ranks a week. If you are starting now, this is the best time.",
    ranks = {
        { 1, "Portal back to the Sanctum after each hunt; +50% loot from Ral'kala if you help summon it" },
        { 2, "Hunts picked at random by Astalor; three profession recipes" },
        { 3, "More sources of Ossified Relics" },
        { 4, "Afflicted Souls in Bountiful Delve 6+ chests: used on Nightmare they give an extra Champion piece a week" },
        { 6, "Transmog armor set" },
        { 7, "Hunt transmog ensemble" },
        { 8, "Two companion pets" },
        { 9, "Tormented Souls in the same chests: an extra Hero piece a week" },
        { 10, "Custom hunts, title and the Preyhunter's Fury mount" },
    },
    souls = "Since 12.1.5 Afflicted and Tormented Souls must be activated between hunts, not during one.",
    S_RALKALA    = "Ral'kala, the Coiled Isle boss",
    ralkala = {
        "Summoned by burning 100 Ossified Relics in a brazier on the Coiled Isle, during a Nightmare hunt or in the Curse of the Isle phase.",
        "The phase unlocks with the Prey: A Slithering Threat chain: you need one of the 4 Coiled Isle Nightmare hunts and the 12.1 campaign up to chapter 2.",
        "Ossified Relics: from skulls on the island, from mobs (from rank 3) and from a daily quest that gives 100.",
        "Relics are shared between players, but contributing your own greatly raises your loot chances.",
        "It always drops Hero and Champion crests, and can also drop a rare mount, a pet and a toy.",
    },
    corrosive = "Corrosive Souls: from hunts and Delves; at the Altar of Corrosion they add a random power to your belt or bracers. They only work in the open world and Delves, not in dungeons and raids: great for solo play.",
    gearIntro = "Solo you can go past item level 321 (the entry to the Myth track) by combining Delves, Prey, crafting and the Great Vault.",
    gearTip = "Do not waste time completing the Adventurer track: aim straight for Veteran.",
    tiers = {
        { "Adventurer", "up to 282. Sources: rares, world quests, treasures, Normal Prey, Delves 1-4, Heroic dungeons.", "Crests: Normal Prey, Delves 1-4, Heroic dungeons." },
        { "Veteran", "Sources: Hard Prey, Bountiful Delves 5-6, LFR, faction Renown, War Mode vendor, crafting, Great Vault.", "Crests: Hard Prey, Delves 5-6, Heroic dungeons, LFR." },
        { "Champion", "Sources: Nightmare Prey, Bountiful Delves 7-11, Delve Nemesis from 7, Conquest vendor, Great Vault.", "Crests: Nightmare Prey, Delves 7-10." },
        { "Hero", "Sources: Delves 8-11 with Trovehunter's Bounty, Journey bonus at rank 9, crafting, Great Vault.", "Crests: Delve 11, Nightmare Prey, Ral'kala, weekly housing quest." },
        { "Myth", "Sources: only crafting with Myth crests and Mythic BoEs.", "Crests: Delve 11 Gilded Stashes (at most 4 a week), Nemesis." },
    },
    S_MUSTDO     = "Three things not to miss",
    mustDo = {
        "Crafting: with crests you craft Hero and Myth pieces of your armor type. Solo it is the only road to Myth: spend Myth crests on the most important pieces, weapon and embellished pieces.",
        "Cracked Keystone: a Delve 11 gives a key for a single Mythic+ run with Hero and Myth crests outside the weekly cap. Worth doing even if you have to find a group.",
        "Delve Nemesis: on the highest difficulty it gives 30 Hero crests outside the cap.",
    },
    otherIntro = "LFR and Heroic dungeons are useful but not the core of solo gearing: the real engine is the Great Vault, fed by Delves and Prey.",
    other = {
        "Great Vault: the World row fills with Delves and Prey. Early in the season it went up to Champion 3/6, later up to Hero 1/6.",
        "LFR (Raid Finder): Veteran gear and crests, automatic queue without a guild. Good for missing pieces in the first weeks.",
        "Queued Heroic dungeons: Adventurer gear but Veteran crests, and sometimes Petrified Root from the last bosses.",
        "Vaults of Atal'utek: Strikes, Incursions and Ancient Foes rotate, a relaxed way to earn crests and a few pieces. Ritual Sites 5-6 give Veteran crests.",
        "Ancient Foe and Purifying the Vaults: one fragment a week each toward a fixed Champion piece.",
        "Renown: the four starting factions and Zul'jarra's Forces sell Veteran pieces; at Zul'jarra Renown 9 also Champion.",
        "Cursed Surges: gear and crests, but they are timed: use them when they show up, do not plan your week around them.",
    },
    routineIntro = "With the catch-up active, 4 hunts and a few Delves a week are enough to rank up fast and fill the Great Vault.",
    routineHunter = "Beast Mastery hunter: the tanking pet makes BM one of the most comfortable classes for solo Hard and Nightmare.",
    P_START      = "First weeks (just hit 90)",
    routineStart = {
        "Finish the Prey unlock chain and Hunt: A Creeping Threat.",
        "4 hunts on Normal or Hard a week: with the catch-up each one is a whole rank while you are below 4.",
        "Delves up to the tier you clear without dying, moving up as you go.",
        "LFR to fill empty slots with Veteran pieces.",
        "Claim the Great Vault every Wednesday.",
    },
    P_VETERAN    = "Once you are full Veteran",
    routineVeteran = {
        "Move to Nightmare hunts: the 2 Champion pieces a week are your backbone.",
        "Bountiful Delves 6+ for Afflicted Souls (from rank 4) and then Tormented Souls (from rank 9).",
        "Activate the souls before starting the next hunt, never during one.",
        "Use crests to craft your own pieces with your profession.",
    },
    S_TIPS       = "Tips for Hard and Nightmare",
    tips = {
        "With Torment the damage you take grows during the hunt: do it in one go, without long breaks.",
        "Leave Toxic Snare circles at once: rooted in the middle of an ambush is the most common way to die.",
    },
    hunterTips = {
        "Against Pack Ambush use Misdirection on your pet as soon as they show up and let it tank.",
        "Keep Exhilaration and Survival of the Fittest ready for the final fight, which on Hard and Nightmare is yours alone.",
    },
    note = "Hunt guide: Method, Playnews, Zygor, Icy Veins, Warcraft Wiki (patch 12.1.5). Some values came from the PTR: when in doubt the game is right. Right click on rows: Wowhead.",
}

function G:Text(key)
    local t = self[ns.lang] or self.it
    return t[key] or self.it[key]
end
