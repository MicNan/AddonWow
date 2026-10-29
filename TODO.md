# Attività da fare

Piano di lavoro e attività aperte su RotAssist e RotAssist Companion. Le voci si spuntano quando
sono fatte; quelle provate solo in simulazione restano da confermare in gioco (fase 0).

## Piano

| Fase | Contenuto | Versione | Stato |
|---|---|---|---|
| 0 | Verifica in gioco dopo la patch 12.1.5 (13 ottobre), con screenshot | - | da fare |
| 1 + 2 | Sei schede (Oggi, Delve, Levelling, Professioni, Oro, Pet) e grafica uniforme | Companion 0.8.0 | fatta in simulazione |
| 3 | Priorità delle statistiche per tutte le specializzazioni, armi per specializzazione, Cucina e Pesca | Companion 0.9.0 | fatta in simulazione |
| 4 | RotAssist per altre classi, una alla volta (classe da scegliere) | RotAssist | da fare |

## 0. Verifica in gioco

- [x] Note della patch 12.1.5 lette (14 ottobre): Hunter e Shaman senza modifiche alla rotazione
      di RotAssist (rimosso Unload di Marksmanship, che RotAssist non usava; correzioni di bug).
      Companion 0.16.0: Labirinto di Kindo'jan nella scheda Delve, novità settimanali in Oggi.
- [ ] Controlli in gioco dopo la 12.1.5 (API, ID delle mappe e delle valute, portali, Labirinto).
- [ ] Larghezze, altezze delle righe, tabelle e colori delle sette schede (oggi provati solo in
      simulazione), anche con il client in italiano.
- [ ] Scansione d'asta corretta (una sola elaborazione per scansione).
- [ ] RotAssist in una delve (AoE) e le nuove specializzazioni con `/rotassist verify`.
- [ ] Talento eroico riconosciuto (nome inglese o selettore con il client in italiano) e ID
      di Cucina (2908) e Pesca (2911).

## 1. Razionalizzare le schede del Companion (0.8.0)

- [x] **World quest lette una volta sola:** in Oggi, per Quel'Thalas e le zone del continente in
      cui ti trovi. Il Riepilogo mostra quelle in scadenza, gli obiettivi le filtrano.
- [x] **Great Vault in un solo posto:** Oggi > Great Vault; il Riepilogo dà solo l'avviso delle
      ricompense da ritirare e la categoria più vicina a uno slot.
- [x] **Concentrazione e punti conoscenza** solo in Professioni; Oro rimanda lì.
- [x] **Strategie per l'oro e build di vendita** collegate con rimandi nei due sensi.
- [x] **Oro e Asta accorpati:** sezioni Strategie, Borse e prezzi, Da farmare.
- [x] **Profilo di gioco** visibile in tutte le sezioni di Oro, compresa Da farmare.
- [x] **Sei schede** al posto di nove: Eventi, Settimanale e Attività diventano Oggi. I vecchi
      comandi (`/rac eventi`, `settimanale`, `attivita`, `asta`) aprono ancora la sezione giusta.

## 2. Allineare la grafica in tutte le schede (0.8.0)

- [x] **Delve:** tabella (delve, zona, stato).
- [x] **Eventi e world quest** (ora in Oggi): tabelle con ricompensa, zona e tempo rimasto.
- [x] **Traveler's Log** come barra e reset in tabella (Oggi > Riepilogo).
- [x] **Levelling:** zona attuale e zone adatte come tabelle (zona, livelli).
- [x] **Borse e materiali da farmare** come tabelle.
- [x] **Pet:** elenchi per zona e spirit beast come tabelle (nome, famiglia o zona, note).
- [x] **Comandi in basso** sostituiti da selettori in cima: filtro delle delve, avvio della
      sessione di farm (pulsante verde).
- [x] **Coerenza dei testi:** stessi titoli per gli stessi concetti, 27 testi non più usati
      rimossi.

