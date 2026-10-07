## MODIFIED Requirements

### Requirement: Fair-share batch scheduling across JEV species

The Main-owned poll path SHALL send, on any poll where agents of two or more species are due, the batch of the due species waiting longest since its last served batch. Single-flight (one batch in flight at a time) is unchanged. Last-served times SHALL live on the run state so a species that is due continuously cannot be skipped while another due species waits. The due set and the last-served record SHALL cover all five JEV species (zorro, halcon, raton, ardilla, sapo).

#### Scenario: Longest-waiting species goes next

- **WHEN** zorro, halcon, raton, ardilla, and sapo agents are all due and the zorro batch was served most recently
- **THEN** the next batch sent covers the longest-waiting of the other four species

#### Scenario: Lone due species is unaffected

- **WHEN** only sapo agents are due on a poll
- **THEN** the sapo batch is sent exactly as today, with no picker delay

### Requirement: Poll telemetry snapshot

The system SHALL maintain cumulative poll counters (`busy_skip`, per-species `sent`, `error`) on the run state and overwrite `user://logs/jev_poll.json` with `{"t": <time>, "poll": <counters>}` on every log flush. The per-species `sent` counters SHALL include sapo alongside the existing four species.

#### Scenario: Scheduler health is inspectable

- **WHEN** a log flush runs with poll counters present
- **THEN** `jev_poll.json` holds the latest cumulative snapshot: busy skips, sends per species (including sapo), and errors
