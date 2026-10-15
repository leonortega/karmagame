## Purpose

Computes a different but always viable starting animal census for every game, so each run feels like a different environment without ever rolling an unplayable or socially dead map.

## ADDED Requirements

### Requirement: Rolled census stays within per-species floor and cap

The system SHALL compute the starting census per game by rolling each species count between its floor (social minimum that keeps verbs usable after 1-2 deaths) and its cap (diet-channel and space ceiling), around these baselines: oruga 8 (floor 4), sapo 4 (floor 3), raton 5 (floor 4), ardilla 5 (floor 4), topo 4 (floor 3), halcon 2 (floor 2), zorro 3 (floor 2), lobo 2 (floor 2). The rolled total includes the player as one member of their species; the system SHALL NOT spawn extra company or hunter bodies on top of the rolled roster.

#### Scenario: Counts vary between games

- **WHEN** two new games start with the same world size
- **THEN** their censuses are usually not identical, and every species count lies within its floor-cap range

#### Scenario: Player is a member not an addition

- **WHEN** a new game starts with the drawn species
- **THEN** the map holds exactly the rolled count for that species including the possessed agent, with the remainder as AI agents

#### Scenario: Lonely species never roll

- **WHEN** any census roll completes
- **THEN** no social species (raton, ardilla, topo, sapo, lobo) holds fewer than its floor, even on lean rolls

### Requirement: Diet channels gate the roll

The system SHALL reject or clamp any roll whose food demand exceeds diet-channel supply at area scale: leaf demand (leaf-eaters at ~1 leaf/min each) SHALL fit within leaf regrow throughput, insect demand (sapo at ~1 insect/min each plus topo insect share) SHALL fit within insect respawn throughput with topo flexing to carrots/nuts first, and fruit/nut demand SHALL fit within fruit regrow throughput. Sapo-heavy rolls SHALL force topo-light insect shares.

#### Scenario: Insect bottleneck clamps sapo

- **WHEN** a roll would demand more insects per minute than respawn sustains
- **THEN** the census is clamped (fewer sapos, or topo share shifted to carrots/nuts) before spawn

#### Scenario: Leaves cover the oruga base

- **WHEN** the oruga roll is at its baseline of 8
- **THEN** leaf demand stays within leaf regrow throughput at area scale

### Requirement: Prey base covers hunter mouths

The system SHALL hold the invariant that edible prey (oruga, sapo, raton, ardilla, topo) outnumber active hunters (zorro, lobo, halcon, sapo-pressure agents) by at least 3 to 1 after every roll, with orugas as the designated feeder surplus hunted by all predators.

#### Scenario: Lean rolls stay huntable

- **WHEN** a lean roll completes
- **THEN** the prey-to-hunter ratio is still at least 3:1 and at least 4 orugas are present

### Requirement: Themes vary the environment within guardrails

The system SHALL pick one theme per game (oruga bloom, rodent year, wet year, lean year, or balanced) that shifts rolls toward its favored species, then apply gentle jitter (+/-1) and re-enforce floors, caps, diet gates, and the prey-hunter invariant. The system SHALL write the theme as a one-line birth-log entry naming the year (for example naming a rodent year).

#### Scenario: Themed years read differently

- **WHEN** a wet year rolls
- **THEN** sapo counts skew high near lagos within cap while floors and the prey-hunter invariant still hold, and the birth log names the wet year

#### Scenario: Balanced years stay near baseline

- **WHEN** a balanced roll completes
- **THEN** every species sits within 1 of its baseline

### Requirement: T0 draws soften early predation

The system SHALL soften early predation when the drawn player species is tier 0: scripted hunters start at their floor (never above), spawn offset from prey clusters, and lobo agents SHALL NOT begin hunts against T0/T1 agents by water or spawn pressure alone (contact damage still applies per the trophic table).

#### Scenario: Oruga start is tense but survivable

- **WHEN** a new game starts with the player as oruga
- **THEN** hunters begin at floor counts, offset from the oruga cluster, and no extra scripted hunter pack spawns on top of the rolled fauna predators