## 3. Estendere le funzionalità a tutte le classi e professioni (0.9.0)

- [x] **Priorità delle statistiche** (Oggi > Equipaggiamento) per tutte le 40 specializzazioni,
      con pari merito, varianti per contenuto (raid / Mitiche+) e per talento eroico (Blood,
      Subtlety, Shadow, Enhancement). Feral senza priorità fissa.
- [x] **Armi per specializzazione** (scheda Professioni): Blacksmithing con il ramo giusto
      (Hafted Weapons o Blades, scudi da Large Plate), Inscription (bastoni, off-hand, archi),
      Engineering (fucili).
- [x] **Cucina e Pesca** nella scheda Professioni: livellamento (Pesca fino a 300), cosa
      cucinare o pescare, attrezzatura; Cucina anche con il calcolo delle ricette.
- [x] **Cosa creare per l'oro** (Professioni > Per l'oro, 0.10.0): guadagno a creazione per ogni
      ricetta che conosci, dai prezzi della scansione d'asta (o Auctionator, TSM), con il rango di
      qualità atteso e l'avviso per i mercati piccoli. Da verificare in gioco.
- [x] **Ricette da imparare e liquidità** (0.11.0): guadagno delle ricette non ancora imparate
      con la fonte del gioco per impararle; liquidità alta/media/bassa da TSM o dalle
      scansioni, anche nel tooltip. Da verificare in gioco.
- [x] **Ordini di lavoro** (0.12.0): ordini letti al tavolo degli ordini (soprattutto Patron),
      con guadagno netto, ricompense e stato. Da verificare in gioco.
- [x] **Prezzo alto o basso** (0.13.0): prezzo attuale rispetto alla media (TSM o media mobile
      delle scansioni) nel tooltip e nella lista della spesa. Da verificare in gioco.
- [x] **Cosa creare: costo totale e ricette da imparare** (0.14.0): costo a creazione e totale,
      ricette non imparate che darebbero punti con la fonte, consiglio quando impararne una
      conviene. Da verificare in gioco.
- [x] **Dopo le prime prove in gioco** (0.15.0): costo e valore di ogni ricetta (anche con i
      tuoi materiali), professione al massimo senza avvisi fuorvianti, conteggio delle ricette
      lette, riga "media non ancora nota" nel tooltip, Concentrazione letta a finestra pronta,
      riquadro "I tuoi attrezzi".
- [x] **Guida alla Caccia (Prey)** (fatta da remoto come 0.13.0, unita nella 0.18.0): obiettivo
      "Caccia" nella scheda Oggi con sblocco, difficoltà e affissi, limiti settimanali,
      Preyhunter's Journey e catch-up, Ral'kala, gear in solo e routine settimanale. Guida
      statica, da verificare in gioco.

## Scheda Settimana (0.17.0)

- [x] Attività settimanali con stato, dove andare e guida; avviso Prey entrando in Midnight.
- [ ] ID delle missioni settimanali (Apex Cache, Abbondanza) e delle cacce Prey da `/rac missioni`,
      per lo stato automatico.

## 4. RotAssist per altre classi

- [x] **Paladin Protection** (RotAssist 0.4.0): priorità Icy Veins 12.1.5 (Templar, Lightsmith,
      ST e AoE) e difese in base alla vita (Word of Glory sotto il 50%, Ardent Defender e le altre
      sotto il 35%). Da verificare in gioco: `/rotassist verify` per gli spell ID, glow di Shining
      Light e Vanguard, override di Hammer of Light e Sacred Weapon, curva della vita negli scontri.

- [ ] **RotAssist (rotazione):** oggi solo Hunter (Beast Mastery, Marksmanship, Survival) e
      Shaman (Elemental, Enhancement, Restoration). Aggiungere le altre classi una alla volta,
      con le stesse regole (nessuna automazione, abilità identificate per spellID). Prima classe
      da scegliere.
