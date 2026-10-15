# flora-lifecycle Specification

## Purpose
The forest is a living biome: plants fruit on clocks, eaten fruit leaves seeds that sprout into new plants, planted saplings grow into oaks, and old oaks shelter the small from ground predators. Flora has a birth, a productive life, and a slow recovery — the map can no longer only trend toward empty.
## Requirements
### Requirement: Fruiting plants regrow fruit on a clock
Every living fruiting plant SHALL regrow 1 fruit per its kind rate in `TUNING.fruitRegrowByKind` while below its fruit cap (berries 20s, carrots 25s, leaves 30s, mushrooms 30s, apples 35s, nuts 45s). A plant stripped to zero fruit SHALL revive (alive again) after one kind-rate cycle, without resetting any other state. Leaf-clumps regrow on the same table (leaves 30s) instead of a separate `leafRegrow` clock.

#### Scenario: Stripped bush recovers
- **WHEN** a berry bush has been dead (0 fruit) for 20s
- **THEN** it is alive again with 1 fruit, and continues regrowing to its cap

#### Scenario: Fruit regrow respects the cap
- **WHEN** a bush sits at 3 fruits for 3 regrow cycles
- **THEN** it still has exactly 3 fruits

#### Scenario: Kind rates differ
- **WHEN** a berry bush and an oak sit one fruit below cap for 20s
- **THEN** the bush has regrown 1 fruit and the oak has regrown none (nuts rate 45s)

#### Scenario: Leaves share the table
- **WHEN** a leaf-clump sits at 2 leaves for 30s
- **THEN** it has regrown to 3 leaves

### Requirement: Eaten fruit can sprout seedlings
Each fruit eaten from a plant (by any brain) SHALL have a `TUNING.seedSproutChance` probability to spawn a seedling of that fruit kind near the plant's position. Seedlings SHALL be capped at `TUNING.seedlingMax` alive at once. A seedling SHALL mature into a new living plant of its kind **bearing its full fruit load** (berries 3, apples 2, carrots 3, mushrooms 2, nuts 3) after `TUNING.seedlingMult` times its kind regrow rate (`fruitRegrowByKind[kind]`, mult 2.0), if the kind's flora cap (area-scaled) has room; otherwise it SHALL wait, retrying each tick. Seedlings and emptied plants renew on this same per-kind velocity: one regrow tick revives, `seedlingMult` ticks mature.

#### Scenario: Seed sprouts after eating
- **WHEN** a fruit is eaten and the sprout roll succeeds with seedlings below cap
- **THEN** a seedling of the eaten fruit's kind appears within 60px of the plant

#### Scenario: Seedling matures into a plant
- **WHEN** a berry seedling reaches 40s age (2.0 x 20s) with the kind's cap unsaturated
- **THEN** it is removed from the seedling array and a living plant of that kind spawns at the seedling's position

#### Scenario: Seedling matures productive
- **WHEN** a berry seedling reaches maturity age with the cap unsaturated
- **THEN** the new bush spawns with 3 fruits, immediately edible and regrowing on the kind clock

#### Scenario: Matured plant rolls fresh poison state
- **WHEN** a new berries plant matures from a seedling
- **THEN** it rolls its own mimic state like an initial spawn (seed source does not inherit toxicity)

#### Scenario: Apple full load stays two
- **WHEN** an apple seedling reaches maturity (2.0 x 35s) with the cap unsaturated
- **THEN** the new shrub spawns with exactly 2 apples

### Requirement: Planted saplings grow young oaks
When the Ardilla (player or AI) buries a carried nut, the deed SHALL spawn an `oak-tree` seedling at the bury position in addition to the existing karma/saplings-bank effects. The oak-tree seedling SHALL mature into a `young-oak` patch (nuts, 3 fruit) after `TUNING.seedlingMult` times the nuts regrow rate (2.0 x 45s = 90s), obeying the oak flora cap.

#### Scenario: Planting grows a tree
- **WHEN** an Ardilla buries a carried nut with the oak cap unsaturated
- **THEN** an oak-tree seedling spawns at the bury spot and matures into a nut-bearing young oak after 90s

### Requirement: Fresh worlds seed below cap for growth
New worlds SHALL seed each fruiting kind `TUNING.floraHeadroom` (2) below its flora cap, so seedlings always have room to mature into new plants during play. Scatter draws keep the old counts and only the kept prefix shrinks, preserving spawn randomness downstream.

#### Scenario: Seedling matures in a fresh world
- **WHEN** a berry seedling reaches maturity in a freshly seeded world
- **THEN** the bush count grows by one instead of waiting at a full cap

### Requirement: Eating cannot drive stock negative
`eat_patch` SHALL refuse dead or empty plants (return false with no heal, no karma, and no seed), so plant stock never drops below zero and worst-case recovery from empty is always exactly one regrow cycle.

#### Scenario: Rebiting an empty bush does nothing
- **WHEN** any brain eats from a bush already at 0 fruit
- **THEN** the bite is refused, stock stays 0, and no Vida, PA, karma, or seed changes hands

### Requirement: Last-fruit message promises recovery
Eating the last fruit SHALL log that the plant will bear fruit again (never that it dries forever), matching the regrow mechanic.

#### Scenario: Honest last-fruit text
- **WHEN** the player eats the last berry of a bush
- **THEN** the feed entry says the bush will bear fruit again alongside the −15 karma

### Requirement: Old oaks shelter from ground predators
The refuge table SHALL include `old-oak` (max size 3, no fruit, sparse spawn). Hiding in an old-oak SHALL blind ground predators (zorro, lobo, saponpc) to the hidden agent exactly as other refuges do (camp rule unchanged). The Halcón SHALL NOT be blinded by canopy: it perceives and strikes agents hidden in old-oaks.

#### Scenario: Zorro loses the hider under the canopy
- **WHEN** a chased Ratón hides in an old-oak
- **THEN** the pursuing Zorro camps the tree ~3s and then wanders off, per the standard hide rule

#### Scenario: Halcón strikes through the canopy
- **WHEN** a Ratón hides in an old-oak and a Halcón hunts it
- **THEN** the Halcón does not enter the camp state and can strike the hidden agent

### Requirement: The forest visibly ages
Rendering SHALL distinguish seedlings (tiny sprout), young oaks (mid trunk), and old oaks (large canopy) from existing plants.

#### Scenario: Silhouettes read by age
- **WHEN** a seedling, a young oak, and an old oak are on screen
- **THEN** each is recognizable by size/shape without HUD text

