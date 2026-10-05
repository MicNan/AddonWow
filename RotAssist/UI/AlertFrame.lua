-- RotAssist - AlertFrame
-- Mostra fino a 4 avvisi (icona + testo) raccolti da ns.Alerts.

local _, ns = ...
local A = ns.API
local UI = ns.UI

local MAX, ROW = 4, 22

local AF = { rows = {}, active = {} }
UI.AlertFrame = AF

function AF:Create()
    local f = CreateFrame("Frame", "RotAssistAlertFrame", UIParent)
    f:SetSize(220, ROW * MAX)
    f:SetFrameStrata("MEDIUM")
    UI.MakeMovable(f, "alertPos")
    UI.AddMoverBackground(f, "RotAssist - avvisi")
    for i = 1, MAX do
        local row = CreateFrame("Frame", nil, f)
        row:SetSize(220, ROW - 2)
        row:SetPoint("TOP", f, "TOP", 0, -(i - 1) * ROW)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(ROW - 2, ROW - 2)
        row.icon:SetPoint("LEFT")
        row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.text:SetTextColor(1, 0.35, 0.25)
        local ag = row:CreateAnimationGroup()
        ag:SetLooping("BOUNCE")
        local a = ag:CreateAnimation("Alpha")
        a:SetFromAlpha(0.55); a:SetToAlpha(1); a:SetDuration(0.5)
        row.anim = ag
        row:Hide()
        self.rows[i] = row
    end
    self.frame = f
    self:ApplySettings()
    return f
end

function AF:ApplySettings()
    local f = self.frame
    if not f then return end
    f:SetScale(ns.db.scale or 1)
    UI.RestorePosition(f, "alertPos")
    f:SetUnlocked(not ns.db.locked)
end

function AF:Update(alerts)
    if not self.frame then return end
    local seen = {}
    for i = 1, MAX do
        local row, a = self.rows[i], alerts and alerts[i]
        if a then
            row.icon:SetTexture(A.SpellTexture(a.icon))
            row.text:SetText(a.text)
            if not row:IsShown() then row:Show(); row.anim:Play() end
            seen[a.key] = true
            if not self.active[a.key] and ns.db.alertSound then
                pcall(PlaySound, SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
            end
        elseif row:IsShown() then
            row.anim:Stop(); row:Hide()
        end
    end
    self.active = seen
end
