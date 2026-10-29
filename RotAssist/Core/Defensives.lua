-- RotAssist - Defensives
-- Difese in base alla vita del giocatore, per le spec che dichiarano
-- spec.defensives = { { key, threshold = "chiaveOpzione", spells = {...},
-- emergency = true? }, ... }.
--
-- Per ogni livello l'addon sceglie la PRIMA abilita' conosciuta e lanciabile
-- (cooldown, IsSpellUsable: dati leggibili anche in combattimento). Se
-- mostrarla dipende dalla vita:
--   * vita leggibile (mondo aperto, fuori dagli scontri): la decide l'addon;
--   * vita segreta (scontri con i boss, Mitiche+, PvP classificato): l'addon
--     non la legge; l'icona si mostra o si nasconde da sola con una curva
--     nativa (UnitHealthPercent + curva), come la barra del pet. L'addon non
--     confronta mai il valore.
-- Solo in combattimento. Niente viene lanciato: e' un suggerimento visivo.

local _, ns = ...
local A, Engine = ns.API, ns.Engine

local D = {}
ns.Defensives = D

-- Prima abilita' pronta del livello (spellID) oppure nil
function D:Pick(spec, tier)
    for _, id in ipairs(tier.spells or {}) do
        if Engine:IsKnown(spec, id) then
            local castable = Engine:Castable(spec, id)
            if castable ~= false then return Engine:DisplaySpell(id) end
        end
    end
    return nil
end

function D:Threshold(tier)
    local v = tier.threshold and ns.db[tier.threshold]
    return type(v) == "number" and v or 0.35
end

-- Elenco per l'interfaccia: { tier, spell, threshold, visible = true/false/nil }
-- visible = nil vuol dire "vita segreta": decide la curva nativa.
function D:Collect(spec)
    local out = {}
    if not (spec and spec.defensives and ns.db.showDefensives) then return out end
    if not A.InCombat() then return out end
    local pct = A.HealthPct("player")
    for _, tier in ipairs(spec.defensives) do
        local spell = self:Pick(spec, tier)
        if spell then
            local th = self:Threshold(tier)
            local visible
            if pct then visible = pct < th end
            if visible ~= false then
                out[#out + 1] = { tier = tier, spell = spell, threshold = th, visible = visible }
            end
        end
    end
    return out
end
