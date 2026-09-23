# Spec Delta

## MODIFIED Requirements

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

### Requirement: Sapo form (Tier 1)
The system SHALL provide the Sapo as a slow, size 1 insectivore form whose tongue grabs insects at 90px range, and whose croak counts as a shout. Sapo cannot eat fruit.

#### Scenario: Sapo tongue grabs at range
- **WHEN** a Sapo uses the eat action with an insect within 90px but beyond contact range
- **THEN** the insect is consumed with +10 Vida, +3 PA, and pest-control karma applied

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

## ADDED Requirements

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
