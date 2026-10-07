# RotAssist – supporto alla rotazione per WoW Midnight (12.1)

Addon per World of Warcraft retail (Midnight, patch 12.1) che **mostra** quale abilità
premere per Hunter e Shaman. **Non lancia mai nulla**: non usa funzioni protette e non
simula input, nel rispetto dei Termini di Servizio di Blizzard.

## Perché un wrapper sopra Assisted Combat

In Midnight Blizzard ha introdotto i *secret values*: in combattimento risorse, aure e tempi
di cooldown sono leggibili dagli addon solo come valori da **mostrare**, non da usare per
decidere. Per questo motivo i motori di rotazione classici come Hekili non funzionano più.

RotAssist parte dal suggerimento nativo di **Assisted Combat**
(`C_AssistedCombat.GetNextCastSpell`). Sopra aggiunge le liste di priorità delle guide
**Icy Veins 12.1**, valutate solo su segnali leggibili:
- cooldown pronto o no;
- i tuoi cast;
- il bagliore dei proc;
- risorse in whitelist (per esempio Maelstrom Weapon).

## Spec supportate

| Classe | Spec | Hero talent |
|---|---|---|
| Hunter | Beast Mastery, Marksmanship, Survival | Pack Leader, Dark Ranger, Sentinel |
| Shaman | Elemental, Enhancement | Farseer, Stormbringer, Totemic |
| Shaman | Restoration (promemoria di cura) | Farseer, Totemic |

## Funzionalità

- **Riquadro dei suggerimenti:** icona grande per la prossima abilità più le due successive,
  con modalità bersaglio singolo / CLEAVE / AoE automatica o manuale.
- **Riquadro dei cooldown maggiori:** si illumina quando sono pronti, senza forzarne l'uso.
- **Avvisi:**
  - Hunter: pet morto o non in attacco, vita del pet, Hunter's Mark.
  - Shaman: Flame Shock, scudi, incantamenti dell'arma.
- **Comandi e interfaccia:**
  - `/rotassist` per tutti i comandi;
  - pannello nelle Opzioni di gioco;
  - icona sulla minimappa;
  - modalità debug che spiega ogni suggerimento.

## RotAssist Companion

Secondo addon del repository, indipendente da RotAssist e attivo solo fuori dal combattimento.
Le sue schede coprono:
- **Delve:** delve attive con le abbondanti in evidenza, chiavi, compagno.
- **Eventi:** eventi sulla mappa, world quest, festività.
- **Settimanale:** Great Vault, Traveler's Log, reset.
- **Levelling:** XP/ora e zone adatte al tuo livello.
- **Oro:** strategie per le tue professioni secondo il profilo (occasionale, medio, assiduo).
- **Asta:** cosa mettere all'asta e cosa vendere al vendor, quali materiali farmare, oro all'ora
  misurato.
- **Pet:** pet da cacciatore rari di Midnight con anteprima 3D, requisiti, percorso con i portali
  e avviso quando compaiono sulla minimappa.

Il clic su una destinazione calcola il **percorso più veloce**, portali compresi, con
istruzioni passo per passo.

Ogni riga offre un waypoint e un link Wowhead. Dettagli in
[RotAssist_Companion/README.md](RotAssist_Companion/README.md).

## Installazione

Copia la cartella [`RotAssist`](RotAssist) in `World of Warcraft\_retail_\Interface\AddOns\`.
Se vuoi anche il Companion, copia nello stesso posto [`RotAssist_Companion`](RotAssist_Companion).
Documentazione completa, piano di test e limiti noti sono in
[RotAssist/README.md](RotAssist/README.md) e [RotAssist_Companion/README.md](RotAssist_Companion/README.md).

## Struttura del repository

| Percorso | Contenuto |
|---|---|
| `RotAssist/` | l'addon di rotazione (Lua + XML, nessuna libreria esterna) |
| `RotAssist_Companion/` | l'addon per delve, eventi, settimanali, levelling, percorsi, oro, asta e pet da cacciatore |
| `docs/` | dati e analisi raccolti per i moduli |
| `tests/` | test in WoW simulato: sintassi Lua 5.1 e scenari con i dati nascosti del combattimento |

## Test

Con Node.js installato, dalla cartella `tests/`:

```bash
npm install
```

```bash
npm test
```

Il primo comando installa le dipendenze (solo la prima volta). Il secondo controlla la sintassi
di tutti i file e fa girare l'addon in un WoW simulato, in cui risorse, aure e cooldown sono
nascosti come in combattimento.

## Fonti e crediti

- **Priorità delle rotazioni:** guide [Icy Veins](https://www.icy-veins.com) per la patch 12.1,
  riassunte e adattate (le fonti sono citate in ogni modulo).
- **Dati sugli incantesimi:** dati di gioco di Blizzard, verificati in gioco con `/rotassist verify`;
  i link agli incantesimi puntano a [Wowhead](https://www.wowhead.com).

RotAssist non è affiliato né approvato da Blizzard Entertainment, Icy Veins o Wowhead.

## Licenza

[MIT](LICENSE)
