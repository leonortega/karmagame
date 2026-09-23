# reincarnation

## Purpose

Turn death into a legible judgment that maps Karma and PA to the next body, preserving progression while making the reason for each reincarnation explicit.

## Requirements

### Requirement: Judgment matrix maps karma and current PA balance to next tier
The system SHALL compute the next form from the PA balance remaining at death (after all mid-life spending) as: dual T2 ascension (player picks Halcón or Zorro, free) WHEN Karma ≥ +50 AND PA ≥ 100; Sapo (T1) WHEN the dead form is Oruga AND Karma ≥ +20 (redemption hop); Oruga (Tier 0) WHEN Karma ≤ -50 regardless of PA; otherwise lateral cycle within Tier 1 (Ratón → Ardilla → Topo → Sapo → Ratón), defaulting to Ratón from Halcón, Zorro, or Sapo. Lobo is never matrix-assigned; it is reachable only via start-select. The first life is exempt: its form comes from the start-select screen, not the matrix.

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

### Requirement: Karma carries 20% and remaining PA persists
The system SHALL start the next life with Karma equal to 20% of the previous final Karma (rounded) and SHALL carry the remaining PA balance unchanged (spent PA never returns).

#### Scenario: Soft redemption across lives
- **WHEN** a life ends with Karma +50 or -50
- **THEN** the next life starts at Karma +10 or -10 respectively with identical PA

#### Scenario: Spending lowers ascension chances
- **WHEN** a life earns 120 PA but spends 50 mid-life
- **THEN** Judgment evaluates the remaining 70 PA, which alone does not meet the 100 threshold

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

### Requirement: Reincarnation keeps persistent world
The system SHALL keep the persistent world across reincarnation (food, carrion, agents carry over; saplings convert in place); the first life is exempt from the judgment matrix via startRun(). The new life restores full Vida, resets life timer and per-life history, adaptations, carried nut, and dug burrows, and applies carried Karma/PA.

#### Scenario: World survives death
- **WHEN** the player confirms reincarnation
- **THEN** uneaten food, unconsumed carrion, and surviving AI agents remain in the same world; the new life starts with full Vida and carried Karma/PA

#### Scenario: Planted saplings convert in place
- **WHEN** a life ended with 2 sapling carry banked
- **THEN** the next world holds those saplings converted to berry bushes and sapling carry resets to 0
