-- RotAssist - Keybinds
-- Trova il tasto assegnato a un'abilita' sulle barre d'azione, per mostrarlo
-- sulle icone suggerite. Solo lettura: GetBindingKey e le informazioni sugli
-- slot non sono protette e non toccano il combattimento.
--
-- Supporta: barre di Blizzard (mappatura slot -> comando di binding) e i
-- pulsanti di ElvUI / Bartender4 / LibActionButton (campo keyBoundTarget).
-- Limiti: abilita' dentro le macro non riconosciute.

local _, ns = ...

local K = { slotKey = {}, spellKey = {}, dirty = true }
ns.Keybinds = K

-- Comando di binding standard per uno slot delle barre di Blizzard.
local function BlizzardCommand(slot)
    if slot <= 12 then return "ACTIONBUTTON" .. slot end
    if slot >= 25 and slot <= 36 then return "MULTIACTIONBAR3BUTTON" .. (slot - 24) end
    if slot >= 37 and slot <= 48 then return "MULTIACTIONBAR4BUTTON" .. (slot - 36) end
    if slot >= 49 and slot <= 60 then return "MULTIACTIONBAR2BUTTON" .. (slot - 48) end
    if slot >= 61 and slot <= 72 then return "MULTIACTIONBAR1BUTTON" .. (slot - 60) end
    if slot >= 73 and slot <= 120 then return "ACTIONBUTTON" .. ((slot - 1) % 12 + 1) end -- barre di forma/stance
    if slot >= 145 and slot <= 156 then return "MULTIACTIONBAR5BUTTON" .. (slot - 144) end
    if slot >= 157 and slot <= 168 then return "MULTIACTIONBAR6BUTTON" .. (slot - 156) end
    if slot >= 169 and slot <= 180 then return "MULTIACTIONBAR7BUTTON" .. (slot - 168) end
end

local function Abbreviate(key)
    if not key or key == "" then return nil end
    key = key:upper()
    key = key:gsub("SHIFT%-", "S"):gsub("CTRL%-", "C"):gsub("ALT%-", "A"):gsub("META%-", "M")
    key = key:gsub("MOUSEWHEELUP", "WU"):gsub("MOUSEWHEELDOWN", "WD"):gsub("MIDDLEBUTTON", "M3")
    key = key:gsub("BUTTON", "M"):gsub("NUMPAD", "N"):gsub("PLUS", "+"):gsub("MINUS", "-")
    key = key:gsub("MULTIPLY", "*"):gsub("DIVIDE", "/"):gsub("DECIMAL", "."):gsub("SPACE", "Sp")
    return key
end

local function KeyFor(command)
    if not command then return nil end
    local ok, key = pcall(GetBindingKey, command)
    if ok and type(key) == "string" then return Abbreviate(key) end
end

-- Pulsanti di addon di barre (ElvUI, Bartender4, LibActionButton in genere).
local ADDON_BUTTONS = {
    function(add) for b = 1, 15 do for i = 1, 12 do add(_G["ElvUI_Bar" .. b .. "Button" .. i]) end end end,
    function(add) for i = 1, 180 do add(_G["BT4Button" .. i]) end end,
}

local function ButtonSlot(btn)
    local slot = btn._state_action or btn.action
    if type(slot) ~= "number" and btn.GetAttribute then
        local ok, v = pcall(btn.GetAttribute, btn, "action")
        if ok then slot = tonumber(v) end
    end
    return type(slot) == "number" and slot or nil
end

function K:Rebuild()
    wipe(self.slotKey)
    wipe(self.spellKey)
    -- 1) pulsanti degli addon di barre
    local function add(btn)
        if type(btn) ~= "table" then return end
        local slot = ButtonSlot(btn)
        if not slot or self.slotKey[slot] then return end
        local key = KeyFor(btn.keyBoundTarget) or KeyFor(btn.bindstring)
            or (btn.GetName and btn:GetName() and KeyFor("CLICK " .. btn:GetName() .. ":LeftButton"))
            or (btn.GetName and btn:GetName() and KeyFor("CLICK " .. btn:GetName() .. ":Keybind"))
        if key then self.slotKey[slot] = key end
    end
    for _, scan in ipairs(ADDON_BUTTONS) do pcall(scan, add) end
    -- 2) barre di Blizzard
    for slot = 1, 180 do
        if not self.slotKey[slot] then
            self.slotKey[slot] = KeyFor(BlizzardCommand(slot))
        end
    end
    self.dirty = false
end

local function SlotsForSpell(spellID)
    if C_ActionBar and C_ActionBar.FindSpellActionButtons then
        local ok, slots = pcall(C_ActionBar.FindSpellActionButtons, spellID)
        if ok and type(slots) == "table" then return slots end
    end
    return {}
end

-- Tasto per l'abilita' mostrata (o per l'abilita' base, se e' un override).
function K:Get(spellID, baseID)
    if not ns.db or not ns.db.showKeybinds then return nil end
    if self.dirty then self:Rebuild() end
    local cached = self.spellKey[spellID]
    if cached ~= nil then return cached or nil end
    local key
    for _, id in ipairs({ spellID, baseID }) do
        if id and not key then
            for _, slot in ipairs(SlotsForSpell(id)) do
                key = self.slotKey[slot]
                if key then break end
            end
        end
    end
    self.spellKey[spellID] = key or false
    return key
end

local function Invalidate() K.dirty = true end
for _, ev in ipairs({ "ACTIONBAR_SLOT_CHANGED", "UPDATE_BINDINGS", "ACTIONBAR_PAGE_CHANGED",
                      "UPDATE_BONUS_ACTIONBAR", "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_ENTERING_WORLD" }) do
    ns:On(ev, Invalidate)
end
