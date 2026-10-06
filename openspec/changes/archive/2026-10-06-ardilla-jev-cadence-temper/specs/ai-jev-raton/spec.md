## MODIFIED Requirements

### Requirement: Macro cadence is staggered timer plus events with data-LOD

The system SHALL re-ask macro intent for each AI raton on a staggered 1s timer, and SHALL re-ask on events — predator pressure entering range, fresh food entering perception, or the current intent reaching its target or expiring — at most once per agent per `jevReaskBackoff` window (0.5s). Ratons far from the player camera SHALL use a 3s timer instead of 1s. Raton batches SHALL share the single-batch-per-window path with fair cross-species scheduling so no species starves another.

#### Scenario: Staggered timer

- **WHEN** 4 ratons are active and 1s elapses
- **THEN** their re-asks spread across the window rather than all firing on the same frame

#### Scenario: Event re-ask on threat

- **WHEN** a hunter enters a raton's fear range outside its timer slot
- **THEN** the system re-asks macro intent for that raton within the backoff window with a flee/refuge menu

#### Scenario: Data-LOD slowdown

- **WHEN** a raton is far from the player camera
- **THEN** its timer cadence is 3s while on-screen ratons keep 1s
