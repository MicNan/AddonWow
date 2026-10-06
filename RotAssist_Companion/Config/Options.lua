-- RotAssist Companion - Options
-- Pannello opzioni (Settings API) e comandi /rac.

local _, ns = ...

ns.settingObjects = {}

function ns:OnSettingChanged(key, value)
    if key == "showMinimap" then ns.Launcher:ApplySettings() end
    if key == "language" then
        self:SetLanguage(value)
        self:Print(self.L.MSG_LANG, self.lang)
    end
    if key == "onlyBountiful" or key == "playerType" then ns.Panel:Refresh() end
    if key == "playerType" then self:Print(self.L.MSG_PROFILE, self.L["PROFILE_" .. tostring(value)]) end
end

function ns:Set(key, value)
    local s = self.settingObjects[key]
    if s and s.SetValue and pcall(s.SetValue, s, value) then return end
    self.db[key] = value
    self:OnSettingChanged(key, value)
end

function ns:OpenSettings()
    if self.settingsCategory and Settings and Settings.OpenToCategory then
        local id = self.settingsCategory.GetID and self.settingsCategory:GetID() or self.settingsCategory
        if pcall(Settings.OpenToCategory, id) then return end
    end
    self:Print(self.L.MSG_NO_SETTINGS)
end

function ns:RegisterSettings()
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnSetting) then return end
    local L, db = self.L, self.db
    local VT = Settings.VarType or {}
    local category = Settings.RegisterVerticalLayoutCategory("RotAssist Companion")
    self.settingsCategory = category

    local function Register(key, vtype, label)
        local s = Settings.RegisterAddOnSetting(category, "ROTASSISTCOMPANION_" .. key:upper(), key, db,
            vtype, label, ns.defaults[key])
        if s.SetValueChangedCallback then
            s:SetValueChangedCallback(function(_, value) ns:OnSettingChanged(key, value) end)
        end
        ns.settingObjects[key] = s
        return s
    end
    local function Checkbox(key, label)
        Settings.CreateCheckbox(category, Register(key, VT.Boolean or "boolean", label))
    end

    Checkbox("showMinimap", L.OPT_MINIMAP)
    Checkbox("notifyLogin", L.OPT_NOTIFY)
    Checkbox("onlyBountiful", L.OPT_ONLY_BOUNTIFUL)
    local profile = Register("playerType", VT.String or "string", L.OPT_PROFILE)
    local function ProfileOptions()
        local c = Settings.CreateControlTextContainer()
        for _, key in ipairs(ns.Gold.PROFILES) do c:Add(key, L["PROFILE_" .. key]) end
        return c:GetData()
    end
    local createDropdown = Settings.CreateDropdown or Settings.CreateDropDown
    createDropdown(category, profile, ProfileOptions)

    local lang = Register("language", VT.String or "string", L.OPT_LANGUAGE)
    local function LangOptions()
        local c = Settings.CreateControlTextContainer()
        c:Add("auto", L.OPT_LANG_AUTO); c:Add("it", L.OPT_LANG_IT); c:Add("en", L.OPT_LANG_EN)
        return c:GetData()
    end
    local create = Settings.CreateDropdown or Settings.CreateDropDown
    create(category, lang, LangOptions)

    Settings.RegisterAddOnCategory(category)
end

-- Profilo per le strategie sull'oro: occasionale -> medio -> assiduo
function ns:CycleProfile()
    local list, current = ns.Gold.PROFILES, self.db.playerType or "medium"
    local nextKey = list[1]
    for i, key in ipairs(list) do
        if key == current then nextKey = list[i % #list + 1] end
    end
    self:Set("playerType", nextKey)
end

---------------------------------------------------------------------------
-- Riepilogo in chat
---------------------------------------------------------------------------
function ns:PrintSummary()
    if ns.API.InCombat() then return end
    local L = self.L
    local bountiful, keys = ns.Delves:Summary()
    if #bountiful > 0 then
        self:Print(L.LOGIN_BOUNTIFUL, #bountiful, table.concat(bountiful, ", "))
    end
    if keys then self:Print(L.LOGIN_KEYS, keys) end
    if ns.Weekly:VaultReady() then self:Print(L.LOGIN_VAULT) end
end

---------------------------------------------------------------------------
-- Comandi
---------------------------------------------------------------------------
local TAB_ALIASES = {
    delve = "delves", delves = "delves",
    eventi = "events", events = "events", event = "events",
    settimanale = "weekly", weekly = "weekly",
    levelling = "leveling", leveling = "leveling", level = "leveling",
    oro = "gold", gold = "gold", soldi = "gold",
}

local PROFILE_ALIASES = {
    occasionale = "casual", casual = "casual",
    medio = "medium", medium = "medium", regular = "medium",
    assiduo = "hardcore", hardcore = "hardcore", dedicated = "hardcore",
}

local function Handler(msg)
    local cmd, arg = (msg or ""):match("^(%S*)%s*(.-)$")
    cmd, arg = (cmd or ""):lower(), (arg or ""):lower()
    if cmd == "" then
        ns.Panel:Toggle()
    elseif TAB_ALIASES[cmd] then
        ns.Panel:Show(TAB_ALIASES[cmd])
    elseif cmd == "aggiorna" or cmd == "refresh" then
        ns.Panel:Show()
    elseif cmd == "profilo" or cmd == "profile" then
        if PROFILE_ALIASES[arg] then ns:Set("playerType", PROFILE_ALIASES[arg]) else ns:CycleProfile() end
    elseif cmd == "stop" then
        ns.Travel:Stop()
    elseif cmd == "riepilogo" or cmd == "summary" then
        ns:PrintSummary()
    elseif cmd == "config" or cmd == "options" then
        ns:OpenSettings()
    elseif cmd == "minimap" then
        ns:Set("showMinimap", not ns.db.showMinimap)
    elseif cmd == "lang" or cmd == "language" then
        if arg == "auto" or arg == "it" or arg == "en" then ns:Set("language", arg)
        else ns:Print(ns.L.MSG_LANG_USAGE) end
    elseif cmd == "reset" then
        ns.db.pos = CopyTable(ns.defaults.pos)
        ns.Panel:ApplyPosition()
        ns:Print(ns.L.MSG_POS_RESET)
    else
        for _, line in ipairs(ns.L.HELP) do ns:Print(line) end
    end
end

SLASH_ROTASSISTCOMPANION1 = "/rac"
SLASH_ROTASSISTCOMPANION2 = "/racompanion"
SlashCmdList.ROTASSISTCOMPANION = function(msg)
    local ok, err = pcall(Handler, msg)
    if not ok then ns:ReportError(err) end
end
