# Spec Delta: living-map

## Purpose

Deltas to the living-map capability for AI behavior and karma system. The previous non-goal "NPC fancy verbs: player-only" is reversed: NPC animals now perform all species-specific verbs.

## MODIFIED Requirements

### Requirement: Unified animal roster with possessed player agent
**Reason**: Reversed — NPC animals now perform all species-specific verbs (dig, groom, plant, shout, sense, carry, hide, curl, camouflage) as part of the AI behavior engine, and every agent carries its own karma/PA ledger.
**Migration**: The roster remains unified; the player-possessed agent keeps judgment eligibility. AI agents now accrue karma/PA and use their species verbs.

The system SHALL represent every animal on the map (player and CPU alike) as an agent with species, position, facing, HP, and brain (PLAYER or AI), where exactly one agent is possessed by the player. The possessed agent carries judgment eligibility; every AI agent additionally carries its own `karma`, `pa`, `owned`, and `lifeLog` ledger.

- **WHEN** an AI agent is near a refuge, nut, or predator
- **THEN** it **SHALL** dig, groom, plant, shout, sense, carry, hide, curl, and camouflage according to its species behavior; it uses wander, graze, flee, hunt, strike, pounce, dive, and cede behaviors

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
- **THEN** it **SHALL** dig, groom, plant, shout, sense, carry, hide, curl, and camouflage according to its species behavior (this reverses the previous player-only rule; see `ai-species-behavior`)

#### Scenario: AI Sapo camouflages from Zorro
- **WHEN** an AI Sapo agent is motionless for 2s outside a refuge
- **THEN** `camouflaged()` returns true and Zorro predators do not track the agent

#### Scenario: AI Ardilla carries and plants nuts
- **WHEN** an AI Ardilla agent finds an oak with nuts
- **THEN** it picks up a nut (`carriedNut: true`) and can plant it for +10 karma

## ADDED Requirements

### Requirement: AI agent visual indicators
Every AI agent rendered on the map SHALL display a live HP bar and karma number above it. The HP bar is proportional to `agent.hp / maxHp`. The karma number is an integer, green when positive, red when negative.

#### Scenario: AI agent rendered with live indicators
- **WHEN** an AI agent is on the map
- **THEN** a small HP bar and karma number are displayed above the agent sprite
- **WHEN** the agent's karma is positive
- **THEN** the karma number is rendered in green
- **WHEN** the agent's karma is negative
- **THEN** the karma number is rendered in red
