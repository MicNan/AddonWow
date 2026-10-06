-- Mock minimo delle API WoW per smoke test (fengari, Lua 5.3)
unpack = table.unpack
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
tinsert = table.insert
CopyTable = function(t) local c = {} for k, v in pairs(t) do c[k] = type(v) == "table" and CopyTable(v) or v end return c end

MOCK = { now = 1000, restricted = false, known = {}, cd = {}, charges = {}, override = {},
         native = nil, auras = { target = {}, player = {} }, pet = { exists = true, dead = false, hp = 100, max = 100, combat = true },
         plates = {}, frames = {}, errors = {}, specID = 253, usableSecret = true, cdBase = {}, rechargeBase = {} }

local SecretMT = { __tostring = function() return "<secret>" end }
local function secret() return setmetatable({}, SecretMT) end
function issecretvalue(v) return type(v) == "table" and getmetatable(v) == SecretMT end
local function S(v) if MOCK.restricted then return secret() end return v end

GetTime = function() return MOCK.now end
GetLocale = function() return "enUS" end
InCombatLockdown = function() return MOCK.restricted end
UnitAffectingCombat = function(u)
    if u == "player" then return MOCK.restricted end
    if u == "pet" then return MOCK.pet.combat end
    return true
end
UnitClass = function() return "Hunter", "HUNTER" end
GetSpecialization = function() return 1 end
GetSpecializationInfo = function() return MOCK.specID end
UnitExists = function(u)
    if u == "pet" then return MOCK.pet.exists end
    if u == "target" then return true end
    return MOCK.plates[u] ~= nil
end
UnitIsDeadOrGhost = function(u) if u == "pet" then return MOCK.pet.dead end return false end
UnitCanAttack = function() return true end
UnitClassification = function() return "elite" end
UnitLevel = function() return 80 end
UnitHealth = function(u) return S(MOCK.pet.hp) end
UnitHealthMax = function(u) return S(MOCK.pet.max) end
UnitPower = function() return S(80) end
UnitPowerMax = function() return S(120) end
UnitSpellHaste = function() return 20 end
IsPlayerSpell = function(id) return MOCK.known[id] == true end
IsSpellKnown = function(id, pet) return MOCK.known[id] == true end
PlaySound = function() end
SOUNDKIT = { RAID_WARNING = 8959 }
Enum = { PowerType = { Focus = 2 } }
CreateColor = function(r, g, b) return { r = r, g = g, b = b, GetRGB = function(s) return s.r, s.g, s.b end } end

local function cdRemaining(id)
    local c = MOCK.cd[id]
    if not c then return 0, 0, 0 end
    local rem = c.start + c.dur - MOCK.now
    if rem <= 0 then MOCK.cd[id] = nil return 0, 0, 0 end
    return rem, c.start, c.dur
end
MOCK.cdRemaining = cdRemaining

C_Spell = {
    GetSpellCooldown = function(id)
        local rem, start, dur = cdRemaining(id)
        local gcdRem, gs, gd = cdRemaining(61304)
        local onGCD = false
        if rem <= 0 and gcdRem > 0 and id ~= 61304 then rem, start, dur, onGCD = gcdRem, gs, gd, true end
        local isActive = rem > 0
        local secretOk = MOCK.restricted and id ~= 61304
        return { startTime = secretOk and secret() or start, duration = secretOk and secret() or dur,
                 isActive = isActive, isOnGCD = (not MOCK.realGCD) and onGCD or nil, isEnabled = true, modRate = 1 }
    end,
    GetSpellCharges = function(id)
        local c = MOCK.charges[id]
        if not c then return nil end
        MOCK.advance(id)
        return { currentCharges = S(c.cur), maxCharges = c.max, cooldownStartTime = S(c.start or 0),
                 cooldownDuration = S(c.dur), isActive = c.cur < c.max, chargeModRate = 1 }
    end,
    IsSpellUsable = function(id)
        if MOCK.usableSecret and MOCK.restricted then return secret(), secret() end
        return true, false
    end,
    GetOverrideSpell = function(id) return MOCK.override[id] or id end,
    GetSpellTexture = function(id) return 100000 + id end,
    GetSpellName = function(id) return MOCK.names[id] or ("spell" .. id) end,
    GetSpellCooldownDuration = function(id) return { obj = true } end,
}
function MOCK.advance(id)
    local c = MOCK.charges[id]
    while c.cur < c.max and c.start and MOCK.now >= c.start + c.dur do
        c.cur = c.cur + 1
        c.start = (c.cur < c.max) and (c.start + c.dur) or nil
    end
end

C_AssistedCombat = {
    GetNextCastSpell = function() return MOCK.native end,
    IsAvailable = function() return true end,
}
C_UnitAuras = {
    GetAuraDataByIndex = function(unit, i, filter)
        if MOCK.restricted then return secret() end
        local a = MOCK.auras[unit] and MOCK.auras[unit][i]
        return a
    end,
}
C_ChallengeMode = { IsChallengeModeActive = function() return false end }

