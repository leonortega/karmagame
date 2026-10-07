## ADDED Requirements

### Requirement: Sapo pest control is AI-castable
The system SHALL allow AI sapo agents to cast the `pest` verb (slot 2) through the same verb core as the player with identical cooldown (8s), costs (0 vida / 0 PA), and payoff (nearest insect within tongue range consumed for +10 vida and +3 pest-control karma). Tongue range SHALL equal `tongueRange` plus 40 with the `tonguePlus` adaptation, matching the player's reach. A cast with no insect in range SHALL fail without starting cooldown, paying costs, or granting karma or vida.

#### Scenario: AI sapo eats through pest
- **WHEN** an AI sapo with slot 2 off cooldown has an insect within tongue range
- **THEN** casting `pest` consumes that insect, grants +10 vida and +3 karma to the agent's ledger, and starts the 8s cooldown

#### Scenario: Pest fails quietly with no prey
- **WHEN** an AI sapo casts `pest` with no insect within tongue range
- **THEN** nothing is consumed, no cooldown starts, no costs are paid, and no karma or vida is granted

#### Scenario: Long tongue reaches further
- **WHEN** an AI sapo owning `tonguePlus` casts `pest` with the nearest insect at 120px
- **THEN** the cast succeeds exactly as the player's 130px tongue would

#### Scenario: Player parity of payoff
- **WHEN** an AI sapo and a player sapo each eat one insect through `pest`
- **THEN** both receive the same vida gain and the same +3 pest-control karma value
