-- RotAssist - Glow
-- Bagliore pulsante semplice (nessuna libreria esterna, nessuna funzione
-- protetta dei pulsanti d'azione).

local _, ns = ...
ns.UI = ns.UI or {}

function ns.UI.AddGlow(frame, r, g, b)
    local tex = frame:CreateTexture(nil, "OVERLAY")
    tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    tex:SetBlendMode("ADD")
    tex:SetVertexColor(r or 1, g or 0.82, b or 0.2)
    tex:SetPoint("CENTER")
    local w, h = frame:GetSize()
    tex:SetSize(w * 1.9, h * 1.9)
    tex:Hide()

    local anim = tex:CreateAnimationGroup()
    anim:SetLooping("BOUNCE")
    local a = anim:CreateAnimation("Alpha")
    a:SetFromAlpha(0.3)
    a:SetToAlpha(1)
    a:SetDuration(0.55)

    function frame:SetGlow(on)
        if on then
            if not tex:IsShown() then tex:Show(); anim:Play() end
        elseif tex:IsShown() then
            anim:Stop(); tex:Hide()
        end
    end
end

-- Icona quadrata con bordo e swipe di cooldown.
function ns.UI.CreateIcon(parent, size)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(size, size)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", -1, 1)
    bg:SetPoint("BOTTOMRIGHT", 1, -1)
    bg:SetColorTexture(0, 0, 0, 0.85)
    f.tex = f:CreateTexture(nil, "ARTWORK")
    f.tex:SetAllPoints()
    f.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cd:SetAllPoints()
    f.cd:SetDrawEdge(false)
    f.badge = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.badge:SetPoint("TOPRIGHT", -2, -2)
    return f
end

-- Rende trascinabile un frame salvando la posizione in ns.db[posKey].
function ns.UI.MakeMovable(frame, posKey)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not ns.db.locked then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint(1)
        ns.db[posKey] = { point = point or "CENTER", x = x or 0, y = y or 0 }
    end)
end

function ns.UI.RestorePosition(frame, posKey)
    local p = ns.db[posKey] or ns.defaults[posKey]
    frame:ClearAllPoints()
    frame:SetPoint(p.point or "CENTER", UIParent, p.point or "CENTER", p.x or 0, p.y or 0)
end

-- Sfondo visibile solo con i riquadri sbloccati.
function ns.UI.AddMoverBackground(frame, label)
    local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetPoint("TOPLEFT", -4, 4)
    bg:SetPoint("BOTTOMRIGHT", 4, -4)
    bg:SetColorTexture(0.1, 0.6, 1, 0.25)
    local txt = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    txt:SetPoint("BOTTOM", frame, "TOP", 0, 6)
    txt:SetText(label)
    frame.mover = { bg, txt }
    function frame:SetUnlocked(on)
        for _, r in ipairs(self.mover) do r:SetShown(on) end
        self:EnableMouse(on)
    end
end
