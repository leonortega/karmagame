## Purpose

Makes the HUD readable at a glance: only usable controls per species with live cooldowns, an emphasized PA readout, animal-years edad, a vertical verb list, and an emoji-first other-animals feed covering every species.

## ADDED Requirements

### Requirement: Per-species controls with live cooldowns
The system SHALL render the right-panel controls list per possessed species (shared BASE rows plus species extras) with live cooldown counters in `(Ns)` style matching the verb bar, SHALL omit R from the in-life panel, and SHALL split the species/tier identity from cooldown state so tier never reads as an input.

#### Scenario: Topo sees only its controls with counters
- **WHEN** the player possesses a topo with dig on cooldown
- **THEN** the controls list shows movement, E cavar with remaining seconds and dug count, Q gritar with remaining seconds, V temblor with remaining seconds, H, and B, and shows no R, no C, and no zorro-only rows

#### Scenario: Zorro sees no shout row
- **WHEN** the player possesses a zorro
- **THEN** the controls list shows E zarpazo and V rastro with counters, and shows no Q row and no R row

#### Scenario: Cooldown counts down like verbs
- **WHEN** a shown control action is on cooldown
- **THEN** its row appends the ceiling of remaining seconds in parentheses and dims until ready, identical in style to verb cooldowns

### Requirement: Emphasized PA readout with icon
The system SHALL render PA with a non-text icon plus numeric balance in an emphasized style (color and weight distinct from surrounding labels) without changing PA earning or spending rules.

#### Scenario: PA reads as the wallet
- **WHEN** the player looks at the HUD bar
- **THEN** PA appears with its icon and balance in the emphasized style and updates immediately on earn or spend

### Requirement: Animal-years edad display
The system SHALL display edad as per-species animal-years derived from lived seconds via a per-species seconds-per-year table, SHALL keep counting `edad` in seconds internally with no gameplay effect, and SHALL keep the elapsed-time clock as a separately labeled run clock.

#### Scenario: Raton age reads in raton years
- **WHEN** a raton has lived 40 seconds at 20 seconds-per-year
- **THEN** the edad readout shows approximately 2 raton-years alongside the raw seconds

#### Scenario: Edad stays display-only
- **WHEN** two animals of the same species differ only in edad
- **THEN** their vida trajectories over the next tick are identical

### Requirement: Vertical verb list
The system SHALL render the 1-5 verb bar as a vertical list with one item per line showing slot, name, and remaining cooldown, SHALL keep the existing unaffordable-dim behavior, and SHALL NOT change verb behavior, costs, or cooldowns.

#### Scenario: Verbs stack vertically
- **WHEN** the player looks at the verb bar as any species
- **THEN** five rows appear stacked vertically, each with its slot number and name, and a row on cooldown appends remaining seconds

### Requirement: Emoji-first karma feed for all species
The system SHALL surface every AI karma entry in the left-panel other-animals feed for all agent species (no silent empty-message drops), SHALL prefix each entry with the actor species emoji followed by the existing text, SHALL keep the roster block unchanged, and SHALL keep the player feed unchanged with karma-only entries (no eat/drink firehose).

#### Scenario: Sapo toxin appears with emoji
- **WHEN** an AI sapo earns toxin karma
- **THEN** the left-panel feed prepends an entry starting with the sapo emoji followed by the deed text

#### Scenario: AI shout is no longer silent
- **WHEN** an AI raton shouts successfully
- **THEN** the left-panel feed gains a karma entry for the shout instead of dropping it
