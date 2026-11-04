## MODIFIED Requirements

### Requirement: Zorro form (Tier 2)
The system SHALL provide the Zorro as a fast hunter, size 3, whose Pounce deals matchup-derived base damage — `PRED[Zorro].damage × (attacker_size / victim_size)` (28 × attacker/victim size ratio) — scaled by attacker force and victim frailty, with 6s cooldown (kill plus carrion only when damage meets or exceeds victim vida, otherwise partial damage plus a decision-gated escape window) and that cannot shout. A real size/strength advantage can make the first hit lethal; comparable or larger victims usually survive it.

#### Scenario: Zorro pounce kills prey
- **WHEN** a prime Zorro uses the eat action adjacent to a congener with Pounce ready and scaled damage meets or exceeds its vida
- **THEN** the congener dies, a fresh carrion spawns at its position, and the Zorro gains Vida per the wasteful-kill rule

#### Scenario: Old Zorro fails on prime prey
- **WHEN** a frail Zorro pounces a prime congener at high vida and scaled damage falls short
- **THEN** the victim takes partial damage, no carrion spawns, the Zorro burns cooldown with no feast heal, and the victim may flee or hide

#### Scenario: Zorro cannot shout
- **WHEN** the player is a Zorro and attempts to shout
- **THEN** no Karma/PA is granted and an informational message is shown

### Requirement: New verbs
The system SHALL provide: Ratón Squeeze (counts as size 1 for refuge fit, passive), Ardilla Carry (C near a nut picks it up, C again drops; only one carried; E while carrying still eats only non-nut food), species-sense on V (Topo Tremor: 3s reveal of food and predators, 25s cooldown; Zorro Track: outline to nearest carrion for 5s, 30s cooldown), Sapo Camouflage (motionless 2s outside refuges drops Zorro pursuit only, breaks on move), Oruga Curl (motionless takes half of the age-scaled damage, 20s cooldown), Halcón Dive (E on a mate within 60px deals matchup-derived base damage `PRED[Halcón].damage × (attacker_size / victim_size)` scaled by age; kill plus carrion only when damage meets or exceeds victim vida, wasteful rule applies).

#### Scenario: Squeeze fits anywhere small
- **WHEN** a Ratón presses H near a burrow-S
- **THEN** it hides successfully

#### Scenario: Tremor reveals
- **WHEN** a Topo presses V with cooldown ready
- **THEN** food and predators show outlines for 3s

#### Scenario: Curl halves damage
- **WHEN** a motionless Oruga with Curl ready takes a bite
- **THEN** the age-scaled damage is halved and the 20s cooldown starts

### Requirement: Lobo form (Tier 2 apex)
The system SHALL provide the Lobo as a Tier 2 apex form, size 4, slower than the Halcón but tougher, whose diet is carrion and mates, that cannot shout, hunts tier 2 agents and zorro agents with matchup-derived base damage `PRED[Lobo].damage × (attacker_size / victim_size)` scaled by age (kill plus carrion only when damage meets or exceeds victim vida), and fears nothing.

#### Scenario: Lobo hunts the big
- **WHEN** a player-controlled prime Lobo uses the eat action adjacent to a tier 2 agent or zorro agent with its kill verb ready and scaled damage is lethal
- **THEN** the victim dies, a fresh carrion spawns at its position, and the wasteful-kill rule applies

#### Scenario: Old Lobo wounds instead of killing
- **WHEN** a frail Lobo strikes a prime tier 2 agent and scaled damage falls short of its vida
- **THEN** the victim survives wounded and may escape per its decision layer

#### Scenario: Lobo cannot shout
- **WHEN** the player is a Lobo and attempts to shout
- **THEN** no Karma/PA is granted and an informational message is shown

#### Scenario: Nothing hunts the Lobo
- **WHEN** a Lobo agent is on the map with zorro agents nearby
- **THEN** no AI agent targets the Lobo as prey; zorro agents flee from it

### Requirement: NPC agents share the hunger-eat-die loop
The system SHALL run hunger drain, diet-gated eating with identical payoffs, age-scaled speed/regen/damage/frailty, and death for AI agents: every agent loses Vida continuously at its own species-paced drain rate (same multiplier as the player of that species), eats only its DIET table entries with the same Vida gains, and dies at 0 Vida or at lifespan leaving a fresh carrion for carnivore diets. AI kills obey the same contact bites and the same matchup-derived kill verbs (pounce/dive/cull base = `PRED[attacker].damage × (attacker_size / victim_size)`, scaled by age) as player kills. NPC agents now also earn karma for species-specific good deeds, spend PA on adaptations, and trigger shouts - AI karma is discarded on death (no reincarnation for AI).

#### Scenario: NPC grazer eats and survives
- **WHEN** an AI raton reaches a berry patch with fruit remaining
- **THEN** the patch loses one fruit and the agent gains the same Vida as a player would, with no karma or PA granted for the meal itself

#### Scenario: NPC starves without food
- **WHEN** an AI agent finds no food for an extended time
- **THEN** its Vida drains at its species rate and it dies at 0, spawning carrion

#### Scenario: NPC carnivore hunts fauna
- **WHEN** an AI carnivore perceives a smaller or equal-size agent (any brain)
- **THEN** it pursues and strikes with age-scaled damage, killing only when lethal and otherwise wounding into a chase; it never targets itself

#### Scenario: NPC grazer earns karma for prudent eating
- **WHEN** an AI Oruga agent eats a sustainable leaf (not the last)
- **THEN** the agent's karma increases by 2 and `record()` logs the event to `agent.lifeLog`

#### Scenario: NPC predator earns karma for ceding kill
- **WHEN** an AI Zorro agent uses eat on carrion at ≥80% HP
- **THEN** the carrion stays uneaten, the agent's karma increases by 15

#### Scenario: NPC agent shouts to alert ecosystem
- **WHEN** an AI Ratón agent triggers `aiTryShout` with cooldown ready
- **THEN** the agent's karma increases by 30, PA by 50, predators target the agent, and company mates flee

#### Scenario: NPC agent dies leaving carrion
- **WHEN** an AI agent finds no food for an extended time
- **THEN** its HP drains at its species rate, it dies at 0, and a fresh carrion spawns - **the agent's karma/PA are lost** (no reincarnation for AI)

#### Scenario: NPC short-lived drains faster
- **WHEN** an AI Oruga and an AI Lobo both go unfed for the same duration
- **THEN** the Oruga loses Vida faster than the Lobo
