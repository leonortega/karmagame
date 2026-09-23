# Spec Delta

## MODIFIED Requirements

### Requirement: Bounded world with camera follow
The system SHALL confine play to a bounded 2D world larger than the 1600x1200 baseline with obstacles-free movement and SHALL keep the camera centered on the possessed agent within world bounds. Food, refuge, and agent counts SHALL scale with world area as densities rather than fixed constants, keeping per-agent food availability and travel-to-food time within baseline proportions.

#### Scenario: Movement stays in bounds
- **WHEN** the possessed agent moves toward any world edge for an extended time
- **THEN** the creature stops at the boundary and never leaves the world

#### Scenario: Larger world stays traversable
- **WHEN** the possessed agent crosses the enlarged world at its species speed
- **THEN** reachable food of its diet lies within a bounded travel time comparable to baseline proportions, because counts scale with area

### Requirement: Predators wander and chase with contact damage
The system SHALL populate the map with carnivore agents (zorro, lobo) plus a sapo-NPC pressure role covered by sapo agents, where carnivore AI hunts agents of any brain (PLAYER or AI) as well as the possessed agent by the trophic table (zorro: tiers 0-1 agents and mates; lobo: tier 2 agents, grounded halcons, and zorro agents), and sapo agents hop toward oruga agents in perception and snap at contact range. No predator SHALL hunt prey 2+ sizes smaller beyond contact-range snap (optimal foraging); all SHALL lose hidden agents and camp the refuge ~3s before wandering off, and carnivore kills of any agent SHALL spawn fresh carrion.

#### Scenario: Chase and bite
- **WHEN** a Ratón agent (any brain) enters a Zorro's perception range
- **THEN** the Zorro pursues, and on contact the victim's Vida drops by 28 and further hits are ignored for 1s

#### Scenario: Zorro ignores distant Oruga
- **WHEN** an Oruga agent sits 150px from a Zorro
- **THEN** the Zorro keeps wandering (size diff 2) unless the Oruga touches it

#### Scenario: Sapo-NPC pressures T0
- **WHEN** an Oruga agent is T0 with a Sapo agent on the map
- **THEN** the Sapo agent hops toward it in perception range

#### Scenario: Zorro flees Lobo
- **WHEN** a Lobo enters a Zorro agent's perception range
- **THEN** the Zorro abandons its hunt and flees away from the Lobo

#### Scenario: Lobo only threatens the big
- **WHEN** tier 2 agents or zorro agents are on the map
- **THEN** the Lobo hunts them, and tier 0-1 agents are ignored except as contact snap

#### Scenario: Camp the hidden
- **WHEN** a hunted agent hides in a refuge while chased
- **THEN** the pursuer waits at the refuge ~3s and then returns to wandering

#### Scenario: Kills feed scavengers
- **WHEN** a carnivore agent kills any agent
- **THEN** a fresh carrion entity spawns at the kill position

### Requirement: Congeners wander and flee when saved
The system SHALL spawn same-species group agents for the possessed agent's species that wander normally and flee from predators after a successful shout. On the mixed-species map these group agents are a subset of the unified roster (AI agents sharing the possessed agent's species), not clones spawned separately.

#### Scenario: Alert saves congeners
- **WHEN** the possessed agent shouts successfully
- **THEN** same-species AI agents switch to fleeing behavior away from predators

#### Scenario: Mixed map keeps company
- **WHEN** the possessed agent is any species on the populated map
- **THEN** at least one same-species AI agent exists nearby at life start per the composition floor
