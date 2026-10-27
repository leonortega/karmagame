## MODIFIED Requirements

### Requirement: Prey base covers hunter mouths

The system SHALL hold the invariant that edible prey (oruga, sapo, raton, ardilla, topo) outnumber active hunters (zorro, lobo, halcon - the species whose trophic data lists animal prey) by at least 3 to 1 after every roll, with orugas as the designated feeder surplus hunted by all predators. No pressure-only species or morph SHALL count toward or reserve a census slot.

#### Scenario: Lean rolls stay huntable

- **WHEN** a lean roll completes
- **THEN** the prey-to-hunter ratio is still at least 3:1 and at least 4 orugas are present

### Requirement: T0 draws soften early predation

The system SHALL soften early predation when the drawn player species is tier 0: the rolled fauna are the only pressure (halcon by its prey-size rule and zorro by contact snap), spawn offset from prey clusters, and lobo agents SHALL NOT begin hunts against T0/T1 agents by water or spawn pressure alone (contact damage still applies per the trophic table). No extra scripted predator or pressure morph SHALL spawn for a T0 start, and the sapo census slot SHALL NOT be reserved for one.

#### Scenario: Oruga start is tense but survivable

- **WHEN** a new game starts with the player as oruga
- **THEN** the rolled fauna predators are present at their rolled counts, offset from the oruga cluster, and no extra scripted predator or pressure morph spawns on top of them
