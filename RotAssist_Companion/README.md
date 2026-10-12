# RotAssist Companion (WoW Midnight 12.1)

Addon di supporto **fuori dal combattimento**: delve, eventi, world quest, obiettivi
settimanali e levelling, con waypoint e link Wowhead. È indipendente da RotAssist: si può
usare da solo.

**Stato:** versione 0.5.0, provata **solo in simulazione**. Alcune API vanno ancora
confermate in gioco (vedi "Da verificare in gioco").

## Schede

| Scheda | Contenuto | Fonte (API di Blizzard) |
|---|---|---|
| **Delve** | Restored Coffer Key, Coffer Key Shards della settimana, livello del compagno; delve attive su tutte le mappe, con le **abbondanti** in cima (filtro "solo abbondanti") | `C_AreaPoiInfo.GetDelvesForMap`, `C_CurrencyInfo`, `C_DelvesUI`, `C_GossipInfo` |
| **Eventi** | festività di oggi, eventi sulla mappa con tempo rimasto, world quest del continente in cui ti trovi (le elite evidenziate), ordinate per scadenza | `C_Calendar`, `C_AreaPoiInfo.GetEventsForMap`, `C_TaskQuest.GetQuestsOnMap` |
| **Settimanale** | Great Vault per tipo (dungeon, raid, delve e mondo) con avviso "ricompense da ritirare", Traveler's Log del mese, tempo ai reset | `C_WeeklyRewards`, `C_PerksActivities`, `C_DateAndTime` |
| **Levelling** | livello, XP, riposo, XP/ora della sessione con tempo stimato al livello successivo, livelli consigliati della zona, zone del continente adatte al tuo livello, missioni nel diario | `UnitXP`, `C_Map.GetMapLevels`, `C_QuestLog` |
| **Oro** | le tue professioni con Concentrazione e punti conoscenza da spendere; strategie per fare oro adatte al tuo **profilo** (occasionale, medio, assiduo) e alle tue professioni | `GetProfessions`, `C_TradeSkillUI`, `C_ProfSpecs` |
| **Professioni** | per ogni tua professione: la fase della guida 1-100 in cui ti trovi, cosa creare adesso spendendo meno (dalle ricette che conosci), cosa comprare togliendo quello che hai già, la specializzazione consigliata per il tuo equipaggiamento e dove prendere i punti conoscenza | `C_TradeSkillUI`, `C_Item.GetItemCount`, `C_ProfSpecs` |
| **Asta** | oggetti delle borse da mettere all'asta o vendere al vendor; materiali di Midnight da farmare per il tuo profilo; sessione di farm con oro all'ora reale | `C_AuctionHouse.ReplicateItems`, `C_Container`, `C_Item` |
| **Pet** | pet da cacciatore rari e notevoli di Midnight per zona e spirit beast di tutte le espansioni, con anteprima 3D, requisiti (esotico, Florafaun), istruzioni per domarli, percorso con i portali e avviso quando uno compare sulla minimappa; consigli su quale famiglia usare | elenco curato (`Data/PetsData.lua`), `PlayerModel:SetCreature`, `C_StableInfo`, `C_VignetteInfo` |

Il levelling è volutamente leggero: per le guide passo per passo esistono addon dedicati,
come RestedXP.

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
usare Flare, cosa cliccare per evocarla, quale sblocco serve). Il filtro in basso ha anche la
voce "solo spirit beast". Sono tutte esotiche: servono la specializzazione Beast Mastery.

**Anteprima.** Passando il mouse su una riga compare a lato del pannello il **modello 3D**
della creatura (trascina per ruotarlo, rotellina per lo zoom). Se il client non ha ancora il
modello compare un avviso: il clic destro dà la pagina Wowhead con le immagini.

**Percorso.** Il clic sinistro calcola il percorso più veloce, portali compresi (per esempio
Stormwind → Silvermoon → portale per Harandar). Per i rari senza coordinate il percorso arriva
alla zona e indica la sottozona da cercare.

**Rari sulla minimappa.** Quando uno dei rari dell'elenco compare sulla minimappa ricevi un
avviso in chat con la posizione esatta presa dal gioco, e la riga diventa gialla per 30 minuti
(con il percorso verso quel punto). L'avviso si disattiva dalle opzioni.

