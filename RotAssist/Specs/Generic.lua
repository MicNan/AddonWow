-- RotAssist - Generic
-- Modulo di ripiego per le spec senza modulo dedicato: mostra solo il
-- suggerimento di Assisted Combat, senza regole; unico avviso: l'interrupt
-- della classe quando il bersaglio lancia (Core\Interrupts.lua).

local _, ns = ...

ns.genericSpec = {
    name = "Generico (solo Assisted Combat)",
    priorities = nil,
    alerts = { { type = "interrupt" } },
    majorCooldowns = {},
}
