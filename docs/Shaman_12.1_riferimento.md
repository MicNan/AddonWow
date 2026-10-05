# Shaman 12.1 – dati raccolti per i moduli RotAssist

Fonti:
- Icy Veins, guide alla rotazione 12.1:
  - [Elemental](https://www.icy-veins.com/wow/elemental-shaman-pve-dps-rotation-cooldowns-abilities), aggiornata il 10 ago 2026;
  - [Enhancement](https://www.icy-veins.com/wow/enhancement-shaman-pve-dps-rotation-cooldowns-abilities), aggiornata il 23 ago 2026;
  - [Restoration](https://www.icy-veins.com/wow/restoration-shaman-pve-healing-rotation-cooldowns-abilities), aggiornata il 10 ago 2026.
- **Spell ID:** tutti verificati su Wowhead il 5 ott 2026 con `node tools/wowhead.mjs spell ...`.
- **Priorità:** sono riassunte con parole nostre. Per il testo completo e aggiornato fa fede la guida.

## Legenda della colonna "Segnale in combattimento"

| Simbolo | Significato |
|---|---|
| ✅ | leggibile (cooldown `isActive`, override, risorsa secondaria in whitelist) |
| 🟡 | stimato dai propri cast (timer o contatore) |
| 💡 | glow del proc (`SPELL_ACTIVATION_OVERLAY_GLOW_*`), da confermare con `/rotassist probe` |
| ❌ | segreto: la regola si delega ad Assisted Combat (`disabled` oppure `onUnknown`) |

---

## Elemental (specID 262)

**Hero talent:**
- **Farseer:** chiave `Call of the Ancestors` (467646). È la scelta consigliata per raid e M+.
- **Stormbringer:** chiave `Tempest` (454009). La guida lo segnala come "non consigliato".

**Bersagli:** la guida ha liste distinte per **1**, **2**, **3** e **4+** bersagli. Nell'addon diventano:
- `ST` per 1 bersaglio;
- `CLEAVE` per 2 o 3 bersagli (nuova modalità da aggiungere al core);
- `AOE` per 4 o più.

### Bersaglio singolo

| # | Azione (sintesi) | Condizione | Segnale in combattimento |
|---|---|---|---|
| 1 | Stormkeeper | quasi sempre al cooldown; trattenerlo solo se Ascendance arriva a breve | ✅ cd, 🟡 Ascendance |
| 2 | Ancestral Swiftness (Farseer) | al cooldown | ✅ |
| 3 | Ascendance | sincronizzato con trinket e Bloodlust | ✅ (solo nel riquadro cooldown) |
| 4 | Flame Shock / Voltaic Blaze | rinnovo a ≤ 6 s (pandemic); senza Voltaic Blaze anche se Fire Elemental sta per finire | 🟡 timer da 18 s (36 s con Fire Elemental) |
| 5 | Elemental Blast / Earth Shock | con entrambi i buff del set 4p | ❌ buff del set |
| 6 | Lava Burst | Flame Shock attivo, nessun overcap di Maelstrom, Master of the Elements non attivo | 🟡 Flame Shock, ❌ Maelstrom, 🟡 MotE (attivato da Lava Burst, consumato dal cast successivo) |
| 7 | Tempest o Lightning Bolt potenziato da Stormkeeper | con Master of the Elements attivo (Stormbringer) | ✅ override di LB in Tempest, 🟡 MotE |
| 8 | Earth Shock / Elemental Blast | spender | ❌ Maelstrom → Assisted Combat |
| 9 | Lava Burst | Farseer: con Flame Shock attivo. Stormbringer: **solo** con Lava Surge | ✅ cariche, 💡 Lava Surge |
| 10 | Lightning Bolt / Tempest | filler | ✅ |

### 4+ bersagli

| # | Azione | Condizione | Segnale |
|---|---|---|---|
| 1 | Stormkeeper, Ancestral Swiftness, Voltaic Blaze, Ascendance | al cooldown (Stormkeeper: meglio se può colpire 5 bersagli con Chain Lightning) | ✅ |
| 2 | Earthquake / Elemental Blast | Farseer: Elemental Blast senza Antenati attivi e fino a 5 bersagli, altrimenti Earthquake | 🟡 Antenati (dal cast di Ancestral Swiftness), ❌ Maelstrom |
| 3 | Tempest | Stormbringer: con 2 stack di Tempest e meno di 4 di Stormkeeper | ❌ stack (✅ solo l'override) |
| 4 | Chain Lightning con Stormkeeper | se non fa overcap | 🟡 Stormkeeper (contatore dei cast), ❌ Maelstrom |
| 5 | Lava Burst | per consumare Purging Flames (talento) | 💡 Lava Surge |
| 6 | Chain Lightning | filler; Lava Surge si usa durante il movimento | ✅ |

**2 e 3 bersagli:** la struttura è simile a quella del bersaglio singolo, con queste differenze:
- 3 bersagli: si tiene attivo un solo Flame Shock.
- 2 bersagli: Flame Shock su entrambi; Earthquake si usa con gli Antenati attivi.
- Il filler è Chain Lightning.

Note utili per l'implementazione:
- **Flame Shock:** dura 18 s e si può rinnovare senza perdite sotto i 5,4 s (il 30%).
- **Maelstrom:** è la risorsa primaria, quindi segreta. Le regole di overcap restano ad Assisted Combat. Nell'interfaccia la barra si mostra comunque in modo esatto.

---

## Enhancement (specID 263)

**Hero talent:**
- **Stormbringer:** chiave `Tempest` (454009).
- **Totemic:** chiave `Surging Totem` (444995).

La guida indica come migliore scelta Stormbringer per il bersaglio singolo e Totemic per M+/AoE.

**Talenti che cambiano la lista:**
- Ascendance (114051);
- Deeply Rooted Elements (378270);
- Sundering (197214);
- Primordial Storm (1218047);
- Surging Elements (382042);
- Fire Nova (333974);
- Lashing Flames (334046).

Gli stack di **Maelstrom Weapon sono in whitelist** (aura 344179). È il segnale più importante della spec ed è leggibile in combattimento. Va confermato con `/rotassist probe`.

### Bersaglio singolo

| # | Azione | Condizione | Segnale |
|---|---|---|---|
| 1 | Voltaic Blaze (Totemic) | se Flame Shock non è attivo | ✅ cd, 🟡 Flame Shock |
| 2 | Surging Totem (Totemic) | al cooldown | ✅ |
| 3 | Sundering (Totemic) | una volta su due, insieme a Surging Totem | ✅ cd, 🟡 contatore |
| 4 | Lava Lash (Totemic) | con Hot Hand o Whirling Fire | 💡 Hot Hand (da verificare), ❌ Whirling Fire |
| 5 | Voltaic Blaze | al cooldown (set 2p) | ✅ |
| 6 | Doom Winds | senza Ascendance e senza Deeply Rooted Elements | ✅ |
| 7 | Primordial Storm | con 10 stack di MW (5+ se il buff sta per scadere) | ✅ MW, 💡/override disponibilità |
| 8 | Sundering | Stormbringer con Surging Elements | ✅ |
| 9 | Crash Lightning | al cooldown | ✅ |
| 10 | Ascendance → Windstrike | Windstrike durante Ascendance | ✅ override Stormstrike → Windstrike |
| 11 | Stormstrike | durante Doom Winds | 🟡 Doom Winds (timer dal cast) |
| 12 | Tempest o Lightning Bolt | 10 stack di MW (Totemic: Lightning Bolt anche da 5+ per Elemental Tempo) | ✅ MW, ✅ override Tempest |
| 13 | Stormstrike → Lava Lash → Stormstrike | filler, in ordine diverso per Stormbringer e Totemic | ✅ |
| 14 | Lightning Bolt | con 5+ stack di MW | ✅ |

### AoE

È simile al bersaglio singolo, con queste differenze:
- Chain Lightning sostituisce Lightning Bolt: 10 stack di MW, oppure 9+ per Stormbringer quando Tempest non è disponibile.
- Sundering sale di priorità.
- Crash Lightning è centrale.
- Il filler finale è Chain Lightning con 5+ stack di MW.

**Valutazione:** Enhancement è la spec Shaman con più segnali leggibili:
- stack di MW;
- cooldown;
- override di Windstrike e Tempest.

Il modulo dovrebbe quindi poter seguire la guida da vicino.

---

## Restoration (specID 264) – supporto, non rotazione

**Hero talent:**
- **Farseer:** `Call of the Ancestors` (467646).
- **Totemic:** `Surging Totem` (444995).

Dalla 12.1 le aure dei guaritori sono state **tolte dalla whitelist**. Earth Shield e Riptide sui bersagli sono quindi segreti in combattimento.

### Prima del pull (fuori combattimento, aure leggibili)

- Water Shield su di sé.
- Earth Shield sul tank e su di sé.
- Earthliving Weapon: Wowhead elenca più ID (382021–382024); quello giusto per l'arma va trovato con `/rotassist probe` e `GetWeaponEnchantInfo`.

### In combattimento: promemoria basati su segnali leggibili

| Promemoria | Condizione | Segnale |
|---|---|---|
| Healing Stream / Stormstream Totem | cariche al massimo ("non sprecare cariche") | ✅ `GetSpellCharges.isActive == false` |
| Stormstream Totem pronto | proc dell'apex | ✅ override di HST, oppure 💡 |
| Riptide | al cooldown | ✅ |
| Unleash Life + Ancestral Swiftness (Farseer) | al cooldown | ✅ |
| Nature's Swiftness (Totemic) | al cooldown, da usare su Chain Heal | ✅ |
| Surging Totem (Totemic) | al cooldown, nel punto migliore | ✅ |
| Healing Rain | se più alleati restano nell'area | ❌ posizione: solo promemoria al cooldown |

### Riquadro cooldown

- Spirit Link Totem (98008);
- Healing Tide Totem (108280) oppure Ascendance (114052);
- Nature's Swiftness (378081);
- Bloodlust (2825) / Heroism (32182).

Il riquadro mostra solo se sono pronti, senza suggerirne l'uso.

---

## Avvisi per tutti gli Shaman

| Avviso | Spec | Come |
|---|---|---|
| Lightning Shield mancante (192106) | Ele, Enh | aura fuori combattimento; in combattimento ❌ (segreta, salvo whitelist) |
| Earth Shield su di sé (974, con Elemental Orbit 383010) | Ele, Enh | aura fuori combattimento |
| Water Shield (52127), Earth Shield su sé e tank | Resto | aura fuori combattimento |
| Imbue dell'arma: Flametongue 318038, Windfury 33757 | Enh | `GetWeaponEnchantInfo` (da verificare con probe) |
| Skyfury (462854) | tutte | aura fuori combattimento |
| Flame Shock mancante o in scadenza | Ele (Enh Totemic) | 🟡 timer dal cast: 18 s, avviso a ≤ 5,4 s |
| Maelstrom vicino al massimo | Ele | ❌ come logica; ✅ barra colorata con curva nativa (come la barra del pet) |
| Maelstrom Weapon a 10 stack | Enh | ✅ glow della barra o dell'icona |

## Spell ID verificati (Wowhead, live, 5 ott 2026)

| Abilità | ID | Base Wowhead (senza talenti) |
|---|---|---|
| Stormkeeper | 191634 | cd 60 s, cast 1,5 s |
| Ascendance (Ele / Enh / Resto) | 114050 / 114051 / 114052 | cd 180 s |
| Lava Burst | 51505 | cd 8 s, 1 carica (2 con talento) |
| Lava Surge (talento / buff) | 77756 / 77762 | proc |
| Flame Shock | 188389 | 18 s |
| Voltaic Blaze | 470057 | cd 10 s |
| Earth Shock / Earthquake / Elemental Blast | 8042 / 61882 / 117014 | EB: cd 12 s |
| Lightning Bolt / Chain Lightning / Tempest | 188196 / 188443 / 454009 | |
| Ancestral Swiftness / Call of the Ancestors | 443454 / 467646 | AS: cd 30 s |
| Fire Elemental | 198067 | cd 120 s |
| Master of the Elements (talento / buff) | 16166 / 260734 | |
| Purging Flames / Lightning Rod | 1259471 / 210689 | |
| Stormstrike / Windstrike | 17364 / 115356 | cd 7,5 s |
| Lava Lash | 60103 | cd 18 s |
| Crash Lightning | 187874 | cd 15 s |
| Sundering | 197214 | cd 30 s |
| Doom Winds | 384352 | cd 60 s |
| Primordial Storm | 1218047 | |
| Maelstrom Weapon (talento / buff) | 187880 / 344179 | |
| Hot Hand / Whirling Fire | 201900 / 453405 | |
| Surging Totem | 444995 | cd 25 s |
| Flametongue / Windfury Weapon | 318038 / 33757 | |
| Riptide | 61295 | cd 6 s |
| Healing Stream Totem / Stormstream Totem | 5394 / 1267016 | HST: cd 30 s |
| Unleash Life / Nature's Swiftness | 73685 / 378081 | 20 s / 60 s |
| Healing Rain / Chain Heal / Healing Wave | 73920 / 1064 / 77472 | HR: cd 12 s |
| Spirit Link / Healing Tide Totem | 98008 / 108280 | cd 180 s |
| Lightning Shield / Earth Shield / Water Shield | 192106 / 974 / 52127 | |
| Elemental Orbit / Skyfury | 383010 / 462854 | |
| Bloodlust / Heroism | 2825 / 32182 | cd 300 s |

## Da verificare in gioco con `/rotassist probe` (classe Shaman)

`probe` ora stampa anche:
- `UnitPower(Maelstrom)`;
- stack di Maelstrom Weapon;
- aura di Lightning Shield;
- override di Lightning Bolt, Stormstrike e Healing Stream Totem;
- `GetTotemInfo`;
- `GetWeaponEnchantInfo`;
- `isActive` delle cariche di Lava Burst.

Va lanciato **fuori** e **dentro** il combattimento, in ogni spec. In particolare va controllato:
- Maelstrom Weapon resta leggibile in combattimento?
- Durante Ascendance l'override di Stormstrike diventa Windstrike (115356)?
- Con Tempest pronto l'override di Lightning Bolt diventa Tempest (454009)?
- Lava Surge fa brillare Lava Burst? Per questo serve `/rotassist debug`.
