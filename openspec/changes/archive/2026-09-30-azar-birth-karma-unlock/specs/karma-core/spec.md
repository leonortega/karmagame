## MODIFIED Requirements

### Requirement: Mid-life adaptations are per-life and non-stackable
The system SHALL offer 3 unique adaptations per species (24 total) from per-species catalogs priced 50–80 PA each, each purchasable at most once per life, and SHALL remove all of them on death. Each catalog SHALL follow the pattern 1 stat + 1 verb-upgrade + 1 signature (e.g. Sapo longer tongue / stronger toxin / wider chorus; mechanics may share numbers with distinct flavor). PA wallet rules (immediate deduct, reject on insufficient funds, never negative) apply unchanged.

#### Scenario: Signature applies once
- **WHEN** a Sapo buys its tongue upgrade mid-life
- **THEN** the tongue range rises immediately and the item shows as owned for the rest of the life

#### Scenario: No stacking
- **WHEN** the player who already owns an item attempts to buy it again in the same life
- **THEN** the purchase is rejected with no PA change

#### Scenario: Death clears adaptations
- **WHEN** a life ends with purchased adaptations
- **THEN** the next life starts with base species stats only

#### Scenario: Typical life affords one item
- **WHEN** a player earns ~60–100 PA in a life and items cost 50–80 PA
- **THEN** at most one item is affordable per life in the common case

### Requirement: AI agents can purchase adaptations
AI agents spend PA to buy items from their own species catalog using the same `buyItem` logic as the player. The same `owned` constraint applies: one purchase per item, no stacking, no debt. Adaptations are per-life.

#### Scenario: AI agent buys adaptation with sufficient PA
- **WHEN** an AI Sapo has PA ≥ its tongue upgrade cost and does not own it
- **THEN** PA is deducted, `owned[item.id]` becomes true, and the effect applies immediately

#### Scenario: AI agent cannot buy without PA
- **WHEN** an AI agent has PA < item cost
- **THEN** no PA is deducted, no effect applies

#### Scenario: AI buys only its species catalog
- **WHEN** an AI Ratón has PA for a Sapo-only item
- **THEN** that item is not offered and cannot be bought
