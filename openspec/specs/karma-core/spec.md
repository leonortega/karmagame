# karma-core

## Purpose

Define the core creature attributes (Vida, Karma, PA) and their tuning so every life, decision, and reward behaves consistently and is testable without any engine.

## Requirements

### Requirement: Vida drains with hunger and triggers judgment at zero
The system SHALL decrease Vida continuously over time and SHALL trigger the Judgment sequence when Vida reaches 0.

#### Scenario: Hunger depletes vida
- **WHEN** the player survives 10 seconds without eating at the default drain rate
- **THEN** Vida is lower than at start by drain-rate × time and the creature remains alive while Vida > 0

#### Scenario: Death opens judgment
- **WHEN** Vida reaches 0 for any reason
- **THEN** the game pauses the life loop and opens the Judgment screen instead of respawning silently

### Requirement: Karma stays within -100 to +100
The system SHALL clamp Karma Ecológico to the range -100…+100 on every change.

#### Scenario: Karma clamps at extremes
- **WHEN** a positive event would push Karma above 100 (or a negative one below -100)
- **THEN** Karma stops exactly at 100 (or -100)

### Requirement: PA rewards survival time
The system SHALL grant PA continuously for time survived at a documented rate (default ~20 PA/min).

#### Scenario: Survival accrues PA
- **WHEN** the player survives 60 seconds without bonuses
- **THEN** PA increases by approximately 20

### Requirement: Sustainable eating vs last-fruit selfish act
The system SHALL grant food-specific Vida/PA only to diet-listed eaters (berries +15/+5, apples +22/+8, carrots +18/+5, mushrooms +10/+0, leaves +12/+3, nuts +18/+5, insects +10/+3), SHALL refuse off-diet attempts with no effect plus a hint message, and SHALL grant −15 Karma and permanently kill the bush/shrub for eating its last fruit or apple. Leaf-clumps are exempt: they regrow 1 leaf per 60s and never trigger karma.

#### Scenario: Apple pays richer
- **WHEN** an Ardilla eats a non-last apple
- **THEN** Vida rises by 22 and PA by 8

#### Scenario: Sustainable eat
- **WHEN** the player eats berries from a bush with 2+ fruits remaining
- **THEN** Vida rises by 15 (capped at max), PA rises by 5, Karma is unchanged, and the bush stays alive

#### Scenario: Selfish last fruit
- **WHEN** the player eats the final berry of a living bush
- **THEN** Vida rises by 20 (capped at max), Karma drops by 15, and that bush never regrows fruit

#### Scenario: Off-diet refused
- **WHEN** a Zorro uses E on berries
- **THEN** nothing is consumed, no values change, and a hint message appears

#### Scenario: Leaves exempt
- **WHEN** an Oruga strips a leaf-clump bare
- **THEN** no karma changes and leaves regrow over time

### Requirement: Altruistic shout has cost and reward
The system SHALL grant +30 Karma and +50 PA for shouting, SHALL enforce a 10s cooldown, and SHALL lure predators toward the player for 5s. Only non-predator forms can shout (Ratón, Ardilla, Topo, and Sapo whose croak counts as a shout); Halcón and Zorro cannot shout — predators don't warn prey.

#### Scenario: Successful shout
- **WHEN** the player shouts with cooldown ready
- **THEN** Karma rises by 30, PA rises by 50, predators within range target the player for 5s, and congeners flee

#### Scenario: Shout on cooldown is ignored
- **WHEN** the player attempts to shout during cooldown
- **THEN** no Karma/PA change occurs and no lure is triggered

#### Scenario: Predator cannot shout
- **WHEN** the player is a Halcón or Zorro and attempts to shout
- **THEN** no Karma/PA is granted and an informational message is shown

### Requirement: Oruga form (Tier 0)
The system SHALL provide the Oruga as a slow, fragile, size 1 form that cannot shout and is hunted by all predators.

#### Scenario: Oruga cannot shout
- **WHEN** the player is an Oruga and attempts the altruistic shout
- **THEN** no Karma/PA is granted and an informational message is shown

