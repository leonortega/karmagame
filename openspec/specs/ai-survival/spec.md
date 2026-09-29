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
When an AI grazer's HP is below 40% of max, it SHALL skip grooming (Ratón), digging (Topo), and planting (Ardilla drops a carried nut before eating) and go straight to food-seeking/eating. An AI Oruga or Sapo at low HP SHALL NOT hold still for curl/camouflage while food is available.

#### Scenario: Starving Raton skips grooming
- **WHEN** an AI Raton at 30% HP stands next to a mate and a berry patch
- **THEN** it eats instead of grooming

#### Scenario: Starving Ardilla drops the nut
- **WHEN** an AI Ardilla at 35% HP carries a nut with food nearby
- **THEN** it drops the carried nut and eats

### Requirement: AI hides in refuges when hunted
When a predator of its fear table (or any role-hunter predator for prey species) is within perception, an AI grazer near a fitting refuge (≤ hide-range) SHALL enter it: `hidden = true` with the refuge as `hideRef`, for up to `aiHideMax` seconds. While hidden, ground predators SHALL lose the agent per existing hide rules. The AI SHALL exit when danger passes or `aiHideMax` expires. Hunger SHALL keep draining while hidden.

#### Scenario: Raton hides from the fox
- **WHEN** a Zorro hunts an AI Raton standing within hide-range of a burrow-M
- **THEN** the Raton enters the refuge, becomes untargeted per hide rules, and exits when the Zorro leaves or 5s pass

#### Scenario: Hiding costs food
- **WHEN** an AI stays hidden for 5s
- **THEN** its HP drained by hunger for those 5s and it did not eat

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

