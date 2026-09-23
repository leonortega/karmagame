# Spec Delta

## Purpose

Turn death into a legible judgment that maps Karma and PA to the next body, preserving progression while making the reason for each reincarnation explicit.

## ADDED Requirements

### Requirement: Judgment matrix maps karma and current PA balance to next tier
The system SHALL compute the next form from the PA balance remaining at death (after all mid-life spending) as: Halcón (Tier 2) WHEN Karma ≥ +50 AND PA ≥ 100; Oruga (Tier 0) WHEN Karma ≤ -50 regardless of PA; otherwise lateral same-tier form (Ratón ↔ Ardilla, defaulting to Ratón from Halcón/Oruga).

#### Scenario: Ascension to predator
- **WHEN** a life ends with Karma +60 and PA 120
- **THEN** the offered next form is Halcón with an ascension reason citing both thresholds

#### Scenario: Involution as punishment
- **WHEN** a life ends with Karma -70 even with PA 200
- **THEN** the offered next form is Oruga with an involution reason citing Karma ≤ -50

#### Scenario: Neutral lateral adaptation
- **WHEN** a life ends with Karma +10 and PA 40 as Ratón
- **THEN** the offered next form is Ardilla with a neutral-adaptation reason

### Requirement: Karma carries 20% and remaining PA persists
The system SHALL start the next life with Karma equal to 20% of the previous final Karma (rounded) and SHALL carry the remaining PA balance unchanged (spent PA never returns).

#### Scenario: Soft redemption across lives
- **WHEN** a life ends with Karma +50 or -50
- **THEN** the next life starts at Karma +10 or -10 respectively with identical PA

#### Scenario: Spending lowers ascension chances
- **WHEN** a life earns 120 PA but spends 50 mid-life
- **THEN** Judgment evaluates the remaining 70 PA, which alone does not meet the 100 threshold

### Requirement: Judgment offers lateral form choice for PA
The system SHALL offer a Choose-form item on the Judgment screen costing 15 PA that lets the player pick Ratón or Ardilla instead of the forced lateral alternate, and SHALL deduct the cost from the carried balance when chosen.

#### Scenario: Player buys form choice
- **WHEN** a neutral Judgment offers Ardilla and the player with 40 PA picks Ratón via Choose-form
- **THEN** the next life starts as Ratón with 25 PA remaining

### Requirement: Judgment screen explains cause and outcome
The system SHALL show final Karma, PA, survived time, the matrix reason, the next species/tier, and the last up-to-4 life events, with a Reincarnar button and R shortcut.

#### Scenario: Player understands why
- **WHEN** Vida reaches 0
- **THEN** the Judgment overlay appears showing stats, reason text, next form, recent history, and a working reincarnate control

### Requirement: Reincarnation resets world and life state
The system SHALL generate a fresh world (bushes, predators, congeners), restore full Vida for the new species, reset life timer and per-life history, and apply carried Karma/PA on reincarnate.

#### Scenario: Fresh life with carried progression
- **WHEN** the player confirms reincarnation
- **THEN** a new life starts as the offered species with full Vida, fresh entities, zeroed timer, and carried Karma/PA values
