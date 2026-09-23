# ecosystem-2d

## Purpose

Provide the explorable 2D ecosystem (map, food, threats, controls, feedback) where karma decisions happen through visible movement, eating, and alerting.

## Requirements

### Requirement: Bounded world with camera follow
The system SHALL confine play to a bounded 2D world larger than the 1600×1200 baseline (WORLD 3200×2400) with obstacles-free movement and SHALL keep the camera centered on the possessed agent within world bounds. Food, refuge, and agent counts SHALL scale with world area as densities rather than fixed constants, keeping per-agent food availability and travel-to-food time within baseline proportions.

#### Scenario: Movement stays in bounds
- **WHEN** the player moves toward any world edge for an extended time
- **THEN** the creature stops at the boundary and never leaves the world

#### Scenario: Larger world stays traversable
- **WHEN** the possessed agent crosses the enlarged world at its species speed
- **THEN** reachable food of its diet lies within a bounded travel time comparable to baseline proportions, because counts scale with area

### Requirement: Keyboard controls for move, eat, shout, shop
The system SHALL support WASD/arrows for movement, E for eat/strike/Pounce/tongue/Dig/Dive (context by species), Q for shout, B to open/close the mid-life shop, H to hide in / exit a nearby fitting refuge, V for species-sense (Topo/Zorro), C to carry/drop/bury a nut (Ardilla), number keys 1-4 to buy shop items, and R to reincarnate from the Judgment screen.

#### Scenario: Basic control mapping
- **WHEN** the user presses movement, E, Q, B, H, V, C, number, or R keys in their valid contexts
- **THEN** the corresponding move, species action, shout, shop toggle, hide toggle, sense, carry, purchase, or reincarnate action occurs

### Requirement: Bushes hold finite fruit and die permanently
The system SHALL spawn 7 living bushes with 3 fruits each per life, SHALL mark a bush permanently dead (grey, no fruit) once its last fruit is eaten, and SHALL mark 1 fruit in every 3rd bush as a mimic poison fruit with a subtly darker tint. Eating a mimic SHALL drain 20 Vida with no karma change.

#### Scenario: Bush exhaustion is permanent for the life
- **WHEN** all fruits of a bush are consumed
- **THEN** the bush remains dead with zero fruit until the next reincarnation generates a fresh world

#### Scenario: Mimic poisons
- **WHEN** the player eats a mimic fruit
- **THEN** Vida drops by 20, no karma changes, and the event is logged as poisoning

### Requirement: Predators wander and chase with contact damage
The system SHALL populate the map with carnivore agents (zorro, lobo) plus a sapo-NPC pressure role covered by sapo agents, where carnivore AI hunts agents of any brain (PLAYER or AI) as well as the possessed agent by the trophic table (zorro: tiers 0-1 agents and mates; lobo: tier 2 agents, grounded halcons, and zorro agents), and sapo agents hop toward oruga agents in perception and snap at contact range. No predator SHALL hunt prey 2+ sizes smaller beyond contact-range snap (optimal foraging); all SHALL lose hidden agents and camp the refuge ~3s before wandering off, and carnivore kills of any agent SHALL spawn fresh carrion.

#### Scenario: Chase and bite
- **WHEN** a Ratón agent (any brain) enters a Zorro's perception range
- **THEN** the Zorro pursues, and on contact Vida drops by 28 and further hits are ignored for 1s

#### Scenario: Zorro ignores distant Oruga
- **WHEN** an Oruga sits 150px from a Zorro
- **THEN** the Zorro keeps wandering (size diff 2) unless the Oruga touches it

#### Scenario: Sapo-NPC pressures T0
- **WHEN** an Oruga player is T0 with a Sapo-NPC on the map
- **THEN** the Sapo-NPC hops toward it in perception range

#### Scenario: Zorro flees Lobo
- **WHEN** a Lobo enters a Zorro NPC's perception range
- **THEN** the Zorro abandons its hunt and flees away from the Lobo

#### Scenario: Lobo only threatens the big
- **WHEN** the player is a T0 or T1 form
- **THEN** no Lobo is on the map

#### Scenario: Camp the hidden
- **WHEN** the player hides in a refuge while chased
- **THEN** the pursuer waits at the refuge ~3s and then returns to wandering

#### Scenario: NPC carnivore hunts fauna
- **WHEN** an AI zorro or lobo kills an AI agent of any brain
- **THEN** a fresh carrion entity spawns at the kill position

