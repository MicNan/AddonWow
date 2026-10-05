-- RotAssist - Engine
-- Valuta le liste di priorita' dichiarate nei moduli spec e le combina con il
-- suggerimento nativo di Assisted Combat.
--
-- Formato di una regola (vedi Specs\Hunter_BeastMastery.lua):
--   { id = "bw", spell = 19574,
--     conds = { {"predicato", arg1, arg2}, ... },   -- tutte vere (AND)
--     any   = { {...}, {...} },                     -- almeno una vera (OR)
--     pin   = true,          -- in modalita' ibrida puo' scavalcare Assisted Combat
--     talent = spellID,      -- regola attiva solo se il talento e' conosciuto
--     notTalent = spellID,   -- regola attiva solo se il talento NON e' conosciuto
--     onUnknown = "match",   -- se un dato e' segreto/ignoto: "match" o "skip" (default)
--     needsResource = true,  -- spender: richiede risorsa sufficiente adesso
--     hero = "PL",           -- regola valida solo per questo hero talent
--     disabled = "motivo",   -- regola documentata ma non valutabile
--     note = "testo per il debug" }
-- Combinatori: {"not", c}, {"and", c1, c2, ...}, {"or", c1, c2, ...}.
-- Gli argomenti in secondi accettano numeri oppure "gcd", "2gcd", ...
-- Un'abilita' senza risorsa (IsSpellUsable, leggibile in combattimento) non
-- viene mai suggerita.
-- Modalita': ST, CLEAVE (se la spec definisce cleaveAt e una lista CLEAVE), AOE.
--
-- Logica a tre valori: ogni predicato restituisce true, false oppure nil
-- (= non so, dato segreto). Nessun predicato confronta valori segreti.

local _, ns = ...
local A, T = ns.API, ns.Tracker

local E = {}
ns.Engine = E

---------------------------------------------------------------------------
-- Contesto
---------------------------------------------------------------------------
local Ctx = {}
Ctx.__index = Ctx

function Ctx:Secs(v)
    if type(v) == "number" then return v end
    if type(v) == "string" then
        local mult = v:match("^(%d*%.?%d*)gcd$")
        if mult then
            local m = tonumber(mult) or 1
            return m * self.gcd
        end
    end
    return 0
end

function E:NewContext(spec, hero, mode, targets, now)
    local _, gcdLen = A.GCD()
    return setmetatable({
        spec = spec, hero = hero, mode = mode, targets = targets,
        now = now, gcd = gcdLen or 1.5,
    }, Ctx)
end

---------------------------------------------------------------------------
-- Utilita' sugli incantesimi
---------------------------------------------------------------------------
-- spellID da mostrare (gestisce gli override, es. Bestial Wrath -> Wailing Arrow)
function E:DisplaySpell(spellID)
    return A.Override(spellID)
end

-- Conosciuto? Per le abilita' che esistono solo come override di un'altra
-- (spec.overrideOf[id] = base) controlla che l'override sia attivo.
function E:IsKnown(spec, spellID)
    local base = spec.overrideOf and spec.overrideOf[spellID]
    if base then return A.Override(base) == spellID end
    return A.IsKnown(spellID, spec.petSpells and spec.petSpells[spellID])
end

-- Lanciabile adesso? true / false / nil (non so)
function E:Castable(spec, spellID)
    if not self:IsKnown(spec, spellID) then return false, "non conosciuto" end
    local ready = T:IsReady(spellID)
    if ready == false then return false, "in cooldown" end
    -- IsSpellUsable e' leggibile in combattimento (verificato in gioco il 05/10):
    -- senza risorsa la regola non vale e si passa alla successiva
    local usable, noPower = A.IsUsable(spellID)
    if noPower == true then return false, "risorsa insufficiente" end
    if usable == false then return false, "non utilizzabile" end
    if ready == nil then return nil, "cooldown ignoto" end
    return true
end

---------------------------------------------------------------------------
-- Predicati
---------------------------------------------------------------------------
local P = {}
E.predicates = P

P.ready = function(ctx, id) return (E:Castable(ctx.spec, id)) end
P.notReady = function(ctx, id)
    local r = T:IsReady(id)
    if r == nil then return nil end
    return not r
end
P.known = function(ctx, id) return E:IsKnown(ctx.spec, id) end
P.cdLT = function(ctx, id, s)
    local r = T:CooldownRemaining(id)
    if r == nil then return nil end
    return r < ctx:Secs(s)
end
P.cdGT = function(ctx, id, s)
    local r = T:CooldownRemaining(id)
    if r == nil then return nil end
    return r > ctx:Secs(s)
end
-- il cooldown di 'id' torna prima che scada il timer 'key'
P.cdBeforeTimerEnds = function(ctx, id, key)
    if not T:TimerActive(key) then return false end
    local r = T:CooldownRemaining(id)
    if r == nil then return nil end
    return r < T:TimerRemaining(key)
