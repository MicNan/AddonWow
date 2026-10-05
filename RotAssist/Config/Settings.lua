-- RotAssist - Settings
-- Pannello opzioni nell'interfaccia di gioco (Settings API, 11.0+).
-- Le impostazioni sono lette/scritte direttamente in RotAssistDB
-- (SavedVariablesPerCharacter), quindi valgono per personaggio.

local _, ns = ...
local L = ns.L

ns.settingObjects = {}

-- Applica una modifica (da pannello o da comando) a tutta l'interfaccia.
function ns:OnSettingChanged(key, value)
    if key == "scale" or key == "locked" then
        ns.UI.Main:ApplySettings()
        ns.UI.Cooldowns:ApplySettings()
        ns.UI.AlertFrame:ApplySettings()
    end
    if key == "showMinimap" then
        ns.UI.Launcher:ApplySettings()
    end
    if key == "debug" and value then
        self:Print("debug attivo: /rotassist why per il dettaglio delle regole.")
    end
    self:RefreshVisibility()
end

-- Imposta un valore passando dall'oggetto Settings se esiste (cosi' il
-- pannello resta sincronizzato), altrimenti direttamente nel DB.
function ns:Set(key, value)
    local s = self.settingObjects[key]
    if s and s.SetValue then
        local ok = pcall(s.SetValue, s, value)
        if ok then return end
    end
    self.db[key] = value
    self:OnSettingChanged(key, value)
end

function ns:OpenSettings()
    if self.settingsCategory and Settings and Settings.OpenToCategory then
        local id = self.settingsCategory.GetID and self.settingsCategory:GetID() or self.settingsCategory
        if pcall(Settings.OpenToCategory, id) then return end
    end
    self:Print("pannello opzioni non disponibile: usa i comandi /rotassist.")
end

function ns:RegisterSettings()
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnSetting) then
        return
    end
    local db = self.db
    local VT = Settings.VarType or {}
    local category = Settings.RegisterVerticalLayoutCategory("RotAssist")
    self.settingsCategory = category

    local function Register(key, vtype, label)
        local s = Settings.RegisterAddOnSetting(category, "ROTASSIST_" .. key:upper(), key, db,
            vtype, label, ns.defaults[key])
        if s.SetValueChangedCallback then
            s:SetValueChangedCallback(function(_, value) ns:OnSettingChanged(key, value) end)
        end
        ns.settingObjects[key] = s
        return s
    end

    local function Checkbox(key, label, tip)
        Settings.CreateCheckbox(category, Register(key, VT.Boolean or "boolean", label), tip)
    end

    local function Slider(key, label, tip, min, max, step, fmt)
        local s = Register(key, VT.Number or "number", label)
        local opts = Settings.CreateSliderOptions(min, max, step)
        if MinimalSliderWithSteppersMixin and opts.SetLabelFormatter then
            opts:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, fmt)
        end
        Settings.CreateSlider(category, s, opts, tip)
    end

    local function Dropdown(key, label, tip, values)
        local s = Register(key, VT.String or "string", label)
        local function GetOptions()
            local c = Settings.CreateControlTextContainer()
            for _, v in ipairs(values) do c:Add(v[1], v[2]) end
            return c:GetData()
        end
        local create = Settings.CreateDropdown or Settings.CreateDropDown
        create(category, s, GetOptions, tip)
    end

    Checkbox("shown", L.OPT_SHOWN)
    Checkbox("locked", L.OPT_LOCKED)
    Slider("scale", L.OPT_SCALE, nil, 0.5, 2.0, 0.05, function(v) return ("%.2f"):format(v) end)
    Checkbox("showOnlyInCombat", L.OPT_ONLYCOMBAT)
    Dropdown("mode", L.OPT_MODE, nil, {
        { "AUTO", L.OPT_MODE_AUTO }, { "ST", L.OPT_MODE_ST }, { "AOE", L.OPT_MODE_AOE },
    })
    Slider("aoeThreshold", L.OPT_THRESHOLD, nil, 2, 8, 1, function(v) return tostring(math.floor(v + 0.5)) end)
    Dropdown("source", L.OPT_SOURCE, nil, {
        { "HYBRID", L.OPT_SRC_HYBRID }, { "NATIVE", L.OPT_SRC_NATIVE }, { "RULES", L.OPT_SRC_RULES },
    })
    Checkbox("showCooldowns", L.OPT_COOLDOWNS)
    Checkbox("showAlerts", L.OPT_ALERTS)
    Checkbox("showResource", L.OPT_RESOURCE)
    Checkbox("alertSound", L.OPT_SOUND)
    Checkbox("showMinimap", L.OPT_MINIMAP)
    Checkbox("debug", L.OPT_DEBUG)

    Settings.RegisterAddOnCategory(category)
end
