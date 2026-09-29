# Proposal: Readable Forest & Solid Terrain

## Why

Everything on the map is a colored dot: berries, apples, nuts and mushrooms are the same circle in a different hue, animals have no faces, refuges are featureless blobs — and nothing stops anything: a Lobo walks straight through an oak, the player phases through bushes, and hunters see through solid wood. The forest we just made alive is illegible and ghostly. You cannot dodge what you cannot read, and cover means nothing when the predator's line of sight passes through a trunk.

## What Changes

- **Solid static elements**: refuge trees (old-oak, hollow-tree, thorn-bush), dug burrows, newly spawned **rocks**, and fruiting plants (bushes, shrubs, patches, clusters, oaks) block movement. Circular push-out with slide — nothing gets stuck.
- **Everyone collides**: player, fauna AI, congeners, and predators share the same solids. No more ghosts.
- **Line of sight**: trunks (old-oak, hollow-tree) break ground-predator perception — a Ratón behind a trunk is invisible to a Zorro. The Halcón always sees over the canopy. Bushes/rocks are low cover: physical only, no LOS.
- **Rocks**: new decorative-solid static element, sparse, no gameplay role beyond obstruction.
- **Legibility pass**: each food gets a distinct glyph (berry mat with red dots, apple with leaf, carrot triangle at soil level, mushroom cap+stem, nut oval, leaf cluster); all species get eyes that face movement; refuges get readable shapes (burrow mound with hole, hollow tree with knothole, thorn-bush spikes, old-oak canopy with shadow); grass tufts and small flowers break up the grid floor.

## Capabilities

### New Capabilities
- `solid-terrain`: static solids registry (radii per entity kind), circular collision response for every agent, trunk line-of-sight blocking for ground predators with the Halcón exemption, rocks.

### Modified Capabilities
- `ecosystem-2d`: "Bounded world with camera follow" — movement is no longer obstacle-free; solids push out. "Predators wander and chase with contact damage" — perception now respects trunk LOS. "Lifelike animal rendering" — upgraded to the legibility catalog (distinct food glyphs, eyes, refuge shapes, grass decor).

## Impact

- **`src/script/data.js`**: `ROCKS` spawn table + solid radius table per kind.
- **`src/script/utils.js`** (or game.js): `solidsNear`, `pushOut`, `losBlocked` helpers.
- **`src/script/state.js`**: `seedTerrain` spawns rocks + registers solids; solid radii on refuges/plants.
- **`src/script/game.js`**: push-out applied after `movePlayer` and in `updateAgents`/`updatePredators` loops.
- **`src/script/predators.js`**: `pickTarget`/`strikeAgents` perception gated by `losBlocked` (ground only).
- **`src/script/draw.js`**: glyph dispatch for foods, eyes, refuge shapes, grass/flower decor.
- **`test/terrain.test.js`**: collision + LOS tests; rendering smoke tests.
