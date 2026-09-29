# Tasks: Readable Forest & Solid Terrain

> **Status: DONE (2026-09-24).** Suite 187/0 green (baseline 170). TDD rojo→verde por tarea.
> ponytail-review: eliminado patchDots muerto (−16 líneas); el anillo de revelado por olfato
> migró a drawPatch (regla Keen nose preservada). Los tests de integración de IA usan sapo
> (no come bayas) para determinismo. Techo ponytail: la IA puede rozar troncos al deslizar
> (sin pathfinding); LOS por muestreo de 10 puntos por segmento.

## 1. Solid terrain core (TDD)

- [x] 1.1 Add TUNING solid radii (`solidRefuge`, `solidPlant`, `solidRock`) + `ROCKS` spawn table in data.js
- [x] 1.2 Add `seedTerrain` (rocks) + `state.rocks` in state.js; carry rocks across reincarnation
- [x] 1.3 Test: `collectSolids()` lists refuges (per type), living plants, rocks — not dead plants, not leaves/insects/carrion
- [x] 1.4 Test: `resolveCollisions` pushes an overlapping agent out to the solid edge
- [x] 1.5 Test: slide — agent moving tangentially keeps most of its motion around a trunk
- [x] 1.6 Implement `resolveCollisions` call in `movePlayer`, `updateAgents`, `updatePredators` (AI `aiFlee`/`aiHuntEat` covered via updateAgents)
- [x] 1.7 Test: dead bush stops blocking after stripping
- [x] 1.8 Test: rocks spawn scaled by area (baseline count + ×4 world)

## 2. Trunk line of sight (TDD)

- [x] 2.1 Test: `losBlocked` true when a trunk overlaps the segment, false for rocks/plants/empty field
- [x] 2.2 Test: halcón never blocked (returns false regardless of geometry)
- [x] 2.3 Test: `pickTarget` mate-stalk ignores a victim behind a trunk (zorro), still hunts with clear LOS
- [x] 2.4 Implement `losBlocked` (segment sampling) + gate `pickTarget` mate hunt and `strikeAgents` victim scan (ground predators only)
- [x] 2.5 Test: lobo losing a zorro behind a trunk (same rule, second species)

## 3. Legibility rendering (TDD smoke + visual)

- [x] 3.1 Test: `drawPatch` renders without throwing for every kind (alive, dead, mimic, toxic states)
- [x] 3.2 Implement per-kind glyph dispatch (berries mat, apple canopy, carrot soil, mushroom cap+stem, nut trunk, leaf fan; dead = grey remnant)
- [x] 3.3 Test: eyes render for all species (drawSpecies smoke with each form)
- [x] 3.4 Implement facing eyes inside drawSpecies
- [x] 3.5 Implement refuge glyphs (burrow mound+hole, hollow-tree knothole, thorn spikes, old-oak canopy+shadow) + rock glyph
- [x] 3.6 Implement deterministic grass/flower decor (`tileHash`), near-camera only
- [x] 3.7 Test: render completes a full frame with rocks + decor present

## 4. Verification gate

- [x] 4.1 `node --check` all touched files
- [x] 4.2 Full suite green (`node --test test/*.test.js`)
- [x] 4.3 No duplicate `function` names across `src/script/`
- [x] 4.4 `src/index.html` refs resolve
- [x] 4.5 `openspec validate readable-forest-solid-terrain` clean
