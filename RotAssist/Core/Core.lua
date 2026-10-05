-- RotAssist - Core
-- Ciclo di vita: caricamento DB, rilevamento classe/spec/hero talent,
-- inoltro degli eventi al Tracker e ciclo di aggiornamento dell'interfaccia.
-- Nessuna funzione protetta, nessun lancio di abilita': solo visualizzazione.

local _, ns = ...
local A, T, Engine, Enemies, Alerts = ns.API, ns.Tracker, ns.Engine, ns.Enemies, ns.Alerts
local UI = ns.UI
local GetTime = GetTime

ns.hero = nil
ns.activeSpec = nil
ns.inEncounter = false

---------------------------------------------------------------------------
-- Specializzazione
---------------------------------------------------------------------------
local function DetectHero(spec)
    if not spec.heroTalents then return nil end
    for _, h in ipairs(spec.heroTalents) do
        if h.spell and A.IsKnown(h.spell) then return h.key end
        for _, id in ipairs(h.spells or {}) do
            if A.IsKnown(id) then return h.key end
        end
    end
    return nil
end

function ns:DetectSpec()
    A.ClearKnownCache()
    local specID = A.SpecID()
    local spec = (specID and self.specs[specID]) or (specID and self.genericSpec) or nil
    local hero = spec and DetectHero(spec)
    local changed = spec ~= self.activeSpec or hero ~= self.hero
    self.activeSpec, self.hero, self.specID = spec, hero, specID
    UI.Cooldowns:Build(spec)   -- i talenti possono cambiare senza cambiare spec
    UI.Launcher:SetIcon(A.SpecIcon())
    if changed then
        T:Reset()
        if spec then
            self:Debug("spec %s (%s), hero %s", spec.name or "?", tostring(specID), tostring(hero))
        end
    end
    self:RefreshVisibility()
end

---------------------------------------------------------------------------
-- Visibilita'
---------------------------------------------------------------------------
local function HostileTarget()
    return A.UnitExists("target") == true and A.UnitCanAttack("target") == true
        and A.UnitIsDead("target") == false
end

function ns:RefreshVisibility()
    if not UI.Main.frame then return end
    local db = self.db
    local unlocked = not db.locked
    local active = db.shown and self.activeSpec ~= nil
    local visible = active and (unlocked or not db.showOnlyInCombat or A.InCombat() or HostileTarget())
    UI.Main.frame:SetShown(visible and true or false)
    UI.Cooldowns.frame:SetShown((visible and db.showCooldowns) and true or false)
    UI.AlertFrame.frame:SetShown((active and db.showAlerts) and true or false)
end

---------------------------------------------------------------------------
-- Modalita' ST / AoE
---------------------------------------------------------------------------
-- Durata dell'indizio AoE ricavato da Assisted Combat (secondi).
local AOE_HINT_TIME = 8

-- Soglia AoE: quella della guida per la spec (es. Elemental 4+), altrimenti
-- quella delle opzioni. 'cleaveAt' attiva la modalita' intermedia CLEAVE.
function ns:Thresholds(spec)
    local aoeAt = (spec and spec.aoeAt) or self.db.aoeThreshold
    local cleaveAt = spec and spec.cleaveAt
    return aoeAt, cleaveAt
end

local function ModeFor(n, aoeAt, cleaveAt)
    if n >= aoeAt then return "AOE" end
    if cleaveAt and n >= cleaveAt then return "CLEAVE" end
    return "ST"
end

-- Restituisce modalita', numero di bersagli e origine della decisione.
-- hintTargets: bersagli minimi dedotti da Assisted Combat (nil se nessun indizio)
function ns:ResolveMode(spec, count, unknown, hintTargets)
    local db = self.db
    local aoeAt, cleaveAt = self:Thresholds(spec)
    if db.mode == "ST" then return "ST", 1, "manuale" end
    if db.mode == "AOE" then return "AOE", math.max(count or 0, aoeAt), "manuale" end
    local targets = count
    if unknown and (count or 0) <= 1 then targets = nil end
    local n = count or 0
    -- Le nameplate non bastano (es. manichini: non risultano in combattimento
    -- e non hanno minaccia leggibile). Se Assisted Combat ha appena suggerito
    -- un'abilita' ad area, ci fidiamo del suo conteggio interno.
    if hintTargets and hintTargets > n then
        return ModeFor(hintTargets, aoeAt, cleaveAt), hintTargets, "Assisted Combat"
    end
    return ModeFor(n, aoeAt, cleaveAt), targets, "nameplate"
end