-- Frame stub ---------------------------------------------------------------
local FrameMT = {}
local function NewObj(kind)
    local o = { _kind = kind, _shown = true, _scripts = {}, _events = {}, _w = 36, _h = 36, _point = { "CENTER", nil, "CENTER", 0, 0 } }
    return setmetatable(o, FrameMT)
end
local methods = {
    CreateTexture = function() return NewObj("Texture") end,
    CreateFontString = function() return NewObj("FontString") end,
    CreateAnimationGroup = function() return NewObj("AnimGroup") end,
    CreateAnimation = function() return NewObj("Anim") end,
    SetScript = function(self, k, fn) self._scripts[k] = fn end,
    RegisterEvent = function(self, e) self._events[e] = true end,
    RegisterUnitEvent = function(self, e) self._events[e] = true end,
    Show = function(self) self._shown = true end,
    Hide = function(self) self._shown = false end,
    SetShown = function(self, v) self._shown = v and true or false end,
    IsShown = function(self) return self._shown end,
    SetSize = function(self, w, h) self._w, self._h = w, h end,
    SetWidth = function(self, w) self._w = w end,
    GetSize = function(self) return self._w, self._h end,
    GetWidth = function(self) return self._w end,
    GetPoint = function(self) return table.unpack(self._point) end,
    SetMinMaxValues = function(self, a, b) if issecretvalue(a) then error("secret passed? ok for widgets") end end,
}
methods.SetMinMaxValues = nil -- i widget accettano segreti: nessun controllo
FrameMT.__index = function(t, k) return methods[k] or function() end end
function CreateFrame(kind, name, parent, template)
    local f = NewObj(kind)
    table.insert(MOCK.frames, f)
    if name then _G[name] = f end
    return f
end
UIParent = NewObj("Frame")
SlashCmdList = {}

-- Settings stub
Settings = {
    VarType = { Boolean = "boolean", Number = "number", String = "string" },
    RegisterVerticalLayoutCategory = function(n) return { GetID = function() return 42 end } end,
    RegisterAddOnSetting = function(cat, var, key, tbl, vt, name, def)
        local s = { cb = nil }
        function s:SetValueChangedCallback(cb) self.cb = cb end
        function s:SetValue(v) tbl[key] = v; if self.cb then self.cb(self, v) end end
        function s:GetValue() return tbl[key] end
        return s
    end,
    CreateCheckbox = function() end,
    CreateSlider = function() end,
    CreateSliderOptions = function() return { SetLabelFormatter = function() end } end,
    CreateControlTextContainer = function() local d = {} return { Add = function(_, v, l) d[#d + 1] = { v, l } end, GetData = function() return d end } end,
    CreateDropdown = function(_, _, get) get() end,
    RegisterAddOnCategory = function() end,
    OpenToCategory = function() end,
}
MinimalSliderWithSteppersMixin = { Label = { Right = 1 } }

function MOCK.fire(event, ...)
    for _, f in ipairs(MOCK.frames) do
        if f._events[event] and f._scripts.OnEvent then f._scripts.OnEvent(f, event, ...) end
    end
end
math.atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
Minimap = NewObj and NewObj("Minimap") or CreateFrame("Frame")
Minimap._w = 140
Minimap.GetCenter = function() return 1000, 600 end
Minimap.GetEffectiveScale = function() return 1 end
GetCursorPosition = function() return 1100, 600 end
IsShiftKeyDown = function() return MOCK.shift == true end
GameTooltip = CreateFrame("GameTooltip")
GetSpecializationInfo = function() return MOCK.specID, "Spec", "", 461112 end
StaticPopupDialogs = {}
OKAY = "Okay"
StaticPopup_Show = function(which, a1, a2, data)
    local d = StaticPopupDialogs[which]
    local eb = CreateFrame("EditBox"); local popup = CreateFrame("Frame"); popup.EditBox = eb
    eb.SetText = function(_, t) print("POPUP editbox:", t) end
    d.OnShow(popup, data)
    print("POPUP testo:", d.text:format(a1))
end
date = function(f) return "12:34:56" end
GetBuildInfo = function() return "12.1.0", "65000", "Aug 27 2026", 120100 end
C_AddOns = { GetAddOnMetadata = function() return "0.1.0" end }
MOCK.realGCD = true            -- come in gioco: isOnGCD sempre nil
local _UAC = UnitAffectingCombat
UnitAffectingCombat = function(u)
    if type(u) == "string" and u:match("^nameplate") then return false end -- manichini
    return _UAC(u)
end
UnitThreatSituation = function(p, u) return 0 end
UnitThreatSituation = function(p, u) return nil end   -- come in gioco sui manichini
