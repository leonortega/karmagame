## MODIFIED Requirements

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
