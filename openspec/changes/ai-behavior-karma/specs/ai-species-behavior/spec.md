# Spec Delta: ai-species-behavior

## Purpose

Every species on the map has a full AI behavior engine that matches the player's capabilities. Grazers eat, dig, curl, camouflage, carry nuts, groom, and perform species-specific actions. Predators hunt, pounce, dive, strike, and cede kills. No AI animal is static.

## ADDED Requirements

### Requirement: All 8 species have species-specific AI behavior
The `updateAgents(dt)` function SHALL call a per-species AI function for every agent: `aiOruga`, `aiSapo`, `aiRaton`, `aiArdilla`, `aiTopo`, `aiZorro`, `aiLobo`, `aiHalcon`. Each function implements the full behavioral kit for that species.

#### Scenario: AI Topo digs burrows
- **WHEN** an AI Topo agent's `digCd` is 0 and `dug` < 3
- **THEN** a `burrow-M` refuge is created at the agent's position, `dug` increments by 1, `digCd` is set, and the agent gains +3 karma

#### Scenario: AI Ardilla carries and plants nuts
- **WHEN** an AI Ardilla agent finds an oak with nuts and has no `carriedNut`
- **THEN** `carriedNut` becomes true and the oak loses one nut
- **WHEN** the same agent uses `carryAction` again with `carriedNut` true
- **THEN** `carriedNut` resets, `saplings` increments, and the agent gains +10 karma

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

### Requirement: AI predators use full kill verbs
Predator agents (zorro, lobo, halcon) use their full kill verbs against AI and player agents: pounce (zorro), dive (halcon), strike (halcon vs predator), and cede (zorro). All kill verbs follow the same values as the player.

#### Scenario: AI Zorro pounces on AI Ratón
- **WHEN** an AI Zorro agent is adjacent to an AI Ratón agent and `pounceCd` is 0
- **THEN** the Ratón dies, a carrion spawns, and the Zorro gains HP per `pounceHp`

#### Scenario: AI Halcon dive-kills AI mate
- **WHEN** an AI Halcon agent dives on an adjacent AI company agent
- **THEN** the mate dies, a carrion spawns at the kill position

### Requirement: AI grazers eat species-appropriate food
Every AI grazer agent eats only its `DIET` entries using the same `eatPatch`, `eatInsect`, `eatCarrion` functions as the player. AI grazers lose HP from hunger and die at 0 HP leaving carrion.

#### Scenario: AI Ratón eats berries
- **WHEN** an AI Ratón agent is adjacent to a berry bush with fruit
- **THEN** the bush loses one fruit and the agent gains +15 HP and +5 PA (no karma, no PA from eating alone — only from good deeds)

#### Scenario: AI Topo eats insects
- **WHEN** an AI Topo agent is adjacent to an insect
- **THEN** the insect is consumed and the agent gains +10 HP and +3 PA

### Requirement: AI agents have full cooldown state tracking
Every AI agent tracks its own cooldowns: `shoutCd`, `pounceCd`, `strikeCd`, `digCd`, `curlCd`, `groomCd`, `senseCd`, `trackT`, `lureTimer`, `satedT`, `restT`, `huntT`. These are decremented per tick in `updateAgents`.

#### Scenario: AI Ratón shout cooldown
- **WHEN** an AI Ratón triggers `aiTryShout`
- **THEN** `agent.shoutCd` is set to `TUNING.shoutCooldown` and the agent cannot shout again until it expires

#### Scenario: AI Topo dig cooldown
- **WHEN** an AI Topo digs a burrow
- **THEN** `agent.digCd` is set to `TUNING.digCd` and the agent cannot dig again until it expires

### Requirement: AI agents participate in the shared hunger-eat-die loop
Every AI agent loses HP at `TUNING.hungerPerSec * dt` per tick. AI agents eat only their diet entries. AI agents die at 0 HP and leave a fresh carrion. Carnivore AI hunt other agents using the trophic table.

#### Scenario: AI agent starves
- **WHEN** an AI agent finds no food for an extended time
- **THEN** its HP drains at the standard rate and it dies at 0, spawning carrion

#### Scenario: AI carnivore hunts AI fauna
- **WHEN** an AI carnivore perceives an AI agent of any brain that is edible per the trophic table
- **THEN** it pursues and strikes on contact, killing the victim and spawning carrion
