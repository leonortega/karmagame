# ecosystem-2d

## Purpose

Provide the explorable 2D ecosystem (map, food, threats, controls, feedback) where karma decisions happen through visible movement, eating, and alerting.
## Requirements
### Requirement: Bounded world with camera follow
The system SHALL confine play to a bounded 2D world larger than the 1600×1200 baseline (WORLD 3200×2400) and SHALL keep the camera centered on the possessed agent within world bounds. Food, refuge, and agent counts SHALL scale with world area as densities rather than fixed constants. Movement SHALL additionally resolve against static solids (per `solid-terrain`): refuges, rocks, and living plants push agents out with slide.

#### Scenario: Movement stays in bounds
- **WHEN** the player moves toward any world edge for an extended time
- **THEN** the creature stops at the boundary and never leaves the world

#### Scenario: Movement respects solids
- **WHEN** the player or any AI walks into a tree, rock, or living plant
- **THEN** position resolves to the solid's edge and slides around it

#### Scenario: Larger world stays traversable
- **WHEN** the possessed agent crosses the enlarged world at its species speed
- **THEN** reachable food of its diet lies within a bounded travel time comparable to baseline proportions, because counts scale with area

### Requirement: Keyboard controls for move, eat, shout, shop
The system SHALL support WASD/arrows for movement, E for eat/drink/strike/Pounce/tongue/Dig/Dive (context by species and need: drink when thirstier with water in range, eat when hungrier with food in range, kill verbs first for carnivores), Q for shout (only for shouting species: raton, ardilla, topo, sapo), B to open/close the mid-life shop, H to hide in / exit a nearby fitting refuge, V for species-sense (Topo/Zorro only), C to carry/drop/bury a nut (Ardilla only), number keys 1-5 to cast species verbs (1-3 to buy shop items while the shop is open), and R to reincarnate from the Judgment screen only. The controls hint SHALL be rendered per possessed species (shared BASE rows plus species extras) as a list with one entry per usable binding in the right panel, each entry showing live cooldown counters in `(Ns)` style while on cooldown, and SHALL omit R from the in-life panel. Species/tier identity SHALL be displayed separately from cooldown state.

#### Scenario: Basic control mapping
- **WHEN** the user presses movement, E, Q, B, H, V, C, number, or R keys in their valid contexts
- **THEN** the corresponding move, species action, shout, shop toggle, hide toggle, sense, carry, purchase, or reincarnate action occurs

#### Scenario: Controls read as a list
- **WHEN** the player looks at the right panel
- **THEN** each usable key binding for the possessed species appears on its own list row (key in bold plus action), not as a single run-on line

#### Scenario: E drinks when thirsty
- **WHEN** the player presses E with water in drink range and sed deficit exceeding hambre deficit
- **THEN** a drink resolves (sed plus small vida gain) instead of an eat

#### Scenario: Non-shouter sees no Q row
- **WHEN** the player possesses a zorro, halcon, or oruga
- **THEN** the controls list shows no Q row

#### Scenario: Sense rows are species-gated
- **WHEN** the player possesses a form without species-sense
- **THEN** the controls list shows no V row

#### Scenario: Reincarnate stays out of life
- **WHEN** the player is alive and looks at the controls list
- **THEN** no R row appears

### Requirement: Bushes hold finite fruit and die permanently
**Reason**: Replaced — permanent plant death contradicts a living forest. Plants now regrow fruit and repopulate via seedlings (see `flora-lifecycle`); the last-fruit karma penalty and mimic poison rule are unchanged.
**Migration**: Bushes still spawn 7×3 with 1-in-3 mimics; exhaustion is now a slow recovery, not death. The scenario "Bush exhaustion is permanent for the life" is replaced by the regrow scenarios in `flora-lifecycle`.

The system SHALL spawn 7 living bushes with 3 fruits each per life, SHALL mark a bush dead-and-recovering (grey, no fruit) once its last fruit is eaten until its regrow clock revives it, and SHALL mark 1 fruit in every 3rd bush as a mimic poison fruit with a subtly darker tint. Eating a mimic SHALL drain 20 Vida with no karma change.

#### Scenario: Mimic poisons
- **WHEN** the player eats a mimic fruit
- **THEN** Vida drops by 20, no karma changes, and the event is logged as poisoning

