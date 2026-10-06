// Controllo di sintassi Lua 5.1 (la versione usata da WoW) su tutte le
// cartelle passate come argomento.
//   node check.js ../RotAssist ../RotAssist_Companion
const fs = require('fs');
const path = require('path');
const luaparse = require('luaparse');

let bad = 0, ok = 0;
function walk(dir) {
  for (const f of fs.readdirSync(dir)) {
    const p = path.join(dir, f);
    if (fs.statSync(p).isDirectory()) walk(p);
    else if (p.endsWith('.lua')) {
      try {
        luaparse.parse(fs.readFileSync(p, 'utf8'), { luaVersion: '5.1' });
        ok++;
      } catch (e) {
        bad++;
        console.log('ERRORE ' + p + ': ' + e.message);
      }
    }
  }
}
process.argv.slice(2).forEach(walk);
console.log(`sintassi: ${ok} file ok, ${bad} con errori`);
process.exit(bad ? 1 : 0);
