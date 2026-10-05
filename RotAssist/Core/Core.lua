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
        if A.IsKnown(h.spell) then return h.key end
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
function ns:ResolveMode(count, unknown)
    local db = self.db
    if db.mode == "ST" then return "ST", 1 end
    if db.mode == "AOE" then return "AOE", math.max(count or 0, db.aoeThreshold) end
    local targets = count
    if unknown and (count or 0) <= 1 then targets = nil end
    if count and count >= db.aoeThreshold then return "AOE", targets end
    return "ST", targets
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

    local count, unknown = Enemies:Count()
    local mode, targets = self:ResolveMode(count, unknown)
    local ctx = Engine:NewContext(spec, self.hero, mode, targets, now)
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
                self:Debug("-> %s [%s] %s | nativo: %s | %s %s nemici", A.SpellName(p.spell),
                    p.source == "native" and "Assisted Combat" or "regola", p.reason or "",
                    result.native and A.SpellName(result.native) or tostring(result.nativeWhy),
                    mode, tostring(targets or "?"))
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
ns:On("PLAYER_REGEN_ENABLED", function() ns:RefreshVisibility() end)
ns:On("PLAYER_TARGET_CHANGED", function() ns:RefreshVisibility() end)
ns:On("ENCOUNTER_START", function() ns.inEncounter = true end)
ns:On("ENCOUNTER_END", function() ns.inEncounter = false end)
ns:On("UNIT_PET", function() A.ClearKnownCache(); UI.Cooldowns:Build(ns.activeSpec) end, "player")
