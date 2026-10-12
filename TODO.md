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

- [ ] Controlli dopo la patch 12.1.5 del 13 ottobre (API, ID delle mappe e delle valute, portali).
- [ ] Larghezze, altezze delle righe, tabelle e colori delle sei schede (oggi provati solo in
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

## 4. RotAssist per altre classi

- [ ] **RotAssist (rotazione):** oggi solo Hunter (Beast Mastery, Marksmanship, Survival) e
      Shaman (Elemental, Enhancement, Restoration). Aggiungere le altre classi una alla volta,
      con le stesse regole (nessuna automazione, abilità identificate per spellID). Prima classe
      da scegliere.
