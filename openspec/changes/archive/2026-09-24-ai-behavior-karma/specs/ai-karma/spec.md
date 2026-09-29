# Spec Delta: ai-karma

## Purpose

Every animal on the map — not just the player — has a karma and PA ledger, earns karma from species-specific good deeds, can trigger the shout mechanic to alert the ecosystem, and auto-purchases adaptations using PA. The karma system is universal across all brains.

## ADDED Requirements

### Requirement: Every AI agent has a karma and PA ledger
Each agent in `state.agents` SHALL have `karma`, `pa`, `owned`, and `lifeLog` fields. When an agent is created via `mkAgent` or `mkPredator`, these initialize to `0`, `0`, `{}`, and `[]`. AI karma and PA are clamped to the same ranges as the player (-100…+100 for karma, no upper bound for PA).

#### Scenario: Agent created with zero karma
- **WHEN** `mkAgent({ role:'fauna', speciesKey:'raton', ... })` is called
- **THEN** the returned agent has `karma === 0` and `pa === 0`

#### Scenario: Predator agent has karma ledger
- **WHEN** `mkPredator('zorro', x, y, playerTier)` is called
- **THEN** the returned predator has `karma === 0` and `pa === 0`

### Requirement: AI agents earn karma from good deeds
Each species earns karma from the same actions that grant the player karma:
- Oruga: +2 per sustainable eat (never taking the last fruit)
- Sapo: +3 per insect eaten (pest control)
- Ratón: +5 after 3s continuous proximity to a mate (groom)
- Ardilla: +10 for burying a carried nut
- Topo: +3 per dug burrow
- Zorro: +15 for using E on carrion at ≥80% HP (cede the kill)
- Lobo/Halcon: +20 for striking a Lobo
- All species: +30 karma and +50 PA for a successful shout

#### Scenario: Sapo pest control karma
- **WHEN** an AI Sapo eats an insect
- **THEN** the agent's karma increases by 3 and an appropriate log entry is recorded

#### Scenario: Ardilla planting karma
- **WHEN** an AI Ardilla buries a carried nut
- **THEN** the agent's karma increases by 10 and the sapling carry resets

#### Scenario: Oruga prudent nibble karma
- **WHEN** an AI Oruga eats a sustainable leaf (not the last)
- **THEN** the agent's karma increases by 2

### Requirement: AI agents can trigger the shout mechanic
Any AI agent that can shout (all except Zorro, Halcón, and Oruga) MAY trigger `aiTryShout(agent)`. The shout follows the same rules as the player's: 10s cooldown, lures predators toward the AI for 5s, scatters company mates, grants +30 karma and +50 PA to the agent.

#### Scenario: AI Ratón shouts
- **WHEN** an AI Ratón's `shoutCd` is 0 and it triggers `aiTryShout`
- **THEN** the agent's karma increases by 30, PA by 50, `lureTimer` is set, and all `companyAgents()` have `saved: true`

#### Scenario: AI Zorro cannot shout
- **WHEN** an AI Zorro attempts `aiTryShout`
- **THEN** no karma/PA change, informational message logged

### Requirement: AI auto-purchase adaptations
AI agents evaluate their PA and needs periodically and purchase the most-needed adaptation from `SHOP` using PA. The same `owned` constraint applies: one adaptation per stat, no stacking. Adaptations are per-life.

#### Scenario: AI Ratón buys Stomach when low HP
- **WHEN** an AI Ratón's HP is below 50% of max and `stomach` is not owned and PA ≥ 30
- **THEN** PA decreases by 30, `owned.stomach` becomes true, HP increases by 25

#### Scenario: AI refuses unaffordable adaptations
- **WHEN** an AI agent has insufficient PA for any adaptation
- **THEN** no purchase occurs; PA remains unchanged

### Requirement: Karma affects ecosystem interactions
An AI agent's karma level modifies how other agents interact with it:
- **High karma (≥ 30)**: Predators have 20% reduced perception of this agent; company mates are attracted more readily.
- **Low karma (≤ -30)**: Predators have 20% increased perception; agents flee more readily.
- **Neutral (-29…+29)**: No modifier.

#### Scenario: High-karma agent is harder to detect
- **WHEN** a Zorro NPC perceives a Ratón NPC with karma ≥ 30
- **THEN** the Zorro's effective perception range is reduced by 20%

#### Scenario: Low-karma agent is easier to detect
- **WHEN** a Zorro NPC perceives a Ratón NPC with karma ≤ -30
- **THEN** the Zorro's effective perception range is increased by 20%

### Requirement: Live bar and karma number displayed over every animal
Every agent rendered on the map SHALL have a small live HP bar and karma number displayed above it. The HP bar is proportional to `agent.hp / maxHp`. The karma number is an integer, green when positive, red when negative.

#### Scenario: Agent with full HP and positive karma
- **WHEN** an agent is rendered with hp=100, maxHp=100, karma=25
- **THEN** a green full-width HP bar and "25" appear above the agent

#### Scenario: Agent with low HP and negative karma
- **WHEN** an agent is rendered with hp=20, maxHp=100, karma=-15
- **THEN** a red-ish partial HP bar and "-15" appear above the agent

### Requirement: Global karma/PA/record functions accept an agent target
`addKarma(n, msg, cls, agent?)`, `addPa(n, agent?)`, and `record(msg, agent?)` SHALL accept an optional agent parameter. When provided, they write to `agent.karma`, `agent.pa`, `agent.lifeLog`. When omitted, they write to `state` (player) as before.

#### Scenario: Player addKarma unchanged
- **WHEN** `addKarma(10, 'test')` is called without an agent
- **THEN** `state.karma` increases by 10 and `state.lifeLog` records the message

#### Scenario: AI addKarma targets the agent
- **WHEN** `addKarma(10, 'test', 'info', aiAgent)` is called with an agent
- **THEN** `aiAgent.karma` increases by 10 and `aiAgent.lifeLog` records the message
