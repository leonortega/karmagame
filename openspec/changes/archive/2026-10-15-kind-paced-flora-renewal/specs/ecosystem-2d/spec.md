## MODIFIED Requirements

### Requirement: Vegetarian menu
The system SHALL spawn per life the listed initial counts of each food minus `TUNING.floraHeadroom` (2) headroom per kind — these are densities of a living total that regrows and reseeds per `flora-lifecycle` (caps are area-scaled per kind; the headroom lets seedlings mature into new plants during play): 7 berry bushes (3 fruits each, +15/+5), 3 apple shrubs (2 apples each, +22/+8), 2 carrot patches (3 carrots each, +18/+5, Ratón/Topo), 4 mushroom clusters (2 mushrooms each, +10/+0, Ratón/Ardilla, 1-in-4 toxic at −20 Vida with tint + Keen-nose reveal), 4 leaf-clumps (3 leaves, +12/+3, Oruga only, regrow 1 per 30s on the per-kind table, karma-exempt), 2 oak clumps (3 nuts each, +18/+5, Ardilla/Ratón/Topo, Ardilla-carriable), and 6 wandering insects (+10/+3, Sapo/Topo, respawn 1 per 20s max 6, Sapo tongue range applies). Food catalog:

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
- **WHEN** a leaf-clump sits stripped for 30s
- **THEN** one leaf has regrown
