-- RotAssist - Generic
-- Modulo di ripiego per le spec senza modulo dedicato: mostra solo il
-- suggerimento di Assisted Combat, senza regole e senza avvisi.

local _, ns = ...

ns.genericSpec = {
    name = "Generico (solo Assisted Combat)",
    priorities = nil,
    alerts = {},
    majorCooldowns = {},
}
