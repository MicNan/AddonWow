-- RotAssist - CooldownFrame
-- Riquadro dei cooldown maggiori: si illumina quando l'abilita' e' pronta
-- (C_Spell.GetSpellCooldown(...).isActive, mai segreto). Non suggerisce ne'
-- forza l'uso: e' solo un promemoria visivo.

local _, ns = ...
local A, L = ns.API, ns.L
local UI = ns.UI

local SIZE, GAP = 36, 4

local CD = { icons = {} }
UI.Cooldowns = CD

function CD:Create()
    local f = CreateFrame("Frame", "RotAssistCooldownFrame", UIParent)
    f:SetSize(SIZE, SIZE)
    f:SetFrameStrata("MEDIUM")
    UI.MakeMovable(f, "cdPos")
    UI.AddMoverBackground(f, "RotAssist - cooldown")
    self.frame = f
    self:ApplySettings()
    return f
end

function CD:ApplySettings()
    local f = self.frame
    if not f then return end
    f:SetScale(ns.db.scale or 1)
    UI.RestorePosition(f, "cdPos")
    f:SetUnlocked(not ns.db.locked)
end

-- Ricostruisce le icone per la spec attiva (solo abilita' conosciute).
function CD:Build(spec)
    for _, icon in ipairs(self.icons) do icon:Hide() end
    self.list = {}
    if not (self.frame and spec and spec.majorCooldowns) then return end
    for _, def in ipairs(spec.majorCooldowns) do
        if A.IsKnown(def.spell, def.pet) then
            self.list[#self.list + 1] = def
        end
    end
    for i, def in ipairs(self.list) do
        local icon = self.icons[i]
        if not icon then
            icon = UI.CreateIcon(self.frame, SIZE)
            UI.AddGlow(icon)
            self.icons[i] = icon
        end
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", self.frame, "LEFT", (i - 1) * (SIZE + GAP), 0)
        icon.def = def
        icon:Show()
    end
    self.frame:SetWidth(math.max(SIZE, #self.list * (SIZE + GAP) - GAP))
end

function CD:Update()
    if not self.list then return end
    for i, def in ipairs(self.list) do
        local icon = self.icons[i]
        local id = A.Override(def.spell)
        icon.tex:SetTexture(A.SpellTexture(id))
        local ready = A.IsReady(id)
        icon.tex:SetDesaturated(ready == false)
        icon:SetGlow(ready == true)
        A.ApplyCooldown(icon.cd, id)
    end
end
