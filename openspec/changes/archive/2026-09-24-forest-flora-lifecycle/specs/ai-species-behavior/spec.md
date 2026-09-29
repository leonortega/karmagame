# Spec Delta: ai-species-behavior

## Purpose

The AI Ardilla's planting deed now lands in the world: burying a nut spawns an oak-tree seedling that matures into a nut-bearing young oak, under the same flora caps as the player's planting.

## MODIFIED Requirements

### Requirement: All 8 species have species-specific AI behavior
The `updateAgents(dt)` function SHALL call a per-species AI function for every agent: `aiOruga`, `aiSapo`, `aiRaton`, `aiArdilla`, `aiTopo`, `aiZorro`, `aiLobo`, `aiHalcon`. Each function implements the full behavioral kit for that species.

#### Scenario: AI Topo digs burrows
- **WHEN** an AI Topo agent's `digCd` is 0 and `dug` < 3
- **THEN** a `burrow-M` refuge is created at the agent's position, `dug` increments by 1, `digCd` is set, and the agent gains +3 karma

#### Scenario: AI Ardilla carries and plants nuts
- **WHEN** an AI Ardilla agent finds an oak with nuts and has no `carriedNut`
- **THEN** `carriedNut` becomes true and the oak loses one nut
- **WHEN** the same agent uses `carryAction` again with `carriedNut` true
- **THEN** `carriedNut` resets, `saplings` increments, the agent gains +10 karma, and an oak-tree seedling spawns at the bury position (per `flora-lifecycle`)

#### Scenario: AI Oruga curls when motionless
- **WHEN** an AI Oruga agent is motionless (`stillT` ≥ 0.01) and `curlCd` ≤ 0
- **THEN** `curled()` returns true, and the agent takes half damage from predator contact

#### Scenario: AI Sapo camouflages when motionless
- **WHEN** an AI Sapo agent is motionless (`stillT` ≥ 2) and not in a refuge
- **THEN** `camouflaged()` returns true, and Zorro predators do not track the agent

#### Scenario: AI Ratón grooms with mates
- **WHEN** an AI Ratón agent stays within 30px of a `companyAgent` for 3s continuous
- **THEN** the agent gains +5 karma, a 30s cooldown starts, and the grooming timer resets

#### Scenario: AI Zorro cedes kills
- **WHEN** an AI Zorro agent uses its eat action on carrion at ≥80% HP
- **THEN** the carrion stays uneaten, the agent gains +15 karma

#### Scenario: AI Halcon drives off Lobo
- **WHEN** an AI Halcon agent uses its strike action adjacent to a Lobo agent
- **THEN** the Lobo is pushed away, and the Halcon gains +20 karma

#### Scenario: AI Lobo hunts T2 and zorros
- **WHEN** an AI Lobo agent perceives a tier-2 agent or zorro agent within perception
- **THEN** the Lobo pursues and strikes on contact, killing the victim and spawning carrion
