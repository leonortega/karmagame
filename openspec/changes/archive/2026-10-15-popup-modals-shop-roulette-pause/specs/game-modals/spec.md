## Purpose

A single centered modal layer gives shop buys, divine birth and rebirth roulettes, and pause a shared ceremony: one popup at a time, sim frozen, keys focused, so no fate or purchase ever applies silently.

## ADDED Requirements

### Requirement: One modal at a time with sim freeze

The system SHALL show at most one modal (shop, birth, judgment, pause) centered with a dimmed world behind it, SHALL freeze hunger, thirst, vida drain/regen, predator and agent ticks, flora/insect timers, cooldowns, PA accrual, and JEV polling while any modal is open while keeping world rendering, and SHALL swallow movement and world-verb keys until the modal is dismissed.

#### Scenario: Shopping is safe

- **WHEN** the shop modal opens with a zorro hunter nearby
- **THEN** no hunger, predator, cooldown, or timer advances until the shop closes

#### Scenario: Single modal wins

- **WHEN** the player dies while the shop is open
- **THEN** the shop closes and only the judgment modal shows

### Requirement: Birth roulette opens every fresh run

The system SHALL open a birth modal on every fresh run showing the `KARMA` title, the line `los dioses han elegido que nazcas como:`, one block per each of the 8 species with its emoji and name, a highlight that cycles across all 8 and settles on the pre-drawn azar form, the settled species name and tier, and a dismiss control that starts play.

#### Scenario: First birth is pure azar with ceremony

- **WHEN** a fresh run starts
- **THEN** the birth modal cycles across all 8 species blocks and settles on the uniform-azar form with no karma evaluation

#### Scenario: No silent birth

- **WHEN** the birth modal is open
- **THEN** the sim is frozen and no movement or verb key has any effect until dismissal

### Requirement: Pause modal toggles safely

The system SHALL toggle a pause modal on `P` and on `Esc` (when no other modal is open), showing `PAUSA`, the current species, PA, Karma, and a controls recap, with resume on `P`/`Esc`/button, and SHALL freeze the sim identically to other modals while open.

#### Scenario: Pause and resume

- **WHEN** the player presses `P` mid-life
- **THEN** the pause modal opens, the sim freezes, and pressing `P` again resumes exactly where play stopped

#### Scenario: Esc closes shop first

- **WHEN** the player presses `Esc` with the shop open
- **THEN** the shop closes and pause does not open
