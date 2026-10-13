# RotAssist Companion (WoW Midnight 12.1)

Addon di supporto **fuori dal combattimento**: delve, eventi, world quest, obiettivi
settimanali e levelling, con waypoint e link Wowhead. È indipendente da RotAssist: si può
usare da solo.

**Stato:** versione 0.10.0, provata **solo in simulazione**. Alcune API vanno ancora
confermate in gioco (vedi "Da verificare in gioco").

## Schede

| Scheda | Contenuto | Fonte (API di Blizzard) |
|---|---|---|
| **Oggi** | **Riepilogo** (cosa fare adesso per ogni obiettivo, eventi e festività, world quest in scadenza con la ricompensa, Traveler's Log e reset) e attività consigliate per **obiettivo** (equipaggiamento, Great Vault, reputazione, oro): world quest confrontate con il tuo equipaggiamento e con la priorità delle statistiche, slot della Vault, fazioni più vicine al prossimo Renown | `C_TaskQuest`, ricompense delle missioni, `C_Calendar`, `C_AreaPoiInfo.GetEventsForMap`, `C_Item.GetItemStats`, `C_WeeklyRewards`, `C_PerksActivities`, `C_MajorFactions`, `C_ClassTalents` |
| **Delve** | Restored Coffer Key, Coffer Key Shards della settimana, livello del compagno; tabella delle delve attive su tutte le mappe, con le **abbondanti** in cima (filtro in cima: tutte o solo abbondanti) | `C_AreaPoiInfo.GetDelvesForMap`, `C_CurrencyInfo`, `C_DelvesUI`, `C_GossipInfo` |
| **Levelling** | livello, XP, riposo, XP/ora della sessione con tempo stimato al livello successivo, tabelle della zona attuale e delle zone del continente adatte al tuo livello, missioni nel diario | `UnitXP`, `C_Map.GetMapLevels`, `C_QuestLog` |
| **Professioni** | per ogni tua professione: Concentrazione e punti conoscenza da spendere, la fase della guida in cui ti trovi, cosa creare adesso spendendo meno (dalle ricette che conosci), cosa creare per l'oro (guadagno a creazione con i prezzi d'asta), cosa comprare togliendo quello che hai già, la specializzazione consigliata per il tuo equipaggiamento e dove prendere i punti conoscenza | `C_TradeSkillUI`, `C_Item.GetItemCount`, `C_ProfSpecs` |
| **Oro** | tre sezioni con il **profilo** di gioco (occasionale, medio, assiduo) in cima: **Strategie** per le tue professioni, **Borse e prezzi** (cosa mettere all'asta e cosa vendere al vendor), **Da farmare** (materiali di Midnight per il tuo profilo e sessione di farm con oro all'ora reale) | `GetProfessions`, `C_AuctionHouse.ReplicateItems`, `C_Container`, `C_Item` |
| **Pet** | pet da cacciatore rari e notevoli di Midnight per zona e spirit beast di tutte le espansioni, con anteprima 3D, requisiti (esotico, Florafaun), istruzioni per domarli, percorso con i portali e avviso quando uno compare sulla minimappa; consigli su quale famiglia usare | elenco curato (`Data/PetsData.lua`), `PlayerModel:SetCreature`, `C_StableInfo`, `C_VignetteInfo` |

Il levelling è volutamente leggero: per le guide passo per passo esistono addon dedicati,
come RestedXP.

**Come leggere il pannello**
- **Selettori** in cima alle schede: obiettivo (Oggi), filtro (Delve e Pet), professione e
  sezione (Professioni), profilo e sezione (Oro). La scelta viene ricordata. I pulsanti verdi
  sono azioni, per esempio avviare o fermare la sessione di farm.
- **Riquadri colorati:** blu per le informazioni e le cose da fare (aprire una finestra, fare
  una scansione), verde per i consigli, arancione per gli avvisi.
- **Barre:** livello della professione con le fasi della guida e il segno del punto in cui sei,
  Concentrazione, esperienza (con il riposo), Great Vault (con le soglie degli slot),
  frammenti delle delve, diario delle missioni.
- **Passi numerati:** il numero a sinistra indica l'ordine oppure i punti da mettere in un nodo
  della specializzazione.
- **Tabelle:** world quest ed eventi, delve, zone per livello, ricette (punti e costo a punto),
  lista della spesa (quanto comprare, quanto hai, costo), fonti dei punti conoscenza, oggetti
  delle borse, materiali da farmare, pet per zona e pet consigliati per contenuto.

Ogni informazione sta in una sola scheda: le world quest si leggono solo in Oggi, la Great Vault
è in Oggi, Concentrazione e punti conoscenza sono in Professioni; le altre schede rimandano lì.

**Clic sulle righe**
- **Clic sinistro:** calcola il **percorso più veloce** (vedi sotto) e mette il waypoint sul
  primo passo.
