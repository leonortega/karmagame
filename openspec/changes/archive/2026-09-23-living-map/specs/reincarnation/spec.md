# Spec Delta

## MODIFIED Requirements

### Requirement: Judgment matrix maps karma and current PA balance to next tier
The system SHALL compute the next form from the PA balance remaining at death (after all mid-life spending) as: dual T2 ascension (player picks Halcón or Zorro, free) WHEN Karma ≥ +50 AND PA ≥ 100; Sapo (T1) WHEN the dead form is Oruga AND Karma ≥ +20 (redemption hop); Oruga (Tier 0) WHEN Karma ≤ -50 regardless of PA; otherwise lateral cycle within Tier 1 (Ratón → Ardilla → Topo → Sapo → Ratón), defaulting to Ratón from Halcón, Zorro, Lobo, or Sapo. The first life is exempt: its form comes from the start-select screen, not the matrix. Lobo is never matrix-assigned; it is reachable only via start-select.

#### Scenario: Ascension to predator
- **WHEN** a life ends with Karma +60 and PA 120
- **THEN** the Judgment offers Halcón and Zorro as a free pick with an ascension reason citing both thresholds

#### Scenario: Involution as punishment
- **WHEN** a life ends with Karma -70 even with PA 200
- **THEN** the offered next form is Oruga with an involution reason citing Karma ≤ -50

#### Scenario: Neutral lateral adaptation
- **WHEN** a life ends with Karma +10 and PA 40 as Ratón
- **THEN** the offered next form is Ardilla with a neutral-adaptation reason

#### Scenario: Good Oruga becomes Sapo
- **WHEN** an Oruga life ends with Karma +25 and PA 30
- **THEN** the offered next form is Sapo with a redemption reason

#### Scenario: First life skips the matrix
- **WHEN** the run starts and the player picks Lobo on the start screen
- **THEN** the first life begins as Lobo with no karma or PA thresholds evaluated

### Requirement: Reincarnation resets world and life state
The system SHALL keep the persistent world across reincarnation (food, carrion ages, refuges, surviving agents and their positions/HP all carry over), SHALL possess or spawn the next-form agent at full Vida for the new species, and SHALL reset only life-scoped state: life timer, per-life history, adaptations, carried nut, and dug-burrow count. Carried Karma (20% rounded) and remaining PA apply to the newly possessed agent, and sapling-carry still converts to extra berry bushes (capped at +3) added to the persistent world. The full-regen fresh world is removed.

#### Scenario: Fresh life with carried progression
- **WHEN** the player confirms reincarnation
- **THEN** a new life starts as the offered species with full Vida in the same world with carried Karma/PA values and zeroed timer

#### Scenario: Planted saplings sprout
- **WHEN** a life ended with 2 sapling carry banked
- **THEN** 2 extra berry bushes are added to the persistent world and sapling carry resets to 0

#### Scenario: World persists across death
- **WHEN** the player dies with stripped bushes and aging carrion on the map
- **THEN** after reincarnation the same bushes are still stripped and carrion ages continue from their values at death
