# Spec Delta: flora-lifecycle

## Purpose

The forest is a living biome: plants fruit on clocks, eaten fruit leaves seeds that sprout into new plants, planted saplings grow into oaks, and old oaks shelter the small from ground predators. Flora has a birth, a productive life, and a slow recovery — the map can no longer only trend toward empty.

## ADDED Requirements

### Requirement: Fruiting plants regrow fruit on a clock
Every living fruiting plant SHALL regrow 1 fruit per `TUNING.fruitRegrow` seconds while below its fruit cap. A plant stripped to zero fruit SHALL revive (alive again) after the same regrow cycle, without resetting any other state. Leaf-clumps keep their existing faster regrow (`TUNING.leafRegrow`).

#### Scenario: Stripped bush recovers
- **WHEN** a bush has been dead (0 fruit) for `fruitRegrow` seconds
- **THEN** it is alive again with 1 fruit, and continues regrowing to its cap

#### Scenario: Fruit regrow respects the cap
- **WHEN** a bush sits at 3 fruits for 3 regrow cycles
- **THEN** it still has exactly 3 fruits

### Requirement: Eaten fruit can sprout seedlings
Each fruit eaten from a plant (by any brain) SHALL have a `TUNING.seedSproutChance` probability to spawn a seedling of that fruit kind near the plant's position. Seedlings SHALL be capped at `TUNING.seedlingMax` alive at once. A seedling SHALL mature into a new living plant of its kind (1 fruit) after `TUNING.seedlingMaturity` seconds, if the kind's flora cap (area-scaled) has room; otherwise it SHALL wait, retrying each tick.

#### Scenario: Seed sprouts after eating
- **WHEN** a fruit is eaten and the sprout roll succeeds with seedlings below cap
- **THEN** a seedling of the eaten fruit's kind appears within 60px of the plant

#### Scenario: Seedling matures into a plant
- **WHEN** a seedling reaches `seedlingMaturity` age with the kind's cap unsaturated
- **THEN** it is removed from the seedling array and a living plant of that kind spawns at the seedling's position

#### Scenario: Matured plant rolls fresh poison state
- **WHEN** a new berries plant matures from a seedling
- **THEN** it rolls its own mimic state like an initial spawn (seed source does not inherit toxicity)

### Requirement: Planted saplings grow young oaks
When the Ardilla (player or AI) buries a carried nut, the deed SHALL spawn an `oak-tree` seedling at the bury position in addition to the existing karma/saplings-bank effects. The oak-tree seedling SHALL mature into a `young-oak` patch (nuts, 3 fruit) obeying the oak flora cap.

#### Scenario: Planting grows a tree
- **WHEN** an Ardilla buries a carried nut with the oak cap unsaturated
- **THEN** an oak-tree seedling spawns at the bury spot and later matures into a nut-bearing young oak

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