- **Maiusc + clic sinistro:** solo il waypoint sulla destinazione.
- **Clic destro:** link Wowhead da copiare (pagina della missione, della valuta, dell'NPC,
  oppure una ricerca per nome).

## Percorso più veloce

WoW non offre agli addon un calcolo dei percorsi, quindi il Companion usa:
- una **tabella di portali** curata a mano;
- un grafo di **regioni**: i continenti, più alcune zone separate che si raggiungono con un
  portale (Harandar, Voidstorm e le zone di Cataclysm collegate agli Earthshrine: Mount Hyjal,
  Twilight Highlands, Vashj'ir).

Il percorso scelto è quello con meno passaggi. Considera i portali della tua fazione e la
**Pietra del ritorno**, se è pronta e il punto di ritorno è un centro conosciuto (per esempio
Silvermoon). Dentro una regione si vola.

Per ogni percorso il Companion:
- **scrive le istruzioni passo per passo** in chat e in fondo al pannello, per esempio:
  - "Prendi il portale per Silvermoon City a Orgrimmar (56.5, 89.0) - nella sala dei portali";
  - "Prendi il portale per Harandar a Silvermoon City (36.7, 68.6)";
  - "Vola fino a …";
- **mette il waypoint sul passo attuale** e passa da solo al successivo quando arrivi nella
  regione giusta;
- **si annulla** con il pulsante "Annulla" o con `/rac stop`.

**Portali conosciuti (12.1).** Fonti: wago.tools per gli ID delle mappe, la guida di method.gg
per Silvermoon, warcraft.wiki.gg per le sale dei portali di Stormwind e Orgrimmar (disposizione
della patch 12.0.1) e per gli Earthshrine, la pagina dell'oggetto su Wowhead per Voidstorm.

| Da | Verso | Coordinate |
|---|---|---|
| Silvermoon City | Stormwind / Orgrimmar (per fazione) | 53.3, 66.2 |
| Silvermoon City | Harandar | 36.7, 68.6 |
| Silvermoon City | Voidstorm | 35.3, 65.7 |
| Voidstorm | Silvermoon City | 51.6, 70.2 |
| Stormwind (Wizard's Sanctum) | Silvermoon · Dornogal · Valdrakken | 48.7, 95.1 · 49.1, 92.0 · 48.8, 93.5 |
| Stormwind (Wizard's Sanctum) | Dalaran (Northrend) · Jade Forest | 44.4, 89.7 · 45.7, 87.2 |
| Stormwind (stanza sul retro) | Azsuna · Stormshield (Draenor) | 42.0, 91.4 · 41.3, 90.0 |
| Orgrimmar (Pathfinder's Den, piano superiore) | Silvermoon · Dornogal · Valdrakken | 56.0, 88.2 · 58.6, 91.3 · 57.1, 87.3 |
| Orgrimmar (Pathfinder's Den, piano superiore) | Dalaran (Northrend) · Jade Forest | 56.2, 91.7 · 57.5, 92.3 |
| Orgrimmar (Pathfinder's Den, piano inferiore) | Azsuna · Warspear (Draenor) | 57.2, 88.3 · 55.2, 92.0 |
| Eastern / Western Earthshrine | Mount Hyjal · Twilight Highlands · Vashj'ir | senza coordinate; ogni portale si sblocca con la missione introduttiva della zona |
| Dornogal | Stormwind / Orgrimmar | da verificare (Foundation Hall, nord-est) |

**Limiti**
- Non conosce il portale di ritorno da Harandar: da lì propone il volo o la Pietra del ritorno.
- Per le espansioni precedenti conosce solo i portali delle capitali verso Northrend,
  Pandaria, Broken Isles, Dragon Isles e Draenor: da lì in poi si vola. Non sa come entrare
  nell'Emerald Dream.
- Non considera i teletrasporti di classe (per esempio quelli del mago) né gli oggetti di
  teletrasporto.
- Le coordinate vanno aggiornate se Blizzard sposta i portali; la tabella è in
  `Data/Travel.lua`.

## Pet da cacciatore

Il gioco non dà agli addon l'elenco delle bestie domabili, quindi la scheda **Pet** usa una
tabella curata a mano (`Data/PetsData.lua`, ottobre 2026): 22 rari, elite e pet dall'aspetto
unico di Harandar, Voidstorm, Eversong Woods e Zul'Aman. La zona in cui ti trovi è in cima.

Per ogni pet:
- **famiglia e abilità di famiglia** (riduzione cure, schivata, purificazione, rallentamento);
- **dove si trova:** zona, sottozona e coordinate quando sono note;
- **requisiti:** *esotico* (solo Beast Mastery), *Florafaun* (serve il libro "Trials of the
  Florafaun Hunter", o essere Haranir), *libro* (il rare può lasciare quel libro);
- **in verde** i pet che hai già: l'elenco si legge quando apri la stalla da uno Stable Master,
  più il pet che hai evocato.

**Spirit beast.** In Midnight non ce ne sono da domare: Petopia segna gli Spirit Pangos come
non domabili. La scheda elenca quindi le **28 spirit beast domabili delle espansioni precedenti**,
divise per continente:
- **facili**, sempre presenti: Mana Saber, Leyline Prowler e Thicket Manahunter a Suramar;
- **rare dall'aspetto unico:** Loque'nahak, Gondria, Skoll, Arcturis, Ankha, Magria,
  Ban'thalos, Karoma, Ghostcrawler, Lightning Paw, Bulvinkel, più Myonix e Pashya;
- **elite:** i tre porcospini di Pandaria (Gumi, Hutia, Degu), Bloodgullet, Sul'raka, Nah'qi;
- **speciali:** Elegon (raid), Aradan (dungeon The Rookery, serve un martello), Gon e il Lost
  Spectral Gryphon (da evocare), Hati e Gara (catene di missioni).

Per ognuna il tooltip spiega **come domarla** (togliere l'armatura, portarla sotto il 30%,
usare Flare, cosa cliccare per evocarla, quale sblocco serve). Il filtro in cima alla scheda ha
anche la voce "solo spirit beast". Sono tutte esotiche: servono la specializzazione Beast Mastery.

**Anteprima.** Passando il mouse su una riga compare a lato del pannello il **modello 3D**
della creatura (trascina per ruotarlo, rotellina per lo zoom). Se il client non ha ancora il
modello compare un avviso: il clic destro dà la pagina Wowhead con le immagini.

**Percorso.** Il clic sinistro calcola il percorso più veloce, portali compresi (per esempio
Stormwind → Silvermoon → portale per Harandar). Per i rari senza coordinate il percorso arriva
alla zona e indica la sottozona da cercare.

**Rari sulla minimappa.** Quando uno dei rari dell'elenco compare sulla minimappa ricevi un
avviso in chat con la posizione esatta presa dal gioco, e la riga diventa gialla per 30 minuti
(con il percorso verso quel punto). L'avviso si disattiva dalle opzioni.

**Quale pet usare.** Una tabella "contenuto → pet consigliato" riassume i consigli di Icy Veins
per Beast Mastery (12.1): Aqiri per raid e Mitiche+, famiglie con riduzione delle cure,
Clefthoof per il gioco in solitaria, Whiptail per il PvP, Feathermane per Updraft. Il tooltip
di ogni riga spiega il perché.

**Fonti.** Elenchi, note di posizione e istruzioni da [wow-petopia.com](https://www.wow-petopia.com),
coordinate dalle pagine degli NPC su Wowhead, rari Florafaun dalla guida di
[method.gg](https://www.method.gg/guides/how-to-tame-florafaun-pets-in-midnight), consigli
dalla [guida pet di Icy Veins](https://www.icy-veins.com/wow/beast-mastery-hunter-pets-guide).
I testi sono riassunti, non copiati.

**Limiti**
- L'addon non doma e non seleziona bersagli: mostra solo dove andare.
- Spawn, famiglie e requisiti vanno verificati in gioco; Blizzard può cambiarli con le patch.
- Le famiglie sono in inglese, come compaiono su Petopia e Wowhead.

## Oggi: attività consigliate

La scheda **Oggi** ha in cima il selettore dell'**obiettivo**. Le world quest sono lette dal
gioco in tutte le zone di Quel'Thalas (Coiled Isle compresa) e nelle zone del continente in cui
ti trovi, con le loro ricompense; il clic su una riga calcola il percorso.

**Riepilogo** (la vista iniziale)
- **Da fare adesso:** la cosa migliore per ogni obiettivo (per esempio l'upgrade più grande, la
  categoria della Vault più vicina a uno slot) e l'avviso se la Great Vault ha ricompense da
  ritirare.
- **Eventi e festività** di oggi in una tabella, con il tempo rimasto.
- **World quest in scadenza**, con la ricompensa in colonna (le prime 15; le altre si vedono
  scegliendo un obiettivo).
- **La settimana:** barra del Traveler's Log e tempo ai reset giornaliero e settimanale.

**Equipaggiamento**
- Le world quest che danno un oggetto **migliore di quello che indossi** in quello slot (per anelli,
  monili e armi si confronta il pezzo più basso), ordinate per livelli guadagnati.
- Per ogni oggetto le **due statistiche principali**, in verde se sono le migliori per te e in
  arancione se sono poco adatte, con la percentuale di "statistiche giuste" rispetto al tuo pezzo.
- Le world quest con **crest** (Mistcrest) per potenziare quello che hai.
- La **priorità delle statistiche** della tua specializzazione con i tuoi valori attuali:

  Tutte le 40 specializzazioni. "Livello oggetto" vuol dire che conta prima di tutto il resto;
  "=" indica statistiche che valgono uguale. Abbreviazioni: Crit = Critico, Cel = Celerità,
  Mae = Maestria, Vers = Versatilità.

  | Classe | Specializzazione | Priorità (12.1) |
  |---|---|---|
  | Warrior | Arms | Crit > Cel > Mae > Vers |
  | | Fury | Mae > Cel > Crit = Vers |
  | | Protection | livello oggetto, poi Cel > Crit = Vers > Mae |
  | Paladin | Holy | livello oggetto; raid: Mae > Cel = Crit > Vers; Mitiche+: Cel = Crit > Vers > Mae |
  | | Protection | livello oggetto, poi Cel > Crit > Vers > Mae |
  | | Retribution | Mae > Cel > Crit > Vers |
  | Death Knight | Blood | Deathbringer: Crit = Vers = Mae > Cel; San'layn: Cel > Crit = Vers = Mae |
  | | Frost | Crit > Mae > Cel > Vers |
  | | Unholy | Crit > Mae > Cel > Vers |
  | Rogue | Assassination | Crit > Cel > Mae > Vers |
  | | Outlaw | Cel > Crit > Vers > Mae |
  | | Subtlety | Trickster: Mae > Cel > Crit > Vers; Deathstalker: Cel > Mae > Crit > Vers |
  | Demon Hunter | Havoc | Crit > Mae > Cel > Vers |
  | | Vengeance | livello oggetto, poi Cel > Crit = Vers = Mae |
  | | Devourer | Mae > Cel > Crit > Vers |
  | Monk | Brewmaster | livello oggetto, poi Crit = Vers > Mae > Cel |
  | | Windwalker | Cel > Mae = Crit > Vers |
  | | Mistweaver | Cel > Crit = Vers > Mae |
  | Druid | Balance | Mae > Cel = Crit > Vers |
  | | Feral | livello oggetto, nessuna priorità fissa |
  | | Guardian | livello oggetto, poi Cel > Vers > Crit > Mae |
  | | Restoration | livello oggetto; raid: Cel = Mae > Crit > Vers; Mitiche+: Cel > Mae > Vers > Crit |
  | Hunter | Beast Mastery | raid (bersaglio singolo): Mae > Cel > Crit > Vers; Mitiche+ e il resto: Mae > Crit > Vers > Cel |
  | | Marksmanship | Crit > Mae > Vers > Cel |
  | | Survival | Mae > Crit > Cel > Vers |
  | Mage | Arcane | Cel > Vers > Crit > Mae |
  | | Fire | Cel > Vers > Mae > Crit |
  | | Frost | Mae = Crit > Cel > Vers |
  | Priest | Discipline | livello oggetto, poi Cel > Mae > Crit > Vers |
  | | Holy | livello oggetto; raid: Crit > Mae > Vers > Cel; Mitiche+: Cel > Vers = Crit > Mae |
  | | Shadow | livello oggetto; Voidweaver e Archon, ciascuno con bersaglio singolo e più bersagli (Mae o Cel in testa) |
  | Shaman | Elemental | livello oggetto, poi Mae > Cel > Crit > Vers |
  | | Enhancement | livello oggetto; Stormbringer: Mae > Crit > Cel > Vers; Totemic: Mae > Cel > Crit > Vers |
  | | Restoration | livello oggetto, poi Crit > Vers > Cel > Mae |
  | Warlock | Affliction | bersaglio singolo: Crit > Cel = Mae > Vers; più bersagli: Cel = Crit > Mae > Vers |
  | | Demonology | Crit > Cel = Mae > Vers |
  | | Destruction | Cel > Crit = Mae > Vers |
  | Evoker | Devastation | Crit > Cel = Mae > Vers |
  | | Preservation | Mae > Crit > Cel > Vers |
  | | Augmentation | Mae > Cel = Crit > Vers |

  Dove l'ordine cambia per contenuto c'è un selettore raid / Mitiche+. Dove cambia con il
  **talento eroico** (Blood, Subtlety, Shadow, Enhancement) l'addon lo legge dal gioco; se non lo
  riconosce, per esempio con il client in italiano, compare un selettore con i due talenti. Sotto
  la tabella una nota spiega soglie e varianti (per esempio il tetto di Celerità del Subtlety).
  Una priorità generica non sostituisce una simulazione del personaggio.

  Fonti: per cacciatore e sciamano le guide di Icy Veins, per le altre classi le pagine sulle
  statistiche di method.gg aggiornate alla 12.1 (agosto-ottobre 2026), riassunte con parole nostre.
- Da dove arriva l'equipaggiamento nella Season 2 (traccia e livelli).

**Great Vault**
- Per dungeon, raid e mondo: barra con le soglie degli slot, quanto manca al prossimo e cosa
  conta (per esempio delve di livello 8+ o Prey Nightmare per la traccia Hero). Prima la categoria
  più vicina a un nuovo slot.
- Quanti slot servono per il bonus roll (Nebulous Voidcore) e la tabella dei livelli oggetto della
  Vault per chiave, livello di delve, Prey e raid.

**Reputazione**
- Il Renown di ogni fazione con quanto manca al livello successivo.
- Le world quest che danno reputazione alle fazioni non al massimo, prima quelle più vicine al
  prossimo livello.

**Oro**
- Le world quest con ricompensa in oro, dalla più ricca.

Per ogni obiettivo c'è anche un elenco delle **attività settimanali ricorrenti** della 12.1 (Great
Vault, Spark, Prey, delve abbondanti, Nemesis, world boss, Mitiche+, Coiled Isle, traguardi di
Renown, ordini delle professioni).

**Limiti**
- Le ricompense delle world quest arrivano dal server dopo qualche secondo: la lista si completa
  da sola.
- Il confronto usa livello oggetto e statistiche secondarie, non gli effetti speciali o i set.
- L'elenco settimanale e i livelli della Vault vanno aggiornati a ogni stagione.

## Guida alle professioni

La scheda **Professioni** ha due selettori in cima: la **professione** e la **sezione**. Sotto i
selettori, per la professione scelta:
- una barra della **Concentrazione**, arancione quando è piena e la stai sprecando;
- i **punti conoscenza** non spesi.

Concentrazione e conoscenza compaiono dopo che hai aperto la professione almeno una volta.

**Livellamento**
- Una **barra da 1 a 100** (da 1 a 300 per la Pesca) divisa nelle fasi della guida, con il segno del tuo livello.
- La **fase attuale** in evidenza (per esempio Leatherworking 60-91: "crea una delle ricette di
  livello medio, circa 35 creazioni") e la fase successiva.
- Il trainer di Silvermoon e l'elenco di **tutte le fasi**, con quella attuale evidenziata.

**Cosa creare** (solo professioni di creazione)
- Quando apri la finestra della professione, l'addon legge le ricette di Midnight che conosci:
  colore (arancione, gialla, verde), punti per creazione, prime creazioni e materiali.
- In cima, **cosa fare adesso**: quale ricetta creare e quante volte per i prossimi 10 punti.
- Una tabella delle ricette per salire, dalla più economica (**costo a punto** con i prezzi della
  scansione d'asta, di Auctionator o di TSM; per le gialle e le verdi i punti sono una stima).
- Le **prime creazioni** ancora da fare (1 punto conoscenza ciascuna).
- La **lista della spesa**: quanto comprare, quanto hai già (borse, banca, banca dei reagenti,
  banca della brigata) e il costo. Per i materiali con più qualità conta tutte quelle che hai e
  propone la più economica.

**Per l'oro** (professioni di creazione e Cucina)
- Per ogni ricetta che conosci e che produce un oggetto in vendita all'asta: **guadagno a
  creazione** = prezzo d'asta più basso, meno la commissione del 5%, per i pezzi prodotti, meno i
  materiali ai prezzi d'asta (anche quelli che hai già, perché l'alternativa è venderli).
- In cima la ricetta che **conviene di più**, con un avviso se ce ne sono pochi in vendita
  (mercato piccolo). La tabella mostra guadagno, prezzo e quantità in vendita; il tooltip i
  materiali e il costo.
- Per le ricette con ranghi di qualità usa il rango che il gioco calcola con i materiali base.
- I materiali che si comprano dal venditore non hanno prezzo d'asta: il guadagno è segnato con
  `*` perché il loro costo manca.
- L'equipaggiamento vincolato non è all'asta e resta fuori: per quello contano gli ordini di
  lavoro.
- Servono la finestra della professione aperta almeno una volta e una scansione dei prezzi (o
  Auctionator, TSM). Multicraft, Resourcefulness e Concentrazione non sono nel calcolo: possono
  solo alzare il guadagno.

**Specializzazioni**
- Il **consiglio per il tuo personaggio**, in base a classe (tipo di armatura) e specializzazione:

  | Professione | Consiglio |
  |---|---|
  | Leatherworking | maglia (cacciatore, sciamano, evocatore): **Safeguarding Scales**, con il set epico Farstrider's; cuoio: **Lasting Leather**, con il set Silvermoon Agent's |
  | Blacksmithing | **Weaponsmithing** con il ramo dell'arma della tua specializzazione (vedi sotto, di solito l'upgrade più grande); piastre: **Armorsmithing** |
  | Tailoring | stoffa: **Sin'dorei Finery**; per tutti: i cooldown dei tessuti e il mantello abbellito |
  | Jewelcrafting | **Alluring Accessories**: anelli e collane |
  | Engineering | **Combat Analytics**: occhiali, bracciali, stivali e pistole (per il cacciatore a distanza) |
  | Inscription | **Blueprints**: archi, bastoni (anche con Agilità) e off-hand, secondo la specializzazione |
  | Alchemy | 15 punti in **Fluent in Flasks** per raid e Mitiche+; per l'oro la build delle pozioni |
  | Enchanting | **Concentrazione** se hai poco tempo, **Vendita di incantamenti** per l'oro in serie |
  | Herbalism | druido: subito Bountiful Harvests; altre classi: prima Botany (raccolta in sella) |

- **Armi per specializzazione di classe.** In Midnight le armi si creano così: Blacksmithing
  (Weaponsmithing: ramo **Hafted Weapons** per asce, mazze e armi ad asta, ramo **Blades** per
  spade, pugnali e warglaive, anche con Intelletto; scudi nel ramo Large Plate di Armorsmithing),
  Inscription (bastoni, off-hand, archi), Engineering (fucili). Il consiglio segue l'arma che usa
  la tua specializzazione:

  | Armi | Specializzazioni | Consiglio |
  |---|---|---|
  | due mani con Forza | Arms, Retribution, Blood, Unholy | Weaponsmithing, Hafted o Blades |
  | due armi | Fury, Frost (Death Knight) | Weaponsmithing (vale doppio) |
  | una mano e scudo | Protection (Warrior e Paladin) | Weaponsmithing per l'arma, Large Plate per lo scudo |
  | pugnali | Assassination, Subtlety | Weaponsmithing, Blades |
  | una mano con Agilità | Outlaw, Enhancement | Weaponsmithing, Hafted e/o Blades |
  | warglaive | Havoc, Vengeance, Devourer | Weaponsmithing, Blades |
  | bastone o arma ad asta | Brewmaster, Windwalker, Feral, Guardian, Survival | Hafted (armi ad asta) o bastone con Agilità di Inscription |
  | arco o fucile | Beast Mastery, Marksmanship | arco di Inscription o fucile di Engineering |
  | incantatori | Mage, Priest, Warlock, Evoker, Balance, Restoration (Druid), Mistweaver | bastone e off-hand di Inscription, oppure arma a una mano con Intelletto di Blacksmithing |
  | incantatori con scudo | Holy (Paladin), Elemental, Restoration (Shaman) | arma a una mano con Intelletto di Blacksmithing; off-hand di Inscription al posto dello scudo |

- La **panoramica** delle quattro specializzazioni e cosa sblocca ciascuna (con i nomi del tuo
  client, che in italiano possono essere tradotti).
- **Quale build scegliere:** una tabella con lo scopo di ogni build (in verde quella consigliata
  per te) e un selettore per vederne una. La build scelta è divisa in **fasi** ("Fase 1 -
  Multicraft") con i **punti da mettere in ogni nodo** e il totale.

**Conoscenza**
- Una tabella delle fonti dei punti conoscenza (punti e frequenza) e le eccezioni: catena di
  missioni per sbloccare la missione del trainer, Treatise, Enchanting, raccolta, reset unico
  della 12.1.

Per le professioni di raccolta (Herbalism, Mining, Skinning) ci sono Livellamento,
Specializzazioni e Conoscenza, senza il calcolo delle ricette.

**Cucina e Pesca.** Sono professioni secondarie: niente specializzazioni né punti conoscenza.
- **Cucina** (1-100): Livellamento (Spiced Biscuits, Felberry Figs, poi l'alternanza con le
  versioni Hearty) e Cosa creare, con lo stesso calcolo delle ricette delle altre professioni.
  In più: banchetti e cibo migliore, cibo economico, attrezzi.
- **Pesca** (1-300): solo Livellamento, con le zone per fascia di livello (Eversong Woods,
  Zul'Aman, Harandar), i punti extra (Fishlog, Darkmoon Faire, Patient Treasure), i pesci che
  servono per banchetti ed esche, canne, esche e lenza.

**Fonti.** Guide pubbliche sulle professioni di Midnight (livellamento, fonti di conoscenza,
build delle specializzazioni, ricette delle armi, Cucina e Pesca), riassunte con parole nostre. ID delle professioni di
Midnight dalla tabella SkillLine di wago.tools.

**Limiti**
- La lettura avviene solo con la finestra della professione aperta, quindi i dati invecchiano:
  riaprila dopo aver salito qualche punto.
- Le ricette non imparate non entrano nel calcolo: la guida ricorda quando tornare dal trainer.

## Oro: strategie, borse e farm

La scheda **Oro** ha in cima due selettori: il **profilo** di gioco e la **sezione** (Strategie,
Borse e prezzi, Da farmare). Il profilo vale per tutte e tre le sezioni.

**Strategie.** Le tue professioni con la **fascia per fare oro** (S, A o B) accanto al nome; poi,
per ogni professione, un riquadro con il **perché** della sua fascia e i **passi numerati**
adatti al profilo; in fondo i consigli validi per tutti. Concentrazione, punti conoscenza e build
di vendita sono nella scheda Professioni, che a sua volta rimanda qui per cosa conviene vendere.

Il profilo si sceglie con il selettore, con `/rac profilo` o dalle opzioni:

| Profilo | Pensato per | Tipo di strategie |
|---|---|---|
| **Occasionale** | poche ore a settimana | Great Vault, oggetti BoE, raccolta lungo il percorso, vendita in blocco |
| **Medio** | qualche sessione a settimana | raccolta + creazione collegata, Concentrazione spesa con regolarità, ordini dei Patron |
| **Assiduo** | ogni giorno, più personaggi | catene complete (raccolta → creazione), ordini su misura con rank massimo, decorazioni per l'housing, controllo dei margini |

Per ogni professione ci sono consigli diversi per ciascun profilo. Senza professioni, la scheda
suggerisce quali prendere.

Accanto a ogni professione c'è la **fascia per fare oro** della classifica di Icy Veins
aggiornata per la Season 2 (agosto 2026):

| Fascia | Professioni |
|---|---|
| S | Inscription, Jewelcrafting, Tailoring, Alchemy con le pozioni |
| A | Enchanting, Alchemy con i flask, Blacksmithing, Engineering, Leatherworking (equip su ordinazione) |
| B | Mining, Herbalism, Skinning, Cooking, Fishing |

I consigli tengono conto della Season 2 e della 12.1. Per esempio: con l'Alchemy rendono le
pozioni create con Concentrazione, perché le erbe di rango 2 costano molto più di quelle di rango
1, mentre i flask costano soprattutto materiali senza qualità; il Leatherworking guadagna con gli
ordini di equipaggiamento, dove il cliente porta i materiali. Ci sono anche le ricette nuove della
12.1, come la Concentrated Silvermoon Health Potion.

Le strategie sono scritte per questo addon (riassumendo Icy Veins e guide pubbliche sulla 12.1) e non
riportano cifre in oro, perché prezzi e domanda cambiano da reame a reame: la scheda ricorda
sempre di controllare la casa d'aste.

### Borse e prezzi, Da farmare

I prezzi vengono dalla **scansione completa** della casa d'aste:
- Con la casa d'aste aperta compare il pulsante **"RotAssist: scansione prezzi"**.
- Blizzard consente una scansione ogni 15 minuti per account.
- I prezzi vengono salvati per reame e valgono per tutti i tuoi personaggi.

Se la scansione ha più di 3 giorni e hai **Auctionator** o **TSM**, si usano i loro prezzi.

**Borse e prezzi.** Due tabelle (oggetto, quantità, valore). Per ogni oggetto la scheda confronta il prezzo d'asta, al netto della commissione
del 5%, con il prezzo del vendor:
- **All'asta:** quando rende almeno 1 oro e il 25% in più del vendor.
- **Al vendor:** oggetti vincolati, grigi, oggetti senza prezzo d'asta, oppure quando l'asta
  renderebbe poco di più.

Il tooltip di ogni oggetto mostra prezzo d'asta, prezzo del vendor e guadagno a pezzo.

**Da farmare.** Dopo la scansione, l'addon individua da solo i **materiali dell'espansione
attuale** in vendita: erbe, minerali, pelli, stoffe, carne e pesce, elementali, materiali
d'incantamento. Li mostra in una tabella (materiale, prezzo, quantità in vendita, chi può
raccoglierlo o la resa misurata) ordinata in base al profilo:

| Profilo | Classifica |
|---|---|
| **Occasionale** | materiali che puoi raccogliere con le tue professioni (o chiunque), con mercato non vuoto, per valore unitario |
| **Medio** | stessi materiali, per valore pesato sulla profondità del mercato |
| **Assiduo** | tutti i materiali (in grigio quelli che richiedono una professione che non hai), per **oro all'ora misurato** dove c'è una sessione, altrimenti per valore e profondità |

**Sessione di farm.** Avviala con il pulsante verde in cima alla sezione Da farmare o con
`/rac farm`. L'addon
conta cosa entra nelle borse e ne mostra il valore e l'oro all'ora. Se la sessione dura almeno
5 minuti, la resa di ogni materiale viene ricordata e usata nella classifica.

**Limiti**
- I prezzi sono una fotografia dell'ultima scansione.
- La casa d'aste mostra cosa è in vendita, non cosa si vende davvero; la profondità del mercato
  è solo un'approssimazione.
- L'addon consiglia: comprare e mettere all'asta restano clic tuoi, come con Auctionator.

## Comandi

| Comando | Effetto |
|---|---|
| `/rac` | apre o chiude il pannello |
| `/rac oggi` · `delve` · `levelling` · `professioni` · `oro` · `pet` | apre la scheda (anche in inglese: `today`, `delves`, `leveling`, `professions`, `gold`, `pets`) |
| `/rac eventi` · `settimanale` · `attivita` · `asta` | nomi delle vecchie schede, ancora validi: aprono Oggi (Riepilogo o Great Vault) oppure Oro (Borse e prezzi) |
| `/rac profilo occasionale|medio|assiduo` | profilo per l'oro e i materiali da farmare (senza argomento passa al successivo) |
| `/rac stop` | annulla il percorso in corso |
| `/rac scan` | scansione dei prezzi (con la casa d'aste aperta) |
| `/rac farm` | avvia o ferma la sessione di farm |
| `/rac aggiorna` | aggiorna subito i dati |
| `/rac riepilogo` | riepilogo in chat: delve abbondanti, chiavi, Great Vault |
| `/rac config` | pannello opzioni |
| `/rac minimap` | mostra o nasconde l'icona sulla minimappa |
| `/rac lang auto\|it\|en` | lingua (auto = lingua del client) |
| `/rac reset` | riporta il pannello al centro |

C'è anche l'icona sulla minimappa e la voce nel menu AddOns: clic sinistro apre il pannello,
clic destro le opzioni. Il tooltip mostra il riepilogo.

## Come lavora

- **Solo fuori dal combattimento.** In combattimento il pannello non si aggiorna e mostra
  "aggiornamento sospeso". Non usa funzioni protette.
- **Scansioni con cache.** Delve ed eventi esplorano tutte le zone del gioco, le world quest
  solo il continente attuale. Il risultato resta in cache per 20 secondi; il pulsante
  "Aggiorna" la svuota.
- **Nessun dato da Wowhead.** Il link è un indirizzo da copiare: l'addon non scarica nulla.

## Da verificare in gioco

1. **Delve abbondanti:** le riconosco dall'icona sulla mappa (atlas contenente "bountiful",
   come in The War Within). Se in Midnight l'icona ha un altro nome, nessuna delve risulterà
   abbondante.
2. **Livello del compagno (Valeera):** letto come "reputazione di amicizia" della fazione del
   compagno.
3. **Restored Coffer Key (3028) e Coffer Key Shards (3310):** ID confermati come attuali,
   da vedere in gioco.
4. **Festività:** il calendario va caricato all'accesso; se la scheda resta vuota il primo
   minuto è normale.
5. **Nomi delle zone e continente:** le world quest mostrate sono quelle del continente in cui
   ti trovi. A Silvermoon dovrebbero essere quelle di Midnight.

6. **Portali:** coordinate e posizioni della tabella del percorso; in particolare i portali di
   Dornogal verso le capitali, che oggi hanno solo un'indicazione testuale.
7. **Concentrazione e conoscenza:** si leggono dopo aver aperto la professione una volta; da
   verificare che il valore resti aggiornato anche a finestra chiusa.

8. **Asta:** durata della scansione completa sul tuo reame e riconoscimento dei materiali di
   Midnight (categoria ed espansione degli oggetti).

9. **Pet:** anteprima 3D con `SetCreature` (alcune creature potrebbero non avere il modello
   finché non le incontri), elenco della stalla (`C_StableInfo`, campo `creatureID`) e
   avviso dei rari tramite le vignette della minimappa (le rare più vecchie potrebbero non
   averle).
10. **Portali delle capitali:** coordinate da warcraft.wiki.gg (patch 12.0.1) e posizione degli
    Earthshrine, da confermare in gioco.
11. **Professioni:** campi delle ricette (`relativeDifficulty`, `numSkillUps`, `firstCraft`),
    materiali obbligatori di `GetRecipeSchematic` e conteggio con la banca della brigata
    (`C_Item.GetItemCount`). Le probabilità di punto per le ricette gialle (50%) e verdi (15%)
    sono stime.
12. **Talento eroico:** riconosciuto per ID (Enhancement) o per nome inglese (Blood, Subtlety,
    Shadow). Con il client in italiano i nomi potrebbero essere tradotti: in quel caso compare
    il selettore. Gli ID dei talenti eroici delle altre classi vanno letti in gioco.
13. **Guadagno per ricetta:** campi `supportsQualities` e `qualityItemIDs` di `GetRecipeInfo`,
    rango atteso da `C_TradeSkillUI.GetCraftingOperationInfo` (senza materiali scelti) e
    quantità prodotta (`quantityMin`, `quantityMax` dello schema).
14. **Cucina e Pesca:** ID delle professioni di Midnight (Cucina 2908, Pesca 2911), livello
    massimo della Pesca (300) e lettura delle ricette di Cucina con la finestra aperta.

## Installazione

Copia la cartella `RotAssist_Companion` in `World of Warcraft\_retail_\Interface\AddOns\`,
oppure collegala con una junction come RotAssist. È un addon nuovo: dopo averlo aggiunto
serve riavviare il gioco.
