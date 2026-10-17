## Context

See `proposal.md` for motivation. Current state that shapes the approach:

- A water body is `{kind, x, y, r}` only (`KarmaState.seed_waters`, karma_state.gd:67); nothing tracks an amount.
- `r` is shared by several consumers: collision solid (`KarmaUtils.collect_solids`:158), `resolve_collisions` (:175), `inside_water`/`nudge_dry` (:75/:82), drink reach (`nearest_water_for`:64), the sapo community anchor (karma_state.gd:234), insect shore zones (karma_game.gd:86), and the render (main.gd:898).
- Drinking has no debit: `KarmaEat.drink_water` (karma_eat.gd:43) adds `sipSed(35)`/`sipHp(5)`.
- Simulation is pure static funcs over a `Dictionary`; all numbers live in `KarmaData.TUNING`; world clocks (`insectT`, `mateT`, `respawnT`, `regrowT`) tick inside `age_world` (karma_game.gd:194).
- `possess_or_spawn` keeps the whole `waters` array across reincarnation (karma_state.gd:374), so any field added to a body persists for free.
- There is an existing year theme `"wet"` (karma_census.gd:41) but no weather runtime.

Calibration: ~32 bodies (24 charcos + 8 lagos) at 4x area scale; thirst ≈ 0.25 sed/s; a life is ~160 s, so ~1-2 sips/animal/life and roughly 30-60 sips per life map-wide. Global drying is a many-life arc; the feelable pressure is local (the puddle you camp goes dry).

## Goals / Non-Goals

**Goals:**
- Finite per-body water with per-species consumption, dry basins, and rain refill, implemented as pure static simulation on the existing state.
- No new dependencies, no new autoloads, no rebalancing outside `TUNING`.
- Behavior testable with seeded rng like the rest of the suite.

**Non-Goals:**
- Evaporation or any drain other than drinking.
- Regional weather, seasons, or weather tied to the census theme.
- Changing collision/`nudge_dry`/LOS geometry, or letting anything spawn inside a body that holds water.
- Rain affecting flora or `sed` directly.

## Decisions

### Decision: Water `level` is an absolute volume; capacity scales with r^2
Each body stores `level` and `cap`. `cap = waterCapCharco * (r / charcoR)^2`, so a charco = `waterCapCharco` units and a lago (r=95 vs 20) ≈ 22.6x that. Alternate: a normalized 0..1 `level` (rejected: makes per-species absolute sip costs awkward and hides the size relationship).

### Decision: Explicit per-species sip-cost table
A `waterSipBySpecies` table in `TUNING`; each drink debits that species' cost from the body. Alternate: derive from `SPECIES.radius` or `hungerMult` (rejected — user chose explicit control). Defaults: oruga 0.5, sapo 0.5, ardilla 0.8, raton 1.0, topo 1.0, halcon 1.5, zorro 1.5, lobo 2.0.

### Decision: Last drop is drinkable; debit is floored
A drink requires `level > 0`; it debits `min(cost, level)` and grants the full `sipSed`/`sipHp`. So the final partial sip is a full benefit and the body then reads dry. Alternate: scale the benefit to remaining water (rejected — extra branching for little gain).

### Decision: Dry basin keeps full radius; only the water fill shrinks
Dry = empty solid basin (option A). `r` stays the physics radius, drink edge, `nudge_dry` radius, and insect-zone radius — none of those consumers change. The rendered water fill is a smaller inner disc, `r * sqrt(level/cap)`, over the fixed shore ring; at `level == 0` it renders as a dry basin. Alternate: shrink the collision radius with level (rejected — threads a dynamic radius through collision, LOS, spawning, and insect zones and rewrites the "water holds nothing else" invariant).

### Decision: Dry gating at two choke points
`KarmaUtils.nearest_water_for` skips bodies with `level <= 0` (covers the player, Halcon landing, Zorro JEV, sapo chorus, and `wander_poi`), and `KarmaAI.ai_seek_water` skips them too (it has its own loop). No other call sites change.

### Decision: Global weather clock, refill in fixed time
`state.weather = {raining, t}` ticks in `age_world`: when `t` hits 0, flip `raining` and roll `t` from a dry or rain duration range. While raining, every body gains `cap / rainFillTime * dt` (capped at `cap`), so a rain of `>= rainFillTime` restores any body to 100% and shorter rains give a uniform partial fill. Alternates: an absolute rate (a lago would need ~450 s, effectively never refilling — rejected); binary full-or-nothing (rejected — contradicts "recover if the rain lasts long enough"). Weather resets each life; body `level` persists via `waters`.

### Decision: Rain insect burst, decayed by existing rules
On a rain start, append a batch of insects at shore rings via the existing `_spawn_water_ring`, allowed to exceed `insectMax` up to `insectMax + rainInsectBurst`. The existing `age_world` respawn only adds while below `insectMax`, so the population decays back as insects are eaten. Default burst: 12.

### Decision: Rain rendering is display-only
A translucent rain overlay plus a "Lluvia" pill on the canvas, and a raining indicator in the HUD; start/end logged through `KarmaState.add_log`. No gameplay effect beyond refill and the burst.

## Risks / Trade-offs

- **Drought death spiral** (all local bodies dry, rain sparse) → lagos are large, slowly-used reservoirs; dry spells and fill time tuned so a long rain reliably restores; revisit cadence if playtests starve.
- **Seeded-rng shifts**: adding weather draws inside `age_world` can shift downstream insect/mate/respawn rng → existing seeded tests may need updated expectations. Keep the weather roll as a single draw per phase flip to minimize churn.
- **Visual/logic mismatch**: water fill shrinks but the drink edge stays the basin rim, so a nearly-dry basin is drunk from its rim. Accepted as the cost of keeping geometry frozen (option A).
- **BREAKING specs**: `vitals-water` and `ecosystem-2d` both lose their "infinite water" guarantee; migration is captured in the delta specs.

## Migration Plan

1. Add `level`/`cap` seeding in `seed_waters`; confirm `possess_or_spawn` already preserves them (waters kept wholesale).
2. Add `TUNING` keys: `waterCapCharco`, `waterSipBySpecies`, `rainFillTime`, dry/rain duration ranges, `rainInsectBurst`.
3. Debit in `drink_water`; gate in `nearest_water_for` and `ai_seek_water`.
4. Weather tick + refill + insect burst in `age_world`.
5. Rendering in `karma_draw.gd`/`main.gd`; HUD/log feedback.
6. Tests: update any suite asserting infinite/undebited water; add suites for depletion, last drop, dry gating, rain refill, and the insect burst.

Rollback: revert the change; the only externally visible loss is the restored infinite-water behavior.

## Open Questions

- Exact tuning (dry/rain duration ranges, `rainFillTime`, `rainInsectBurst`, charco capacity) — all in `TUNING`, answerable by playtest without changing the specs or approach.
- Whether lagos should refill on a longer schedule than the uniform `rainFillTime` (kept uniform for now).
