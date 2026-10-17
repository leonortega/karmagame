## MODIFIED Requirements

### Requirement: Shared hunger-eat-die loop for all agents
Every agent on the map (player or AI) SHALL drain hambre and sed continuously at the same species rates, regenerate vida over time only when hambre AND sed are both above threshold (scaled down by age per `animal-senescence`), otherwise drain vida with the same deficit multiplier, drink from charcos and lagos with the same sed and sip-vida gains, eat only its DIET table entries with the same Vida gains (no karma, no PA for AI), age through prime/worn/frail stages, and die at 0 Vida or at its species lifespan leaving a fresh carrion. AI kills obey the same age-scaled damage and kill verbs as player kills. Role-hunter NPC predators (zorro, lobo, saponpc pressure roles) SHALL drain hambre/sed/edad, weaken with age, and drink like other agents, and their Vida SHALL drain from needs and age like everyone else: they starve, weaken, and die of hunger, thirst, or old age, and combat and feast gains still apply. **BREAKING**: the old pressure-role needs-immunity guarantee is removed.

#### Scenario: NPC grazer eats and survives
- **WHEN** an AI raton reaches a berry patch with fruit remaining
- **THEN** the patch loses one fruit and the agent gains the same Vida as a player would, with no karma or PA granted

#### Scenario: NPC starves without food
- **WHEN** an AI agent finds no food or water for an extended time below threshold
- **THEN** its Vida drains at the standard deficit rate and it dies at 0, spawning carrion

#### Scenario: NPC carnivore hunts fauna
- **WHEN** an AI carnivore (zorro or lobo) perceives a smaller or equal-size agent
- **THEN** it pursues and strikes with age-scaled damage, killing only when damage meets or exceeds victim vida and otherwise wounding and opening a chase; it never targets itself

#### Scenario: NPC drinks like the player
- **WHEN** an AI agent with sed below threshold reaches a charco edge within drink range
- **THEN** it gains the same sed refill and sip-vida heal as a player would, with no karma or PA granted

#### Scenario: Hunter pressure never starves out
- **WHEN** a role-hunter NPC goes unfed and unwatered for an extended time
- **THEN** the old immunity no longer applies (**BREAKING**): its Vida drops from needs and age like any agent and it can die, weakening first

#### Scenario: Hunter pressure can starve and age out
- **WHEN** a role-hunter NPC goes unfed and unwatered for an extended time or reaches its lifespan
- **THEN** its Vida drops from needs and age like any agent, it weakens (slower, softer hits), and it dies at 0 or at lifespan, spawning carrion
