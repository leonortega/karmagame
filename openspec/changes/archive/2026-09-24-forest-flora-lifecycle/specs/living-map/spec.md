# Spec Delta: living-map

## Purpose

The persistent world now carries a living forest across lives: seedlings, young oaks, and planted trees persist like bushes do, and the AI Ardilla's planting deed grows real trees on the map.

## MODIFIED Requirements

### Requirement: Persistent world across reincarnation
The world SHALL persist across lives: food patches, seedlings, young oaks, carrion, and agent roster carry over; saplings planted in the previous life convert in place as berry bushes (existing rule) and oak-tree seedlings planted in the previous life continue maturing into young oaks. The first life is exempt from the judgment matrix and comes from the start screen.

#### Scenario: World survives death
- **WHEN** a life ends and the player reincarnates
- **THEN** uneaten food, unconsumed carrion, surviving AI agents, growing seedlings, and young oaks remain in the same world

#### Scenario: First life is free
- **WHEN** the run starts
- **THEN** the player's form comes from the start-select screen, not the judgment matrix; no karma or PA is evaluated

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
