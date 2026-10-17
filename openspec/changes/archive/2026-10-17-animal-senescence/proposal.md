## Why

Animals currently never age: `edad` counts seconds but has no gameplay effect, kills are binary, and role-hunter predators are needs-immune. The exploration converged on a systemic senescence model where every animal weakens with years — velocity, force, and vida-recovery decay per species until natural death — so old-vs-prime matchups (e.g. old zorro vs prime raton) resolve through damage, not scripts.

## What Changes

- Per-species aging: animal-years from lived seconds drive prime/worn/frail stages, stat decay (speed, attack force, vida-regen, action/cooldown times), victim frailty, and a hard lifespan death ("vejez").
- Two-sided force damage: `dmg = base x attacker_force(age, species) x victim_frailty(age, species)` for bites, pounce, dive, cull, and strike contact.
- **BREAKING**: instant kills become emergent — removal + carrion only when `dmg >= victim hp`; otherwise the victim takes partial damage and may escape if its decision layer says so.
- Failed pounce/dive leaves a wounded victim plus a real chase window (attacker on cooldown, victim decision-gated flee/hide).
- **BREAKING**: role-hunter predators (zorro, lobo, saponpc) lose needs-immunity — they drain, starve, weaken, and die of age like all agents.
- Age slows actions: movement velocity plus verb/action times and cooldowns (dig, groom, thermal, howl, escort, etc.) scale per species.
- Decisions become age-aware: micro reflexes (flee vs hide vs eat) and JEV macro menus/snapshots carry self age-stage plus hunter/prey age signals.
- HUD surfaces age-stage alongside animal-years (stage/frailty signal, not just a number).

## Capabilities

### New Capabilities

- `animal-senescence`: per-species lifespan and decay model — stages, speed/force/regen/action-time multipliers, victim frailty, natural death, unified age-scaled damage, failed-kill wound-plus-escape rule, and age signals for decisions.

### Modified Capabilities

- `vitals-water`: `edad` gains gameplay effect (was explicitly display-only with identical vida trajectories); thresholds/regen now age-scaled.
- `living-map`: role-hunter predators lose Vida-needs immunity and die of hunger/thirst/age; all agents age and die naturally.
- `karma-core`: kill verbs and contact damage become age-scaled damage values; instakill only when damage exceeds life; speed and regen age-scaled.
- `species-locomotion`: gait/step envelope age-scaled (old legs move differently, same modes).
- `karma-verbs`: verb cooldowns/durations age-scaled; failed kills defined as wound + cooldown (no free re-hit).
- `hud-clarity`: edad readout gains age-stage/frailty signal (was display-only animal-years).
- `ai-survival`: hunger/thirst/flee/hide/carrion-preference decisions weigh age (self frailty, hunter force, escape viability).

## Impact

- Simulation: `KarmaData` (SENESCENCE table in TUNING, base damages), `KarmaUtils.update_needs`, `KarmaState.eff_*`, `KarmaGame.move/loco`, `KarmaPredators.strike_contact/strike_agents/chase`, `KarmaEat.pounce/dive/cull/strike`, `KarmaAI` micro + all `KarmaJev*` menu/state builders.
- Specs: 1 new + 7 modified capability deltas; `living-map` pressure-floor guarantee removed (balance shift).
- Tests: gdUnit4 per behavior (decay curves, two-sided damage, failed-pounce chase, hunter starvation/age death, age-aware decisions, HUD stage).
