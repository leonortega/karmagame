## MODIFIED Requirements

### Requirement: Poll telemetry snapshot

The system SHALL maintain cumulative poll counters (`busy_skip`, per-species `sent`, `error`) on the run state and overwrite `user://logs/jev_poll.json` with `{"t": <time>, "poll": <counters>, "census": <snapshot>}` on every log flush, where `census` holds the live insect count, carrion count, and agent count per species key at flush time.

#### Scenario: Scheduler health is inspectable

- **WHEN** a log flush runs with poll counters present
- **THEN** `jev_poll.json` holds the latest cumulative snapshot: busy skips, sends per species, and errors

#### Scenario: Population and supply are inspectable

- **WHEN** a log flush runs with insects, carrion, and agents on the map
- **THEN** `jev_poll.json` also holds their counts at flush time, so empty species logs can be told apart from dead populations and missing supply