**Quale pet usare.** In cima alla scheda c'è un riassunto dei consigli di Icy Veins per
Beast Mastery (12.1): Aqiri per raid e Mitiche+, famiglie con riduzione delle cure, Clefthoof
per il gioco in solitaria, Whiptail per il PvP, Feathermane per Updraft.

**Fonti.** Elenchi, note di posizione e istruzioni da [wow-petopia.com](https://www.wow-petopia.com),
coordinate dalle pagine degli NPC su Wowhead, rari Florafaun dalla guida di
[method.gg](https://www.method.gg/guides/how-to-tame-florafaun-pets-in-midnight), consigli
dalla [guida pet di Icy Veins](https://www.icy-veins.com/wow/beast-mastery-hunter-pets-guide).
I testi sono riassunti, non copiati.

**Limiti**
- L'addon non doma e non seleziona bersagli: mostra solo dove andare.
- Spawn, famiglie e requisiti vanno verificati in gioco; Blizzard può cambiarli con le patch.
- Le famiglie sono in inglese, come compaiono su Petopia e Wowhead.

## Guida alle professioni

La scheda **Professioni** mostra, per ogni professione del personaggio:

1. **La fase della guida** in cui ti trovi, secondo il livello attuale (per esempio
   Leatherworking 60-91: "crea una delle ricette di livello medio, circa 35 creazioni"), con la
   fase successiva e il trainer di Silvermoon. Il tooltip mostra tutte le fasi da 1 a 100.
2. **Cosa creare adesso.** Quando apri la finestra della professione, l'addon legge le ricette
   di Midnight che conosci: colore (arancione, gialla, verde), punti per creazione, prime
   creazioni ancora da fare e materiali. Poi:
   - elenca le **prime creazioni** (ognuna vale 1 punto conoscenza);
   - ordina le ricette per **costo per punto**, usando i prezzi della scansione d'asta (o di
     Auctionator e TSM). Per le ricette gialle e verdi i punti sono una stima;
   - dice quante volte creare la migliore per i prossimi 10 punti.
3. **Cosa comprare.** Per le prime creazioni e per la ricetta migliore somma i materiali che
   servono, toglie quelli che hai già in borse, banca, banca dei reagenti e banca della brigata,
   e mostra cosa manca con il costo. Per i materiali con più qualità conta tutte quelle che hai e
   propone la più economica. Un materiale senza prezzo d'asta di solito si compra dal venditore
   accanto al trainer.
4. **La specializzazione consigliata** per l'equipaggiamento del tuo personaggio, in base alla
   classe (tipo di armatura) e alla specializzazione:

   | Professione | Consiglio |
   |---|---|
   | Leatherworking | maglia (cacciatore, sciamano, evocatore): **Safeguarding Scales**, con il set epico Farstrider's; cuoio: **Lasting Leather**, con il set Silvermoon Agent's |
   | Blacksmithing | armi da mischia: **Weaponsmithing** (di solito l'upgrade più grande); piastre: **Armorsmithing** |
   | Tailoring | stoffa: **Sin'dorei Finery**; per tutti: **Nimble Needlework** (cooldown dei tessuti, mantello abbellito) |
   | Jewelcrafting | **Alluring Accessories**: anelli e collane |
   | Engineering | **Combat Analytics**: occhiali, bracciali, stivali e pistole (per il cacciatore a distanza) |
   | Inscription | **Blueprints**: archi per il cacciatore a distanza, bastoni e off-hand per gli incantatori |
   | Alchemy | **Fluent in Flasks** (15 punti) per raid e Mitiche+; per l'oro la build delle pozioni; Transmutation Authority per l'Alchemist Stone |
   | Enchanting | **Elevating Equipment** |

   Nel client italiano le specializzazioni possono avere nomi tradotti: il tooltip mostra quelli
   del tuo client e cosa sblocca ciascuna.
5. **Le build delle specializzazioni** di wow-professions.com, per tutte le 11 professioni
   (anche quelle di raccolta): per esempio per Alchemy "Durata dei flask", "Consumabili da
   vendere" e "Trasmutazioni", per Leatherworking "Standard", "Ordini di lavoro" e "Casa
   d'aste". Il tooltip di ogni build spiega dove mettere i punti, fase per fase.
6. **Dove prendere i punti conoscenza:** prime creazioni, tesori, libro della reputazione,
   fonti settimanali e mensili, e il reset una tantum della patch 12.1.

Per le professioni di raccolta (Herbalism, Mining, Skinning) la scheda mostra la guida e le
build, senza il calcolo delle ricette.

**Fonti.** Guide "Leveling 1-100", "Recipes & Knowledge Points" e "Specialization Guide" di
[wow-professions.com](https://www.wow-professions.com) e la guida alle fonti di conoscenza di
[method.gg](https://www.method.gg/guides/all-profession-knowledge-point-sources-in-midnight),
riassunte. ID delle professioni di Midnight dalla tabella SkillLine di wago.tools.

**Limiti**
- La lettura avviene solo con la finestra della professione aperta, quindi i dati invecchiano:
  riaprila dopo aver salito qualche punto.
- Le ricette non imparate non entrano nel calcolo: la guida ricorda quando tornare dal trainer.

## Strategie per l'oro

La scheda **Oro** legge le tue professioni. Per ogni professione mostra:
- la **Concentrazione**, in arancione quando è piena e la stai sprecando;
- i **punti conoscenza** non spesi.

Questi due valori compaiono dopo che hai aperto la professione almeno una volta.

Il **profilo** si sceglie con il pulsante in basso nella scheda, con `/rac profilo` o dalle
opzioni:

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

Le strategie sono scritte per questo addon (riassumendo Icy Veins e wow-professions.com) e non
riportano cifre in oro, perché prezzi e domanda cambiano da reame a reame: la scheda ricorda
sempre di controllare la casa d'aste.

## Asta: cosa vendere e cosa farmare

I prezzi vengono dalla **scansione completa** della casa d'aste:
- Con la casa d'aste aperta compare il pulsante **"RotAssist: scansione prezzi"**.
- Blizzard consente una scansione ogni 15 minuti per account.
- I prezzi vengono salvati per reame e valgono per tutti i tuoi personaggi.

Se la scansione ha più di 3 giorni e hai **Auctionator** o **TSM**, si usano i loro prezzi.

**Borse.** Per ogni oggetto la scheda confronta il prezzo d'asta, al netto della commissione
del 5%, con il prezzo del vendor:
- **All'asta:** quando rende almeno 1 oro e il 25% in più del vendor.
- **Al vendor:** oggetti vincolati, grigi, oggetti senza prezzo d'asta, oppure quando l'asta
  renderebbe poco di più.

Il tooltip di ogni oggetto mostra prezzo d'asta, prezzo del vendor e guadagno a pezzo.

**Da farmare.** Dopo la scansione, l'addon individua da solo i **materiali dell'espansione
attuale** in vendita: erbe, minerali, pelli, stoffe, carne e pesce, elementali, materiali
d'incantamento. Li ordina in base al profilo:

| Profilo | Classifica |
|---|---|
| **Occasionale** | materiali che puoi raccogliere con le tue professioni (o chiunque), con mercato non vuoto, per valore unitario |
| **Medio** | stessi materiali, per valore pesato sulla profondità del mercato |
| **Assiduo** | tutti i materiali (in grigio quelli che richiedono una professione che non hai), per **oro all'ora misurato** dove c'è una sessione, altrimenti per valore e profondità |

**Sessione di farm.** Avviala con il pulsante in basso nella scheda o con `/rac farm`. L'addon
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
| `/rac delve` · `eventi` · `settimanale` · `levelling` · `oro` | apre la scheda (anche in inglese: `delves`, `events`, `weekly`, `leveling`, `gold`) |
| `/rac profilo occasionale|medio|assiduo` | profilo per le strategie sull'oro (senza argomento passa al successivo) |
| `/rac professioni` | apre la scheda Professioni (anche `prof` o `professions`) |
| `/rac stop` | annulla il percorso in corso |
| `/rac asta` | apre la scheda Asta |
| `/rac scan` | scansione dei prezzi (con la casa d'aste aperta) |
| `/rac farm` | avvia o ferma la sessione di farm |
| `/rac pet` | apre la scheda Pet (pet da cacciatore rari) |
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

## Installazione

Copia la cartella `RotAssist_Companion` in `World of Warcraft\_retail_\Interface\AddOns\`,
oppure collegala con una junction come RotAssist. È un addon nuovo: dopo averlo aggiunto
serve riavviare il gioco.
