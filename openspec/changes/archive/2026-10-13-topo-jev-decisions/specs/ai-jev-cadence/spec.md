## MODIFIED Requirements

### Requirement: Fair-share batch scheduling across JEV species

The Main-owned poll path SHALL send, on any poll where agents of two or more species are due, the batch of the due species waiting longest since its last served batch. Single-flight (one batch in flight at a time) is unchanged. Last-served times SHALL live on the run state so a species that is due continuously cannot be skipped while another due species waits. The due set and the last-served record SHALL cover all six JEV species (zorro, halcon, raton, ardilla, sapo, topo).

#### Scenario: Longest-waiting species goes next

- **WHEN** zorro, halcon, raton, ardilla, sapo, and topo agents are all due and the zorro batch was served most recently
- **THEN** the next batch sent covers the longest-waiting of the other five species

#### Scenario: Lone due species is unaffected

- **WHEN** only topo agents are due on a poll
- **THEN** the topo batch is sent exactly as today, with no picker delay

### Requirement: Poll telemetry snapshot

The system SHALL maintain cumulative poll counters (`busy_skip`, per-species `sent`, `error`) on the run state and overwrite `user://logs/jev_poll.json` with `{"t": <time>, "poll": <counters>, "census": <snapshot>}` on every log flush, where `census` holds the live insect count, carrion count, and agent count per species key at flush time. The per-species `sent` counters SHALL include topo alongside the existing five species.

#### Scenario: Scheduler health is inspectable

- **WHEN** a log flush runs with poll counters present
- **THEN** `jev_poll.json` holds the latest cumulative snapshot: busy skips, sends per species (including topo), and errors

#### Scenario: Population and supply are inspectable

- **WHEN** a log flush runs with insects, carrion, and agents on the map
- **THEN** `jev_poll.json` also holds their counts at flush time, so empty species logs can be told apart from dead populations and missing supply
