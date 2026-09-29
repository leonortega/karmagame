# Tasks: Forest Flora Lifecycle

> **Status: DONE (2026-09-24).** Suite 170/0 green (baseline 148). Implementado con TDD (rojo→verde
> por tarea). ponytail-review aplicado: leaves plegadas a regrowFruit (rate param), seedFood derivado
> de floraCap (una sola fuente de densidades, −10 líneas netas). Nota: dropSeed('oak-tree') es
> plantado deliberado sin azar; brotes de fruta usan seedSproutChance. oakTreeCap: 6 (tope extra
> de robles jóvenes sobre floraCap('nuts')).

## 1. Regrow clocks (TDD)

- [x] 1.1 Add `fruitRegrow: 90` to TUNING; give every `mkPatch` a `regrowT: 0` default
- [x] 1.2 Test: stripped bush (alive=false) revives with 1 fruit after `fruitRegrow` via `ageWorld`
- [x] 1.3 Test: bush at fruit cap does not exceed cap over multiple cycles
- [x] 1.4 Implement flora regrow in `ageWorld` for bushes/shrubs/patches/clusters/oaks (leaves keep `leafRegrow`)
- [x] 1.5 Keep `eatLastFruit` karma rule intact; verify existing eat tests still green
- [x] 1.6 Update `world.test.js`/`eat.test.js` assertions that assumed permanent death

## 2. Seedlings from eaten fruit (TDD)

- [x] 2.1 Add TUNING: `seedSproutChance: 0.35`, `seedlingMaturity: 75`, `seedlingMax: 10`, per-kind flora caps
- [x] 2.2 Add `state.seedlings = []` in `seedFood` + carried over in `possessOrSpawn`
- [x] 2.3 Test: eating a fruit rolls sprout → seedling appears near plant (force chance=1)
- [x] 2.4 Test: seedlings below cap enforced (chance=1, feed many eats, cap holds)
- [x] 2.5 Test: seedling matures into living plant of its kind at 1 fruit after `seedlingMaturity`
- [x] 2.6 Test: maturation respects per-kind flora cap (waits, retries)
- [x] 2.7 Test: matured berries plant rolls its own mimic state
- [x] 2.8 Implement seed drop in `eatPatch` (covers sustainable/last-fruit/mimic paths) + maturation in `ageWorld`
- [x] 2.9 Test: AI eater also sows seeds (forAgent path)

## 3. Planted saplings → young oaks (TDD)

- [x] 3.1 Test: player `carryAction` bury spawns `oak-tree` seedling at bury position (+ existing karma/bank asserts stay green)
- [x] 3.2 Test: `oak-tree` seedling matures into `young-oak` patch (nuts, 3) under oak cap
- [x] 3.3 Implement in `carryAction` + `ageWorld` maturation branch
- [x] 3.4 Test: AI `aiArdilla` planting spawns the same oak-tree seedling
- [x] 3.5 Keep `state.saplings` cross-life banking semantics unchanged (verify state tests green)

## 4. Old-oak refuges (TDD)

- [x] 4.1 Add `{ type:'old-oak', maxSize:3, count:2 }` to REFUGES; spawn in `seedCompany`
- [x] 4.2 Test: `refugeFits` accepts size ≤3, rejects size 4 (lobo)
- [x] 4.3 Test: hidden-in-old-oak blocks ground-predator targeting (zorro camps, per existing hide rule)
- [x] 4.4 Test: Halcón ignores old-oak cover — no camp state, can strike hidden agent
- [x] 4.5 Implement halcón canopy exemption in `pickTarget`/`strikeAgents` path
- [x] 4.6 Test: old-oak renders as large canopy distinct from other refuges

## 5. Rendering

- [x] 5.1 Draw seedlings (tiny sprout), young oaks (mid trunk) in `draw.js` render loops
- [x] 5.2 Old-oak canopy visual distinct from hollow-tree
- [x] 5.3 Test: render completes with seedlings/young oaks/old oaks present (no-throw)

## 6. Verification gate

- [x] 6.1 `node --check` all touched files
- [x] 6.2 Full suite green (`node --test test/*.test.js`)
- [x] 6.3 No duplicate `function` names across `src/script/`
- [x] 6.4 `src/index.html` refs resolve
- [x] 6.5 `openspec validate forest-flora-lifecycle` clean (warnings tolerated, no errors)
