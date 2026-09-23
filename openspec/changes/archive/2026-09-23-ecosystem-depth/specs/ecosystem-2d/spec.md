# Spec Delta

## MODIFIED Requirements

### Requirement: Keyboard controls for move, eat, shout, shop
The system SHALL support WASD/arrows for movement, E for eat/strike/Pounce/tongue/Dig (context by species), Q for shout, B to open/close the mid-life shop, H to hide in / exit a nearby fitting refuge, number keys 1-4 to buy shop items, and R to reincarnate from the Judgment screen.

#### Scenario: Basic control mapping
- **WHEN** the user presses movement, E, Q, B, H, number, or R keys in their valid contexts
- **THEN** the corresponding move, species action, shout, shop toggle, hide toggle, purchase, or reincarnate action occurs

### Requirement: Bushes hold finite fruit and die permanently
The system SHALL spawn 7 living bushes with 3 fruits each per life, SHALL mark a bush permanently dead (grey, no fruit) once its last fruit is eaten, and SHALL mark 1 fruit in every 3rd bush as a mimic poison fruit with a subtly darker tint. Eating a mimic SHALL drain 20 Vida with no karma change.

#### Scenario: Bush exhaustion is permanent for the life
- **WHEN** all fruits of a bush are consumed
- **THEN** the bush remains dead with zero fruit until the next reincarnation generates a fresh world

#### Scenario: Mimic poisons
- **WHEN** the player eats a mimic fruit
- **THEN** Vida drops by 20, no karma changes, and the event is logged as poisoning

### Requirement: Predators wander and chase with contact damage
The system SHALL spawn predators by tier table (player T0: 2 Zorro; player T1: 2 Zorro; player T2: 1 Zorro + 1 Lobo), where Zorro NPCs hunt the player (T0/T1 forms), congeners, and flee Lobo, and the Lobo NPC (Tier 3, faster than Zorro, fears nothing) hunts T2 players, grounded Halcóns, and Zorro NPCs. Predators SHALL chase edible targets in perception, lose hidden players and camp the refuge ~3s before wandering off, and Zorro kills of congeners SHALL spawn fresh carrion.

#### Scenario: Chase and bite
- **WHEN** the player enters predator perception range
- **THEN** at least one predator pursues, and on contact Vida drops by 28 and further hits are ignored for 1s

#### Scenario: Zorro flees Lobo
- **WHEN** a Lobo enters a Zorro NPC's perception range
- **THEN** the Zorro abandons its hunt and flees away from the Lobo

#### Scenario: Lobo only threatens the big
- **WHEN** the player is a T0 or T1 form
- **THEN** no Lobo is on the map

#### Scenario: Camp the hidden
- **WHEN** the player hides in a refuge while chased
- **THEN** the pursuer waits at the refuge ~3s and then returns to wandering

#### Scenario: Kills feed scavengers
- **WHEN** a Zorro NPC kills a congener
- **THEN** a fresh carrion entity spawns at the kill position

### Requirement: HUD and cause-effect log are always visible
The system SHALL display species/tier, Vida with max, Karma value with polarity, PA, elapsed time, shout cooldown state, hidden state with refuge prompt when near a fitting refuge, and the last 5 cause-effect log entries with good/bad/info polarity.

#### Scenario: Player reads consequences
- **WHEN** any karma-relevant event occurs
- **THEN** the HUD values update immediately and a new log entry appears at the top describing cause and effect

#### Scenario: Refuge prompt appears
- **WHEN** the player stands near a refuge its size fits
- **THEN** a prompt shows the H key and the refuge name

## ADDED Requirements

### Requirement: Refuges gate hiding by size
The system SHALL spawn per life 3 burrow-S (max size 1), 3 burrow-M (max size 2), 2 hollow-trees (max size 2, climbers only: Ardilla), and 2 thorn-bushes (max size 2). Hiding SHALL require size fit, SHALL freeze movement and eating while hidden, SHALL keep hunger draining, and SHALL end on H or on death.

#### Scenario: Too big to hide
- **WHEN** a Zorro (size 3) presses H near a burrow-M
- **THEN** nothing happens and a message states it does not fit

#### Scenario: Hiding costs time not safety forever
- **WHEN** the player hides for 30s
- **THEN** Vida has drained for 30s of hunger while predators lost the trail

### Requirement: Carrion rots on a clock
The system SHALL age every carrion fresh (eat: +20 Vida) → stale after 30s (eat: +8 Vida) → rotten after 60s (eat: −25 Vida), with visible state (color shift, flies when rotten), and SHALL never change karma for eating carrion at any stage.

#### Scenario: Fresh meat rewards
- **WHEN** the player eats a carrion younger than 30s
- **THEN** Vida rises by 20 capped at max with no karma change

#### Scenario: Rotten meat punishes
- **WHEN** the player eats a rotten carrion
- **THEN** Vida drops by 25 with no karma change

### Requirement: Halcón must land to eat
The system SHALL forbid an airborne Halcón from eating; attempting E near food SHALL land it for 1s (immobile, vulnerable, shown grounded), after which the eat resolves, and the next movement input takes off again.

#### Scenario: Landing is the risk
- **WHEN** a Halcón eats beside a patrolling Lobo
- **THEN** the Lobo can reach and damage it during the 1s grounded window
