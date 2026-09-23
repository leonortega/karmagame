# Spec Delta

## Purpose

Define the living ecosystem shared by player and CPU animals: one unified roster of agents of every species on a bigger persistent map, where the player possesses exactly one agent and can start as any species.

## ADDED Requirements

### Requirement: Unified animal roster with possessed player agent
The system SHALL represent every animal on the map (player and CPU alike) as an agent with species, position, facing, HP, and brain (PLAYER or AI), where exactly one agent is possessed by the player and only the possessed agent carries karma, PA, shop adaptations, and judgment eligibility.

#### Scenario: One roster holds all animals
- **WHEN** a life is running with a mixed population
- **THEN** every visible animal is an entry in the single agents roster with a species key from the full set (oruga, sapo, raton, ardilla, topo, halcon, zorro, lobo) and a brain flag

#### Scenario: Only the possessed agent has karma and PA
- **WHEN** any karma or PA event fires (shout, plant, wasteful kill, survival tick)
- **THEN** only the PLAYER-brained agent's karma/PA changes; AI agents never accrue karma or PA

#### Scenario: Fancy verbs stay player-only
- **WHEN** an AI agent is near a refuge, nut, or predator
- **THEN** it never digs, grooms, plants, shouts, senses, carries, hides via H, or shops; it uses only wander, graze, flee, and hunt/strike behaviors

### Requirement: Mixed-species population composition by density
The system SHALL seed and maintain a mixed-species population scaled to world area: at least one agent of every playable grazer kind (oruga, sapo, raton, ardilla, topo), at least one airborne halcon and at least two carnivores (zorro and lobo) whenever the world area supports them, with per-species target counts defined as densities (agents per unit area) rather than fixed constants.

#### Scenario: All kinds present on a fresh large map
- **WHEN** a new persistent world generates at the new larger size
- **THEN** the roster contains at least one oruga, sapo, raton, ardilla, topo, halcon, zorro, and lobo agent

#### Scenario: Population scales with area
- **WHEN** the world area doubles relative to the baseline
- **THEN** target agent counts and food/refuge counts scale proportionally to area instead of staying at baseline constants

#### Scenario: Population floor maintained
- **WHEN** agents die and a species drops below its density floor
- **THEN** a new AI agent of a below-floor species respawns at a spawn point away from the possessed agent within a bounded time

### Requirement: Start-as-any-animal select
The system SHALL show a start-select screen before the first life offering every playable species (oruga, sapo, raton, ardilla, topo, halcon, zorro, and lobo once promoted), SHALL start the chosen form with 0 karma and 0 PA at full Vida, and SHALL possess the matching agent in the world.

#### Scenario: Player starts as a predator
- **WHEN** the player picks zorro on the start screen
- **THEN** the first life begins as a zorro with full Vida, 0 karma, 0 PA, and PLAYER brain

#### Scenario: Player starts as prey
- **WHEN** the player picks oruga on the start screen
- **THEN** the first life begins as an oruga under the same zero-carry rules, with hunters present on the map

### Requirement: Persistent world across lives
The system SHALL keep one persistent world across deaths: reincarnation re-possesses into the SAME world (eaten food stays eaten, carrion keeps aging, surviving agents keep their positions and HP), spawning only a fresh agent for the new form when no suitable AI agent of that species exists to possess.

#### Scenario: Eaten food stays eaten after death
- **WHEN** the player dies and reincarnates
- **THEN** bushes stripped in the previous life remain stripped and carrion ages continue rather than resetting to zero

#### Scenario: Killer still there after death
- **WHEN** a zorro agent kills the possessed agent and the player reincarnates
- **THEN** that zorro agent remains on the map at its current position and HP

#### Scenario: HUD and camera follow the possessed agent
- **WHEN** possession moves to a new agent after reincarnation
- **THEN** HUD values, species label, vision ring, and camera center all track the newly possessed agent