#### Scenario: Bush exhaustion is permanent for the life
- **WHEN** all fruits of a bush are consumed
- **THEN** the bush is no longer immediately edible (grey, zero fruit) — its recovery is governed by the regrow clock in `flora-lifecycle`, replacing the old permanent-death rule

#### Scenario: Exhaustion is a slow recovery
- **WHEN** all fruits of a bush are consumed
- **THEN** the bush renders dead for one `fruitRegrow` cycle, then revives with 1 fruit (per `flora-lifecycle`)

### Requirement: Predators wander and chase with contact damage
The system SHALL populate the map with carnivore agents (zorro, lobo) plus a sapo-NPC pressure role covered by sapo agents, where carnivore AI hunts agents of any brain (PLAYER or AI) as well as the possessed agent by the trophic table (zorro: tiers 0-1 agents and mates; lobo: tier 2 agents, grounded halcons, and zorro agents), and sapo agents hop toward oruga agents in perception and snap at contact range. No predator SHALL hunt prey 2+ sizes smaller beyond contact-range snap (optimal foraging); all SHALL lose hidden agents and camp the refuge ~3s before wandering off, and carnivore kills of any agent SHALL spawn fresh carrion. Ground-predator perception SHALL additionally respect trunk cover (per `solid-terrain`); the Halcón is exempt.

#### Scenario: Chase and bite
- **WHEN** a Ratón agent (any brain) enters a Zorro's perception range with clear line of sight
- **THEN** the Zorro pursues, and on contact Vida drops by 28 and further hits are ignored for 1s

#### Scenario: Trunk cover breaks the chase
- **WHEN** a pursued Ratón crosses behind a hollow-tree trunk
- **THEN** the Zorro loses the trail while the segment stays blocked (per `solid-terrain`)

#### Scenario: Zorro ignores distant Oruga
- **WHEN** an Oruga sits 150px from a Zorro
- **THEN** the Zorro keeps wandering (size diff 2) unless the Oruga touches it

#### Scenario: Sapo-NPC pressures T0
- **WHEN** an Oruga player is T0 with a Sapo-NPC on the map
- **THEN** the Sapo-NPC hops toward it in perception range

#### Scenario: Lobo only threatens the big
- **WHEN** the player is a T0 or T1 form
- **THEN** no Lobo is on the map

#### Scenario: Zorro flees Lobo
- **WHEN** a Lobo enters a Zorro NPC's perception range
- **THEN** the Zorro abandons its hunt and flees away from the Lobo

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
The page SHALL use a three-column disposition: a left panel with the emoji legend and the other-animals block, the canvas in the center, and a right panel with the player HUD and the player event feed. The system SHALL display species and tier separately from cooldown state, Vida with max, hambre stock, sed stock, edad as per-species animal-years alongside raw seconds (display-only), Karma value with polarity, PA with icon plus emphasized style, elapsed run time with a clear label, shout cooldown state, hidden state with refuge prompt when near a fitting refuge, carried nut state, and species-sense cooldown in the right panel. Cause-effect entries SHALL be split by subject: player entries (last 5, good/bad/info polarity) go to the right-panel feed, while AI-agent karma entries for all agent species go to the left-panel other-animals feed with the actor species emoji prefixed to the existing text. The left-panel other-animals block SHALL hold a single heading with the agent roster rows (icon, karma, vida, last deed) above the other-animals event feed, and the roster format SHALL NOT change in this change. Only karma entries SHALL appear in either feed.

#### Scenario: Player reads consequences
- **WHEN** any karma-relevant event occurs
- **THEN** the HUD values update immediately and a new log entry appears at the top of the matching feed describing cause and effect

#### Scenario: AI deeds stay out of the player feed
- **WHEN** an AI agent earns karma through its own verbs
- **THEN** the entry appears in the left-panel other-animals feed and the right-panel player feed is unchanged

#### Scenario: Refuge prompt appears
- **WHEN** the player stands near a refuge its size fits
- **THEN** a prompt shows the H key and the refuge name

#### Scenario: Needs read at a glance
- **WHEN** hambre drops below its regen threshold or sed drops below its regen threshold
- **THEN** the corresponding bar shows the shortfall state immediately without opening any overlay

#### Scenario: Every species deed reaches the left feed with emoji
- **WHEN** an AI agent of any species earns karma (including shouts and hunts that previously logged empty text)
- **THEN** the left-panel feed prepends an entry starting with that species emoji followed by the deed text

