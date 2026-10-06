## MODIFIED Requirements

### Requirement: Macro cadence is staggered timer plus events with data-LOD

The system SHALL re-ask macro intent for each AI halcon on a staggered 1s timer, and SHALL re-ask on events — predator pressure entering range, HP falling below the hunger-priority threshold, fresh carrion entering perception, a kill resolving, landing/grounded state changing, or the current intent reaching its target or expiring — at most once per agent per `jevReaskBackoff` window (0.5s). Halcons far from the player camera SHALL use a 3s timer instead of 1s.

#### Scenario: Staggered timer

- **WHEN** 4 halcons are active and 1s elapses
- **THEN** their re-asks spread across the window rather than all firing on the same frame

#### Scenario: Event re-ask on grounded carrion

- **WHEN** a halcon lands on carrion outside its timer slot
- **THEN** the system re-asks macro intent for that halcon within the backoff window with an eat/courtesy menu

#### Scenario: Data-LOD slowdown

- **WHEN** a halcon is far from the player camera
- **THEN** its timer cadence is 3s while on-screen halcons keep 1s
