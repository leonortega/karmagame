## MODIFIED Requirements

### Requirement: Static elements are solid to every agent
Refuge trees (old-oak, hollow-tree, thorn-bush), dug burrows, rocks, living fruiting plants (bushes, shrubs, carrot patches, mushroom clusters, oak clumps), and water bodies (charcos and lagos) SHALL block movement, except that amphibious species (`sapo`) MAY be inside water and the airborne `halcon` SHALL ignore water. Collision SHALL resolve with circular push-out so agents slide around solids instead of sticking. Dead plants (no fruit) SHALL stop being solid. Leaf clumps, insects, and carrion SHALL remain walk-through.

#### Scenario: Player cannot walk through a trunk
- **WHEN** the player moves into an old-oak trunk
- **THEN** position resolves to the circle edge and movement slides tangentially around it

#### Scenario: AI does not phase through plants
- **WHEN** an AI grazer wanders into a berry bush
- **THEN** it is pushed out of the bush's solid radius like the player

#### Scenario: Dead plants release their space
- **WHEN** a bush is stripped dead
- **THEN** agents move through its tile until it regrows

#### Scenario: Non-swimmer stops at the shore
- **WHEN** a raton, zorro, or topo moves into a lago
- **THEN** position resolves to the water edge and movement slides tangentially around it

#### Scenario: Sapo swims through
- **WHEN** a sapo moves into a charco or lago
- **THEN** no push-out applies and the sapo continues inside

#### Scenario: Halcon flies over water
- **WHEN** an airborne halcon moves across a lago
- **THEN** no push-out applies, exactly as trunks never block its sight

### Requirement: Trunks break ground-predator line of sight
Old-oak and hollow-tree trunks SHALL block perception between a ground predator (zorro, lobo, saponpc) and a target when a trunk overlaps the straight segment between them. The Halcón SHALL NOT lose targets to trunks (flies over). Rocks, plants, and water SHALL NOT block LOS.

#### Scenario: Cover behind a trunk
- **WHEN** a Ratón stands with a hollow-tree between it and a pursuing Zorro
- **THEN** the Zorro loses the target and does not hunt it while the segment stays blocked

#### Scenario: The sky ignores wood
- **WHEN** a Halcón hunts a target behind a trunk
- **THEN** perception is unchanged; only the old-oak canopy rule (existing) still applies

#### Scenario: Water never hides
- **WHEN** a sapo sits inside a lago with open water between it and a pursuing Zorro
- **THEN** the Zorro keeps perceiving the sapo; only distance, camouflage, or the existing contact rules decide the outcome
