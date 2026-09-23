# Spec Delta

## MODIFIED Requirements

### Requirement: Altruistic shout has cost and reward
The system SHALL grant +30 Karma and +50 PA for shouting, SHALL enforce a 10s cooldown, and SHALL lure predators toward the player for 5s. Only non-predator forms can shout (Ratón, Ardilla, Topo, and Sapo whose croak counts as a shout); Halcón and Zorro cannot shout — predators don't warn prey.

#### Scenario: Successful shout
- **WHEN** the player shouts with cooldown ready
- **THEN** Karma rises by 30, PA rises by 50, predators within range target the player for 5s, and congeners flee

#### Scenario: Shout on cooldown is ignored
- **WHEN** the player attempts to shout during cooldown
- **THEN** no Karma/PA change occurs and no lure is triggered

#### Scenario: Predator cannot shout
- **WHEN** the player is a Halcón or Zorro and attempts to shout
- **THEN** no Karma/PA is granted and an informational message is shown

### Requirement: Species differ in speed, vision, and max vida
The system SHALL provide seven playable forms with distinct observable traits and a size stat (1–3) used by refuges: Oruga (T0, slow, fragile, size 1, cannot shout), Sapo (T1, slow, size 1, tongue grabs fruit at 90px range, croak counts as shout), Ratón (T1, balanced, size 2, can shout), Ardilla (T1, faster, less max Vida, size 2, climber, can shout), Topo (T1, size 2, Dig creates a burrow-M at its position with 20s cooldown and max 3 per life, can shout), Halcón (T2, fastest, largest vision, size 3, strike repels predators with +5 Karma/+10 PA/+10 Vida, cannot shout, must land to eat), Zorro (T2, fast hunter, size 3, Pounce dash-kills prey with 6s cooldown, cannot shout).

#### Scenario: Oruga cannot shout
- **WHEN** the player is an Oruga and attempts the altruistic shout
- **THEN** no Karma/PA is granted and an informational message is shown

#### Scenario: Halcón repels predator
- **WHEN** a Halcón uses the eat action adjacent to a predator
- **THEN** the predator is pushed away and suppressed, and the player gains the documented bonus

#### Scenario: Sapo tongue grabs at range
- **WHEN** a Sapo uses the eat action with a fruit within 90px but beyond contact range
- **THEN** the fruit is consumed with the normal sustainable/last-fruit rules applied

#### Scenario: Topo dig creates refuge
- **WHEN** a Topo uses Dig with cooldown ready and fewer than 3 burrows dug this life
- **THEN** a burrow-M refuge appears at its position and the cooldown starts

#### Scenario: Zorro pounce kills prey
- **WHEN** a Zorro uses the eat action adjacent to a congener with Pounce ready
- **THEN** the congener dies, a fresh carrion spawns at its position, and the Zorro gains Vida per the wasteful-kill rule

### Requirement: Mid-life adaptations are per-life and non-stackable
The system SHALL offer stat adaptations (Swift paws +15% speed for 50 PA, Big stomach +25 max Vida and +25 heal for 30 PA, Keen nose +50 vision for 25 PA and reveals mimic fruit exactly within vision, Quiet voice reducing the next shout lure to 2s for 35 PA), each purchasable at most once per life, and SHALL remove all of them on death.

#### Scenario: Adaptation applies once
- **WHEN** the player buys Swift paws mid-life
- **THEN** speed rises by 15% immediately and the item shows as owned for the rest of the life

#### Scenario: No stacking
- **WHEN** the player who already owns Swift paws attempts to buy it again in the same life
- **THEN** the purchase is rejected with no PA change

#### Scenario: Death clears adaptations
- **WHEN** a life ends with purchased adaptations
- **THEN** the next life starts with base species stats only

#### Scenario: Keen nose reveals mimics
- **WHEN** a player owning Keen nose has a mimic fruit within vision
- **THEN** the mimic is visually marked as poison before being eaten

## ADDED Requirements

### Requirement: Wasteful kills cost karma
The system SHALL grant −10 Karma when a carnivore form (Zorro Pounce, and any future killing verb) kills prey while its Vida is at or above 80% of max, and SHALL still grant the normal Vida gain capped at max.

#### Scenario: Needed kill is clean
- **WHEN** a Zorro at 50% Vida pounce-kills a congener
- **THEN** no karma change occurs and Vida rises normally

#### Scenario: Sport kill is punished
- **WHEN** a Zorro at 90% Vida pounce-kills a congener
- **THEN** Karma drops by 10 and the kill is logged as wasteful
