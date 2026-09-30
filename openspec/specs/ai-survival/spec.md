# ai-survival Specification

## Purpose
AI animals feed themselves, survive hunts, and use cover: they seek food beyond contact range, prioritize eating when starving, flee toward cover, and hide for real inside refuges. Predators scavenge before hunting when weak. The ecosystem sustains itself instead of thinning out.
## Requirements
### Requirement: AI grazers seek food beyond contact range
Every grazer species SHALL, when no food is within eat-range, move toward the nearest diet patch within `SPECIES.vision × forageRangeMult` instead of idling. Arrival at eat-range resolves eating through the normal eat functions. Insects count as food for insectivores the same way.

#### Scenario: Raton crosses the gap
- **WHEN** an AI Raton with no food in eat-range has a berry bush 90px away (within vision × 0.5 = 95px)
- **THEN** it moves toward the bush each tick until eat-range is reached, then eats

#### Scenario: Nothing edible in range
- **WHEN** no diet patch lies within forage range
- **THEN** the AI keeps its existing idle behavior (wander jitter, stillness verbs)

### Requirement: Hunger overrides secondary behaviors
When an AI grazer's HP is below 40% of max, or its hambre or sed is below its regen threshold with the corresponding resource available, it SHALL skip grooming (Ratón), digging (Topo), and planting (Ardilla drops a carried nut before eating) and go straight to food-seeking/eating or water-seeking/drinking by need. An AI Oruga or Sapo at low HP SHALL NOT hold still for curl/camouflage while food or water is available.

#### Scenario: Starving Raton skips grooming
- **WHEN** an AI Raton at 30% HP stands next to a mate and a berry patch
- **THEN** it eats instead of grooming

#### Scenario: Starving Ardilla drops the nut
- **WHEN** an AI Ardilla at 35% HP carries a nut with food nearby
- **THEN** it drops the carried nut and eats

#### Scenario: Parched Topo skips digging
- **WHEN** an AI Topo with sed below threshold has a charco in forage range
- **THEN** it moves to drink instead of digging a burrow

### Requirement: AI hides in refuges when hunted
When a predator of its fear table (or any role-hunter predator for prey species) is within perception, an AI grazer near a fitting refuge (≤ hide-range) SHALL enter it: `hidden = true` with the refuge as `hideRef`, for up to `aiHideMax` seconds. While hidden, ground predators SHALL lose the agent per existing hide rules. The AI SHALL exit when danger passes or `aiHideMax` expires. Hunger and thirst SHALL keep draining while hidden.

#### Scenario: Raton hides from the fox
- **WHEN** a Zorro hunts an AI Raton standing within hide-range of a burrow-M
- **THEN** the Raton enters the refuge, becomes untargeted per hide rules, and exits when the Zorro leaves or 5s pass

#### Scenario: Hiding costs food
- **WHEN** an AI stays hidden for 5s
- **THEN** its HP drained by hunger for those 5s and it did not eat

#### Scenario: Hiding costs water too
- **WHEN** an AI stays hidden for 5s without drinking
- **THEN** its sed drained alongside hunger and vida regen stayed suspended unless both needs held above threshold

### Requirement: Fleeing biases toward cover
When an AI flees a feared predator, its escape vector SHALL blend toward the nearest fitting refuge within 250px (majority weight on escape). Pure away-fleeing remains when no refuge is near.

#### Scenario: Escape arcs to the tree
- **WHEN** an AI Ardilla flees a Lobo with an old-oak 150px to the side
- **THEN** its flee path bends toward the old-oak instead of straight away

### Requirement: Hungry predators scavenge first
A predator AI at HP below 40% SHALL prefer carrion within its perception over hunting live prey. Above that threshold, hunting behavior is unchanged.

#### Scenario: Weak Lobo eats carrion instead of chasing
- **WHEN** a Lobo at 30% HP has fresh carrion 200px away and a zorro 100px away
- **THEN** it walks to the carrion and eats it

#### Scenario: Healthy Lobo hunts normally
- **WHEN** a Lobo at 80% HP has both carrion and prey available
- **THEN** hunting behavior is unchanged (prey first, per existing rules)

### Requirement: AI seeks water beyond contact range
Every species SHALL, when no water is within drink-range, sed is below its regen threshold, and sed deficit exceeds hambre deficit, move toward the nearest charco or lago within `SPECIES.vision × forageRangeMult` instead of idling. Arrival at drink-range resolves drinking through the normal drink function. Thirstier animals SHALL prefer water over food when both are in forage range. Sated animals SHALL NOT detour to water (no travel on a tied full tank; the E-tie-drinks rule covers co-located food and water at zero travel cost).

#### Scenario: Thirsty Raton crosses to the charco
- **WHEN** an AI Raton with sed deficit above hambre deficit has a charco 90px away (within vision × 0.5 = 95px) and no water in drink-range
- **THEN** it moves toward the charco each tick until drink-range is reached, then drinks

#### Scenario: Hunger wins when hungrier
- **WHEN** an AI Raton is hungrier than thirsty with both a berry bush and a charco in forage range
- **THEN** it moves toward the bush first

#### Scenario: Nothing drinkable in range
- **WHEN** no water lies within forage range
- **THEN** the AI falls back to existing food-seeking or idle behavior unchanged

