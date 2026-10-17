## 1. Tuning and data model

- [x] 1.1 Add `TUNING` keys: `waterCapCharco`, `waterSipBySpecies` (oruga 0.5, sapo 0.5, ardilla 0.8, raton 1.0, topo 1.0, halcon 1.5, zorro 1.5, lobo 2.0), `rainFillTime`, dry/rain duration ranges, `rainInsectBurst`; add gdUnit4 test asserting the table covers every species key.
- [x] 1.2 Seed `level` and `cap` on every body in `KarmaState.seed_waters` (cap = `waterCapCharco * (r/charcoR)^2`); test that a charco and a lago get proportional capacities and both start full.
- [x] 1.3 Test that `possess_or_spawn` keeps each body's `level`/`cap` across reincarnation.

## 2. Depletion

- [x] 2.1 Add a `water_sip_cost_for(species)` helper (single source for the table) with a test.
- [x] 2.2 Debit the drunk body in `KarmaEat.drink_water` by the drinker's sip cost; test that a drink lowers `level` by exactly that cost.
- [x] 2.3 Test the costlier-drinker rule: two species with different costs empty identical fresh bodies in the expected number of drinks.
- [x] 2.4 Test the last drop: a body with `level < cost` still grants the full `sipSed`/`sipHp` and ends at level 0.
- [x] 2.5 Test that a level never goes negative after any drink.

## 3. Dry gating

- [x] 3.1 Make `KarmaUtils.nearest_water_for` skip bodies with `level <= 0`; test that a dry body is not returned even when nearest.
- [x] 3.2 Test that a player drink resolves only against a body with water (dry-only-in-range → no drink, no sed/vida gain).
- [x] 3.3 Make `KarmaAI.ai_seek_water` skip dry bodies; test that a thirsty AI ignores a dry body and targets a wet one.

## 4. Rain cycle

- [x] 4.1 Add `state.weather` (`raining`, `t`) and tick it in `age_world`; test that a fresh state is not raining and that a dry spell's timer flip starts a rain of a rolled duration.
- [x] 4.2 Test that a rain ends when its duration elapses and the next dry spell begins.
- [x] 4.3 Implement rain refill (`level += cap / rainFillTime * dt`, capped at `cap`); test that a long rain restores a body to full, a short one leaves it partial, and full never overfills.
- [x] 4.4 Test that a dry body refilled by rain becomes drinkable again.
- [x] 4.5 Implement the rain insect burst via `_spawn_water_ring` on rain start, allowed up to `insectMax + rainInsectBurst`; test the burst count, that no insect lands inside water, and that the population decays back toward `insectMax` via existing respawn.

## 5. Rendering and feedback

- [x] 5.1 Add a `KarmaDraw` lookup for the water fill radius (`r * sqrt(level/cap)`) and a dry-basin color; test the lookup returns a smaller fill as level drops and none at zero.
- [x] 5.2 Render the inner water fill over the fixed shore ring in `main.gd`, with a dry basin at `level == 0`; test/verify the render path compiles and reads by level.
- [x] 5.3 Add a rain visual on the canvas and a raining indicator in the HUD; log rain start/end via `KarmaState.add_log`.

## 6. Verification

- [x] 6.1 Update any existing test suite that assumes infinite or undebited water, keeping every remaining test green.
- [x] 6.2 Run the full gdUnit4 suite green and confirm no duplicate `class_name`/`func` collisions.
- [x] 6.3 Run the `ponytail-review` pass over the diff and resolve or explicitly defer each finding.
