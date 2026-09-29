# Spec Delta: ecosystem-2d

## Purpose

The world gains physics and legibility: movement is no longer obstacle-free, predator perception respects trunk cover, and the rendering catalog upgrades from colored dots to distinct glyphs.

## MODIFIED Requirements

### Requirement: Bounded world with camera follow
The system SHALL confine play to a bounded 2D world larger than the 1600×1200 baseline (WORLD 3200×2400) and SHALL keep the camera centered on the possessed agent within world bounds. Food, refuge, and agent counts SHALL scale with world area as densities rather than fixed constants. Movement SHALL additionally resolve against static solids (per `solid-terrain`): refuges, rocks, and living plants push agents out with slide.

#### Scenario: Movement stays in bounds
- **WHEN** the player moves toward any world edge for an extended time
- **THEN** the creature stops at the boundary and never leaves the world

#### Scenario: Movement respects solids
- **WHEN** the player or any AI walks into a tree, rock, or living plant
- **THEN** position resolves to the solid's edge and slides around it

#### Scenario: Larger world stays traversable
- **WHEN** the possessed agent crosses the enlarged world at its species speed
- **THEN** reachable food of its diet lies within a bounded travel time comparable to baseline proportions, because counts scale with area

### Requirement: Predators wander and chase with contact damage
The system SHALL populate the map with carnivore agents (zorro, lobo) plus a sapo-NPC pressure role covered by sapo agents, where carnivore AI hunts agents of any brain (PLAYER or AI) as well as the possessed agent by the trophic table (zorro: tiers 0-1 agents and mates; lobo: tier 2 agents, grounded halcons, and zorro agents), and sapo agents hop toward oruga agents in perception and snap at contact range. No predator SHALL hunt prey 2+ sizes smaller beyond contact-range snap (optimal foraging); all SHALL lose hidden agents and camp the refuge ~3s before wandering off, and carnivore kills of any agent SHALL spawn fresh carrion. Ground-predator perception SHALL additionally respect trunk cover (per `solid-terrain`); the Halcón is exempt.

#### Scenario: Chase and bite
- **WHEN** a Ratón agent (any brain) enters a Zorro's perception range with clear line of sight
- **THEN** the Zorro pursues, and on contact Vida drops by 28 and further hits are ignored for 1s

#### Scenario: Trunk cover breaks the chase
- **WHEN** a pursued Ratón crosses behind a hollow-tree trunk
- **THEN** the Zorro loses the trail while the segment stays blocked (per `solid-terrain`)

#### Scenario: Zorro ignores distant Oruga
- **WHEN** an Oruga sits 150px from a Zorro
- **THEN** the Zorro keeps wandering (size diff 2) unless the Oruga touches it

#### Scenario: Sapo-NPC pressures T0
- **WHEN** an Oruga player is T0 with a Sapo-NPC on the map
- **THEN** the Sapo-NPC hops toward it in perception range

#### Scenario: Lobo only threatens the big
- **WHEN** the player is a T0 or T1 form
- **THEN** no Lobo is on the map

#### Scenario: Zorro flees Lobo
- **WHEN** a Lobo enters a Zorro NPC's perception range
- **THEN** the Zorro abandons its hunt and flees away from the Lobo

#### Scenario: Camp the hidden
- **WHEN** the player hides in a refuge while chased
- **THEN** the pursuer waits at the refuge ~3s and then returns to wandering

#### Scenario: NPC carnivore hunts fauna
- **WHEN** an AI zorro or lobo kills an AI agent of any brain
- **THEN** a fresh carrion entity spawns at the kill position

### Requirement: Lifelike animal rendering
The system SHALL draw each form as a distinct lifelike shape with facing (features rotate toward movement, eyes included) and motion (2-frame wiggle via time): Oruga 4 rippling segments, Sapo wide ellipse + throat pulse, Ratón circle + ears + tail line, Ardilla circle + big tail arc, Topo dark ellipse + snout dot, Halcón twin flapping triangles, Zorro circle + snout triangle + brush tail. Predator NPCs SHALL reuse their species draw with red outline and scale. Foods SHALL render as distinct per-kind glyphs (mats with fruit dots, canopy with apples, soil carrots, cap+stem mushrooms, trunk with nuts, leaf fans — per `solid-terrain`); refuge shapes SHALL read as mound+hole, trunk+knothole, spiky bush, and old-oak canopy; the ground SHALL show deterministic grass tufts and flowers.

#### Scenario: Silhouettes differ
- **WHEN** all seven forms stand side by side
- **THEN** each is recognizable by shape without reading the HUD

#### Scenario: The map reads at a glance
- **WHEN** any gameplay moment is frozen
- **THEN** foods, refuges, rocks, and animals are identifiable by silhouette, not only by color
