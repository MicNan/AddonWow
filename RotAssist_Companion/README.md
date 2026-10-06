# RotAssist Companion (WoW Midnight 12.1)

Addon di supporto **fuori dal combattimento**: delve, eventi, world quest, obiettivi
settimanali e levelling, con waypoint e link Wowhead. È indipendente da RotAssist: si può
usare da solo.

**Stato:** versione 0.2.0, provata **solo in simulazione**. Alcune API vanno ancora
confermate in gioco (vedi "Da verificare in gioco").

## Schede

| Scheda | Contenuto | Fonte (API di Blizzard) |
|---|---|---|
| **Delve** | Restored Coffer Key, Coffer Key Shards della settimana, livello del compagno; delve attive su tutte le mappe, con le **abbondanti** in cima (filtro "solo abbondanti") | `C_AreaPoiInfo.GetDelvesForMap`, `C_CurrencyInfo`, `C_DelvesUI`, `C_GossipInfo` |
| **Eventi** | festività di oggi, eventi sulla mappa con tempo rimasto, world quest del continente in cui ti trovi (le elite evidenziate), ordinate per scadenza | `C_Calendar`, `C_AreaPoiInfo.GetEventsForMap`, `C_TaskQuest.GetQuestsOnMap` |
| **Settimanale** | Great Vault per tipo (dungeon, raid, delve e mondo) con avviso "ricompense da ritirare", Traveler's Log del mese, tempo ai reset | `C_WeeklyRewards`, `C_PerksActivities`, `C_DateAndTime` |
| **Levelling** | livello, XP, riposo, XP/ora della sessione con tempo stimato al livello successivo, livelli consigliati della zona, zone del continente adatte al tuo livello, missioni nel diario | `UnitXP`, `C_Map.GetMapLevels`, `C_QuestLog` |
| **Oro** | le tue professioni con Concentrazione e punti conoscenza da spendere; strategie per fare oro adatte al tuo **profilo** (occasionale, medio, assiduo) e alle tue professioni | `GetProfessions`, `C_TradeSkillUI`, `C_ProfSpecs` |

Il levelling è volutamente leggero: per le guide passo per passo esistono addon dedicati,
come RestedXP.

**Clic sulle righe**
- **Clic sinistro:** calcola il **percorso più veloce** (vedi sotto) e mette il waypoint sul
  primo passo.
- **Maiusc + clic sinistro:** solo il waypoint sulla destinazione.
- **Clic destro:** link Wowhead da copiare (pagina della missione, della valuta, oppure una
  ricerca per nome).

## Percorso più veloce

WoW non offre agli addon un calcolo dei percorsi, quindi il Companion usa:
- una **tabella di portali** curata a mano;
- un grafo di **regioni**: i continenti, più Harandar e Voidstorm, che sono zone separate
  raggiungibili solo con portali.

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
per Silvermoon, le pagine degli oggetti su Wowhead.

| Da | Verso | Coordinate |
|---|---|---|
| Silvermoon City | Stormwind / Orgrimmar (per fazione) | 53.3, 66.2 |
| Silvermoon City | Harandar | 36.7, 68.6 |
| Silvermoon City | Voidstorm | 35.3, 65.7 |
| Voidstorm | Silvermoon City | 51.6, 70.2 |
| Stormwind City | Silvermoon City · Dornogal | 48.4, 94.5 · 47.5, 92.2 |
| Orgrimmar | Silvermoon City · Dornogal | 56.5, 89.0 · 57.4, 89.3 |
| Dornogal | Stormwind / Orgrimmar | da verificare (Foundation Hall, nord-est) |

**Limiti**
- Non conosce il portale di ritorno da Harandar: da lì propone il volo o la Pietra del ritorno.
- Non considera i teletrasporti di classe (per esempio quelli del mago) né gli oggetti di
  teletrasporto.
- Le coordinate vanno aggiornate se Blizzard sposta i portali; la tabella è in
  `Data/Travel.lua`.

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

Le strategie sono scritte per questo addon e non riportano cifre in oro, perché prezzi e domanda
cambiano da reame a reame: la scheda ricorda sempre di controllare la casa d'aste.

## Comandi

| Comando | Effetto |
|---|---|
| `/rac` | apre o chiude il pannello |
| `/rac delve` · `eventi` · `settimanale` · `levelling` · `oro` | apre la scheda (anche in inglese: `delves`, `events`, `weekly`, `leveling`, `gold`) |
| `/rac profilo occasionale|medio|assiduo` | profilo per le strategie sull'oro (senza argomento passa al successivo) |
| `/rac stop` | annulla il percorso in corso |
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

## Installazione

Copia la cartella `RotAssist_Companion` in `World of Warcraft\_retail_\Interface\AddOns\`,
oppure collegala con una junction come RotAssist. È un addon nuovo: dopo averlo aggiunto
serve riavviare il gioco.
