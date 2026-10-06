-- RotAssist - Init
-- Namespace, valori di default, utility di stampa e dispatcher degli eventi.
-- Tutti gli handler degli eventi girano dentro pcall: un errore interno viene
-- segnalato una sola volta in chat invece di generare popup di errore Lua.

local ADDON_NAME, ns = ...

RotAssist = ns              -- globale: usata da Bindings.xml e per /dump RotAssist
ns.name = ADDON_NAME
ns.specs = {}               -- [specID] = modulo spec (registrato dai file in Specs\)

ns.defaults = {
    dbVersion       = 1,
    shown           = true,
    locked          = false,
    scale           = 1.0,
    showOnlyInCombat = false,
    mode            = "AUTO",     -- AUTO | ST | AOE
    aoeThreshold    = 3,          -- nemici per passare in AoE in modalita' AUTO
    source          = "HYBRID",   -- HYBRID | NATIVE | RULES
    showCooldowns   = true,
    showAlerts      = true,
    showResource    = true,
    alertSound      = false,
    debug           = false,
    showMinimap     = true,
    showKeybinds    = true,
    language        = "auto",     -- auto | it | en
    minimapAngle    = 225,
    updateRate      = 0.1,
    pos      = { point = "CENTER", x = 0,   y = -180 },
    cdPos    = { point = "CENTER", x = 0,   y = -250 },
    alertPos = { point = "CENTER", x = 0,   y = -110 },
    learned  = {},                -- durate apprese: [spellID] = { cd = n, recharge = n }
    learnedAura = {},             -- durate apprese dei buff tracciati: [chiave] = secondi
}

local function ApplyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            ApplyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end
ns.ApplyDefaults = ApplyDefaults

---------------------------------------------------------------------------
-- Stampa
---------------------------------------------------------------------------
local PREFIX = "|cff33ff99RotAssist|r: "
local LOG_MAX = 600

local function Format(msg, ...)
    local n = select("#", ...)
    if n == 0 then return tostring(msg) end
    local args = {}
    for i = 1, n do args[i] = tostring((select(i, ...))) end
    return tostring(msg):format(unpack(args, 1, n))
end

-- Registro salvato in RotAssistDB.log (scritto su disco al /reload o al logout):
-- permette di analizzare probe, debug ed errori leggendo il file SavedVariables.
function ns:Log(text)
    local db = self.db
    if not db then return end
    db.log = db.log or {}
    text = tostring(text):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    local stamp = (date and date("%H:%M:%S")) or ""
    table.insert(db.log, ("%s %.1f %s"):format(stamp, GetTime and GetTime() or 0, text))
    while #db.log > LOG_MAX do table.remove(db.log, 1) end
end

function ns:Print(msg, ...)
    local text = Format(msg, ...)
    print(PREFIX .. text)
    self:Log(text)
end

function ns:Debug(msg, ...)
    if self.db and self.db.debug then
        local text = Format(msg, ...)
        print("|cff888888[RA]|r " .. text)
        self:Log("[debug] " .. text)
    end
end

local reported = {}
function ns:ReportError(err)
    err = tostring(err)
    if reported[err] then return end
    reported[err] = true
    self:Log("[errore] " .. err .. (debugstack and ("\n" .. debugstack(2, 6, 0)) or ""))
    if self.db and self.db.debug then
        self:Print(self.L.MSG_INTERNAL_ERROR_DETAIL, err)
    elseif not reported._hinted then
        reported._hinted = true
        self:Print(self.L.MSG_INTERNAL_ERROR)
    end
end

---------------------------------------------------------------------------
-- Moduli spec
---------------------------------------------------------------------------
function ns:RegisterSpec(specID, module)
    module.specID = specID
    self.specs[specID] = module
end

---------------------------------------------------------------------------
-- Eventi
---------------------------------------------------------------------------
local handlers = {}
local eventFrame = CreateFrame("Frame")
ns.eventFrame = eventFrame

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do
        local ok, err = pcall(list[i], event, ...)
        if not ok then ns:ReportError(err) end
    end
end)

-- Registra un handler. unit1/unit2 opzionali per RegisterUnitEvent.
function ns:On(event, fn, unit1, unit2)
    if not handlers[event] then
        handlers[event] = {}
        local ok
        if unit1 then
            ok = pcall(eventFrame.RegisterUnitEvent, eventFrame, event, unit1, unit2)
        else
            ok = pcall(eventFrame.RegisterEvent, eventFrame, event)
        end
        if not ok then
            -- evento inesistente in questa versione del client: lo ignoriamo
            handlers[event] = nil
            return
        end
    end
    table.insert(handlers[event], fn)
end