### Requirement: Congeners wander and flee when saved
The system SHALL spawn 4 congeners that wander normally and flee from predators after a successful shout.

#### Scenario: Alert saves congeners
- **WHEN** the player shouts successfully
- **THEN** congeners switch to fleeing behavior away from predators

### Requirement: HUD and cause-effect log are always visible
The system SHALL display species/tier, Vida with max, Karma value with polarity, PA, elapsed time, shout cooldown state, hidden state with refuge prompt when near a fitting refuge, carried nut state, species-sense cooldown, and the last 5 cause-effect log entries with good/bad/info polarity.

#### Scenario: Player reads consequences
- **WHEN** any karma-relevant event occurs
- **THEN** the HUD values update immediately and a new log entry appears at the top describing cause and effect

#### Scenario: Refuge prompt appears
- **WHEN** the player stands near a refuge its size fits
- **THEN** a prompt shows the H key and the refuge name

### Requirement: Mid-life shop runs in real time
The system SHALL open the shop overlay on B without pausing the world (predators keep hunting, hunger keeps draining), SHALL close it on B, number-key purchase, or Escape, SHALL list each item with cost, effect, and affordable/owned state, and SHALL log every purchase as a cause-effect entry.

#### Scenario: Shopping under pressure
- **WHEN** the player opens the shop while a predator chases
- **THEN** the predator keeps moving and can still deal contact damage while the overlay is open

#### Scenario: Death wins over shop
- **WHEN** Vida reaches 0 while the shop overlay is open
- **THEN** the shop closes and the Judgment screen appears instead

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

### Requirement: Vegetarian menu
The system SHALL spawn per life, besides 7 berry bushes: 3 apple shrubs (2 apples each, +22/+8), 2 carrot patches (3 carrots each, +18/+5, Ratón/Topo), 4 mushroom clusters (2 mushrooms each, +10/+0, Ratón/Ardilla, 1-in-4 toxic at −20 Vida with tint + Keen-nose reveal), 4 leaf-clumps (3 leaves, +12/+3, Oruga only, regrow 1 per 60s, karma-exempt), 2 oak clumps (3 nuts each, +18/+5, Ardilla/Ratón/Topo, Ardilla-carriable), and 6 wandering insects (+10/+3, Sapo/Topo, respawn 1 per 20s max 6, Sapo tongue range applies). Food catalog:

| Food | Entity | Count | Eaters | Payoff | Twist |
|---|---|---|---|---|---|
| berries | bush | 7×3 | Ratón, Ardilla | +15/+5, last −15K | baseline |
| apples | shrub | 3×2 | Ardilla, Ratón | +22/+8, last −15K | scarce, rich |
| carrots | patch | 2×3 | Ratón, Topo | +18/+5, last −15K | root veg |
| mushrooms | cluster | 4×2 | Ratón, Ardilla | +10/+0, toxic −20 | 1-in-4 toxic |
| leaves | clump | 4×3 | Oruga | +12/+3 | regrow, karma-exempt |
| nuts | oak clump | 2×3 | Ardilla, Ratón, Topo | +18/+5, last −15K | carriable |
| insects | wanderer | 6 | Sapo, Topo | +10/+3 | Sapo +3K deed |

#### Scenario: Toxic mushroom mirrors mimic
- **WHEN** a Ratón eats a toxic mushroom
- **THEN** Vida drops by 20 with no karma change

#### Scenario: Leaves regrow
- **WHEN** a leaf-clump sits stripped for 60s
- **THEN** one leaf has regrown

### Requirement: Lifelike animal rendering
The system SHALL draw each form as a distinct lifelike shape with facing (features rotate toward movement) and motion (2-frame wiggle via time): Oruga 4 rippling segments, Sapo wide ellipse + throat pulse, Ratón circle + ears + tail line, Ardilla circle + big tail arc, Topo dark ellipse + snout dot, Halcón twin flapping triangles, Zorro circle + snout triangle + brush tail. Predator NPCs SHALL reuse their species draw with red outline and scale. Foods SHALL read distinctly: berries red dots, apples larger red, carrots orange triangles, mushrooms cap+stem, leaves green clusters, nuts brown ovals, insects tiny dark dots.

#### Scenario: Silhouettes differ
- **WHEN** all seven forms stand side by side
- **THEN** each is recognizable by shape without reading the HUD
