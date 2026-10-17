## MODIFIED Requirements

### Requirement: AI hides in refuges when hunted
When a predator of its fear table (or any role-hunter predator for prey species) is within perception, an AI grazer near a fitting refuge (≤ hide-range) SHALL enter it: `hidden = true` with the refuge as `hideRef`, for up to `aiHideMax` seconds. Frail animals SHALL weigh hiding over outrunning (they hide on weaker threat signals and at longer ranges than prime animals of the same species). While hidden, ground predators SHALL lose the agent per existing hide rules. The AI SHALL exit when danger passes or `aiHideMax` expires. Hunger and thirst SHALL keep draining while hidden.

#### Scenario: Raton hides from the fox
- **WHEN** a Zorro hunts an AI Raton standing within hide-range of a burrow-M
- **THEN** the Raton enters the refuge, becomes untargeted per hide rules, and exits when the Zorro leaves or 5s pass

#### Scenario: Old raton holes up earlier
- **WHEN** a frail AI Raton senses a prime Zorro at the edge of perception with a refuge in range
- **THEN** it hides while a prime Raton in the same spot keeps foraging until the threat closes

#### Scenario: Hiding costs food
- **WHEN** an AI stays hidden for 5s
- **THEN** its HP drained by hunger for those 5s and it did not eat

#### Scenario: Hiding costs water too
- **WHEN** an AI stays hidden for 5s without drinking
- **THEN** its sed drained alongside hunger and vida regen stayed suspended unless both needs held above threshold

### Requirement: Fleeing biases toward cover
When an AI flees a feared predator, its escape vector SHALL blend toward the nearest fitting refuge within 250px (majority weight on escape). Frail animals SHALL bias harder toward cover (they cannot win open-field races), while prime animals MAY hold straighter away-lines. Pure away-fleeing remains when no refuge is near.

#### Scenario: Escape arcs to the tree
- **WHEN** a prime AI Ardilla flees a Lobo with an old-oak 150px to the side
- **THEN** its flee path bends toward the old-oak instead of straight away

#### Scenario: Old prey commits to cover
- **WHEN** a frail AI Ardilla flees with the same geometry
- **THEN** its path commits to the refuge sooner and tighter than the prime one's

### Requirement: Hungry predators scavenge first
A predator AI at HP below 40% or in worn/frail stage SHALL prefer carrion within its perception over hunting live prey; frail hunters SHALL also refuse hunts their age-scaled damage cannot win (prime healthy prey out of reach). Above that threshold, hunting behavior is unchanged.

#### Scenario: Weak Lobo eats carrion instead of chasing
- **WHEN** a Lobo at 30% HP has fresh carrion 200px away and a zorro 100px away
- **THEN** it walks to the carrion and eats it

#### Scenario: Old Zorro skips the unwinnable pounce
- **WHEN** a frail Zorro at full HP senses only prime prey its scaled damage cannot kill plus fresh carrion in perception
- **THEN** it seeks the carrion instead of burning pounce on a doomed chase

#### Scenario: Healthy Lobo hunts normally
- **WHEN** a prime Lobo at 80% HP has both carrion and prey available
- **THEN** hunting behavior is unchanged (prey first, per existing rules)
