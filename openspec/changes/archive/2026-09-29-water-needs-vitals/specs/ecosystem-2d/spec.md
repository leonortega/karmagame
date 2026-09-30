## ADDED Requirements

### Requirement: Infinite water bodies dot the map
The system SHALL seed infinite charcos (small, scattered) and lagos (large, few) as drinkable terrain with counts scaled by world area as densities, SHALL render each with a distinct water glyph and drink radius, and SHALL persist them across reincarnation like refuges and rocks.

#### Scenario: Water is reachable by density
- **WHEN** the possessed agent crosses the enlarged world at its species speed
- **THEN** a drinkable charco or lago lies within a bounded travel time comparable to food proportions, because counts scale with area

### Requirement: Insects cluster at lagos
The system SHALL bias insect respawns near lagos while keeping the existing respawn cadence (1 per 20s, max 6) and wander behavior, so lake shores visibly hold more insects for Sapo/Topo hunters.

#### Scenario: Shore respawn bias
- **WHEN** an insect respawns with a lago on the map
- **THEN** it appears within lake-shore range far more often than at a uniform random point

## MODIFIED Requirements

### Requirement: Keyboard controls for move, eat, shout, shop
The system SHALL support WASD/arrows for movement, E for eat/drink/strike/Pounce/tongue/Dig/Dive (context by species and need: drink when thirstier with water in range, eat when hungrier with food in range, kill verbs first for carnivores), Q for shout, B to open/close the mid-life shop, H to hide in / exit a nearby fitting refuge, V for species-sense (Topo/Zorro), C to carry/drop/bury a nut (Ardilla), number keys 1-4 to buy shop items, and R to reincarnate from the Judgment screen.

#### Scenario: Basic control mapping
- **WHEN** the user presses movement, E, Q, B, H, V, C, number, or R keys in their valid contexts
- **THEN** the corresponding move, species action, shout, shop toggle, hide toggle, sense, carry, purchase, or reincarnate action occurs

#### Scenario: E drinks when thirsty
- **WHEN** the player presses E with water in drink range and sed deficit exceeding hambre deficit
- **THEN** a drink resolves (sed plus small vida gain) instead of an eat

### Requirement: HUD and cause-effect log are always visible
The system SHALL display species/tier, Vida with max, hambre stock, sed stock, edad counter, Karma value with polarity, PA, elapsed time, shout cooldown state, hidden state with refuge prompt when near a fitting refuge, carried nut state, species-sense cooldown, and the last 5 cause-effect log entries with good/bad/info polarity.

#### Scenario: Player reads consequences
- **WHEN** any karma-relevant event occurs
- **THEN** the HUD values update immediately and a new log entry appears at the top describing cause and effect

#### Scenario: Refuge prompt appears
- **WHEN** the player stands near a refuge its size fits
- **THEN** a prompt shows the H key and the refuge name

#### Scenario: Needs read at a glance
- **WHEN** hambre drops below its regen threshold or sed drops below its regen threshold
- **THEN** the corresponding bar shows the shortfall state immediately without opening any overlay

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
