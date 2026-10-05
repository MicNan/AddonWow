-- RotAssist - Tracker
-- Ricostruisce lo stato che in combattimento e' segreto usando solo segnali
-- leggibili:
--   * i propri cast (UNIT_SPELLCAST_SUCCEEDED del giocatore, non segreto);
--   * i flag isActive/isOnGCD dei cooldown (NeverSecret);
--   * l'evento di glow dei proc;
--   * le letture esatte fatte FUORI combattimento, usate per "imparare"
--     durate di cooldown, ricariche e buff (salvate in RotAssistDB).
-- Tutto cio' che esce da qui e' una STIMA: la modalita' debug lo dichiara.

local _, ns = ...
local A = ns.API
local GetTime = GetTime

local T = {
    lastCast = {},   -- [spellID] = istante dell'ultimo cast
    timers   = {},   -- [chiave]  = istante di scadenza
    flags    = {},   -- [chiave]  = boolean
    charges  = {},   -- [spellID] = { cur, max, start, dur }
    cdStart  = {},   -- [spellID] = inizio stimato del cooldown
    wasReady = {},   -- [spellID] = ultimo stato pronto/non pronto osservato
    glows    = {},   -- [spellID] = true mentre il pulsante brilla
}
ns.Tracker = T

local function Spec() return ns.activeSpec end

function T:Reset()
    for _, t in pairs({ self.lastCast, self.timers, self.flags, self.charges,
                        self.cdStart, self.wasReady, self.glows }) do
        wipe(t)
    end
    local spec = Spec()
    if spec and spec.track and spec.track.charges then
        for _, id in ipairs(spec.track.charges) do
            self.charges[id] = { cur = 2, max = 2 }
        end
    end
end

function T:Learned(spellID)
    local db = ns.db and ns.db.learned
    if not db then return {} end
    local l = db[spellID]
    if not l then l = {}; db[spellID] = l end
    return l
end

-- Valore di partenza: prima 'base' del modulo spec (con talenti, dalla guida),
-- poi i dati base di Wowhead generati in Core\SpellData.lua (senza talenti).
local function BaseValue(spellID, field)
    local spec = Spec()
    local base = spec and spec.base and spec.base[spellID]
    if base and base[field] then return base[field] end
    local wh = ns.SpellData and ns.SpellData[spellID]
    return wh and wh[field]
end

local function CooldownLength(self, spellID)
    return self:Learned(spellID).cd or BaseValue(spellID, "cd")
end

local function RechargeLength(self, spellID, c)
    return (c and c.dur) or self:Learned(spellID).recharge or BaseValue(spellID, "recharge")
        or BaseValue(spellID, "cd")
end

---------------------------------------------------------------------------
-- Timer e flag (buff ricostruiti dai cast)
---------------------------------------------------------------------------
function T:AuraDuration(key, default)
    local l = ns.db and ns.db.learnedAura and ns.db.learnedAura[key]
    return l or default
end

function T:StartTimer(key, duration, now)
    self.timers[key] = (now or GetTime()) + duration
end

function T:TimerRemaining(key)
    local exp = self.timers[key]
    if not exp then return 0 end
    local rem = exp - GetTime()
    if rem <= 0 then self.timers[key] = nil; return 0 end
    return rem
end

function T:TimerActive(key)
    return self:TimerRemaining(key) > 0
end

local function EffectAllowed(e)
    if e.hero and e.hero ~= ns.hero then return false end
    if e.talent and not A.IsKnown(e.talent) then return false end
    if e.minTargets then
        local n = ns.Enemies and ns.Enemies.lastCount
        if not n or n < e.minTargets then return false end
    end
    return true
end

function T:ApplyEffect(e, now)
    if not EffectAllowed(e) then return end
    if e.type == "timer" then
        self:StartTimer(e.key, self:AuraDuration(e.key, e.duration), now)
    elseif e.type == "clearTimer" then
        self.timers[e.key] = nil
    elseif e.type == "flag" then
        self.flags[e.key] = e.value and true or false
    elseif e.type == "resetCharges" then
        local c = self.charges[e.spell]
        if c then c.cur = c.max; c.start = nil end
    end
