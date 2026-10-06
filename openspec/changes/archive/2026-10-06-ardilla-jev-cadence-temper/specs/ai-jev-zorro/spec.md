## MODIFIED Requirements

### Requirement: Macro cadence is staggered timer plus events with data-LOD

The system SHALL re-ask macro intent for each AI zorro on a staggered 1s timer, and SHALL re-ask on events — lobo entering fear range, HP falling below the hunger-priority threshold, fresh carrion entering perception, a kill resolving, or the current intent reaching its target or expiring — at most once per agent per `jevReaskBackoff` window (0.5s). Zorros far from the player camera SHALL use a 3s timer instead of 1s.

#### Scenario: Staggered timer

- **WHEN** 4 zorros are active and 1s elapses
- **THEN** their re-asks spread across the window rather than all firing on the same frame

#### Scenario: Event re-ask on threat

- **WHEN** a lobo enters a zorro's fear range outside its timer slot
- **THEN** the system re-asks macro intent for that zorro within the backoff window with a flee/refuge menu

#### Scenario: Data-LOD slowdown

- **WHEN** a zorro is far from the player camera
- **THEN** its timer cadence is 3s while on-screen zorros keep 1s
