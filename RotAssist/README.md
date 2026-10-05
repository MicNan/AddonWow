# RotAssist (WoW Midnight 12.1)

Supporto alla rotazione per Hunter e Shaman. Mostra cosa premere, **non lancia mai nulla**:
nessuna funzione protetta, nessun input simulato.

## Spec supportate

Tutte le priorità vengono dalle guide Icy Veins 12.1.

| Spec | Hero talent | Modalità | Stato |
|---|---|---|---|
| Beast Mastery | Pack Leader, Dark Ranger | ST, AoE | provata in gioco (manichini) |
| Marksmanship | Sentinel, Dark Ranger | ST, AoE (con Trick Shots) | solo simulazione |
| Survival | Sentinel, Pack Leader | ST, AoE | solo simulazione |
| Elemental | Farseer, Stormbringer | ST, CLEAVE (2-3), AoE (4+) | solo simulazione |
| Enhancement | Stormbringer, Totemic | ST, AoE | solo simulazione |
| Restoration | Farseer, Totemic | promemoria di cura (niente Assisted Combat) | solo simulazione |

Le altre classi e spec usano la modalità "Generico", che mostra solo il suggerimento di
Assisted Combat.

## Strategia (sintesi della Fase 1)

In combattimento Focus, Maelstrom di Elemental, mana, aure e tempi di cooldown sono
**secret values**: un addon può mostrarli ma non usarli per decidere. Per questo RotAssist
è un **wrapper ibrido sopra Assisted Combat**:

- **Icona grande**
  - Di base mostra `C_AssistedCombat.GetNextCastSpell()`, con il badge **N**.
  - Una regola `pin` della lista di priorità della spec la può sostituire (badge **R**, bagliore azzurro).
- **Regole**
  - Valutano solo segnali leggibili:
    - flag `isActive`/`isOnGCD` dei cooldown;
    - i propri cast (`UNIT_SPELLCAST_SUCCEEDED`);
    - il glow dei proc;
    - durate apprese fuori combattimento.
  - Tutto ciò che deriva dai cast è una **stima**.
- **Icone piccole**: le regole successive soddisfatte.

## Struttura

```
RotAssist/
  RotAssist.toc              Interface 120100, 120105; SavedVariablesPerCharacter: RotAssistDB
  Bindings.xml               tasto "Cambia modalità (Auto/ST/AoE)"
  Core/Init.lua              namespace, default, stampa, dispatcher eventi (pcall)
  Core/Locale.lua            testi dell'interfaccia (italiano)
  Core/API.lua               UNICO accesso alle API Blizzard: pcall + secret values -> nil
  Core/Tracker.lua           stato ricostruito: cast, timer buff, modello cariche, cooldown appresi
  Core/Enemies.lua           conteggio nemici dalle nameplate (euristico)
  Core/Engine.lua            predicati a tre valori, valutazione regole, fusione con Assisted Combat
  Core/Alerts.lua            libreria di tipi di avviso riutilizzabili
  Core/Core.lua              rilevamento spec/hero talent, eventi, ciclo di aggiornamento (10 Hz)
  UI/Glow.lua                icone, bagliore, trascinamento
  UI/MainFrame.lua           icona grande + 2 piccole, modalità, barra risorsa, barra pet
  UI/CooldownFrame.lua       cooldown maggiori (si illuminano quando pronti)
  UI/AlertFrame.lua          avvisi
  UI/Launcher.lua            icona minimappa (trascinabile) + voce nel menu AddOns della minimappa
  Specs/Generic.lua          ripiego: solo Assisted Combat
  Specs/Hunter_BeastMastery.lua   dati BM: spellID, priorità PL/DR × ST/AoE, avvisi, cooldown
  Specs/Hunter_Marksmanship.lua   dati MM: Sentinel/Dark Ranger, Precise Shots e Trick Shots dai cast
  Specs/Hunter_Survival.lua       dati SV: Sentinel/Pack Leader, Tip of the Spear contato dai cast
  Specs/Shaman_Elemental.lua      dati Ele: Farseer/Stormbringer, ST/CLEAVE/AoE, Flame Shock stimato
  Specs/Shaman_Enhancement.lua    dati Enh: Stormbringer/Totemic, stack di Maelstrom Weapon (whitelist)
  Specs/Shaman_Restoration.lua    promemoria di cura, scudi, incantamento dell'arma
  Config/Settings.lua        pannello Opzioni > AddOns > RotAssist (Settings API)
  Config/Slash.lua           /rotassist (alias /rota)
```

