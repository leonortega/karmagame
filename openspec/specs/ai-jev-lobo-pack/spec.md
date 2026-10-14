# ai-jev-lobo-pack Specification

## Purpose

Pack hunting and feeding let AI lobos act as the pack apex they are: sharing food with hungry packmates and ranging widely for carrion, so the migrated lobo kit is exercised in every run instead of idling on two-candidate menus.

## Requirements

### Requirement: Regurg reaches any hungry lobo packmate

The system SHALL let an AI lobo regurgitate for any hungry lobo packmate — company or fauna — within groom range when slot 2 is ready and its HP is above the regurg cost, through the same HP/karmic path as the player. The JEV candidate menu SHALL offer `regurg` for fauna packmates on the same terms as company mates.

#### Scenario: Fauna packmates feed each other

- **WHEN** two fauna lobos stand within groom range, one with HP above the regurg cost and slot 2 ready and the other hungry
- **THEN** the fed lobo gains HP and hambre through the same path as a company feed, and the feeder gains the same karma

#### Scenario: Menu offers fauna regurg

- **WHEN** an AI lobo's only hungry in-range packmate is a fauna lobo
- **THEN** its candidate menu includes `regurg` with that mate as target

### Requirement: Hungry seek ranges beyond perception

The system SHALL offer `seek_carrion` to a hungry AI lobo for carrion up to `wanderSeekRange` away (not just within 280 perception), mirroring the ladder's urgent-seek trek. The legal-only contract is unchanged: the candidate appears only when hungry and only for existing carrion.

#### Scenario: Distant carrion is seekers-eligible

- **WHEN** a hungry AI lobo has no carrion within perception but one lies within wander-seek range
- **THEN** its candidate menu includes `seek_carrion` with that carrion as target

### Requirement: State text carries an explicit need token

The lobo state text sent to the ranker SHALL include an explicit need token derived from the same snapshot rules as the local emocion appraisal: `urgent` when hambre sits at or below the floor-hunger line, else `hunger` when the agent counts as hungry, else `thirst` when sed sits below the drink threshold while hunger does not dominate, else `none`. The token SHALL be appended to the existing one-line summary without removing any current field.

#### Scenario: Hungry framing is explicit

- **WHEN** a lobo state text is built for a hungry agent above floor hunger
- **THEN** the text contains `need=hunger` alongside the existing `hungry`/`hambre` fields

#### Scenario: Sated framing is explicit

- **WHEN** a lobo state text is built for a sated, unthirsty agent
- **THEN** the text contains `need=none`

### Requirement: Flushed lobo decisions are screened for the hungry-wander pattern

Every live lobo macro decision SHALL be screened at log time for the red-flag pattern: snapshot hungry AND `eat` present in the candidate menu AND ranked choice `wander`. Matching entries SHALL increment a cumulative per-species red-flag counter on the run state. Mocked decisions SHALL never be screened or counted.

#### Scenario: Red flag is counted

- **WHEN** a live lobo decision with a hungry snapshot and an `eat` candidate resolves to `wander`
- **THEN** the lobo red-flag counter increments by one

#### Scenario: Sated wander is not flagged

- **WHEN** a live lobo decision with a sated snapshot resolves to `wander`
- **THEN** the lobo red-flag counter does not change
