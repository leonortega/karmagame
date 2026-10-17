## Why

Water is currently infinite: `vitals-water` and `ecosystem-2d` explicitly declare charcos and lagos as non-depletable terrain, and `KarmaEat.drink_water` only refills `sed`/`vida` without debiting the body. That removes any scarcity pressure from thirst and makes water placement a non-decision. Making water finite — drained by drinking, restored by rain — turns thirst into a real survival axis and gives the world a weather rhythm.

## What Changes

- **BREAKING**: charcos and lagos stop being infinite. Each body carries a finite water `level`; drinking debits the body you drank from.
- Each species has an explicit per-species sip cost (a predator drains a puddle faster than an oruga).
- A drink requires `level > 0`; the last drop is drinkable (debits the remainder, still grants the full sip), after which the body is dry.
- A dry body stays an empty basin: it keeps its radius and still blocks non-amphibious movement, but no longer offers a drink. Player and AI both skip dry bodies when drinking / seeking water.
- **New rain cycle**: an independent global weather clock produces dry spells and rain events. Rain refills every body at a rate while it lasts, so a long enough rain returns a body to 100% and a short shower leaves it partial.
- Rain is also a fertility event: it spawns a burst of insects, feeding Sapo/Topo.
- Rendering reflects depletion (water disc scales with `level`, dry basins read as empty) and rain (a visible rain state).
- Water `level` persists across reincarnation, like the bodies themselves; weather timers reset each life.

## Capabilities

### New Capabilities
- `rain-cycle`: a global weather clock, rain events that refill charcos/lagos by rate x duration, the rain insect burst, and the rain visual/HUD state.

### Modified Capabilities
- `vitals-water`: water bodies become finite with a per-body `level` and per-species sip cost; drinking is gated on `level > 0`; both player and AI skip dry bodies. Replaces the "infinite charcos and lagos" requirement.
- `ecosystem-2d`: replaces the "infinite water bodies" requirement with finite bodies rendered by `level`, and adds the rain visual.

## Impact

- `scripts/karma_data.gd` — new `TUNING` entries: per-species sip-cost table, water capacity model, rain cadence/duration/rate, rain insect burst.
- `scripts/karma_state.gd` — `seed_waters` seeds `level`; `possess_or_spawn` keeps levels (already kept via `waters`).
- `scripts/karma_eat.gd` — `drink_water` debits `level`; dry gating.
- `scripts/karma_utils.gd` — `nearest_water_for` skips dry bodies.
- `scripts/karma_ai.gd` — `ai_seek_water`/`ai_drink` skip dry bodies.
- `scripts/karma_game.gd` — `age_world` ticks the weather clock and rain refill; rain insect burst.
- `scripts/karma_draw.gd` + `scripts/main.gd` — depletion and rain rendering.
- `tests/` — new gdUnit4 suites for depletion, rain refill, dry gating, insect burst.
- No new dependencies; pure static simulation on the existing `Dictionary` state.
