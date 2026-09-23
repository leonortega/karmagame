# Spec Delta

## MODIFIED Requirements

### Requirement: Judgment matrix maps karma and current PA balance to next tier
The system SHALL compute the next form from the PA balance remaining at death (after all mid-life spending) as: dual T2 ascension (player picks Halcón or Zorro, free) WHEN Karma ≥ +50 AND PA ≥ 100; Sapo (T1) WHEN the dead form is Oruga AND Karma ≥ +20 (redemption hop); Oruga (Tier 0) WHEN Karma ≤ -50 regardless of PA; otherwise lateral cycle within Tier 1 (Ratón → Ardilla → Topo → Sapo → Ratón), defaulting to Ratón from Halcón, Zorro, or Sapo.

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

### Requirement: Judgment offers lateral form choice for PA
The system SHALL offer a Choose-form item on neutral lateral Judgments costing 15 PA that lets the player pick any Tier 1 pool member (Ratón, Ardilla, Topo, Sapo) instead of the forced cycle next, and SHALL deduct the cost from the carried balance when chosen. T2 ascension picks are always free.

#### Scenario: Player buys form choice
- **WHEN** a neutral Judgment offers Ardilla and the player with 40 PA picks Topo via Choose-form
- **THEN** the next life starts as Topo with 25 PA remaining

### Requirement: Judgment screen explains cause and outcome
The system SHALL show final Karma, PA, survived time, the matrix reason, the next species/tier (or the T2 pick buttons on ascension), and the last up-to-4 life events, with a Reincarnar button and R shortcut.

#### Scenario: Player understands why
- **WHEN** Vida reaches 0
- **THEN** the Judgment overlay appears showing stats, reason text, next form or T2 pick, recent history, and a working reincarnate control

### Requirement: Reincarnation resets world and life state
The system SHALL generate a fresh world (bushes with mimics, tier-table predators, congeners, refuges, no carrion), restore full Vida for the new species, reset life timer, per-life history, adaptations, and dug burrows, and apply carried Karma/PA on reincarnate.

#### Scenario: Fresh life with carried progression
- **WHEN** the player confirms reincarnation
- **THEN** a new life starts as the offered species with full Vida, fresh entities, zeroed timer, and carried Karma/PA values
