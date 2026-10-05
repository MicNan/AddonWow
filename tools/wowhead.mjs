#!/usr/bin/env node
// RotAssist - strumento di sviluppo per Wowhead (Node 18+, nessuna dipendenza).
//
// Gli addon di WoW non possono accedere a Internet: questo script gira sul PC
// dello sviluppatore e usa il servizio tooltip pubblico di Wowhead per:
//
//   node tools/wowhead.mjs verify          controlla gli spellID dichiarati nei moduli
//                                          (tabelle S in RotAssist/Specs/*.lua): esistono?
//                                          il nome corrisponde alla chiave?
//   node tools/wowhead.mjs gen             rigenera RotAssist/Core/SpellData.lua con nome,
//                                          cooldown, cariche e ricarica BASE (senza talenti)
//   node tools/wowhead.mjs spell 191634 ...  stampa le informazioni di uno o piu' spellID
//   node tools/wowhead.mjs search stormkeeper  cerca uno spellID per nome (inglese)
//
// Opzioni: --ptr (dati PTR), --refresh (ignora la cache locale tools/.cache/).
// I valori di Wowhead sono quelli base del tooltip: i talenti li modificano.
// L'addon li usa solo come ultimo ripiego, dopo i valori appresi in gioco.

import { readFileSync, writeFileSync, readdirSync, mkdirSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const ADDON = join(ROOT, "RotAssist");
const CACHE_DIR = join(ROOT, "tools", ".cache");
const args = process.argv.slice(2);
const flags = new Set(args.filter(a => a.startsWith("--")));
const positional = args.filter(a => !a.startsWith("--"));
const DATA_ENV = flags.has("--ptr") ? 2 : 1;
const CACHE_FILE = join(CACHE_DIR, `wowhead-${DATA_ENV}.json`);

const cache = !flags.has("--refresh") && existsSync(CACHE_FILE)
    ? JSON.parse(readFileSync(CACHE_FILE, "utf8")) : {};

const sleep = ms => new Promise(r => setTimeout(r, ms));

function toSeconds(value, unit) {
    const v = parseFloat(value);
    return unit.startsWith("min") ? v * 60 : unit.startsWith("hr") ? v * 3600 : v;
}

// Estrae i dati utili dal tooltip HTML di Wowhead.
function parseTooltip(json) {
    const html = json.tooltip || "";
    const info = { name: json.name, icon: json.icon };
    const cd = html.match(/baseCooldown:([\d.]+) (sec|min|hr) (cooldown|recharge)/);
    if (cd) {
        const secs = toSeconds(cd[1], cd[2]);
        if (cd[3] === "recharge") info.recharge = secs; else info.cd = secs;
    }
    const ch = html.match(/baseCharges:(\d+) Charges?/);
    if (ch) info.charges = parseInt(ch[1], 10);
    const cast = html.match(/>([\d.]+) sec cast</);
    info.cast = cast ? parseFloat(cast[1]) : (/>Instant</.test(html) ? 0 : undefined);
    info.talent = />Talent</.test(html);
    return info;
}

async function fetchSpell(id) {
    const key = String(id);
    if (cache[key]) return cache[key];
    const url = `https://nether.wowhead.com/tooltip/spell/${id}?dataEnv=${DATA_ENV}&locale=0`;
    const res = await fetch(url, { headers: { "User-Agent": "RotAssist-dev-tool" } });
    let info;
    if (res.status === 404) {
        info = { missing: true };
    } else if (!res.ok) {
        throw new Error(`HTTP ${res.status} per spell ${id}`);
    } else {
        const json = await res.json();
        info = json.error ? { missing: true } : parseTooltip(json);
    }
    cache[key] = info;
    await sleep(250); // gentile con il servizio
    return info;
}

function saveCache() {
    mkdirSync(CACHE_DIR, { recursive: true });
    writeFileSync(CACHE_FILE, JSON.stringify(cache, null, 1));
}

// Legge le tabelle "local S = { NOME = 12345, ... }" dei moduli spec.
function scanSpecs() {
    const dir = join(ADDON, "Specs");
    const entries = [];
    for (const file of readdirSync(dir).filter(f => f.endsWith(".lua"))) {
        const src = readFileSync(join(dir, file), "utf8");
        const block = src.match(/local S = \{([\s\S]*?)\n\}/);
        if (!block) continue;
        for (const m of block[1].matchAll(/^\s*([A-Z0-9_]+)\s*=\s*(\d+)\s*,/gm)) {
            entries.push({ file, key: m[1], id: Number(m[2]) });
        }
    }
    return entries;
}

const norm = s => String(s).toLowerCase().replace(/[^a-z0-9]/g, "");
const fmt = v => (v === undefined ? "-" : String(v));

async function cmdVerify() {
    const entries = scanSpecs();
    let problems = 0;
    console.log(`Verifica di ${entries.length} spellID (dataEnv ${DATA_ENV})\n`);
    for (const e of entries) {
        const info = await fetchSpell(e.id);
        let status = "ok";
        if (info.missing) status = "NON TROVATO";
        else if (!norm(info.name).includes(norm(e.key).replace(/buff$/, "")) &&
                 !norm(e.key).includes(norm(info.name))) status = "nome diverso?";
        if (status !== "ok") problems++;
        console.log(`${status.padEnd(12)} ${e.file.padEnd(28)} ${e.key.padEnd(20)} ${String(e.id).padEnd(8)} ` +
            `${fmt(info.name).padEnd(26)} cd ${fmt(info.cd)} cariche ${fmt(info.charges)} ricarica ${fmt(info.recharge)}`);
    }
    saveCache();
    console.log(`\n${problems} da controllare. "nome diverso?" e' solo un avviso: la chiave e' un nostro alias.`);
    process.exitCode = problems ? 1 : 0;
}

async function cmdGen() {
    const ids = [...new Set(scanSpecs().map(e => e.id))].sort((a, b) => a - b);
    const lines = [];
    for (const id of ids) {
        const i = await fetchSpell(id);
        if (i.missing) continue;
        const fields = [`name = ${JSON.stringify(i.name)}`];
        if (i.cd !== undefined) fields.push(`cd = ${i.cd}`);
        if (i.charges !== undefined) fields.push(`charges = ${i.charges}`);
        if (i.recharge !== undefined) fields.push(`recharge = ${i.recharge}`);
        lines.push(`    [${id}] = { ${fields.join(", ")} },`);
    }
    saveCache();
    const out = `-- RotAssist - SpellData (GENERATO da tools/wowhead.mjs gen: non modificare a mano)
-- Valori BASE dai tooltip di Wowhead (dataEnv ${DATA_ENV}), senza talenti.
-- Usati solo come ultimo ripiego: hanno precedenza i valori appresi in gioco
-- e quelli dichiarati in 'base' nei moduli spec.
-- Generato il ${new Date().toISOString().slice(0, 10)}.

local _, ns = ...

ns.SpellData = {
${lines.join("\n")}
}
`;
    writeFileSync(join(ADDON, "Core", "SpellData.lua"), out);
    console.log(`Scritto RotAssist/Core/SpellData.lua con ${lines.length} incantesimi.`);
}

async function cmdSearch(query) {
    const url = `https://www.wowhead.com/search/suggestions-template?q=${encodeURIComponent(query)}`;
    const res = await fetch(url, { headers: { "User-Agent": "RotAssist-dev-tool" } });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const json = await res.json();
    const spells = (json.results || []).filter(r => r.type === 6);
    if (!spells.length) console.log("nessun incantesimo trovato");
    for (const r of spells.slice(0, 15)) {
        const desc = String(r.pinDescription || "").replace(/\s+/g, " ").trim().slice(0, 90);
        console.log(`${String(r.id).padEnd(8)} ${r.name.padEnd(28)} ${desc}`);
    }
}

async function cmdSpell(ids) {
    for (const id of ids) {
        const i = await fetchSpell(id);
        console.log(i.missing ? `${id}: NON TROVATO` :
            `${id}: ${i.name} | cd ${fmt(i.cd)} | cariche ${fmt(i.charges)} | ricarica ${fmt(i.recharge)} | ` +
            `cast ${fmt(i.cast)} | ${i.talent ? "talento" : "base"} | https://www.wowhead.com/spell=${id}`);
    }
    saveCache();
}

const [cmd, ...rest] = positional;
try {
    if (cmd === "verify") await cmdVerify();
    else if (cmd === "gen") await cmdGen();
    else if (cmd === "spell" && rest.length) await cmdSpell(rest.map(Number));
    else if (cmd === "search" && rest.length) await cmdSearch(rest.join(" "));
    else console.log("uso: node tools/wowhead.mjs verify | gen | spell <id...> | search <nome> [--ptr] [--refresh]");
} catch (err) {
    console.error("Errore:", err.message);
    process.exitCode = 2;
}
