## MODIFIED Requirements

### Requirement: Five species verbs on keys 1–5
The game SHALL define `VERB_DEFS[speciesKey]` with exactly 5 verbs per species (slot 1–5), each with name, description, cooldown, and real costs (`costHp`, `costPa`). Keys 1–5 SHALL cast the matching verb; when the shop overlay is open, keys 1–4 SHALL keep buying shop items instead. E/Q/B/H/V/C behavior SHALL be unchanged. The verb bar SHALL render as a vertical list with one item per line showing slot, name, and remaining cooldown, keeping the existing unaffordable-dim behavior.

#### Scenario: Cast a verb
- **WHEN** the player as topo presses 1 with the shop closed and cooldown ready
- **THEN** the aerate verb executes, its cooldown starts, and its costs are paid

#### Scenario: Shop keeps its keys
- **WHEN** the player presses 2 while the shop overlay is open
- **THEN** the shop buys Estómago grande as before, and no verb is cast

#### Scenario: Dead form cannot cast
- **WHEN** the player presses any verb key while dead or while the verb is on cooldown
- **THEN** nothing happens

#### Scenario: Verbs stack vertically
- **WHEN** the player looks at the verb bar as any species
- **THEN** five rows appear stacked vertically, each with its slot number and name, and a row on cooldown appends remaining seconds