end
P.chargesNearMax = function(ctx, id, s) return T:ChargesNearMax(id, ctx:Secs(s)) end
P.atMaxCharges = function(ctx, id) return T:AtMaxCharges(id) end
P.chargesGE = function(ctx, id, n)
    local cur = T:Charges(id)
    if cur == nil then return nil end
    return cur >= n
end
P.timer = function(ctx, key) return T:TimerActive(key) end
P.noTimer = function(ctx, key) return not T:TimerActive(key) end
-- residuo del timer < s (vero anche se il timer e' gia' scaduto)
P.timerLT = function(ctx, key, s) return T:TimerRemaining(key) < ctx:Secs(s) end
P.flag = function(ctx, key) return T.flags[key] == true end
P.recentCast = function(ctx, id, s)
    local t = T.lastCast[id]
    return t ~= nil and (ctx.now - t) <= ctx:Secs(s)
end
P.targetsGE = function(ctx, n)
    if ctx.targets == nil then return nil end
    return ctx.targets >= n
end
P.targetsLT = function(ctx, n)
    if ctx.targets == nil then return nil end
    return ctx.targets < n
end
P.glow = function(ctx, id) return T.glows[id] == true end
P.overrideIs = function(ctx, base, ov) return A.Override(base) == ov end
-- contatori ricostruiti dai cast (es. stack di Stormkeeper, Tip of the Spear)
P.counterGE = function(ctx, key, n) return (T.counters[key] or 0) >= n end
P.counterLT = function(ctx, key, n) return (T.counters[key] or 0) < n end
-- stack di un'aura del giocatore: solo per aure in whitelist (es. Maelstrom
-- Weapon) o fuori dalle restrizioni; altrimenti nil
P.stacksGE = function(ctx, auraID, n)
    local s = A.PlayerAuraStacks(auraID, ctx.spec.whitelistedAuras and ctx.spec.whitelistedAuras[auraID])
    if s == nil then return nil end
    return s >= n
end
P.stacksLT = function(ctx, auraID, n)
    local s = A.PlayerAuraStacks(auraID, ctx.spec.whitelistedAuras and ctx.spec.whitelistedAuras[auraID])
    if s == nil then return nil end
    return s < n
end
-- risorsa sufficiente secondo IsSpellUsable (leggibile in combattimento)
P.usable = function(ctx, id)
    local usable = A.IsUsable(id)
    if usable == nil then return nil end
    return usable and true or false
end

P.powerGE = function(ctx, powerType, n)
    local v = A.Power(powerType)
    if v == nil then return nil end
    return v >= n
end
P.powerLT = function(ctx, powerType, n)
    local v = A.Power(powerType)
    if v == nil then return nil end
    return v < n
end

---------------------------------------------------------------------------
-- Valutazione
---------------------------------------------------------------------------
local function Describe(c)
    if type(c) ~= "table" then return tostring(c) end
    if c[1] == "not" then return "not(" .. Describe(c[2]) .. ")" end
    if c[1] == "and" or c[1] == "or" then
        local parts = {}
        for i = 2, #c do parts[#parts + 1] = Describe(c[i]) end
        return c[1] .. "(" .. table.concat(parts, ", ") .. ")"
    end
    local parts = { tostring(c[1]) }
    for i = 2, #c do parts[#parts + 1] = tostring(c[i]) end
    return table.concat(parts, " ")
end
E.Describe = Describe

local EvalCond

-- {"and", c1, c2, ...} / {"or", c1, c2, ...} con logica a tre valori
local function EvalGroup(c, ctx, isAnd)
    local unknown = false
    for i = 2, #c do
        local r = EvalCond(c[i], ctx)
        if isAnd and r == false then return false end
        if not isAnd and r == true then return true end
        if r == nil then unknown = true end
    end
    if unknown then return nil end
    return isAnd
end

EvalCond = function(c, ctx)
    if c[1] == "not" then
        local r = EvalCond(c[2], ctx)
        if r == nil then return nil end
        return not r
    end
    if c[1] == "and" then return EvalGroup(c, ctx, true) end
    if c[1] == "or" then return EvalGroup(c, ctx, false) end
    local fn = P[c[1]]
    if not fn then return nil end
    local ok, r = pcall(fn, ctx, c[2], c[3], c[4])
    if not ok then ns:ReportError(r); return nil end
    if r == nil then return nil end
    return r and true or false
end

-- AND a tre valori: false se una e' falsa, nil se una e' ignota, altrimenti true
local function EvalAll(list, ctx)
    if not list then return true end
    local unknown
    for _, c in ipairs(list) do
        local r = EvalCond(c, ctx)
        if r == false then return false, Describe(c) end
        if r == nil then unknown = Describe(c) end
    end
    if unknown then return nil, unknown end
    return true
end

-- OR a tre valori
local function EvalAny(list, ctx)
    if not list or #list == 0 then return true end
    local unknown
    for _, c in ipairs(list) do
        local r = EvalCond(c, ctx)
        if r == true then return true end
        if r == nil then unknown = Describe(c) end
    end
    if unknown then return nil, unknown end
    return false, "nessuna condizione 'any' vera"
