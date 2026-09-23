# Spec Delta

## ADDED Requirements

### Requirement: Lobo form (Tier 2 apex)
The system SHALL provide the Lobo as a Tier 2 apex form, size 4, slower than the Halcón but tougher, whose diet is carrion and mates, that cannot shout, hunts tier 2 agents and zorro agents, and fears nothing.

#### Scenario: Lobo hunts the big
- **WHEN** a player-controlled Lobo uses the eat action adjacent to a tier 2 agent or zorro agent with its kill verb ready
- **THEN** the victim dies, a fresh carrion spawns at its position, and the wasteful-kill rule applies

#### Scenario: Lobo cannot shout
- **WHEN** the player is a Lobo and attempts the altruistic shout
- **THEN** no Karma/PA is granted and an informational message is shown

#### Scenario: Nothing hunts the Lobo
- **WHEN** a Lobo agent is on the map with zorro agents nearby
- **THEN** no AI agent targets the Lobo as prey; zorro agents flee from it

### Requirement: NPC agents share the hunger-eat-die loop
The system SHALL run hunger drain, diet-gated eating with identical payoffs, and death for AI agents: every agent loses Vida continuously at the same drain rate, eats only its DIET table entries with the same Vida gains (no karma, no PA), and dies at 0 Vida leaving a fresh carrion for carnivore diets. AI kills obey the same contact and kill verbs (pounce/dive/strike values) as player kills.

#### Scenario: NPC grazer eats and survives
- **WHEN** an AI raton reaches a berry patch with fruit remaining
- **THEN** the patch loses one fruit and the agent gains the same Vida as a player would, with no karma or PA granted

#### Scenario: NPC starves without food
- **WHEN** an AI agent finds no food for an extended time
- **THEN** its Vida drains at the standard rate and it dies at 0, spawning carrion

#### Scenario: NPC diet refusal
- **WHEN** an AI sapo is near berries with no insects around
- **THEN** the berries are not consumed and the agent keeps wandering or hunting insects

## MODIFIED Requirements

### Requirement: Hard diet restrictions
The system SHALL allow each form to eat only its diet table entries; all other foods are refused. Diet matrix (X = staple):

| Form | berries | apples | carrots | mushrooms | leaves | insects | nuts | carrion | mates |
|---|---|---|---|---|---|---|---|---|---|
| Oruga | - | - | - | - | X | - | - | - | - |
| Sapo | - | - | - | - | - | X | - | - | - |
| Ratón | X | X | X | X | - | - | X | - | - |
| Ardilla | X | X | - | X | - | - | X | - | - |
| Topo | - | - | X | - | - | X | X | - | - |
| Halcón | - | - | - | - | - | - | - | X | X |
| Zorro | - | - | - | - | - | - | - | X | X |
| Lobo | - | - | - | - | - | - | - | X | X |

The matrix applies to agents of any brain; only the possessed agent receives karma/PA side effects for eating.

#### Scenario: Staple works
- **WHEN** a Topo agent (any brain) eats an unearthed carrot
- **THEN** Vida rises by 18 with no PA granted to AI agents (PA only for the possessed agent)

#### Scenario: Wrong food refused
- **WHEN** a Sapo agent (any brain) is at berries with no insects in range
- **THEN** the berries stay and no values change
