## Why

Water (charcos and lagos) is currently walk-through for every species and renders almost identically regardless of size, so lakes neither read as terrain nor shelter anyone. Making lagos/charcos solid blue bodies that only the amphibious `sapo` can enter (extensible to a future `pato`) gives water a physical presence, gives `sapo` a risky shoreline refuge, and keeps drinking universal from the edge.

## What Changes

- Water bodies render as blue objects scaled to their radius: `charco` stays tiny, `lago` grows into a landscape anchor; the existing water emoji/label is kept on top.
- Entry rule: water is solid terrain for every species except the amphibious whitelist (`sapo` now); `halcon` flies over and ignores it. Non-swimmers stop/slide at the shore; swimmers move freely inside.
- Drinking is unchanged in reach and effect and stays available to all species from the water edge within drink range.
- Predators CAN bite across the shoreline at existing contact/kill ranges (~20px): charco interiors are never safe, lago rims are dangerous, only deep lago centers are safe. Trophic targeting is unchanged (`zorro` hunts `sapo`, `lobo` only bumps opportunistically). Water does not block line of sight.
- Exclusion rule: only water exists inside a charco/lago — food, refuges, rocks, agents, insects, seedlings, and carrion never spawn (and never mature/drop) inside water; lake-biased insects spawn in a shore ring around (not inside) lagos.

## Capabilities

### New Capabilities

- None. All behavior extends existing capabilities.

### Modified Capabilities

- `vitals-water`: water entry whitelist, drink-from-edge preserved for all, bigger lago radius, insect shore-ring (not disc), water-only interiors.
- `solid-terrain`: water joins the solid set with per-species exemption (`sapo` enters, `halcon` flies over, `topo` stays blocked); water never blocks LOS.
- `ecosystem-2d`: water render tier (blue disc scaled by `r` + kept emoji/label), area-scaled counts preserved, spawn exclusion from water interiors.

## Impact

- Affected code: `src/script/data.js` (TUNING radii/table), `src/script/utils.js` (solids/LOS), `src/script/state.js` + `src/script/game.js` (seeding/exclusion, movement resolution, insect bias), `src/script/draw.js` (water render), `src/script/ai.js` + `src/script/predators.js` (no targeting change; shore pursuit falls out of existing chase + solids).
- No new dependencies, no API changes, no save-format changes. Balance touch: `sapo` gains a positional refuge with a hittable rim; charcos remain drink-stops only.
