# Spec Delta

## MODIFIED Requirements

### Requirement: Keyboard controls for move, eat, shout, shop
The system SHALL support WASD/arrows for movement, E for eat/strike/Pounce/tongue/Dig/Dive (context by species), Q for shout, B to open/close the mid-life shop, H to hide in / exit a nearby fitting refuge, V for species-sense (Topo/Zorro), C to carry/drop/bury a nut (Ardilla), number keys 1-4 to buy shop items, and R to reincarnate from the Judgment screen.

#### Scenario: Basic control mapping
- **WHEN** the user presses movement, E, Q, B, H, V, C, number, or R keys in their valid contexts
- **THEN** the corresponding move, species action, shout, shop toggle, hide toggle, sense, carry, purchase, or reincarnate action occurs

### Requirement: Predators wander and chase with contact damage
The system SHALL spawn predators by tier table (player T0: 1 Zorro + 1 Sapo-NPC; player T1: 2 Zorro; player T2: 1 Zorro + 1 Lobo), where Sapo-NPCs hop toward Oruga players in perception and snap at contact range, Zorro NPCs hunt the player (T0/T1 forms except Oruga beyond contact range), congeners, and flee Lobo, and the Lobo NPC hunts T2 players, grounded Halcóns, and Zorro NPCs. No predator SHALL hunt prey 2+ sizes smaller beyond contact-range snap (optimal foraging); all SHALL lose hidden players and camp the refuge ~3s before wandering off, and Zorro kills of congeners SHALL spawn fresh carrion.

#### Scenario: Chase and bite
- **WHEN** a Ratón enters a Zorro's perception range
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

#### Scenario: Kills feed scavengers
- **WHEN** a Zorro NPC kills a congener
- **THEN** a fresh carrion entity spawns at the kill position

### Requirement: HUD and cause-effect log are always visible
The system SHALL display species/tier, Vida with max, Karma value with polarity, PA, elapsed time, shout cooldown state, hidden state with refuge prompt when near a fitting refuge, carried nut state, species-sense cooldown, and the last 5 cause-effect log entries with good/bad/info polarity.

#### Scenario: Player reads consequences
- **WHEN** any karma-relevant event occurs
- **THEN** the HUD values update immediately and a new log entry appears at the top describing cause and effect

#### Scenario: Refuge prompt appears
- **WHEN** the player stands near a refuge its size fits
- **THEN** a prompt shows the H key and the refuge name

## ADDED Requirements

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
