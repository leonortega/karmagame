# ai-jev-cadence Specification

## Purpose

The single-flight JEV batch path shared by all species needs fairness and churn guarantees so the per-species 1s/3s cadence specs hold in practice, plus a permanent telemetry surface proving scheduler health in live logs.

## Requirements

### Requirement: Fair-share batch scheduling across JEV species

The Main-owned poll path SHALL send, on any poll where agents of two or more species are due, the batch of the due species waiting longest since its last served batch. Single-flight (one batch in flight at a time) is unchanged. Last-served times SHALL live on the run state so a species that is due continuously cannot be skipped while another due species waits.

#### Scenario: Longest-waiting species goes next

- **WHEN** zorro, halcon, raton, and ardilla agents are all due and the zorro batch was served most recently
- **THEN** the next batch sent covers the longest-waiting of the other three species

#### Scenario: Lone due species is unaffected

- **WHEN** only ardilla agents are due on a poll
- **THEN** the ardilla batch is sent exactly as today, with no picker delay

### Requirement: Event re-ask backoff per agent

Event-triggered re-asks (hunger transition, hunted state without flee intent, carrion growth, nut pickup/burial, intent reaching target or expiring) SHALL fire at most once per agent per `jevReaskBackoff` window (0.5s in `TUNING`). Timer cadence (1s near, 3s far) is unchanged and keeps dominating re-ask timing.

#### Scenario: Threat churn is bounded

- **WHEN** a threatened agent keeps a non-flee intent across consecutive physics ticks
- **THEN** at most one event re-ask fires per backoff window instead of one per tick

#### Scenario: Genuine new events still re-ask promptly

- **WHEN** a fresh event arrives for an agent whose backoff window has elapsed
- **THEN** the re-ask fires on the next poll without waiting for the timer slot

### Requirement: Poll telemetry snapshot

The system SHALL maintain cumulative poll counters (`busy_skip`, per-species `sent`, `error`) on the run state and overwrite `user://logs/jev_poll.json` with `{"t": <time>, "poll": <counters>}` on every log flush.

#### Scenario: Scheduler health is inspectable

- **WHEN** a log flush runs with poll counters present
- **THEN** `jev_poll.json` holds the latest cumulative snapshot: busy skips, sends per species, and errors
