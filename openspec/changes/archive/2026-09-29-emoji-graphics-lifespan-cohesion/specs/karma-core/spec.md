## MODIFIED Requirements

### Requirement: Vida drains with hunger and triggers judgment at zero
The system SHALL decrease Vida continuously over time at a species-paced rate derived from life expectancy, and SHALL trigger the Judgment sequence when Vida reaches 0. The drain rate SHALL equal the global base rate multiplied by the possessed species' hunger multiplier: short-lived forms drain faster, long-lived forms drain slower. Default multipliers SHALL keep the Ratón near the historic baseline pace.

#### Scenario: Hunger depletes vida
- **WHEN** the player survives 10 seconds without eating at its species drain rate
- **THEN** Vida is lower than at start by species-rate × time and the creature remains alive while Vida > 0

#### Scenario: Death opens judgment
- **WHEN** Vida reaches 0 for any reason
- **THEN** the game pauses the life loop and opens the Judgment screen instead of respawning silently

#### Scenario: Short-lived starves faster than apex
- **WHEN** an Oruga and a Lobo both survive 30 seconds without eating
- **THEN** the Oruga has lost more Vida than the Lobo

#### Scenario: Lobo anchor vive 30 minutos
- **WHEN** a Lobo survives 1800 seconds without eating
- **THEN** its total Vida loss equals its max Vida (species-rate × time ≈ 160), i.e. it starves at ~30 minutes, and every other species scales by its own multiplier

### Requirement: NPC agents share the hunger-eat-die loop
The system SHALL run hunger drain, diet-gated eating with identical payoffs, and death for AI agents: every agent loses Vida continuously at its own species-paced drain rate (same multiplier as the player of that species), eats only its DIET table entries with the same Vida gains, and dies at 0 Vida leaving a fresh carrion for carnivore diets. AI kills obey the same contact and kill verbs (pounce/dive/strike values) as player kills. NPC agents now also earn karma for species-specific good deeds, spend PA on adaptations, and trigger shouts — AI karma is discarded on death (no reincarnation for AI).

#### Scenario: NPC grazer eats and survives
- **WHEN** an AI raton reaches a berry patch with fruit remaining
- **THEN** the patch loses one fruit and the agent gains the same Vida as a player would, with no karma or PA granted for the meal itself

#### Scenario: NPC starves without food
- **WHEN** an AI agent finds no food for an extended time
- **THEN** its Vida drains at its species rate and it dies at 0, spawning carrion

#### Scenario: NPC carnivore hunts fauna
- **WHEN** an AI carnivore perceives a smaller or equal-size agent (any brain)
- **THEN** it pursues and strikes on contact, killing the victim and spawning carrion; it never targets itself

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
- **THEN** its HP drains at its species rate, it dies at 0, and a fresh carrion spawns — **the agent's karma/PA are lost** (no reincarnation for AI)

#### Scenario: NPC short-lived drains faster
- **WHEN** an AI Oruga and an AI Lobo both go unfed for the same duration
- **THEN** the Oruga loses Vida faster than the Lobo
