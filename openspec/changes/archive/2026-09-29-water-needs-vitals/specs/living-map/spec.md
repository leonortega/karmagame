## MODIFIED Requirements

### Requirement: Unified animal roster with possessed player agent
The system SHALL represent every animal on the map (player and CPU alike) as an agent with species, position, facing, HP, hambre, sed, edad, and brain (PLAYER or AI), where exactly one agent is possessed by the player. The possessed agent carries judgment eligibility; every AI agent additionally carries its own `karma`, `pa`, `owned`, and `lifeLog` ledger.

- **WHEN** an AI agent interacts with flora
- **THEN** it **SHALL** plant nuts (Ardilla) that grow young oaks in the shared world, graze diet plants, and shelter per its species behavior

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
- **THEN** it **SHALL** dig, groom, plant, shout, sense, carry, hide, curl, and camouflage according to its species behavior (see `ai-species-behavior`)

#### Scenario: AI Sapo camouflages from Zorro
- **WHEN** an AI Sapo agent is motionless for 2s outside a refuge
- **THEN** `camouflaged()` returns true and Zorro predators do not track the agent

#### Scenario: AI Ardilla carries and plants nuts
- **WHEN** an AI Ardilla agent finds an oak with nuts
- **THEN** it picks up a nut (`carriedNut: true`) and can plant it for +10 karma

#### Scenario: AI Ardilla plants trees in the shared world
- **WHEN** an AI Ardilla buries a carried nut
- **THEN** an oak-tree seedling spawns at the bury spot exactly as when the player plants, and both grow under the same flora caps

#### Scenario: Every agent carries needs
- **WHEN** any AI agent is on the map
- **THEN** it carries hambre, sed, and edad values with the same ranges and reset rules as the player, discarded on death like the rest of its ledger

### Requirement: Shared hunger-eat-die loop for all agents
Every agent on the map (player or AI) SHALL drain hambre and sed continuously at the same species rates, regenerate vida over time only when hambre AND sed are both above threshold, otherwise drain vida with the same deficit multiplier, drink from charcos and lagos with the same sed and sip-vida gains, eat only its DIET table entries with the same Vida gains (no karma, no PA for AI), and die at 0 Vida leaving a fresh carrion. AI kills obey the same contact and kill verbs as player kills.

#### Scenario: NPC grazer eats and survives
- **WHEN** an AI raton reaches a berry patch with fruit remaining
- **THEN** the patch loses one fruit and the agent gains the same Vida as a player would, with no karma or PA granted

#### Scenario: NPC starves without food
- **WHEN** an AI agent finds no food or water for an extended time below threshold
- **THEN** its Vida drains at the standard deficit rate and it dies at 0, spawning carrion

#### Scenario: NPC carnivore hunts fauna
- **WHEN** an AI carnivore (zorro or lobo) perceives a smaller or equal-size agent
- **THEN** it pursues and strikes on contact, killing the victim and spawning carrion; it never targets itself

#### Scenario: NPC drinks like the player
- **WHEN** an AI agent with sed below threshold reaches a charco edge within drink range
- **THEN** it gains the same sed refill and sip-vida heal as a player would, with no karma or PA granted
