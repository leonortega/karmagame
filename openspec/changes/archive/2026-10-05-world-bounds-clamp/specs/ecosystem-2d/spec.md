## MODIFIED Requirements

### Requirement: Bounded world with camera follow
The system SHALL confine play to a bounded 2D world larger than the 1600×1200 baseline (WORLD 3200×2400) and SHALL keep the camera centered on the possessed agent within world bounds. Food, refuge, and agent counts SHALL scale with world area as densities rather than fixed constants. Movement SHALL additionally resolve against static solids (per `solid-terrain`): refuges, rocks, and living plants push agents out with slide. Every agent SHALL stay inside the world margin each tick: AI fauna, company mates, and hunters are clamped to the same boundary as the player after all movement resolves, so no animal ever leaves the world.

#### Scenario: Movement stays in bounds
- **WHEN** the player moves toward any world edge for an extended time
- **THEN** the creature stops at the boundary and never leaves the world

#### Scenario: Movement respects solids
- **WHEN** the player or any AI walks into a tree, rock, or living plant
- **THEN** position resolves to the solid's edge and slides around it

#### Scenario: Larger world stays traversable
- **WHEN** the possessed agent crosses the enlarged world at its species speed
- **THEN** reachable food of its diet lies within a bounded travel time comparable to baseline proportions, because counts scale with area

#### Scenario: AI agents stay in bounds
- **WHEN** any AI agent, company mate, or hunter is pushed or steered past a world edge in a tick
- **THEN** its position resolves back inside the same boundary margin as the player and it never leaves the world
