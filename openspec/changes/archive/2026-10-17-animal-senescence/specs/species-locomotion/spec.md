## MODIFIED Requirements

### Requirement: Gaits preserve existing tactical rules
Locomotion envelopes SHALL NOT change existing tactical semantics: hidden creatures stay frozen; grounded halcon stays at half speed; predator chase multipliers still exceed prey average speed at equal age; topo tunneling MAY ignore rock solids underground while still respecting refuges and plants. Effective displacement SHALL scale by age stage per `animal-senescence` (old legs slower, same gait mode), so prime-vs-frail chases resolve through speed difference: an old hunter may fail to close on prime prey while a prime hunter closes on frail prey.

#### Scenario: Chase still catches
- **WHEN** a prime zorro (trot + chase multiplier) pursues a prime raton (scurry)
- **THEN** it closes distance over time as it does today

#### Scenario: Old hunter loses the young
- **WHEN** a frail zorro pursues a prime raton in the open with equal needs
- **THEN** it closes slower than a prime zorro and may fail to reach kill range before cooldowns or cover intervene

#### Scenario: The mole tunnels under stones
- **WHEN** a topo moves underground across a rock
- **THEN** it passes while rocks still block other species and refuges/plants still interact normally

#### Scenario: Hidden is frozen
- **WHEN** any creature is hidden
- **THEN** no gait displaces it until it exits the refuge