---------------------------------------------------------------------------
-- Aggiornamento
---------------------------------------------------------------------------
local lastKey
function ns:Tick()
    local spec = self.activeSpec
    if not spec then return end
    local now = GetTime()
    T:Sync(now)

    -- suggerimento nativo letto una volta per tick: serve anche come indizio AoE
    local native, nativeWhy = A.NativeSuggestion()
    local hint = native and spec.aoeHints and spec.aoeHints[native]
    if hint then
        -- aoeHints[id] = true (soglia AoE) oppure numero minimo di bersagli.
        -- L'indizio copre almeno il cooldown dell'abilita' + margine, cosi'
        -- resta valido tra un suggerimento e il successivo.
        local learned = self.db.learned[native]
        local base = spec.base and spec.base[native]
        local len = (learned and learned.cd) or (base and base.cd) or 0
        self.aoeHintUntil = now + math.max(AOE_HINT_TIME, len + 4)
        self.aoeHintTargets = (type(hint) == "number") and hint or (self:Thresholds(spec))
    end
    local hintTargets = self.aoeHintUntil and now < self.aoeHintUntil and A.InCombat() and self.aoeHintTargets or nil

    local count, unknown = Enemies:Count()
    local mode, targets, modeSource = self:ResolveMode(spec, count, unknown, hintTargets)
    local ctx = Engine:NewContext(spec, self.hero, mode, targets, now)
    ctx.native, ctx.nativeWhy, ctx.modeSource = native, nativeWhy, modeSource
    local result = Engine:Recommend(spec, ctx)
    self.lastResult, self.lastCtx = result, ctx

    if UI.Main.frame:IsShown() then
        UI.Main:Update(result, ctx)
        UI.Main:UpdateBars(spec)
    end
    if UI.Cooldowns.frame:IsShown() then UI.Cooldowns:Update() end
    if UI.AlertFrame.frame:IsShown() then UI.AlertFrame:Update(Alerts:Collect(spec)) end

    -- debug: una riga solo quando cambia il suggerimento principale
    if self.db.debug then
        local p = result.primary
        local key = p and (p.spell .. ":" .. (p.source or "")) or "none"
        if key ~= lastKey then
            lastKey = key
            if p then
                self:Debug("-> %s [%s] %s | nativo: %s | %s %s nemici (%s)", A.SpellName(p.spell),
                    p.source == "native" and "Assisted Combat" or "regola", p.reason or "",
                    result.native and A.SpellName(result.native) or tostring(result.nativeWhy),
                    mode, tostring(targets or "?"), tostring(modeSource))
            else
                self:Debug("-> nessun suggerimento (nativo: %s)", tostring(result.nativeWhy))
            end
        end
    end
end

local elapsed = 0
local function OnUpdate(_, dt)
    elapsed = elapsed + dt
    if elapsed < (ns.db.updateRate or 0.1) then return end
    elapsed = 0
    local ok, err = pcall(ns.Tick, ns)
    if not ok then ns:ReportError(err) end
end

---------------------------------------------------------------------------
-- Eventi
---------------------------------------------------------------------------
ns:On("ADDON_LOADED", function(_, name)
    if name ~= ns.name then return end
    RotAssistDB = RotAssistDB or {}
    ns.ApplyDefaults(RotAssistDB, ns.defaults)
    ns.db = RotAssistDB

    UI.Main:Create()
    UI.Cooldowns:Create()
    UI.AlertFrame:Create()
    UI.Launcher:Create()
    local ok, err = pcall(ns.RegisterSettings, ns)
    if not ok then ns:ReportError(err) end

    ns.eventFrame:SetScript("OnUpdate", OnUpdate)
end)

ns:On("PLAYER_LOGIN", function() ns:DetectSpec() end)
ns:On("PLAYER_ENTERING_WORLD", function() ns:DetectSpec() end)
ns:On("PLAYER_SPECIALIZATION_CHANGED", function() ns:DetectSpec() end, "player")
ns:On("TRAIT_CONFIG_UPDATED", function() ns:DetectSpec() end)
ns:On("PLAYER_TALENT_UPDATE", function() ns:DetectSpec() end)
ns:On("SPELLS_CHANGED", function() ns:DetectSpec() end)

ns:On("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, _, spellID)
    spellID = A.Plain(spellID)
    if spellID then T:OnCast(spellID) end
end, "player")

ns:On("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", function(_, spellID) T:OnGlow(A.Plain(spellID), true) end)
ns:On("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", function(_, spellID) T:OnGlow(A.Plain(spellID), false) end)

ns:On("PLAYER_REGEN_DISABLED", function() ns:RefreshVisibility() end)
ns:On("PLAYER_REGEN_ENABLED", function()
    ns.aoeHintUntil = nil
    T:OnCombatEnd()
    ns:RefreshVisibility()
end)
ns:On("PLAYER_TARGET_CHANGED", function()
    T:OnTargetChanged()
    ns:RefreshVisibility()
end)
ns:On("ENCOUNTER_START", function() ns.inEncounter = true end)
ns:On("ENCOUNTER_END", function() ns.inEncounter = false end)
ns:On("UNIT_PET", function() A.ClearKnownCache(); UI.Cooldowns:Build(ns.activeSpec) end, "player")
