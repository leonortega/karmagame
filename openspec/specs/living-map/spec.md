# living-map

## Purpose

Define the living ecosystem shared by player and CPU animals: one unified roster of agents of every species on a bigger persistent map, where the player possesses exactly one agent and can start as any species.
## Requirements
### Requirement: Unified animal roster with possessed player agent
The system SHALL represent every animal on the map (player and CPU alike) as an agent with species, position, facing, HP, and brain (PLAYER or AI), where exactly one agent is possessed by the player. The possessed agent carries judgment eligibility; every AI agent additionally carries its own `karma`, `pa`, `owned`, and `lifeLog` ledger.

- **WHEN** an AI agent interacts with flora
- **THEN** it **SHALL** plant nuts (Ardilla) that grow young oaks in the shared world, graze diet plants, and shelter per its species behavior

#### Scenario: One roster holds all animals
- **WHEN** a life is running with a mixed population
- **THEN** every visible animal is an entry in the single agents roster with a species key from the full set (oruga, sapo, raton, ardilla, topo, halcon, zorro, lobo) and a brain flag

#### Scenario: Only the possessed agent has karma and PA
- **WHEN** any karma or PA event fires (shout, plant, wasteful kill, survival tick)
- **THEN** the PLAYER-brained agent's karma/PA changes; AI agents accrue karma/PA only through their own good deeds, shouts, and purchases — never from the player's actions

#### Scenario: AI Topo digs a burrow near a predator
- **WHEN** an AI Topo agent's `digCd` is 0 and `dug` < 3
- **THEN** a `burrow-M` refuge is created at the agent's position and the agent gains +3 karma

#### Scenario: Fancy verbs stay player-only
- **WHEN** an AI agent is near a refuge, nut, or predator
- **THEN** it **SHALL** dig, groom, plant, shout, sense, carry, hide, curl, and camouflage according to its species behavior (see `ai-species-behavior`)

#### Scenario: AI Sapo camouflages from Zorro
- **WHEN** an AI Sapo agent is motionless for 2s outside a refuge
- **THEN** `camouflaged()` returns true and Zorro predators do not track the agent

#### Scenario: AI Ardilla carries and plants nuts
- **WHEN** an AI Ardilla agent finds an oak with nuts
- **THEN** it picks up a nut (`carriedNut: true`) and can plant it for +10 karma

#### Scenario: AI Ardilla plants trees in the shared world
- **WHEN** an AI Ardilla buries a carried nut
- **THEN** an oak-tree seedling spawns at the bury spot exactly as when the player plants, and both grow under the same flora caps

### Requirement: Mixed-species population composition by density
The system SHALL seed and maintain a mixed-species population scaled to world area: at least one agent of every playable grazer kind (oruga, sapo, raton, ardilla, topo), at least one airborne halcon and at least two carnivores (zorro and lobo) whenever the world area supports them, with per-species target counts defined as densities (agents per unit area).

#### Scenario: All playable grazers present
- **WHEN** a life starts
- **THEN** at least one agent of each grazer kind (oruga, sapo, raton, ardilla, topo) exists in the roster

#### Scenario: Predator presence by tier
- **WHEN** the player species is Tier 2
- **THEN** at least one zorro and one lobo agent exist; if the player is lobo, at least one zorro exists

#### Scenario: Densities scale with area
- **WHEN** the world area increases versus baseline
- **THEN** agent counts scale proportionally so per-agent food availability stays comparable

### Requirement: Shared hunger-eat-die loop for all agents
Every agent on the map (player or AI) SHALL lose Vida continuously at the same drain rate, eat only its DIET table entries with the same Vida gains (no karma, no PA for AI), and die at 0 Vida leaving a fresh carrion. AI kills obey the same contact and kill verbs as player kills.

#### Scenario: NPC grazer eats and survives
- **WHEN** an AI raton reaches a berry patch with fruit remaining
- **THEN** the patch loses one fruit and the agent gains the same Vida as a player would, with no karma or PA granted

#### Scenario: NPC starves without food
- **WHEN** an AI agent finds no food for an extended time
- **THEN** its Vida drains at the standard rate and it dies at 0, spawning carrion

#### Scenario: NPC carnivore hunts fauna
- **WHEN** an AI carnivore (zorro or lobo) perceives a smaller or equal-size agent
- **THEN** it pursues and strikes on contact, killing the victim and spawning carrion; it never targets itself

### Requirement: Player can start as any species
The start-select screen SHALL list all playable species across all tiers (oruga, sapo, raton, ardilla, topo, halcon, zorro, lobo) and the player MAY choose any of them for the first life. The first life is exempt from the judgment matrix.

#### Scenario: Start as predator
- **WHEN** the player selects Lobo or Halcon on the start screen
- **THEN** the first life begins as that species with no karma or PA thresholds evaluated

#### Scenario: Start as grazer
- **WHEN** the player selects any grazer on the start screen
- **THEN** the first life begins as that species with the normal hunger-eat-die loop

### Requirement: Persistent world across reincarnation
The world SHALL persist across lives: food patches, seedlings, young oaks, carrion, and agent roster carry over; saplings planted in the previous life convert in place as berry bushes (existing rule) and oak-tree seedlings planted in the previous life continue maturing into young oaks. The first life is exempt from the judgment matrix and comes from the start screen.

#### Scenario: World survives death
- **WHEN** a life ends and the player reincarnates
- **THEN** uneaten food, unconsumed carrion, surviving AI agents, growing seedlings, and young oaks remain in the same world

#### Scenario: First life is free
- **WHEN** the run starts
- **THEN** the player's form comes from the start-select screen, not the judgment matrix; no karma or PA is evaluated

### Requirement: Lobo form (Tier 2 apex)
The system SHALL provide the Lobo as a Tier 2 apex form, size 4, slower than the Halcón but tougher, whose diet is carrion and mates, that cannot shout, hunts tier 2 agents and zorro agents, and fears nothing.

#### Scenario: Lobo hunts the big
- **WHEN** a player-controlled Lobo uses the eat action adjacent to a tier 2 agent or zorro agent with its kill verb ready
- **THEN** the victim dies, a fresh carrion spawns at its position, and the wasteful-kill rule applies

#### Scenario: Lobo cannot shout
- **WHEN** the player is a Lobo and attempts the altruistic shout
- **THEN** no Karma/PA is granted and an informational message is shown

#### Scenario: Nothing hunts the Lobo
- **WHEN** a Lobo agent is on the map with zorro agents nearby
- **THEN** no AI agent targets the Lobo as prey; zorro agents flee from it

### Requirement: AI agent visual indicators
Every AI agent rendered on the map SHALL display a live HP bar and karma number above it. The HP bar is proportional to `agent.hp / maxHp`. The karma number is an integer, green when positive, red when negative.

#### Scenario: AI agent rendered with live indicators
- **WHEN** an AI agent is on the map
- **THEN** a small HP bar and karma number are displayed above the agent sprite
- **WHEN** the agent's karma is positive
- **THEN** the karma number is rendered in green
- **WHEN** the agent's karma is negative
- **THEN** the karma number is rendered in red

