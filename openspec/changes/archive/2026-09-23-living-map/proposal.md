# Proposal

## Why

The map feels empty and the animals feel staged: one player plus 4 clones of itself plus 2 hunters on a small fixed arena, always starting as Raton. The request is a living ecosystem — a bigger map populated by every animal kind where the player possesses one of them, with no CPU/player separation.

## What Changes

- Bigger world: grow WORLD beyond 1600x1200 and convert food/refuge/predator counts from fixed constants to density-based composition so the map stays balanced at larger sizes.
- Unified animal roster: replace the three castes (player / mates / predators) with a single agents array; every agent has a species, position, HP/hunger, and a brain (PLAYER or AI). The player is the possessed agent; only it carries karma, PA, shop, and judgment.
- All species present: seed NPC agents of every SPECIES kind (oruga, sapo, raton, ardilla, topo, halcon, zorro) plus lobo promoted to a full species; reuse lifelike art for all.
- Shared eat/die loop: NPC agents run hunger, eat their DIET foods, and die; NPC carnivore kills spawn carrion via the existing carrion pipeline so kills feed scavengers (including the player).
- Start as any animal: pre-run select screen offering all playable species (predator or not); first life starts with 0 karma / 0 PA as the chosen form.
- Persistent world across deaths: death + judgment re-possesses into the SAME world (fresh or newborn agent) instead of regenerating everything; food eaten stays eaten, carrion ages on.
- Fancy verbs (dig, groom, plant, shout, sense, hide) stay player-only in this change; NPC AI is wander + graze + flee + hunt/strike.

## Capabilities

### New Capabilities
- `living-map`: unified agent roster, population composition, start-as-any select, persistent world across lives.

### Modified Capabilities
- `ecosystem-2d`: bounded world size/density, spawn tables, NPC-vs-NPC hunting and carrion, persistent (non-reset) world.
- `karma-core`: lobo becomes a full species with diet/verbs; NPC shared hunger/eat/die loop; player-only karma/PA/verbs clarified.
- `reincarnation`: first-life free form choice; re-possess into the persistent world instead of fresh-world regen; judgment matrix still gates later T2 ascension.

## Impact

- `src/script/data.js`: WORLD size, SPECIES (lobo entry), composition/density tables replacing fixed counts and TIER_SPAWNS.
- `src/script/state.js`: agents array, seeding of mixed population, persistent-world reincarnate path, start-select entry.
- `src/script/eat.js`, `src/script/predators.js`, `src/script/utils.js`: un-globalize verbs (`agent` param), NPC graze/flee/hunt brains, agent-targeted nearest/predation.
- `src/script/draw.js`, `src/script/hud.js`, `src/index.html`: render all agents by species, HUD follows possessed agent, start-select UI.
- `test/`: harness stubs multi-agent state; new tests for composition, shared loop, start-select, persistence.
