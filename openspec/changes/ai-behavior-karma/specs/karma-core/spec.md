# Spec Delta: karma-core

## Purpose

Deltas to the karma-core capability for AI animals now participating in the karma system. NPC agents now earn and spend karma/PA and perform good deeds, not just the player.

## MODIFIED Requirements

### Requirement: NPC agents share the hunger-eat-die loop
**Reason**: Expanded — NPC agents now also earn and spend karma/PA, perform good deeds, trigger shouts, and auto-purchase adaptations. The hunger-eat-die loop remains, but is enriched with karma mechanics.
**Migration**: The existing scenario "NPC grazer eats and survives" and "NPC starves without food" remain valid. New scenarios for karma earning are added below.

- **WHEN** an AI agent finds food
- **THEN** the patch loses one fruit and the agent gains the same Vida as a player would, **and species-specific karma is granted for good deeds** (prudent nibble, pest control, etc.)
- **WHEN** an AI agent uses a species-specific good deed (dig, plant, cede, groom, aerate)
- **THEN** the agent's karma increases by the documented amount and `record()` logs the event to `agent.lifeLog`
- **WHEN** an AI agent triggers a shout
- **THEN** the agent gains +30 karma and +50 PA, `lureTimer` is set, and company mates are saved

#### Scenario: NPC grazer earns karma for prudent eating
- **WHEN** an AI Oruga agent eats a sustainable leaf (not the last)
- **THEN** the agent's karma increases by 2 and `record()` logs the event

#### Scenario: NPC predator earns karma for ceding kill
- **WHEN** an AI Zorro agent uses eat on carrion at ≥80% HP
- **THEN** the carrion stays uneaten, the agent's karma increases by 15

#### Scenario: NPC agent shouts to alert ecosystem
- **WHEN** an AI Ratón agent triggers `aiTryShout` with cooldown ready
- **THEN** the agent's karma increases by 30, PA by 50, predators target the agent, and company mates flee

#### Scenario: NPC agent dies leaving carrion
- **WHEN** an AI agent finds no food for an extended time
- **THEN** its HP drains at the standard rate, it dies at 0, and a fresh carrion spawns — **the agent's karma/PA are lost** (no reincarnation for AI)

## ADDED Requirements

### Requirement: AI agents can purchase adaptations
AI agents spend PA to buy items from `SHOP` using the same `buyItem` logic as the player. The same `owned` constraint applies: one purchase per stat, no stacking, no debt. Adaptations are per-life.

#### Scenario: AI agent buys adaptation with sufficient PA
- **WHEN** an AI agent has PA ≥ an item's cost and does not own it
- **THEN** PA is deducted, `owned[item.id]` becomes true, and the effect applies immediately

#### Scenario: AI agent cannot buy without PA
- **WHEN** an AI agent has PA < item cost
- **THEN** no PA is deducted, no effect applies

### Requirement: AI karma is lost on death
When an AI agent dies, its `karma`, `pa`, `owned`, and `lifeLog` are discarded. The agent becomes a carrion. AI agents do not reincarnate or transfer karma.

#### Scenario: AI agent karma lost on death
- **WHEN** an AI agent dies (HP ≤ 0)
- **THEN** the agent's karma, pa, owned, and lifeLog are discarded; a carrion spawns at its position
