# species-locomotion

## Purpose

Every species moves like its real-world counterpart instead of uniform sliding: gaits are data (a LOCO table) consumed by one shared stepping function used by both player and AI, so the whole forest moves like the ecosystem it depicts.
## Requirements
### Requirement: Each species moves with its signature gait
The game SHALL define a LOCO table entry per species with `mode` and cadence constants in TUNING, and `locoStep` SHALL modulate effective movement per tick: sapo `hop` (impulse burst + forced pause), oruga `inchworm` (stretch-freeze-burst), raton `scurry` (continuous, current feel), ardilla `bound` (gallop envelope), topo `tunnel` (continuous at reduced speed), halcon `glide` (smooth air, half speed grounded), zorro/lobo `trot` (continuous). No species SHALL slide continuously under a mode that is not continuous.

#### Scenario: The sapo jumps, it does not walk
- **WHEN** the player holds a direction as sapo
- **THEN** it advances in impulse bursts separated by pauses (hop cadence), never steady sliding

#### Scenario: The oruga inches
- **WHEN** the oruga travels toward food
- **THEN** its displacement comes in stretch-freeze-burst cycles, slower on average than a raton scurry

#### Scenario: Continuous species stay continuous
- **WHEN** raton, ardilla, halcon (airborne), zorro or lobo hold a direction
- **THEN** movement is continuous per their mode, with halcon grounded still at half speed

### Requirement: One shared locomotion step for player and AI
Player movement and AI movement SHALL both pass through `locoStep` (AI displacement via a `moveToward` helper that consumes the same envelope), so every gait is ecosystem-wide.

#### Scenario: An AI sapo hops like the player's
- **WHEN** an AI sapo travels toward prey or cover
- **THEN** its displacement uses the same hop cadence as the player's sapo

### Requirement: Gaits preserve existing tactical rules
Locomotion envelopes SHALL NOT change existing tactical semantics: hidden creatures stay frozen; grounded halcon stays at half speed; predator chase multipliers still exceed prey average speed; topo tunneling MAY ignore rock solids underground while still respecting refuges and plants.

#### Scenario: Chase still catches
- **WHEN** a zorro (trot + chase multiplier) pursues a raton (scurry)
- **THEN** it closes distance over time as it does today

#### Scenario: The mole tunnels under stones
- **WHEN** a topo moves underground across a rock
- **THEN** it passes while rocks still block other species and refuges/plants still interact normally

#### Scenario: Hidden is frozen
- **WHEN** any creature is hidden
- **THEN** no gait displaces it until it exits the refuge