end

---------------------------------------------------------------------------
-- Cast del giocatore
---------------------------------------------------------------------------
function T:OnCast(spellID)
    local spec = Spec()
    if not spec or type(spellID) ~= "number" then return end
    local now = GetTime()
    local id = (spec.aliases and spec.aliases[spellID]) or spellID
    self.lastCast[id] = now
    self.lastCast[spellID] = now

    if spec.track and spec.track.cooldowns and spec.track.cooldowns[id] then
        self.cdStart[id] = now
        self.wasReady[id] = false
    end

    local c = self.charges[id]
    if c then
        self:AdvanceCharges(id, c, now)
        if c.cur >= c.max then c.start = now end
        c.cur = math.max(0, c.cur - 1)
    end

    local effects = spec.onCast and spec.onCast[id]
    if effects then
        for _, e in ipairs(effects) do self:ApplyEffect(e, now) end
    end
    ns:Debug("cast %s (%d)", A.SpellName(id), id)
end

function T:OnGlow(spellID, shown)
    if type(spellID) ~= "number" then return end
    self.glows[spellID] = shown or nil
    local spec = Spec()
    local alias = spec and spec.aliases and spec.aliases[spellID]
    if alias then self.glows[alias] = shown or nil end
    ns:Debug("glow %s %s (%d)", shown and "ON " or "OFF", A.SpellName(spellID), spellID)
end

---------------------------------------------------------------------------
-- Pronto / non pronto tenendo conto del GCD.
-- In 12.1 isOnGCD risulta nil fuori dall'evento SPELL_UPDATE_COOLDOWN e
-- start/duration sono segreti: durante il GCD ogni abilita' appare "attiva".
-- Il GCD invece e' sempre leggibile (spell 61304 in whitelist), quindi un
-- "non pronto" letto durante il GCD e' ambiguo e va risolto con il modello.
---------------------------------------------------------------------------
local function GCDActive()
    return (A.GCD()) > 0
end

-- Lettura grezza usata dalla sincronizzazione: nil se ambigua per il GCD.
local function RawReady(spellID)
    local r = A.IsReady(spellID)
    if r == false and GCDActive() then return nil end
    return r
end

function T:IsReady(spellID)
    local r = A.IsReady(spellID)
    if r ~= false then return r end
    local gcdRem = A.GCD()
    if gcdRem <= 0 then return false end
    -- siamo nel GCD: decidiamo con il modello
    local c = self.charges[spellID]
    if c then return c.cur > 0 end
    local s, len = self.cdStart[spellID], CooldownLength(self, spellID)
    if s and len then return (s + len - GetTime()) <= gcdRem + 0.05 end
    local spec = Spec()
    if spec and spec.track and spec.track.cooldowns and spec.track.cooldowns[spellID] then
        if self.wasReady[spellID] ~= nil then return self.wasReady[spellID] end
        return nil
    end
    -- abilita' senza cooldown proprio (es. Cobra Shot): era solo il GCD
    if not BaseValue(spellID, "cd") and not BaseValue(spellID, "recharge") then return true end
    return nil
end

---------------------------------------------------------------------------
-- Modello delle cariche
---------------------------------------------------------------------------
function T:AdvanceCharges(spellID, c, now)
    local dur = RechargeLength(self, spellID, c)
    if not dur or dur <= 0 then return end
    while c.cur < c.max and c.start and now >= c.start + dur do
        c.cur = c.cur + 1
        if c.cur < c.max then c.start = c.start + dur else c.start = nil end
    end
end