### Requirement: Sapo form (Tier 1)
The system SHALL provide the Sapo as a slow, size 1 insectivore form whose tongue grabs insects at 90px range, and whose croak counts as a shout. Sapo cannot eat fruit.

#### Scenario: Sapo tongue grabs at range
- **WHEN** a Sapo uses the eat action with an insect within 90px but beyond contact range
- **THEN** the insect is consumed with +10 Vida, +3 PA, and pest-control karma applied

### Requirement: Ratón form (Tier 1)
The system SHALL provide the Ratón as a balanced, size 2 form that can shout with standard rewards.

#### Scenario: Ratón shouts normally
- **WHEN** a Ratón shouts with cooldown ready
- **THEN** Karma rises by 30, PA rises by 50, and predators are lured as usual

### Requirement: Ardilla form (Tier 1)
The system SHALL provide the Ardilla as a faster form with less max Vida than the Ratón, size 2, climber (fits hollow-tree refuges), that can shout.

#### Scenario: Ardilla fits hollow-tree
- **WHEN** an Ardilla presses H near a hollow-tree refuge
- **THEN** it hides successfully

### Requirement: Topo form (Tier 1)
The system SHALL provide the Topo as a size 2 form that can shout and whose Dig creates a burrow-M refuge at its position with 20s cooldown and max 3 per life.

#### Scenario: Topo dig creates refuge
- **WHEN** a Topo uses Dig with cooldown ready and fewer than 3 burrows dug this life
- **THEN** a burrow-M refuge appears at its position and the cooldown starts

### Requirement: Halcón form (Tier 2)
The system SHALL provide the Halcón as the fastest form with the largest vision, size 3, whose strike repels predators with +5 Karma/+10 PA/+10 Vida, that cannot shout and must land to eat.

#### Scenario: Halcón repels predator
- **WHEN** a Halcón uses the eat action adjacent to a predator
- **THEN** the predator is pushed away and suppressed, and the player gains the documented bonus

#### Scenario: Halcón cannot shout
- **WHEN** the player is a Halcón and attempts to shout
- **THEN** no Karma/PA is granted and an informational message is shown

### Requirement: Zorro form (Tier 2)
The system SHALL provide the Zorro as a fast hunter, size 3, whose Pounce dash-kills prey with 6s cooldown and that cannot shout.

#### Scenario: Zorro pounce kills prey
- **WHEN** a Zorro uses the eat action adjacent to a congener with Pounce ready
- **THEN** the congener dies, a fresh carrion spawns at its position, and the Zorro gains Vida per the wasteful-kill rule

#### Scenario: Zorro cannot shout
- **WHEN** the player is a Zorro and attempts to shout
- **THEN** no Karma/PA is granted and an informational message is shown

### Requirement: PA wallet spends without debt
The system SHALL deduct PA immediately on every purchase, SHALL reject any purchase when the balance is insufficient, and SHALL never let PA go negative.

#### Scenario: Purchase deducts balance
- **WHEN** the player with 60 PA buys an item costing 50 PA
- **THEN** the balance becomes 10 PA and the effect applies immediately

#### Scenario: Insufficient funds rejected
- **WHEN** the player with 10 PA attempts to buy an item costing 25 PA
- **THEN** no PA is deducted, no effect applies, and the item shows as unaffordable

### Requirement: Mid-life adaptations are per-life and non-stackable
The system SHALL offer stat adaptations (Swift paws +15% speed for 50 PA, Big stomach +25 max Vida and +25 heal for 30 PA, Keen nose +50 vision for 25 PA and reveals mimic fruit exactly within vision, Quiet voice reducing the next shout lure to 2s for 35 PA), each purchasable at most once per life, and SHALL remove all of them on death.

#### Scenario: Adaptation applies once
- **WHEN** the player buys Swift paws mid-life
- **THEN** speed rises by 15% immediately and the item shows as owned for the rest of the life

#### Scenario: No stacking
- **WHEN** the player who already owns Swift paws attempts to buy it again in the same life
- **THEN** the purchase is rejected with no PA change