### Requirement: Mid-life shop runs in real time
The system SHALL open the shop overlay on B without pausing the world (predators keep hunting, hunger keeps draining), SHALL close it on B, number-key purchase, or Escape, SHALL list each item with cost, effect, and affordable/owned state, and SHALL log every purchase as a cause-effect entry.

#### Scenario: Shopping under pressure
- **WHEN** the player opens the shop while a predator chases
- **THEN** the predator keeps moving and can still deal contact damage while the overlay is open

#### Scenario: Death wins over shop
- **WHEN** Vida reaches 0 while the shop overlay is open
- **THEN** the shop closes and the Judgment screen appears instead

### Requirement: Refuges gate hiding by size
The system SHALL spawn per life 3 burrow-S (max size 1), 3 burrow-M (max size 2), 2 hollow-trees (max size 2, climbers only: Ardilla), 2 thorn-bushes (max size 2), and 2 old-oaks (max size 3, no fruit, canopy cover vs ground predators; the Halcón is exempt — see `flora-lifecycle`). Hiding SHALL require size fit, SHALL freeze movement and eating while hidden, SHALL keep hunger and thirst draining, SHALL suspend vida regen while hidden unless both needs stay above threshold, and SHALL end on H or on death.

#### Scenario: Too big to hide
- **WHEN** a Zorro (size 3) presses H near a burrow-M
- **THEN** nothing happens and a message states it does not fit

#### Scenario: Hiding costs time not safety forever
- **WHEN** the player hides for 30s
- **THEN** Vida has drained for 30s of hunger while predators lost the trail

#### Scenario: Old oak fits the mid-sized
- **WHEN** a Ratón or Zorro (size ≤ 3) presses H near an old-oak
- **THEN** it hides under the canopy; ground predators lose the trail while the Halcón does not

#### Scenario: Hiding drains thirst too
- **WHEN** the player hides for 30s without drinking
- **THEN** sed has drained for 30s exactly as hambre did, and vida regen stayed suspended unless both needs held above threshold

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
The system SHALL spawn per life the listed initial counts of each food — these are densities of a living total that regrows and reseeds per `flora-lifecycle` (caps are area-scaled per kind): 7 berry bushes (3 fruits each, +15/+5), 3 apple shrubs (2 apples each, +22/+8), 2 carrot patches (3 carrots each, +18/+5, Ratón/Topo), 4 mushroom clusters (2 mushrooms each, +10/+0, Ratón/Ardilla, 1-in-4 toxic at −20 Vida with tint + Keen-nose reveal), 4 leaf-clumps (3 leaves, +12/+3, Oruga only, regrow 1 per 60s, karma-exempt), 2 oak clumps (3 nuts each, +18/+5, Ardilla/Ratón/Topo, Ardilla-carriable), and 6 wandering insects (+10/+3, Sapo/Topo, respawn 1 per 20s max 6, Sapo tongue range applies). Food catalog:

| Food | Entity | Count | Eaters | Payoff | Twist |
|---|---|---|---|---|---|
| berries | bush | 7×3 | Ratón, Ardilla | +15/+5, last −15K | regrows, reseeds |
| apples | shrub | 3×2 | Ardilla, Ratón | +22/+8, last −15K | regrows, reseeds |
| carrots | patch | 2×3 | Ratón, Topo | +18/+5, last −15K | regrows, reseeds |
| mushrooms | cluster | 4×2 | Ratón, Ardilla | +10/+0, toxic −20 | 1-in-4 toxic, reseeds |
| leaves | clump | 4×3 | Oruga | +12/+3 | regrow, karma-exempt |
| nuts | oak clump | 2×3 | Ardilla, Ratón, Topo | +18/+5, last −15K | carriable, plantable |
| insects | wanderer | 6 | Sapo, Topo | +10/+3 | Sapo +3K deed |

#### Scenario: Toxic mushroom mirrors mimic
- **WHEN** a Ratón eats a toxic mushroom
- **THEN** Vida drops by 20 with no karma change

#### Scenario: Leaves regrow
- **WHEN** a leaf-clump sits stripped for 60s
- **THEN** one leaf has regrown

