## MODIFIED Requirements

### Requirement: Infinite charcos and lagos as drinkable terrain
The system SHALL seed infinite water bodies as terrain (not depletable patches): `charcos` (tiny, scattered count) and `lagos` (large landscape anchors, few), with counts scaled by world area as densities like food and rocks. The lago radius SHALL be visibly larger than a charco so a lago reads as a lake and a charco as a puddle. Drinking SHALL work from the water edge within drink range for every species; water SHALL persist across reincarnation like refuges and rocks. Only water SHALL exist inside a charco or lago: food, refuges, rocks, agents, insects, seedlings, and carrion SHALL never spawn, mature, or drop inside water.

#### Scenario: Charco drinks at its edge
- **WHEN** the player presses E within drink range of a charco edge
- **THEN** a drink resolves with sed plus small vida gain and the charco remains fully available

#### Scenario: Lago drinks along its shore
- **WHEN** the player presses E at any point within drink range of a lago shore
- **THEN** a drink resolves exactly as at a charco, with the larger radius allowing more approach angles

#### Scenario: Water survives death
- **WHEN** a life ends and the player reincarnates
- **THEN** all charcos and lagos remain at the same positions

#### Scenario: Water holds nothing else
- **WHEN** the world seeds or respawns food, refuges, rocks, agents, insects, seedlings, or carrion
- **THEN** no entity is placed with its center inside any charco or lago radius

### Requirement: Lagos anchor insect density
The system SHALL bias insect spawns to a shore ring around lagos so lake shores visibly hold more insects than open ground, while keeping the existing global respawn cadence and cap; insects SHALL never spawn inside water, SHALL then wander as today and remain edible for Sapo/Topo with unchanged payoffs.

#### Scenario: Lake shore buzzes
- **WHEN** insects respawn with a lago on the map
- **THEN** new insects appear biased to the shore ring around the lago far more often than at uniform random points, and never inside the water

#### Scenario: Lake insects stay edible
- **WHEN** a Sapo tongues an insect near a lago
- **THEN** the insect is consumed with the standard +10 vida/+3 PA and pest-control karma

## ADDED Requirements

### Requirement: Amphibious entry with hittable shoreline
The system SHALL allow only amphibious species (`sapo` now; a future `pato` joins by table row, no logic change) to be inside charco/lago water; every other species SHALL be stopped at the shore but SHALL still drink from the edge. A `sapo` inside water at the border or in the lake SHALL remain hittable by `zorro` or `lobo` at the existing contact/kill ranges across the shoreline; trophic targeting SHALL NOT change (`zorro` hunts `sapo`, `lobo` only damages on opportunistic contact). Water SHALL NOT block line of sight.

#### Scenario: Sapo enters, raton stops
- **WHEN** a sapo moves into a lago and a raton moves into the same lago
- **THEN** the sapo continues inside while the raton resolves to the shore edge and can still drink with E

#### Scenario: Rim is dangerous, deep is safe
- **WHEN** a sapo sits just inside the shoreline within predator contact range and a zorro stands at the edge
- **THEN** the zorro can deal contact damage across the shore with the existing hit rules

#### Scenario: Charco never hides
- **WHEN** a sapo sits inside a charco
- **THEN** a zorro at the charco edge is always within contact range, so the charco grants no safety

#### Scenario: Trophic table frozen
- **WHEN** a lobo is on the map with a sapo in the water
- **THEN** the lobo does not begin a hunt for the sapo by water alone, though contact damage still applies on touch
