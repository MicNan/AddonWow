-- RotAssist Companion - GoldStrategies
-- Strategie per fare oro in Midnight 12.1, per professione e per profilo:
--   casual   = giocatore occasionale (poche ore a settimana)
--   medium   = giocatore medio (qualche sessione a settimana)
--   hardcore = giocatore assiduo (ogni giorno, piu' personaggi)
--
-- Testi scritti per RotAssist Companion (non copiati da guide). Basi usate
-- per i fatti di Midnight: Concentrazione +240 al giorno fino a 1000, punti
-- conoscenza soprattutto dagli ordini dei Patron, reset unico della
-- conoscenza in 12.1 da Theremis a Silvermoon, decorazioni per l'housing
-- prodotte dalle professioni di creazione. Niente cifre in oro: i prezzi
-- cambiano da reame a reame, quindi si rimanda sempre alla casa d'aste.
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
            "Completa gli ordini dei Patron della settimana: danno punti conoscenza e spesso materiali rari.",
        },
        hardcore = {
            "Piu' personaggi con professioni diverse: ogni personaggio ha la sua Concentrazione da spendere.",
            "Controlla i prezzi prima di creare: vendi solo cio' che ha margine dopo il costo dei materiali.",
            "Se hai scelto male la specializzazione, la 12.1 offre un reset unico della conoscenza (Theremis, Silvermoon).",
            "Mercato delle decorazioni per l'housing: pezzi rari e ricercati, ottimi per chi crea su ordinazione.",
        },
    },
    alchemy = {
        casual = { "Crea pozioni e flask popolari solo quando servono a te e vendi l'eccesso.",
                   "Fai le missioni settimanali di professione per la conoscenza." },
        medium = { "Specializzati in una linea (pozioni o flask) e usa la Concentrazione per la qualita' massima.",
                   "Le flask e le pozioni di raid si vendono soprattutto a inizio settimana (reset)." },
        hardcore = { "Integrazione con Erboristeria: raccogli tu le erbe e trasforma in consumabili.",
                     "Tieni sempre scorte di consumabili prima delle uscite di nuovo contenuto e del reset." },
    },
    blacksmithing = {
        casual = { "Rispondi agli ordini di creazione pubblici delle armi/armature che sai gia' fare." },
        medium = { "Specializzati nei pezzi d'equip richiesti dagli ordini e usa la Concentrazione per la qualita' alta.",
                   "Crea decorazioni in metallo per l'housing quando hanno margine." },
        hardcore = { "Ordini personalizzati per l'equip creato con rank massimo: punta ai giocatori che salgono di livello di oggetti.",
                     "Abbina Estrazione per ridurre il costo dei materiali." },
    },
    enchanting = {
        casual = { "Disincanta gli oggetti verdi e blu che non ti servono e vendi le polveri." },
        medium = { "Vendi gli incantesimi piu' richiesti (armi e anelli) sotto forma di pergamene.",
                   "Compra oggetti economici da disincantare quando il valore delle polveri e' superiore." },
        hardcore = { "Segui gli incantesimi 'meta' dopo ogni aggiornamento: la domanda cambia subito.",
                     "Tieni scorte di pergamene per l'inizio di stagione e per il reset settimanale." },
    },
    engineering = {
        casual = { "Crea per te gli oggetti utili (strumenti, gadget) e vendi l'eccesso dei componenti." },
        medium = { "Rispondi agli ordini per accessori ed equip ingegneristico con buona qualita'." },
        hardcore = { "Componenti intermedi venduti in quantita' agli altri creatori: domanda stabile.",
                     "Abbina Estrazione: i metalli sono la tua materia prima principale." },
    },
    herbalism = {
        casual = { "Raccogli le erbe lungo il percorso delle altre attivita' e vendile in blocco." },
        medium = { "Percorsi di raccolta dedicati di 20-30 minuti nelle zone di Midnight; vendi a inizio settimana.",
                   "Spendi la conoscenza nei talenti che aumentano raccolta e materiali rari." },
        hardcore = { "La raccolta e' tra le attivita' con piu' oro all'ora: sessioni lunghe nelle zone meno affollate.",
                     "Rifornisci Alchimia/Runografia (tue o di altri giocatori) con contratti di fornitura." },
    },
    inscription = {
        casual = { "Crea per te gli oggetti utili e vendi gli inchiostri in eccesso." },
        medium = { "Inchiostri e contratti: domanda costante da parte degli altri giocatori.",
                   "Usa la Concentrazione sui prodotti di qualita' piu' richiesti." },
        hardcore = { "Catena completa: compra o raccogli erbe, crea inchiostri e prodotti finiti, vendi ogni passaggio con margine.",
                     "Segui le uscite settimanali: alcuni prodotti si vendono solo al reset." },
    },
    jewelcrafting = {
        casual = { "Taglia le gemme che usi e vendi le gemme grezze in eccesso." },
        medium = { "Gemme richieste per l'equip: vendi soprattutto dopo ogni nuova stagione o patch.",
                   "Prospetta i minerali quando il valore delle gemme supera quello del minerale." },
        hardcore = { "Gemme e componenti di rank alto con Concentrazione: sono tra i prodotti piu' redditizi.",
                     "Abbina Estrazione e tieni scorte prima degli aggiornamenti." },
    },
    leatherworking = {
        casual = { "Rispondi agli ordini pubblici dei pezzi che conosci gia'." },
        medium = { "Kit e rinforzi per l'equip: domanda costante.",
                   "Decorazioni in pelle per l'housing quando hanno margine." },
        hardcore = { "Equip creato con rank massimo su ordinazione; abbina Scuoiatura per i materiali." },
    },
    mining = {
        casual = { "Estrai lungo il percorso e vendi i minerali in blocco." },
        medium = { "Percorsi dedicati e talenti di conoscenza per i materiali rari; vendi a inizio settimana." },
        hardcore = { "Sessioni lunghe di raccolta; rifornisci Forgiatura, Ingegneria e Oreficeria con contratti di fornitura." },
    },
    skinning = {
        casual = { "Scuoia cio' che uccidi durante le world quest e le missioni: e' oro quasi gratis." },
        medium = { "Zone con molte bestie: brevi sessioni dedicate; vendi pelli e materiali rari." },
        hardcore = { "Abbinata a Conciatura per prodotti finiti; tieni d'occhio i materiali rari, che valgono molto." },
    },
    tailoring = {
        casual = { "Usa la stoffa che trovi per creare borse o oggetti richiesti; vendi la stoffa in eccesso." },
        medium = { "Borse e decorazioni in stoffa per l'housing: domanda stabile.",
                   "Rispondi agli ordini di equip in stoffa con buona qualita'." },
        hardcore = { "Decorazioni rare per l'housing e equip di rank massimo su ordinazione con Concentrazione." },
    },
    cooking = {
        casual = { "Cucina i piatti che usi e vendi l'eccesso; i banchetti si vendono bene prima dei raid." },
        medium = { "Banchetti e cibo per raid: vendi il giorno del reset e prima delle serate di raid." },
        hardcore = { "Abbina Pesca: materia prima tua, margine pieno sul prodotto finito." },
    },
    fishing = {
        casual = { "Pesca in modo rilassato mentre aspetti la coda: i pesci si vendono ai cuochi." },
        medium = { "Pesce per banchetti: domanda costante; cerca i banchi di pesce nelle zone di Midnight." },
        hardcore = { "Fornisci i cuochi in quantita' oppure cucina tu stesso (Cucina) per il margine pieno." },
    },
    none = {
        casual = { "Senza professioni: per poche ore a settimana prendi due professioni di raccolta (es. Erboristeria + Estrazione)." },
        medium = { "Senza professioni: una raccolta + una creazione collegata (es. Erboristeria + Alchimia)." },
        hardcore = { "Senza professioni: scegli una coppia raccolta/creazione per personaggio e copri piu' mercati." },
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
            "Complete the weekly Patron orders: they give knowledge points and often rare materials.",
        },
        hardcore = {
            "Several characters with different professions: each one has its own Concentration to spend.",
            "Check prices before crafting: sell only what has a margin after material costs.",
            "If you picked the wrong specialization, 12.1 offers a one-time knowledge reset (Theremis, Silvermoon).",
            "Housing decor market: rare, sought-after pieces, great for crafting on order.",
        },
    },
    alchemy = {
        casual = { "Craft popular potions and flasks only when you need them and sell the surplus.",
                   "Do the weekly profession quests for knowledge." },
        medium = { "Specialize in one line (potions or flasks) and use Concentration for top quality.",
                   "Flasks and raid potions sell best early in the week (reset)." },
        hardcore = { "Integrate with Herbalism: gather the herbs yourself and turn them into consumables.",
                     "Always stock consumables before new content releases and before reset." },
    },
    blacksmithing = {
        casual = { "Fill public crafting orders for weapons/armor you already know." },
        medium = { "Specialize in the gear pieces requested in orders and use Concentration for high quality.",
                   "Craft metal housing decor when it has a margin." },
        hardcore = { "Personal orders for max-rank crafted gear: target players upgrading their item level.",
                     "Pair with Mining to cut material costs." },
    },
    enchanting = {
        casual = { "Disenchant green and blue items you don't need and sell the dust." },
        medium = { "Sell the most requested enchants (weapons and rings) as scrolls.",
                   "Buy cheap items to disenchant when the dust is worth more." },
        hardcore = { "Follow the 'meta' enchants after every update: demand shifts immediately.",
                     "Stock scrolls for season start and weekly reset." },
    },
    engineering = {
        casual = { "Craft useful items (tools, gadgets) for yourself and sell surplus components." },
        medium = { "Fill orders for engineering accessories and gear at good quality." },
        hardcore = { "Intermediate components sold in bulk to other crafters: steady demand.",
                     "Pair with Mining: metals are your main raw material." },
    },
    herbalism = {
        casual = { "Gather herbs along the path of your other activities and sell them in bulk." },
        medium = { "Dedicated 20-30 minute gathering routes in the Midnight zones; sell early in the week.",
                   "Spend knowledge on talents that boost yield and rare materials." },
        hardcore = { "Gathering is among the best gold-per-hour activities: long sessions in quieter zones.",
                     "Supply Alchemy/Inscription (yours or other players') with bulk contracts." },
    },
    inscription = {
        casual = { "Craft useful items for yourself and sell surplus inks." },
        medium = { "Inks and contracts: steady demand from other players.",
                   "Spend Concentration on the most requested quality products." },
        hardcore = { "Full chain: buy or gather herbs, craft inks and finished goods, sell each step at a margin.",
                     "Follow the weekly cycle: some products only sell at reset." },
    },
    jewelcrafting = {
        casual = { "Cut the gems you use and sell surplus raw gems." },
        medium = { "Gems needed for gear: sell mostly after each new season or patch.",
                   "Prospect ore when the gems are worth more than the ore." },
        hardcore = { "High-rank gems and components with Concentration: among the most profitable products.",
                     "Pair with Mining and stock up before updates." },
    },
    leatherworking = {
        casual = { "Fill public orders for pieces you already know." },
        medium = { "Kits and armor reinforcements: steady demand.",
                   "Leather housing decor when it has a margin." },
        hardcore = { "Max-rank crafted gear on order; pair with Skinning for materials." },
    },
    mining = {
        casual = { "Mine along your path and sell ore in bulk." },
        medium = { "Dedicated routes and knowledge talents for rare materials; sell early in the week." },
        hardcore = { "Long gathering sessions; supply Blacksmithing, Engineering and Jewelcrafting with bulk contracts." },
    },
    skinning = {
        casual = { "Skin what you kill during world quests and quests: almost free gold." },
        medium = { "Zones with many beasts: short dedicated sessions; sell leather and rare materials." },
        hardcore = { "Pair with Leatherworking for finished goods; watch rare materials, they are worth a lot." },
    },
    tailoring = {
        casual = { "Use the cloth you find to craft bags or requested items; sell surplus cloth." },
        medium = { "Bags and cloth housing decor: steady demand.",
                   "Fill cloth gear orders at good quality." },
        hardcore = { "Rare housing decor and max-rank gear on order with Concentration." },
    },
    cooking = {
        casual = { "Cook the food you use and sell the surplus; feasts sell well before raids." },
        medium = { "Feasts and raid food: sell on reset day and before raid nights." },
        hardcore = { "Pair with Fishing: your own raw material, full margin on the finished product." },
    },
    fishing = {
        casual = { "Fish while waiting in queue: fish sell to cooks." },
        medium = { "Fish for feasts: steady demand; look for fishing pools in the Midnight zones." },
        hardcore = { "Supply cooks in bulk or cook yourself (Cooking) for the full margin." },
    },
    none = {
        casual = { "No professions: with few hours a week pick two gathering professions (e.g. Herbalism + Mining)." },
        medium = { "No professions: one gathering + one related crafting profession (e.g. Herbalism + Alchemy)." },
        hardcore = { "No professions: pick a gathering/crafting pair per character and cover several markets." },
    },
}

-- Testi per lingua, profilo e chiave ("general", professione o "none")
function S:Get(key, profile)
    local lang = (ns.lang == "it") and self.it or self.en
    local entry = lang[key]
    return entry and entry[profile] or {}
end
