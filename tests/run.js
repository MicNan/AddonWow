// Esegue un addon dentro un WoW simulato (fengari, Lua 5.3) ed esce con
// codice 1 se lo scenario registra errori.
//
//   node run.js <cartella-addon> <scenario.lua> [mock-aggiuntivo.lua ...]
//
// Carica mock.lua (API di WoW simulate, compresi i "secret values"), poi gli
// eventuali mock aggiuntivi, poi passa i file del .toc allo scenario nella
// tabella globale FILES = { {name, src}, ... }.
const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');

const [addonDir, scenario, ...extraMocks] = process.argv.slice(2);
if (!addonDir || !scenario) {
  console.log('uso: node run.js <cartella-addon> <scenario.lua> [mock.lua ...]');
  process.exit(2);
}
const here = __dirname;
const tocName = fs.readdirSync(addonDir).find(f => f.endsWith('.toc'));
const files = fs.readFileSync(path.join(addonDir, tocName), 'utf8').split(/\r?\n/)
  .map(l => l.trim()).filter(l => l && !l.startsWith('#'));

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);

function run(file) {
  const src = fs.readFileSync(path.join(here, file), 'utf8');
  if (lauxlib.luaL_loadbuffer(L, to_luastring(src), null, to_luastring('@' + file)) !== 0 ||
      lua.lua_pcall(L, 0, 0, 0) !== 0) {
    console.log('LUA FAIL: ' + lua.lua_tojsstring(L, -1));
    process.exit(1);
  }
}

run('mock.lua');
extraMocks.forEach(run);

lua.lua_newtable(L);
files.forEach((f, i) => {
  lua.lua_newtable(L);
  lua.lua_pushstring(L, to_luastring(f));
  lua.lua_setfield(L, -2, to_luastring('name'));
  lua.lua_pushstring(L, to_luastring(fs.readFileSync(path.join(addonDir, f.replace(/\\/g, '/')), 'utf8')));
  lua.lua_setfield(L, -2, to_luastring('src'));
  lua.lua_rawseti(L, -2, i + 1);
});
lua.lua_setglobal(L, to_luastring('FILES'));

run(scenario);

// esito: numero di errori registrati in MOCK.errors
lua.lua_getglobal(L, to_luastring('MOCK'));
lua.lua_getfield(L, -1, to_luastring('errors'));
const errors = lua.lua_rawlen(L, -1);
console.log(errors ? `\nFALLITO: ${errors} errori in ${scenario}` : `\nOK: ${scenario}`);
process.exit(errors ? 1 : 0);