Per aggiungere una spec si crea `Specs/<Classe>_<Spec>.lua` con `ns:RegisterSpec(specID, {...})`
e lo si aggiunge al `.toc`. Non serve toccare il core.

## Installazione

1. Chiudi il gioco, oppure preparati a fare `/reload` dopo la copia.
2. Copia la cartella `RotAssist` (quella che contiene `RotAssist.toc`) in
   `World of Warcraft\_retail_\Interface\AddOns\`. Il risultato deve essere
   `...\AddOns\RotAssist\RotAssist.toc`, non `...\AddOns\RotAssist\RotAssist\...`.
3. Nella schermata dei personaggi apri **AddOns** e verifica che RotAssist sia attivo e non "obsoleto".
4. In gioco usa `/rotassist` per l'elenco dei comandi e `/rotassist unlock` per posizionare i riquadri.
5. Facoltativo: assegna un tasto in **Opzioni > Comandi rapidi > AddOns > RotAssist**.

## Comandi

| Comando | Effetto |
|---|---|
| `/rotassist show \| hide \| toggle` | mostra o nasconde l'addon |
| `/rotassist lock \| unlock` | blocca o sblocca i riquadri (sbloccati sono visibili e trascinabili) |
| `/rotassist scale 0.5-2` | cambia la scala |
| `/rotassist mode auto\|st\|aoe` | sceglie la modalità bersagli; senza argomento passa alla successiva |
| `/rotassist source hybrid\|native\|rules` | sceglie la fonte dell'icona principale |
| `/rotassist debug [on\|off]` | stampa una riga ogni volta che cambia il suggerimento, con il perché |
| `/rotassist why` | mostra lo stato di ogni regola: match, fail, unknown, skip, disabled |
| `/rotassist probe` | indica quali API sono **segrete in questo momento** |
| `/rotassist config` | apre il pannello opzioni |
| `/rotassist minimap` | mostra o nasconde l'icona sulla minimappa (la voce nel menu AddOns resta sempre) |
| `/rotassist reset` | riporta i riquadri al centro |
| `/rotassist wowhead [spellID]` | mostra il link Wowhead del suggerimento attuale (o dello spellID) |

## Piano di test: Beast Mastery

### 0. Verifica delle ipotesi (5 minuti, da fare per prima)

1. Fuori combattimento, con un manichino come bersaglio, esegui `/rotassist probe`: quasi tutto
   dovrebbe essere verde.
2. Attacca il manichino ed esegui `/rotassist probe` in combattimento. Annota cosa diventa
   **SEGRETO**. Ci aspettiamo:
   - **Segreti:** `UnitPower`, `start`/`duration` dei cooldown, `currentCharges`, `UnitHealth(pet)`
     e le aure.
   - **Verdi:**
     - `GetNextCastSpell`;
     - `isActive`/`isOnGCD`;
     - `maxCharges`;
     - `UnitExists`/`UnitIsDeadOrGhost` sul pet;
     - `UnitCanAttack`/`UnitAffectingCombat`/`UnitClassification` sul bersaglio.
   - **Incerto:** `IsSpellUsable`.
3. **Se `GetNextCastSpell` risulta SEGRETO o in errore**, la modalità ibrida degrada
   automaticamente sulle sole regole. Segnalamelo, perché cambia la strategia.

### 1. Manichino di addestramento: bersaglio singolo

- Il riquadro mostra 1 icona grande e 2 piccole.
  - Badge **N** quando segue Assisted Combat.
  - Badge **R** e bagliore azzurro quando interviene una regola.
- Usa `/rotassist debug on` e `/rotassist mode st`, poi attacca per 2 minuti e controlla:
  - [ ] **Bestial Wrath** appare appena è pronto (regola `bw`).
  - [ ] **Barbed Shot** appare prima di BW quando BW è a meno di un GCD, o quando sono imminenti
        2 cariche (`bs_pre_bw`).
  - [ ] **Pack Leader:** dopo BW il primo **Kill Command** è forzato (`kc_howl`).
  - [ ] **Dark Ranger:** dopo BW appare **Black Arrow** durante Withering Fire (10 s), poi
        **Wailing Arrow** verso la fine.
  - [ ] Kill Command non viene suggerito a 1 carica quando BW arriva entro 3 s (PL) o 4 s (DR).
- Esegui `/rotassist why` in vari momenti: le regole `cobra_fang` devono risultare `disabled`
  con il motivo indicato.
- Dopo il primo combattimento, `/dump RotAssistDB.learned` deve mostrare le durate apprese di
  BW, Barbed Shot e Kill Command. Confrontale con i valori del tooltip.

### 2. Più manichini o open world: AoE

- Attiva le nameplate nemiche (tasto V), passa a `/rotassist mode auto` e ingaggia 3 o più mob.
  - [ ] L'etichetta passa a `AUTO AOE (n)`.
  - [ ] Wild Thrash viene suggerito subito dopo BW o quando Beast Cleave è scaduto.
  - [ ] BW viene suggerito con Beast Cleave attivo.
- Con le nameplate disattivate la modalità resta ST: è il comportamento atteso, e il tasto
  manuale funziona.

### 3. Cooldown e avvisi

- [ ] Il riquadro cooldown mostra BW, Bloodshed e Call of the Wild (se conosciuti) e Primal Rage
      del pet. Si illumina quando sono pronti e mostra lo swipe in combattimento.
- [ ] Congeda il pet: compare **"Pet assente"**. Fallo morire: compare **"Pet morto"**.
- [ ] Metti il pet in passivo e attacca: dopo 3 s compare **"Pet non in attacco"**.
- [ ] Fuori combattimento, su un'elite o un boss senza Hunter's Mark: compare l'avviso, che
      sparisce dopo aver applicato il marchio.
- [ ] Barra del pet: diventa rossa sotto il 40%. Fuori combattimento è sicuro; in combattimento
      funziona solo se la curva colore nativa è supportata, verificalo.

### 4. Icona minimappa e menu AddOns

- [ ] L'icona compare sul bordo della minimappa, si trascina lungo il bordo e la posizione resta dopo `/reload`.
- [ ] I clic fanno quanto segue:
  - clic sinistro: apre le opzioni;
  - Maiusc + clic: mostra o nasconde l'addon;
  - clic destro: blocca o sblocca i riquadri;
  - clic centrale: cambia modalità.
- [ ] Il tooltip mostra spec, hero talent, modalità, fonte e stato.
- [ ] RotAssist compare anche nel menu AddOns della minimappa (ingranaggio), con gli stessi clic.
- [ ] `/rotassist minimap` nasconde l'icona e l'opzione nel pannello resta sincronizzata.

### 5. Robustezza: nessun errore Lua

Attiva `/console scriptErrors 1` e prova questi casi:

- cambio spec in città e durante il combattimento con un manichino;
- cambio hero talent;
- `/reload` in combattimento;
- nessun bersaglio;
- pet morto;
- montatura;
- morte del personaggio;
- ingresso in un dungeon o in una delve.

Non deve comparire nessun errore. Se compare "errore interno (ignorato)", esegui
`/rotassist debug` e mandami il testo.

## Piano di test: altre spec

Per ogni spec la procedura è la stessa:

1. `/reload`, poi `/rotassist log clear`, `/rotassist info` e `/rotassist debug on`.
2. Un minuto su un bersaglio, poi su un gruppo di mob (delve o open world).
3. Durante il combattimento lancia `/rotassist probe` e `/rotassist why`.
4. Alla fine `/rotassist debug off` e `/reload`.

| Spec | Cosa controllare in particolare |
|---|---|
| **Elemental** | Flame Shock rinnovato verso i 6 s; Lava Burst subito dopo Lava Surge (glow); Master of the Elements seguito da uno spender; modalità `CLEAVE` con 2-3 mob e `AOE` da 4; barra del Maelstrom arancione sopra l'85%; avvisi Lightning Shield e Flame Shock. |
| **Enhancement** | la barra mostra gli stack di Maelstrom Weapon in combattimento (in probe: "Maelstrom Weapon stack" non segreto); spender a 10 stack; Windstrike durante Ascendance; avvisi Windfury/Flametongue sull'arma. |
| **Restoration** | promemoria Healing Stream Totem a cariche piene e Stormstream Totem; nessun suggerimento di danno; fuori combattimento gli avvisi Water Shield, Earth Shield (su di te e su un alleato) ed Earthliving. |
| **Marksmanship** | dopo Aimed Shot viene suggerito Arcane Shot (Precise Shots); con 3+ mob, Multi-Shot prima di Aimed Shot/Rapid Fire (Trick Shots); Moonlight Chakram negli ultimi 5 s di Trueshot (Sentinel). |
| **Survival** | Kill Command quando Tip of the Spear è finito; Raptor Swipe solo con Tip; Wildfire Bomb vicino alle 2 cariche; avvisi pet. |

## Limiti noti

- **Le stime dai cast non vedono i reset.** Non vengono rilevati i reset dei cooldown e delle
  cariche causati da proc invisibili (per esempio i reset di Kill Command). Il modello si
  riallinea solo quando `isActive` cambia stato.
- **Dati non leggibili in combattimento:** Cobra Fang, Nature's Ally e il Focus. Le righe della
  guida che li usano sono `disabled`; ci pensa Assisted Combat.
- **Hunter's Mark** viene controllato solo fuori combattimento, perché le aure sono segrete in
  combattimento e nelle istanze ristrette.
- **Conteggio nemici:** nessun controllo di distanza. Conta i mob in combattimento con
  nameplate visibile.
- **Icone 2 e 3:** sono "le prossime regole soddisfatte adesso", non una simulazione del futuro.
- **Durate da verificare in gioco:** Beast Cleave (6 s) e le ricariche base di Barbed Shot e
  Kill Command. Si correggono da sole fuori combattimento.
- **Stime che si possono sbagliare:**
  - **Flame Shock:** il timer si azzera quando cambi bersaglio e non considera il raddoppio
    della durata con Fire Elemental.
  - **Stack di Stormkeeper e Tip of the Spear:** sono contati sui tuoi cast; non vedono le
    cariche aggiunte o tolte dai proc.
  - **Precise Shots e Trick Shots:** si accendono e si spengono in base ai tuoi cast.
- **Indizi dal glow da confermare:**
  - Hot Hand sul pulsante di Lava Lash;
  - Lock and Load su Aimed Shot;
  - Howl of the Pack Leader su Kill Command (Survival).
- **Non leggibili, quindi lasciati ad Assisted Combat:**
  - Maelstrom di Elemental (overcap);
  - buff del set 4p;
  - stack di Tempest;
  - Sentinel's Mark e Spotter's Mark sui bersagli;
  - Bullseye.
- **Restoration:** non sceglie chi curare, ricorda solo le abilità da non sprecare. Earth Shield
  sugli alleati si controlla fuori combattimento e solo in gruppo.

## Wowhead

Gli addon di WoW **non possono accedere a Internet**. Il collegamento a Wowhead passa quindi
da due strade.

**In gioco:** `/rotassist wowhead` (alias `/rotassist wh`) mostra l'URL Wowhead del suggerimento
attuale in un riquadro già selezionato, pronto per Ctrl+C. L'URL è nella lingua del client, per
esempio `wowhead.com/it/...`. Si può anche indicare uno spellID: `/rotassist wh 191634`.

**Strumento di sviluppo** `tools/wowhead.mjs` (Node 18+, nessuna dipendenza), da lanciare dalla
cartella del progetto:

```bash
node tools/wowhead.mjs verify
```

Controlla tutti gli spellID dei moduli (`local S = {...}` in `Specs/*.lua`): esistenza, nome,
cooldown, cariche e ricarica.

```bash
node tools/wowhead.mjs gen
```

Rigenera `RotAssist/Core/SpellData.lua`. Contiene i valori base senza talenti, che l'addon usa
solo come ultimo ripiego.

```bash
node tools/wowhead.mjs search withering fire
```

Trova lo spellID dato il nome inglese. Ci sono anche `spell <id...>`, `--ptr` per i dati del PTR
e `--refresh` per ignorare la cache.

Lo strumento è pensato per l'uso personale durante lo sviluppo. Fa poche richieste, con una
pausa tra l'una e l'altra e una cache locale, al servizio pubblico dei tooltip di Wowhead. Non
usarlo per scaricare dati in massa e rispetta i termini d'uso di Wowhead.

La prima verifica ha già trovato un errore: lo spellID di Withering Fire preso da Icy Veins
(430715) non esiste più ed è stato corretto in **466990**.

## Cosa aggiornare a ogni patch

1. Il campo `## Interface` nel `.toc`.
2. Gli spellID e le priorità in `Specs/*.lua`, confrontandoli con la guida Icy Veins aggiornata.
   Poi esegui `node tools/wowhead.mjs verify --refresh` e `node tools/wowhead.mjs gen`.
3. La pagina wiki "Patch X.Y/API changes", controllando le voci su secret values, `C_AssistedCombat`,
   `C_Spell` e `C_UnitAuras`.
4. L'output di `/rotassist probe` in combattimento, per vedere se qualcosa è diventato segreto
   o leggibile.
