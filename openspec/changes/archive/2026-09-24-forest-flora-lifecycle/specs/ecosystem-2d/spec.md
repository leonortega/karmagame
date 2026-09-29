# Spec Delta: ecosystem-2d

## Purpose

The forest biome becomes self-renewing: the "bushes die permanently" rule is replaced by regrowth and reproduction, the vegetarian menu's counts become initial densities over a living total, and the refuge table gains the old-oak canopy.

## MODIFIED Requirements

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

### Requirement: Refuges gate hiding by size
The system SHALL spawn per life 3 burrow-S (max size 1), 3 burrow-M (max size 2), 2 hollow-trees (max size 2, climbers only: Ardilla), 2 thorn-bushes (max size 2), and 2 old-oaks (max size 3, no fruit, canopy cover vs ground predators; the Halcón is exempt — see `flora-lifecycle`). Hiding SHALL require size fit, SHALL freeze movement and eating while hidden, SHALL keep hunger draining, and SHALL end on H or on death.

#### Scenario: Too big to hide
- **WHEN** a Zorro (size 3) presses H near a burrow-M
- **THEN** nothing happens and a message states it does not fit

#### Scenario: Hiding costs time not safety forever
- **WHEN** the player hides for 30s
- **THEN** Vida has drained for 30s of hunger while predators lost the trail

#### Scenario: Old oak fits the mid-sized
- **WHEN** a Ratón or Zorro (size ≤ 3) presses H near an old-oak
- **THEN** it hides under the canopy; ground predators lose the trail while the Halcón does not

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
The system SHALL draw each form as a distinct lifelike shape with facing (features rotate toward movement) and motion (2-frame wiggle via time): Oruga 4 rippling segments, Sapo wide ellipse + throat pulse, Ratón circle + ears + tail line, Ardilla circle + big tail arc, Topo dark ellipse + snout dot, Halcón twin flapping triangles, Zorro circle + snout triangle + brush tail. Predator NPCs SHALL reuse their species draw with red outline and scale. Foods SHALL read distinctly: berries red dots, apples larger red, carrots orange triangles, mushrooms cap+stem, leaves green clusters, nuts brown ovals, insects tiny dark dots. Flora ages SHALL render distinctly: seedling sprout, young-oak mid trunk, old-oak large canopy.

#### Scenario: Silhouettes differ
- **WHEN** all seven forms stand side by side
- **THEN** each is recognizable by shape without reading the HUD
