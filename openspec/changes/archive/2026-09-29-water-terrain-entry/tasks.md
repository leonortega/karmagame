## 1. Data and entry table

- [x] 1.1 Add amphibious entry table (`sapo` in, all others out) plus bigger `lagoR` tuning with `charcoR` kept tiny (specs: vitals-water amphibious entry; design: entry as data).
- [x] 1.2 Add test: whitelist contains `sapo` only and lago radius reads visibly larger than charco radius.

## 2. Water as selective solid

- [x] 2.1 Include water bodies in solids with per-species exemption (`sapo` inside, airborne `halcon` over, `topo` blocked) reusing the push-out/slide path (specs: solid-terrain static elements; design: `skipWater` pattern).
- [x] 2.2 Add test: non-swimmer resolves to the shore edge with slide; `sapo` continues inside; `halcon` ignores water.
- [x] 2.3 Confirm water never blocks predator LOS and combat math is untouched — rim bite, charco unsafe, deep-lago safe fall out of existing reach (specs: vitals-water shoreline, solid-terrain LOS).

## 3. Seeding, exclusion, and insects

- [x] 3.1 Seed waters before other scatters and keep food, refuges, rocks, agents, seedlings, and carrion out of water interiors (specs: vitals-water water-only, ecosystem-2d spawn exclusion; design: `insideWater` gate).
- [x] 3.2 Rework lake insect bias to a shore ring around (never inside) the lago, keeping cadence/cap/wander/payoffs (specs: vitals-water insect ring, ecosystem-2d shore bias).
- [x] 3.3 Add test: seeded/respawned entities never land inside water; biased insects land in the shore ring.

## 4. Rendering

- [x] 4.1 Render each water body as a blue disc scaled to its radius with the existing water glyph and label kept on top; lago reads as lake, charco as puddle (specs: ecosystem-2d water bodies).
- [x] 4.2 Add test or harness check: water draw scales with `r` and keeps glyph/label per kind.

## 5. Verification gate

- [x] 5.1 Run `node --check` on touched files, full `node --test` suite green, no duplicate `function` names across `src/script/`, and `src/index.html` refs resolve.
- [x] 5.2 Playtest: drink-from-edge for all species, `sapo` rim risk vs deep safety vs `zorro`, `lobo` contact-only, thirsty AI stabilizing at shores.
