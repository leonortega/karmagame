## MODIFIED Requirements

### Requirement: Infinite water bodies dot the map
The system SHALL seed infinite charcos (tiny, scattered) and lagos (large landscape anchors, few) as drinkable terrain with counts scaled by world area as densities, SHALL render each as a blue body scaled to its radius with its distinct water glyph and label kept on top, and SHALL persist them across reincarnation like refuges and rocks. Only water SHALL exist inside: all other scatters SHALL avoid water interiors.

#### Scenario: Water is reachable by density
- **WHEN** the possessed agent crosses the enlarged world at its species speed
- **THEN** a drinkable charco or lago lies within a bounded travel time comparable to food proportions, because counts scale with area

#### Scenario: Lago reads as a lake, charco as a puddle
- **WHEN** a lago and a charco appear on screen together
- **THEN** the lago renders as a visibly larger blue body than the charco, each keeping its water glyph and label

#### Scenario: Nothing else spawns inside
- **WHEN** the world seeds food, refuges, rocks, or agents
- **THEN** every placed entity lands outside all water radii

### Requirement: Insects cluster at lagos
The system SHALL bias insect respawns to a shore ring around lagos (never inside the water) while keeping the existing respawn cadence (1 per 20s, max 6) and wander behavior, so lake shores visibly hold more insects for Sapo/Topo hunters.

#### Scenario: Shore respawn bias
- **WHEN** an insect respawns with a lago on the map
- **THEN** it appears in the shore ring around the lago far more often than at a uniform random point, and never inside the water

## ADDED Requirements

### Requirement: Shoreline predation without new targeting
The system SHALL let existing pursuit plus water solids produce shoreline hunting with no trophic change: a zorro SHALL chase a sapo to the nearest shore point and bite across it within existing contact/kill ranges; a lobo SHALL NOT begin hunts for sapo by water alone though contact damage still applies; water SHALL NOT break perception, and hiding/camping rules for H-refuges SHALL NOT apply to water.

#### Scenario: Zorro works the rim
- **WHEN** a zorro pursues a sapo that enters a lago
- **THEN** the zorro closes to the nearest shore point and deals contact damage whenever the sapo is within the existing reach across the shore

#### Scenario: No camp timer for water
- **WHEN** a sapo sits deep inside a lago beyond contact reach
- **THEN** the pursuer does not enter a refuge-camp state for the water; it continues by its existing wander/hunt rules
