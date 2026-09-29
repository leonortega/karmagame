# Spec Delta: flora-lifecycle

## Purpose

New plants arrive ready to feed: seedlings mature with a full fruit load and the fruiting clock doubles its pace, so the forest out-produces consumption and the new growth visibly bears fruit.

## MODIFIED Requirements

### Requirement: Eaten fruit can sprout seedlings
Each fruit eaten from a plant (by any brain) SHALL have a `TUNING.seedSproutChance` probability to spawn a seedling of that fruit kind near the plant's position. Seedlings SHALL be capped at `TUNING.seedlingMax` alive at once. A seedling SHALL mature into a new living plant of its kind **bearing its full fruit load** (berries 3, apples 2, carrots 3, mushrooms 2, nuts 3) after `TUNING.seedlingMaturity` seconds, if the kind's flora cap (area-scaled) has room; otherwise it SHALL wait, retrying each tick.

#### Scenario: Seed sprouts after eating
- **WHEN** a fruit is eaten and the sprout roll succeeds with seedlings below cap
- **THEN** a seedling of the eaten fruit's kind appears within 60px of the plant

#### Scenario: Seedling matures into a plant
- **WHEN** a seedling reaches `seedlingMaturity` age with the kind's cap unsaturated
- **THEN** it is removed from the seedling array and a living plant of that kind spawns at the seedling's position

#### Scenario: Seedling matures productive
- **WHEN** a berry seedling reaches `seedlingMaturity` age with the cap unsaturated
- **THEN** the new bush spawns with 3 fruits, immediately edible and regrowing on the clock

#### Scenario: Matured plant rolls fresh poison state
- **WHEN** a new berries plant matures from a seedling
- **THEN** it rolls its own mimic state like an initial spawn (seed source does not inherit toxicity)

### Requirement: Fruiting plants regrow fruit on a clock
Every living fruiting plant SHALL regrow 1 fruit per `TUNING.fruitRegrow` seconds (45s) while below its fruit cap. A plant stripped to zero fruit SHALL revive (alive again) after the same regrow cycle, without resetting any other state. Leaf-clumps keep their existing faster regrow (`TUNING.leafRegrow`).

#### Scenario: Stripped bush recovers
- **WHEN** a bush has been dead (0 fruit) for `fruitRegrow` seconds
- **THEN** it is alive again with 1 fruit, and continues regrowing to its cap

#### Scenario: Fruit regrow respects the cap
- **WHEN** a bush sits at 3 fruits for 3 regrow cycles
- **THEN** it still has exactly 3 fruits