end

-- Stato di una regola: "match", "fail", "unknown", "skip", "disabled" + motivo
function E:CheckRule(rule, ctx)
    local spec = ctx.spec
    if rule.disabled then return "disabled", rule.disabled end
    if rule.hero and rule.hero ~= ctx.hero then return "skip", "hero talent diverso" end
    if rule.talent and not A.IsKnown(rule.talent) then return "skip", "talento assente" end
    if rule.notTalent and A.IsKnown(rule.notTalent) then return "skip", "talento presente" end

    local castable, why = self:Castable(spec, rule.spell)
    if castable == false then return "fail", why end
    -- spender: serve la risorsa adesso (IsSpellUsable non e' segreto in 12.1)
    if rule.needsResource then
        local usable, noPower = A.IsUsable(rule.spell)
        if usable == false or noPower == true then return "fail", "risorsa insufficiente" end
    end

    local rAll, whyAll = EvalAll(rule.conds, ctx)
    local rAny, whyAny = EvalAny(rule.any, ctx)
    local result, reason
    if rAll == false then result, reason = false, whyAll
    elseif rAny == false then result, reason = false, whyAny
    elseif rAll == nil or rAny == nil or castable == nil then
        result, reason = nil, whyAll or whyAny or why
    else
        result = true
    end

    if result == true then return "match" end
    if result == false then return "fail", "condizione falsa: " .. tostring(reason) end
    if rule.onUnknown == "match" then return "match", "dato ignoto, regola accettata: " .. tostring(reason) end
    return "unknown", "dato ignoto: " .. tostring(reason)
end

function E:GetList(spec, hero, mode)
    local p = spec.priorities
    if not p then return nil end
    local set = (hero and p[hero]) or p[spec.defaultHero or "default"] or p.default
    if not set then return nil end
    -- AoE dedicata solo con un talento chiave (es. Trick Shots per Marksmanship)
    if mode == "AOE" and spec.aoeRequires and not A.IsKnown(spec.aoeRequires) then mode = "ST" end
    if mode == "CLEAVE" and not set.CLEAVE then
        return set.ST
    end
    return set[mode] or set.ST
end

-- Risultato: { primary, next = {..}, native, nativeWhy, trace, source }
-- primary/next sono voci { spell, rule, reason, source = "native"|"rule" }
function E:Recommend(spec, ctx)
    local res = { next = {}, trace = {} }
    local list = self:GetList(spec, ctx.hero, ctx.mode)
    local matches = {}

    if list then
        for _, rule in ipairs(list) do
            local status, why = self:CheckRule(rule, ctx)
            res.trace[#res.trace + 1] = { rule = rule, status = status, why = why }
            if status == "match" then
                matches[#matches + 1] = {
                    spell = self:DisplaySpell(rule.spell), rule = rule,
                    reason = rule.note or rule.id, source = "rule",
                }
            end
        end
    end

    local nativeID, nativeWhy = nil, "disattivato"
    local src = ns.db.source
    -- spec di supporto (es. Restoration): Assisted Combat suggerirebbe danni
    if spec.nativeMode == "off" then src = "RULES" end
    if src ~= "RULES" then
        if ctx.native ~= nil or ctx.nativeWhy ~= nil then
            nativeID, nativeWhy = ctx.native, ctx.nativeWhy   -- gia' letto nel tick
        else
            nativeID, nativeWhy = A.NativeSuggestion()
        end
    end
    res.native, res.nativeWhy = nativeID, nativeWhy

    local nativeEntry = nativeID and { spell = nativeID, reason = "Assisted Combat", source = "native" }
    local primary
    if src == "NATIVE" then
        primary = nativeEntry or matches[1]
    elseif src == "RULES" or not nativeEntry then
        primary = matches[1]
    else
        -- HYBRID: scorriamo la nostra lista; se troviamo prima la stessa
        -- abilita' del nativo concordiamo, se troviamo prima una regola "pin"
        -- la usiamo, altrimenti vince Assisted Combat.
        for _, m in ipairs(matches) do
            if m.spell == nativeID or m.rule.spell == nativeID then
                primary = nativeEntry
                primary.reason = "Assisted Combat (conferma regola '" .. m.rule.id .. "')"
                break
            elseif m.rule.pin then
                primary = m
                break
            end
        end
        primary = primary or nativeEntry
    end
    res.primary = primary

    -- icone 2 e 3: regole soddisfatte successive, senza duplicati
    local used = {}
    if primary then used[primary.spell] = true end
    for _, m in ipairs(matches) do
        if #res.next >= 2 then break end
        if not used[m.spell] then
            used[m.spell] = true
            res.next[#res.next + 1] = m
        end
    end
    if #res.next < 2 and spec.filler then
        local f = self:DisplaySpell(spec.filler)
        if not used[f] and self:IsKnown(spec, spec.filler) then
            res.next[#res.next + 1] = { spell = f, reason = "filler", source = "rule" }
        end
    end
    return res
end
