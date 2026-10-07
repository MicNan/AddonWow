-- RotAssist Companion - Init
-- Namespace, valori di default, stampa e dispatcher degli eventi.
-- Addon indipendente da RotAssist: lavora solo fuori dal combattimento e legge
-- dati pubblici del gioco (mappe, missioni, valute, Great Vault, calendario).
-- Tutti gli handler girano dentro pcall: nessun popup di errore Lua.

local ADDON_NAME, ns = ...

RotAssistCompanion = ns
ns.name = ADDON_NAME

ns.defaults = {
    dbVersion     = 1,
    language      = "auto",      -- auto | it | en
    showMinimap   = true,
    minimapAngle  = 200,
    notifyLogin   = true,        -- riepilogo in chat all'accesso
    onlyBountiful = false,       -- scheda Delve: solo le abbondanti
    playerType    = "medium",
    tooltipPrices = true,        -- prezzi d'asta e vendor nei tooltip degli oggetti    -- strategie sull'oro: casual | medium | hardcore
    tab           = "delves",    -- ultima scheda aperta
    pos           = { point = "CENTER", x = 0, y = 60 },
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

local PREFIX = "|cff66ccffRotAssist Companion|r: "

local function Format(msg, ...)
    local n = select("#", ...)
    if n == 0 then return tostring(msg) end
    local args = {}
    for i = 1, n do args[i] = tostring((select(i, ...))) end
    return tostring(msg):format(unpack(args, 1, n))
end
ns.Format = Format

-- Registro in RotAssistCompanionDB.log (scritto su disco al /reload o al
-- logout): permette di analizzare scansioni e problemi leggendo il file.
local LOG_MAX = 300
function ns:Log(text)
    local db = self.db
    if not db then return end
    db.log = db.log or {}
    text = tostring(text):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    table.insert(db.log, ((date and date("%Y-%m-%d %H:%M:%S")) or "") .. " " .. text)
    while #db.log > LOG_MAX do table.remove(db.log, 1) end
end

function ns:Print(msg, ...)
    local text = Format(msg, ...)
    print(PREFIX .. text)
    self:Log(text)
end

local reported = {}
function ns:ReportError(err)
    err = tostring(err)
    if reported[err] then return end
    reported[err] = true
    self:Print("|cffff5555%s|r %s", self.L and self.L.MSG_INTERNAL_ERROR or "errore interno:", err)
    self:Log("[errore] " .. err .. (debugstack and ("\n" .. debugstack(2, 6, 0)) or ""))
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

function ns:On(event, fn)
    if not handlers[event] then
        handlers[event] = {}
        if not pcall(eventFrame.RegisterEvent, eventFrame, event) then
            handlers[event] = nil
            return
        end
    end
    table.insert(handlers[event], fn)
end

-- Esegue fn dopo 'delay' secondi (protetto da pcall).
function ns:After(delay, fn)
    local run = function()
        local ok, err = pcall(fn)
        if not ok then ns:ReportError(err) end
    end
    if C_Timer and C_Timer.After then C_Timer.After(delay, run) else run() end
end
