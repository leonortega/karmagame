## MODIFIED Requirements

### Requirement: Bounded world with camera follow

The system SHALL confine play to a bounded 2D world larger than the 1600×1200 baseline (WORLD 3200×2400) and SHALL keep the camera centered on the possessed agent within world bounds. Food, refuge, and water counts SHALL scale with world area as densities rather than fixed constants, and agent counts SHALL come from the rolled census per `ecosystem-census` (fixed roster for the run, player as a member) instead of fixed per-species constants plus stacked company and scripted hunters. Movement SHALL additionally resolve against static solids (per `solid-terrain`): refuges, rocks, and living plants push agents out with slide. Every agent SHALL stay inside the world margin each tick: AI fauna, company mates, and hunters are clamped to the same boundary as the player after all movement resolves, so no animal ever leaves the world.

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

#### Scenario: Rolled roster replaces stacked spawns

- **WHEN** a new game starts
- **THEN** total agents equal the rolled census exactly, with no extra company pack or scripted hunter multiplication on top

### Requirement: Predators wander and chase with contact damage

The system SHALL populate the map with the rolled carnivore communities (zorro, lobo, halcon) plus a sapo pressure role covered by sapo agents, where carnivore AI hunts agents of any brain (PLAYER or AI) as well as the possessed agent by the trophic table (zorro: tiers 0-1 agents and mates; lobo: tier 2 agents, grounded halcons, and zorro agents; lobo SHALL NOT begin hunts against T0/T1 agents by water or spawn pressure alone though contact damage still applies), and sapo agents hop toward oruga agents in perception and snap at contact range. No predator SHALL hunt prey 2+ sizes smaller beyond contact-range snap (optimal foraging); all SHALL lose hidden agents and camp the refuge ~3s before wandering off, and carnivore kills of any agent SHALL spawn fresh carrion. Ground-predator perception SHALL additionally respect trunk cover (per `solid-terrain`); the Halcón is exempt. Scripted hunters beyond the rolled fauna predators SHALL NOT spawn when the rolled communities already provide that pressure, and T0 player starts cap hunters at floor and offset from prey clusters per `ecosystem-census`.

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
- **THEN** lobo agents are present per the rolled census but do not begin hunts against T0/T1 agents by pressure alone, though contact damage still applies

#### Scenario: Zorro flees Lobo

- **WHEN** a Lobo enters a Zorro NPC's perception range
- **THEN** the Zorro abandons its hunt and flees away from the Lobo

#### Scenario: Camp the hidden

- **WHEN** the player hides in a refuge while chased
- **THEN** the pursuer waits at the refuge ~3s and then returns to wandering

#### Scenario: NPC carnivore hunts fauna

- **WHEN** an AI zorro or lobo kills an AI agent of any brain
- **THEN** a fresh carrion entity spawns at the kill position

### Requirement: Congeners wander and flee when saved

The system SHALL spawn each species as one loose community per the rolled census (clustered around its food anchor with jitter inside travel range, predators offset from prey) instead of a fixed 4-congener pack plus uniform scatter, where community members wander normally and flee from predators after a successful shout.

#### Scenario: Alert saves congeners

- **WHEN** the player shouts successfully
- **THEN** congeners switch to fleeing behavior away from predators

#### Scenario: Communities start in travel reach

- **WHEN** a new game spawns a community
- **THEN** its members start clustered near their food anchor close enough that POI-travel reaches food, water, cover, or company within wander-seek range, not scattered uniformly across the world

#### Scenario: Social verbs stay castable

- **WHEN** an AI community of a social species begins the game
- **THEN** at least two congeners start within social-verb range of each other so groom, chorus, share, howl, regurg, and escort preconditions can be met
