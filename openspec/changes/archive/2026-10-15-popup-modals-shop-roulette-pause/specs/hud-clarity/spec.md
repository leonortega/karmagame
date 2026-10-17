## ADDED Requirements

### Requirement: Shop renders as centered modal
The system SHALL render the shop as a centered modal (not only right-panel text) showing species name, PA balance with its icon, one row per catalog item with slot key, name, cost, description, and owned/affordable/locked state, SHALL buy on `1-3` with immediate PA deduct, reject on insufficient funds, never-negative PA, at most once per life, and SHALL close on `B`, `Esc`, or close button while freezing the sim identically to other modals.

#### Scenario: Shop buys with focus
- **WHEN** the player opens the shop as raton with 70 PA and presses 1
- **THEN** the matching adaptation is owned, PA drops by its cost immediately, and no verb is cast

#### Scenario: Shop refuses the poor
- **WHEN** the player presses a shop key without enough PA or for an owned item
- **THEN** the purchase is rejected, PA is unchanged, and the row stays locked or owned

#### Scenario: Shop is safe to read
- **WHEN** the shop modal is open
- **THEN** no hunger, predator, cooldown, or timer advances until it closes