### Requirement: Lifelike animal rendering
The system SHALL draw every world entity as a cohesive emoji glyph over a solid opaque color medal with a size tier by category: animals at animal size with per-species offsets (medal in species color), plants/foods at food size (medal in type color), terrain and small decor at terrain size, except landmark trees (old-oak, hollow-tree) which render larger as landscape anchors. Each form SHALL use its established species emoji, each food its food emoji, each refuge/rock/seedling its terrain emoji, rendered through shared helpers that apply category size, medal backing, shadow, and facing. Vector portrait painters SHALL NOT be the primary sprite. Info overlays SHALL remain: label pills with food counts and refuge names, HP bars with karma over agents, predator outline rings, reveal/tracking rings, vision circle, meadow, and grid. Depleted patches SHALL render a cross with a recovering tag, carrion SHALL use a per-stage icon (fresh, stale, rotten) with a freshness label, and oak-tree seedlings SHALL render as a young tree. Predator NPCs SHALL reuse their species emoji at animal size with a red outline and warning glyph. The legend SHALL live only in the left HTML panel and SHALL NOT be drawn on the canvas; the game-state warning texts (exposed, hidden, grounded, camouflaged, curled) SHALL be drawn right-aligned on the canvas as UI chrome text.

#### Scenario: Silhouettes differ
- **WHEN** all seven forms stand side by side
- **THEN** each is recognizable by its emoji glyph without reading the HUD

#### Scenario: The map reads at a glance
- **WHEN** any gameplay moment is frozen
- **THEN** foods, refuges, rocks, and animals are identifiable by emoji kind and size tier, not only by color

#### Scenario: Size tiers by category
- **WHEN** an animal, a food patch, and a rock appear together
- **THEN** the animal glyph renders largest, the food glyph medium, and the rock/decor glyph smallest, except landmark trees (old-oak, hollow-tree) which render larger as landscape anchors

#### Scenario: Apex reads larger than prey
- **WHEN** a Lobo and an Oruga appear together
- **THEN** the Lobo emoji renders larger than the Oruga emoji within the animal band

### Requirement: Infinite water bodies dot the map
The system SHALL seed infinite charcos (tiny, scattered) and lagos (large landscape anchors, few) as drinkable terrain with counts scaled by world area as densities, SHALL render each as a blue body scaled to its radius with its distinct water glyph and label kept on top, and SHALL persist them across reincarnation like refuges and rocks. Only water SHALL exist inside: all other scatters SHALL avoid water interiors.

#### Scenario: Water is reachable by density
- **WHEN** the possessed agent crosses the enlarged world at its species speed
- **THEN** a drinkable charco or lago lies within a bounded travel time comparable to food proportions, because counts scale with area

#### Scenario: Lago reads as a lake, charco as a puddle
- **WHEN** a lago and a charco appear on screen together
- **THEN** the lago renders as a visibly larger blue body than the charco, each keeping its water glyph and label

#### Scenario: Nothing else spawns inside
- **WHEN** the world seeds food, refuges, rocks, or agents
- **THEN** every placed entity lands outside all water radii

### Requirement: Insects cluster at lagos
The system SHALL bias insect respawns to a shore ring around lagos (never inside the water) while keeping the existing respawn cadence (1 per 20s, max 6) and wander behavior, so lake shores visibly hold more insects for Sapo/Topo hunters.

#### Scenario: Shore respawn bias
- **WHEN** an insect respawns with a lago on the map
- **THEN** it appears in the shore ring around the lago far more often than at a uniform random point, and never inside the water

### Requirement: Shoreline predation without new targeting
The system SHALL let existing pursuit plus water solids produce shoreline hunting with no trophic change: a zorro SHALL chase a sapo to the nearest shore point and bite across it within existing contact/kill ranges; a lobo SHALL NOT begin hunts for sapo by water alone though contact damage still applies; water SHALL NOT break perception, and hiding/camping rules for H-refuges SHALL NOT apply to water.

#### Scenario: Zorro works the rim
- **WHEN** a zorro pursues a sapo that enters a lago
- **THEN** the zorro closes to the nearest shore point and deals contact damage whenever the sapo is within the existing reach across the shore

#### Scenario: No camp timer for water
- **WHEN** a sapo sits deep inside a lago beyond contact reach
- **THEN** the pursuer does not enter a refuge-camp state for the water; it continues by its existing wander/hunt rules