function T:SyncCharges(now)
    for id, c in pairs(self.charges) do
        local info = A.ChargeInfo(id)
        if info then
            if info.max and info.max > 0 then c.max = info.max end
            if info.cur then
                -- lettura esatta (fuori combattimento): sincronizza e impara
                c.cur = info.cur
                c.start = (info.cur < c.max) and info.start or nil
                if info.dur and info.dur > 0 then
                    c.dur = info.dur
                    self:Learned(id).recharge = info.dur
                end
            else
                self:AdvanceCharges(id, c, now)
                if info.isActive == false then
                    c.cur, c.start = c.max, nil          -- cariche piene
                else
                    local ready = RawReady(id)
                    if ready == false then
                        c.cur = 0                        -- nessuna carica
                        c.start = c.start or now
                    elseif ready == true and c.cur == 0 then
                        c.cur = 1                        -- carica restituita da un proc
                    end
                    if info.isActive == true and c.cur >= c.max then
                        c.cur = c.max - 1                -- sta ricaricando
                        c.start = c.start or now
                    end
                end
            end
        end
    end
end

function T:Charges(spellID)
    local c = self.charges[spellID]
    if not c then return nil end
    return c.cur, c.max
end

function T:AtMaxCharges(spellID)
    local c = self.charges[spellID]
    if not c then return nil end
    return c.cur >= c.max
end

-- La prossima carica che porta al massimo arriva entro 'secs'?
function T:ChargesNearMax(spellID, secs)
    local c = self.charges[spellID]
    if not c then return nil end
    if c.cur >= c.max then return true end
    if c.cur < c.max - 1 then return false end
    local dur = RechargeLength(self, spellID, c)
    if not dur or not c.start then return nil end
    return (c.start + dur - GetTime()) <= secs
end

---------------------------------------------------------------------------
-- Cooldown: stima del tempo residuo + apprendimento delle durate
---------------------------------------------------------------------------
function T:SyncCooldowns(now)
    local spec = Spec()
    if not (spec and spec.track and spec.track.cooldowns) then return end
    for id in pairs(spec.track.cooldowns) do
        local ready = RawReady(id)
        local _, onGCD, start, dur = A.CooldownInfo(id)
        if start and dur and dur > 2 and not onGCD then
            -- valore leggibile: inizio e durata reali
            self.cdStart[id] = start
            self:Learned(id).cd = dur
        end
        if ready == true then
            if self.wasReady[id] == false and self.cdStart[id] then
                local observed = now - self.cdStart[id]
                if observed > 3 and observed < 900 then
                    local l = self:Learned(id)
                    l.cd = l.cd and (l.cd * 0.7 + observed * 0.3) or observed
                end
            end
            self.cdStart[id] = nil
        end
        if ready ~= nil then self.wasReady[id] = ready end
    end
end

-- Secondi al prossimo utilizzo: 0 se pronto, nil se non stimabile.
function T:CooldownRemaining(spellID)
    local ready = self:IsReady(spellID)
    if ready == true then return 0 end
    local _, onGCD, start, dur = A.CooldownInfo(spellID)
    if start and dur and not onGCD then
        return math.max(0, start + dur - GetTime())
    end
    local c = self.charges[spellID]
    if c and c.cur == 0 and c.start then
        local len = RechargeLength(self, spellID, c)
        if len then return math.max(0.1, c.start + len - GetTime()) end
    end
    local s, len = self.cdStart[spellID], CooldownLength(self, spellID)
    if s and len then
        return math.max(0.1, s + len - GetTime())
    end
    if ready == false then return nil end
    return nil
end

---------------------------------------------------------------------------
-- Calibrazione dei buff fuori combattimento: se l'aura e' leggibile ne
-- leggiamo durata e scadenza reali.
---------------------------------------------------------------------------
function T:CalibrateAuras()
    local spec = Spec()
    if not (spec and spec.calibrateAuras) or A.AurasRestricted() then return end
    for key, def in pairs(spec.calibrateAuras) do
        local found, expires, duration = A.FindAura(def.unit or "player", def.auras, def.filter or "HELPFUL")
        if found == true then
            if duration and duration > 0 then ns.db.learnedAura[key] = duration end
            if expires and expires > 0 then self.timers[key] = expires end
        elseif found == false then
            self.timers[key] = nil
        end
    end
end

function T:Sync(now)
    self:SyncCooldowns(now)
    self:SyncCharges(now)
    self:CalibrateAuras()
end
