## ADDED Requirements

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

## MODIFIED Requirements

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
