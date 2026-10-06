# RotAssist Companion (WoW Midnight 12.1)

Addon di supporto **fuori dal combattimento**: delve, eventi, world quest, obiettivi
settimanali e levelling, con waypoint e link Wowhead. È indipendente da RotAssist: si può
usare da solo.

**Stato:** versione 0.1.0, provata **solo in simulazione**. Alcune API vanno ancora
confermate in gioco (vedi "Da verificare in gioco").

## Schede

| Scheda | Contenuto | Fonte (API di Blizzard) |
|---|---|---|
| **Delve** | Restored Coffer Key, Coffer Key Shards della settimana, livello del compagno; delve attive su tutte le mappe, con le **abbondanti** in cima (filtro "solo abbondanti") | `C_AreaPoiInfo.GetDelvesForMap`, `C_CurrencyInfo`, `C_DelvesUI`, `C_GossipInfo` |
| **Eventi** | festività di oggi, eventi sulla mappa con tempo rimasto, world quest del continente in cui ti trovi (le elite evidenziate), ordinate per scadenza | `C_Calendar`, `C_AreaPoiInfo.GetEventsForMap`, `C_TaskQuest.GetQuestsOnMap` |
| **Settimanale** | Great Vault per tipo (dungeon, raid, delve e mondo) con avviso "ricompense da ritirare", Traveler's Log del mese, tempo ai reset | `C_WeeklyRewards`, `C_PerksActivities`, `C_DateAndTime` |
| **Levelling** | livello, XP, riposo, XP/ora della sessione con tempo stimato al livello successivo, livelli consigliati della zona, zone del continente adatte al tuo livello, missioni nel diario | `UnitXP`, `C_Map.GetMapLevels`, `C_QuestLog` |

Il levelling è volutamente leggero: per le guide passo per passo esistono addon dedicati,
come RestedXP.

**Clic sulle righe**
- **Clic sinistro:** waypoint sul punto (usa TomTom se è installato, altrimenti il waypoint di
  Blizzard).
- **Clic destro:** link Wowhead da copiare (pagina della missione, della valuta, oppure una
  ricerca per nome).

## Comandi

| Comando | Effetto |
|---|---|
| `/rac` | apre o chiude il pannello |
| `/rac delve` · `eventi` · `settimanale` · `levelling` | apre la scheda (anche in inglese: `delves`, `events`, `weekly`, `leveling`) |
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

## Installazione

Copia la cartella `RotAssist_Companion` in `World of Warcraft\_retail_\Interface\AddOns\`,
oppure collegala con una junction come RotAssist. È un addon nuovo: dopo averlo aggiunto
serve riavviare il gioco.
