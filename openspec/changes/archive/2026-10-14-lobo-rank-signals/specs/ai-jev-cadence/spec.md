## MODIFIED Requirements

### Requirement: Poll telemetry snapshot

The system SHALL maintain cumulative poll counters (`busy_skip`, per-species `sent`, `error`) on the run state and overwrite `user://logs/jev_poll.json` with `{"t": <time>, "poll": <counters>, "census": <snapshot>}` on every log flush, where `census` holds the live insect count, carrion count, and agent count per species key at flush time. The per-species `sent` counters SHALL include topo alongside the existing five species. The snapshot SHALL also carry cumulative per-species red-flag counters (`red_flags`), incremented whenever a flushed live decision matches a species' screened pattern (e.g. hungry lobo offered `eat` but ranked `wander`).

#### Scenario: Scheduler health is inspectable

- **WHEN** a log flush runs with poll counters present
- **THEN** `jev_poll.json` holds the latest cumulative snapshot: busy skips, sends per species (including sapo and topo), and errors

#### Scenario: Population and supply are inspectable

- **WHEN** a log flush runs with insects, carrion, and agents on the map
- **THEN** `jev_poll.json` also holds their counts at flush time, so empty species logs can be told apart from dead populations and missing supply

#### Scenario: Red flags are inspectable

- **WHEN** a log flush runs after live decisions matched a screened pattern
- **THEN** `jev_poll.json` holds the cumulative per-species red-flag counts alongside the existing counters
