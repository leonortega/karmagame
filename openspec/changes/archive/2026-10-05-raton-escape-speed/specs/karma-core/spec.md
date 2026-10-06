## MODIFIED Requirements

### Requirement: Ratón form (Tier 1)
The system SHALL provide the Ratón as a balanced, size 2 form that can shout with standard rewards, and that outruns the Zorro in base speed (190 vs 185) so it can reach refuge cover in the open.

#### Scenario: Ratón shouts normally
- **WHEN** a Ratón shouts with cooldown ready
- **THEN** Karma rises by 30, PA rises by 50, and predators are lured as usual

#### Scenario: Ratón outruns the Zorro
- **WHEN** a Ratón and a Zorro run the same line at base speed with no chase multiplier active
- **THEN** the Ratón pulls ahead over time

#### Scenario: Zorro chase still closes on a Ratón
- **WHEN** a Zorro (trot + chase multiplier) pursues a fleeing Ratón
- **THEN** it closes distance over time as it does today

### Requirement: Ardilla form (Tier 1)
The system SHALL provide the Ardilla as a fast, agile Tier 1 form with less max Vida than the Ratón, size 2, climber (fits hollow-tree refuges), that can shout.

#### Scenario: Ardilla fits hollow-tree
- **WHEN** an Ardilla presses H near a hollow-tree refuge
- **THEN** it hides successfully
