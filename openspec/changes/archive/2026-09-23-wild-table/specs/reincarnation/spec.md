# Spec Delta

## MODIFIED Requirements

### Requirement: Reincarnation resets world and life state
The system SHALL generate a fresh world (berry bushes, apple shrubs, carrot patches, mushroom clusters, leaf-clumps, oak clumps, insects, tier-table predators, congeners, refuges, no carrion, plus carried saplings as extra berry bushes capped at +3 and consumed on use), restore full Vida for the new species, reset life timer, per-life history, adaptations, carried nut, and dug burrows, and apply carried Karma/PA on reincarnate.

#### Scenario: Fresh life with carried progression
- **WHEN** the player confirms reincarnation
- **THEN** a new life starts as the offered species with full Vida, fresh entities, zeroed timer, and carried Karma/PA values

#### Scenario: Planted saplings sprout
- **WHEN** a life ended with 2 sapling carry banked
- **THEN** the next world holds 9 berry bushes and sapling carry resets to 0
