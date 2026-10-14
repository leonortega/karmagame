## ADDED Requirements

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
