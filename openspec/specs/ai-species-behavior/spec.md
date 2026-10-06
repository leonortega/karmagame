# ai-species-behavior Specification

## Purpose
Every species on the map has a full AI behavior engine that matches the player's capabilities. Grazers eat, dig, curl, camouflage, carry nuts, groom, and perform species-specific actions. Predators hunt, pounce, dive, strike, and cede kills. No AI animal is static.
## Requirements
### Requirement: All 8 species have species-specific AI behavior
The `updateAgents(dt)` function SHALL call a per-species AI function for every agent: `aiOruga`, `aiSapo`, `aiRaton`, `aiArdilla`, `aiTopo`, `aiZorro`, `aiLobo`, `aiHalcon`. Four species implement the full behavioral kit inline (contact eating, food seeking beyond contact range, hunger-priority gating of secondary behaviors, refuge hiding when hunted, flee-toward-cover, and the species deeds below per `ai-survival`). An agent is hungry whenever its `hambre` is below 100, for every species: any food deficit outranks secondary behaviors. The zorro function SHALL split into micro steering every physics tick plus macro intent from NanoJev ranking per `ai-jev-zorro`, using the same kill, carrion, and karma values as the player. The halcon function SHALL split into micro steering every physics tick (dive-kill, grounded/land cycle, drink, needs/cooldowns) plus macro intent from NanoJev ranking per `ai-jev-halcon`, using the same dive, carrion, and karma values as the player. The raton function SHALL split into micro steering every physics tick (contact eat, forage-seek, drink, hide/flee, needs/cooldowns, social-verb fallthrough) plus macro intent from NanoJev ranking per `ai-jev-raton`, using the same patch-eat, drink, and karma values as the player. The ardilla function SHALL split into micro steering every physics tick (contact eat, forage-seek, drink, hide/flee, needs/cooldowns, social-verb fallthrough) plus macro intent from NanoJev ranking per `ai-jev-ardilla`, using the same patch-eat, nut carry/bury, drink, and karma values as the player.

#### Scenario: AI Topo digs burrows
- **WHEN** an AI Topo agent's `digCd` is 0, `dug` < 3, and it is not hungry
- **THEN** a `burrow-M` refuge is created at the agent's position, `dug` increments by 1, `digCd` is set, and the agent gains +3 karma

#### Scenario: AI Ardilla carries and plants nuts
- **WHEN** an AI Ardilla agent finds an oak with nuts, has no `carriedNut`, and is not hungry
- **THEN** `carriedNut` becomes true and the oak loses one nut
- **WHEN** the same agent uses `carryAction` again with `carriedNut` true
- **THEN** `carriedNut` resets, `saplings` increments, the agent gains +10 karma, and an oak-tree seedling spawns at the bury position (per `flora-lifecycle`)

#### Scenario: AI Oruga curls when motionless
- **WHEN** an AI Oruga agent is motionless (`stillT` ≥ 0.01) and `curlCd` ≤ 0 and not hungry
- **THEN** `curled()` returns true, and the agent takes half damage from predator contact

#### Scenario: AI Sapo camouflages when motionless
- **WHEN** an AI Sapo agent is motionless (`stillT` ≥ 2), not in a refuge, and not hungry
- **THEN** `camouflaged()` returns true, and Zorro predators do not track the agent

#### Scenario: AI Ratón grooms with mates
- **WHEN** an AI Ratón agent stays within 30px of a `companyAgent` for 3s continuous and is not hungry
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

#### Scenario: AI hides instead of starving in the open
- **WHEN** any grazer AI is hunted and a fitting refuge is within hide-range
- **THEN** it hides per `ai-survival` before all other behaviors except immediate contact eating
#### Scenario: AI Zorro intent comes from JEV ranking

- **WHEN** an AI Zorro agent needs macro intent
- **THEN** its intent is the ranked winner of its code-built legal candidate menu via one batched NanoJev request, applied through the same eat/verb functions as the player, while micro steering continues every tick

#### Scenario: AI Halcon intent comes from JEV ranking

- **WHEN** an AI Halcon agent needs macro intent
- **THEN** its intent is the ranked winner of its code-built legal candidate menu via one batched NanoJev request, applied through the same eat/verb functions as the player, while micro steering (including the grounded/land cycle) continues every tick

#### Scenario: AI Raton intent comes from JEV ranking

- **WHEN** an AI Raton agent needs macro intent
- **THEN** its intent is the ranked winner of its code-built legal candidate menu via one batched NanoJev request, applied through the same eat/drink/social functions as the player, while micro steering continues every tick

#### Scenario: AI Ardilla intent comes from JEV ranking

- **WHEN** an AI Ardilla agent needs macro intent
- **THEN** its intent is the ranked winner of its code-built legal candidate menu via one batched NanoJev request, applied through the same eat/carry/bury/drink/social functions as the player, while micro steering continues every tick

#### Scenario: AI is hungry on any food deficit

- **WHEN** any AI agent's `hambre` drops below 100
- **THEN** it counts as hungry: distant-food seeking activates and secondary behaviors defer to eating until `hambre` is full again

#### Scenario: Thirsty AI treks to distant water

- **WHEN** an AI agent needs drink and no water lies inside scout range
- **THEN** it moves toward the nearest water at any distance instead of wandering without drink

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

### Requirement: Wander travel is purposeful
Whenever an agent (AI fauna, company mate, or hunter acting without a hunt target) has no other intent, deed, or reflex to execute, it SHALL steer toward the nearest point of interest instead of random-walking: nearest edible food first, else nearest water, else nearest fitting cover, else nearest company, else a short random step only when nothing qualifies. This changes movement targets only: no karma, cost, cooldown, or gait changes. The possessed (player-controlled) agent is exempt and keeps free control. Oruga and sapo are exempt at the terminal wander tail: their stillness-gated defenses (curl, camouflage per `ai-species-behavior`) require motionlessness, so they keep accumulating stillness instead of traveling — the defense counts as the deed.

#### Scenario: Idle grazer heads for food
- **WHEN** a raton with wander intent has no contact food but an edible patch lies within the TUNING wander-seek range
- **THEN** it moves toward that patch each tick instead of drifting randomly

#### Scenario: Thirsty wanderer heads for water
- **WHEN** a wandering agent has no edible food in range but water is the nearest point of interest
- **THEN** it moves toward that water each tick

#### Scenario: Nothing nearby, small step
- **WHEN** a wandering agent has no food, water, cover, or company anywhere in range
- **THEN** it takes a short random step (bounded jitter, same as today) rather than freezing

#### Scenario: Player control untouched
- **WHEN** the possessed agent holds no direction
- **THEN** it stays put exactly as today; purposeful travel never moves the player

#### Scenario: Stillness defenses keep their stillness
- **WHEN** an oruga or sapo with wander intent has no food, water, or other trigger
- **THEN** it keeps accumulating stillness (curl/camouflage path) instead of traveling

