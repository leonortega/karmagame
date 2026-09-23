# Spec Delta

## Purpose

Define the core creature attributes (Vida, Karma, PA) and their tuning so every life, decision, and reward behaves consistently and is testable without any engine.

## ADDED Requirements

### Requirement: Vida drains with hunger and triggers judgment at zero
The system SHALL decrease Vida continuously over time and SHALL trigger the Judgment sequence when Vida reaches 0.

#### Scenario: Hunger depletes vida
- **WHEN** the player survives 10 seconds without eating at the default drain rate
- **THEN** Vida is lower than at start by drain-rate × time and the creature remains alive while Vida > 0

#### Scenario: Death opens judgment
- **WHEN** Vida reaches 0 for any reason
- **THEN** the game pauses the life loop and opens the Judgment screen instead of respawning silently

### Requirement: Karma stays within -100 to +100
The system SHALL clamp Karma Ecológico to the range -100…+100 on every change.

#### Scenario: Karma clamps at extremes
- **WHEN** a positive event would push Karma above 100 (or a negative one below -100)
- **THEN** Karma stops exactly at 100 (or -100)

### Requirement: PA rewards survival time
The system SHALL grant PA continuously for time survived at a documented rate (default ~20 PA/min).

#### Scenario: Survival accrues PA
- **WHEN** the player survives 60 seconds without bonuses
- **THEN** PA increases by approximately 20

### Requirement: Sustainable eating vs last-fruit selfish act
The system SHALL grant +15 Vida and +5 PA for eating a non-last fruit, and SHALL grant +20 Vida and -15 Karma and permanently kill the bush for eating the last fruit.

#### Scenario: Sustainable eat
- **WHEN** the player eats from a bush with 2+ fruits remaining
- **THEN** Vida rises (capped at max), PA rises by 5, Karma is unchanged, and the bush stays alive

#### Scenario: Selfish last fruit
- **WHEN** the player eats the final fruit of a living bush
- **THEN** Vida rises by 20 (capped at max), Karma drops by 15, and that bush never regrows fruit

### Requirement: Altruistic shout has cost and reward
The system SHALL grant +30 Karma and +50 PA for shouting, SHALL enforce a 10s cooldown, and SHALL lure predators toward the player for 5s.

#### Scenario: Successful shout
- **WHEN** the player shouts with cooldown ready
- **THEN** Karma rises by 30, PA rises by 50, predators within range target the player for 5s, and congeners flee

#### Scenario: Shout on cooldown is ignored
- **WHEN** the player attempts to shout during cooldown
- **THEN** no Karma/PA change occurs and no lure is triggered

### Requirement: Species differ in speed, vision, and max vida
The system SHALL provide four playable forms with distinct observable traits: Oruga (slow, fragile, cannot shout), Ratón (balanced), Ardilla (faster, less max Vida), Halcón (fastest, largest vision, can strike predators to repel them with +5 Karma/+10 PA/+10 Vida).

#### Scenario: Oruga cannot shout
- **WHEN** the player is an Oruga and attempts the altruistic shout
- **THEN** no Karma/PA is granted and an informational message is shown

#### Scenario: Halcón repels predator
- **WHEN** a Halcón uses the eat action adjacent to a predator
- **THEN** the predator is pushed away and suppressed, and the player gains the documented bonus

### Requirement: PA wallet spends without debt
The system SHALL deduct PA immediately on every purchase, SHALL reject any purchase when the balance is insufficient, and SHALL never let PA go negative.

#### Scenario: Purchase deducts balance
- **WHEN** the player with 60 PA buys an item costing 50 PA
- **THEN** the balance becomes 10 PA and the effect applies immediately

#### Scenario: Insufficient funds rejected
- **WHEN** the player with 10 PA attempts to buy an item costing 25 PA
- **THEN** no PA is deducted, no effect applies, and the item shows as unaffordable

### Requirement: Mid-life adaptations are per-life and non-stackable
The system SHALL offer stat adaptations (Swift paws +15% speed for 50 PA, Big stomach +25 max Vida and +25 heal for 30 PA, Keen nose +50 vision for 25 PA, Quiet voice reducing the next shout lure to 2s for 35 PA), each purchasable at most once per life, and SHALL remove all of them on death.

#### Scenario: Adaptation applies once
- **WHEN** the player buys Swift paws mid-life
- **THEN** speed rises by 15% immediately and the item shows as owned for the rest of the life

#### Scenario: No stacking
- **WHEN** the player who already owns Swift paws attempts to buy it again in the same life
- **THEN** the purchase is rejected with no PA change

#### Scenario: Death clears adaptations
- **WHEN** a life ends with purchased adaptations
- **THEN** the next life starts with base species stats only
