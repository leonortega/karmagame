## REMOVED Requirements

### Requirement: Predators wander and chase with contact damage
**Reason**: Replaced by the unified animal model. The `saponpc` pressure morph, the `type`/`role`/`kind` labels, and the separate predator pass are deleted; hunting is now a per-pair property of species data.

**Migration**: See the added requirement "Animals hunt by trophic data with contact damage". T0 pressure comes from rolled halcon and zorro instead of `saponpc`; no scripted predator is added.

## ADDED Requirements

### Requirement: Animals hunt by trophic data with contact damage
The system SHALL populate the map with the rolled animal communities only (zorro, lobo, halcon, and the grazers); no scripted predator or pressure morph SHALL spawn. Every animal SHALL evaluate prey per pair from its species trophic data (diet entries, prey tiers/sizes, carrion, mates), with no `role`, `kind`, or `type` label deciding behavior. A carnivore SHALL hunt AI agents and the possessed agent by the same per-pair check, and the possessed agent SHALL fight and be hunted as any other animal of its species. Each animal SHALL run exactly one behavior step per tick, and its needs, age, and cooldowns SHALL advance exactly once in that step. No animal SHALL hunt prey 2+ sizes smaller beyond contact-range snap (optimal foraging); all SHALL lose hidden agents and camp the refuge ~3s before wandering off, and kills of any agent SHALL spawn fresh carrion. Ground-animal perception SHALL additionally respect trunk cover (per `solid-terrain`); the Halcon is exempt. T0 player starts use the rolled fauna at their counts, offset from prey clusters per `ecosystem-census`; no extra scripted predator SHALL spawn.

#### Scenario: Chase and bite
- **WHEN** a Raton agent (any brain) enters a Zorro's perception range with clear line of sight
- **THEN** the Zorro pursues, and on contact Vida drops by 28 and further hits are ignored for 1s

#### Scenario: Trunk cover breaks the chase
- **WHEN** a pursued Raton crosses behind a hollow-tree trunk
- **THEN** the Zorro loses the trail while the segment stays blocked (per `solid-terrain`)

#### Scenario: Zorro ignores distant Oruga
- **WHEN** an Oruga sits 150px from a Zorro
- **THEN** the Zorro keeps wandering (size diff 2) unless the Oruga touches it

#### Scenario: T1 player is prey
- **WHEN** a fauna Zorro stands in contact range of a T1 player that is not hidden, curled, or invulnerable
- **THEN** the player's Vida drops by 28 and further hits are ignored for 1s

#### Scenario: A fauna carnivore ages once per tick
- **WHEN** a fauna Zorro is stepped once by the world update for `dt`
- **THEN** its animal age advances by `dt` exactly once and its needs drain exactly once

#### Scenario: T0 pressure comes from rolled fauna
- **WHEN** a new game starts with the player as a T0 Oruga
- **THEN** rolled Halcones and Zorros are present at their census counts and can pressure the player by their species prey rules; no `saponpc` or other scripted pressure morph exists

#### Scenario: No scripted pressure morph
- **WHEN** any life starts or respawns
- **THEN** no animal is spawned outside the rolled census and normal respawn top-up, and no animal carries a pressure-only species or type

#### Scenario: Halcon hunts by size
- **WHEN** a Halcon perceives an animal of size 1 or 2 that is not hidden
- **THEN** it pursues and strikes using its species trophic row, including the possessed agent

#### Scenario: Lobo only threatens the big
- **WHEN** the player is a T0 or T1 form
- **THEN** lobo agents are present per the rolled census but do not begin hunts against T0/T1 agents by pressure alone, though contact damage still applies

#### Scenario: Zorro flees Lobo
- **WHEN** a Lobo enters a Zorro's perception range
- **THEN** the Zorro abandons its hunt and flees away from the Lobo

#### Scenario: Camp the hidden
- **WHEN** the player hides in a refuge while chased
- **THEN** the pursuer waits at the refuge ~3s and then returns to wandering

#### Scenario: NPC carnivore hunts fauna
- **WHEN** an AI zorro or lobo kills an AI agent of any brain
- **THEN** a fresh carrion entity spawns at the kill position