#### Scenario: Death clears adaptations
- **WHEN** a life ends with purchased adaptations
- **THEN** the next life starts with base species stats only

#### Scenario: Keen nose reveals mimics
- **WHEN** a player owning Keen nose has a mimic fruit within vision
- **THEN** the mimic is visually marked as poison before being eaten

### Requirement: Wasteful kills cost karma
The system SHALL grant −10 Karma when a carnivore form (Zorro Pounce, Halcón Dive, and any future killing verb) kills prey while its Vida is at or above 80% of max, and SHALL still grant the normal Vida gain capped at max.

#### Scenario: Needed kill is clean
- **WHEN** a Zorro at 50% Vida pounce-kills a congener
- **THEN** no karma change occurs and Vida rises normally

#### Scenario: Sport kill is punished
- **WHEN** a Zorro at 90% Vida pounce-kills a congener
- **THEN** Karma drops by 10 and the kill is logged as wasteful

#### Scenario: Dive-kill obeys the same rule
- **WHEN** a Halcón at 90% Vida dive-kills a mate
- **THEN** Karma drops by 10

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

#### Scenario: Staple works
- **WHEN** a Topo eats an unearthed carrot
- **THEN** Vida rises by 18 and PA by 5

#### Scenario: Wrong food refused
- **WHEN** a Sapo uses E on berries
- **THEN** the berries stay and values don't change

### Requirement: Signature good deeds
The system SHALL grant karma for one characteristic virtue per form: Oruga prudent nibbling (+2 per sustainable eat, i.e. never taking the last fruit), Sapo pest control (+3 per insect), Ratón Groom (+5 after 3s continuous proximity to a mate, 30s cooldown), Ardilla Plant (+10 for burying a carried nut, plus +1 sapling carry), Topo Aerate (+3 per dug burrow), Halcón drive off Lobo (+20 for striking a Lobo), Zorro Cede the kill (+15 for using E on carrion at ≥80% Vida, leaving it uneaten).

#### Scenario: Plant rewards and banks
- **WHEN** an Ardilla carrying a nut buries it
- **THEN** Karma rises by 10 and sapling carry rises by 1

#### Scenario: Cede costs the meal
- **WHEN** a Zorro at 90% Vida uses E on fresh carrion
- **THEN** Karma rises by 15 and the carrion stays for others

#### Scenario: Groom rewards company
- **WHEN** a Ratón stays within 30px of a mate for 3s continuous
- **THEN** Karma rises by 5 and a 30s cooldown starts

#### Scenario: Heroism priced by risk
- **WHEN** a Halcón strikes an adjacent Lobo
- **THEN** Karma rises by 20

### Requirement: New verbs
The system SHALL provide: Ratón Squeeze (counts as size 1 for refuge fit, passive), Ardilla Carry (C near a nut picks it up, C again drops; only one carried; E while carrying still eats only non-nut food), species-sense on V (Topo Tremor: 3s reveal of food and predators, 25s cooldown; Zorro Track: outline to nearest carrion for 5s, 30s cooldown), Sapo Camouflage (motionless 2s outside refuges drops Zorro pursuit only, breaks on move), Oruga Curl (motionless takes half damage, 20s cooldown), Halcón Dive (E on a mate within 60px kills it, spawns carrion, wasteful rule applies).

#### Scenario: Squeeze fits anywhere small
- **WHEN** a Ratón presses H near a burrow-S
- **THEN** it hides successfully

#### Scenario: Tremor reveals
- **WHEN** a Topo presses V with cooldown ready
- **THEN** food and predators show outlines for 3s

#### Scenario: Curl halves damage
- **WHEN** a motionless Oruga with Curl ready takes a bite
- **THEN** the damage is halved and the 20s cooldown starts

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

#### Scenario: NPC carnivore hunts fauna
- **WHEN** an AI carnivore perceives a smaller or equal-size agent (any brain)
- **THEN** it pursues and strikes on contact, killing the victim and spawning carrion; it never targets itself
