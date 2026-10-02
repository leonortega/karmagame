## Purpose

NanoJev-backed macro decisions let AI zorros choose from the same full verb menu as a human zorro, ranked in parallel by a local decision service while Godot keeps real-time steering.

## ADDED Requirements

### Requirement: Zorro macro intent comes from NanoJev ranking over code-built candidates

The system SHALL obtain each AI zorro's macro intent by sending one batched NanoJev `Choice` request covering all AI zorros and applying the ranked winner. GDScript SHALL build the candidate menu per zorro from legal moves only (cooldown, range, diet, HP-cost checked); NanoJev SHALL only rank, never invent moves. Every applied intent SHALL execute through the same functions as the player (`eat_carrion`, `cede_carrion`, `cast_verb_for`, pounce/hunt resolve).

#### Scenario: Batched parallel decision

- **WHEN** 3 AI zorros need macro intent in the same window
- **THEN** the system sends one batch request with 3 states and per-zorro candidates and applies one returned choice per zorro

#### Scenario: Illegal move is impossible by construction

- **WHEN** a zorro's pounce is on cooldown
- **THEN** its candidate menu contains no pounce entry, so no ranking can select it

#### Scenario: Player parity of effects

- **WHEN** the ranked winner is cede on a carrion within eat range at HP at or above the wasteful threshold
- **THEN** the carrion is marked ceded and the zorro gains the same karma as a player cede, including adaptation multipliers

### Requirement: Micro steering never waits for the API

The system SHALL steer every AI zorro every physics tick toward its current intent, resolve contact kills, drink water within drink range, flee a lobo within fear range, and tick needs and cooldowns regardless of pending or failed macro answers.

#### Scenario: Movement continues during API latency

- **WHEN** a macro answer is pending for 500ms with intent seek-carrion
- **THEN** the zorro keeps moving toward the carrion each physics tick

#### Scenario: Contact kill resolves locally

- **WHEN** a zorro with hunt intent reaches kill range of an edible mate
- **THEN** the kill resolves that tick through the same hunt path as today, without waiting for a new macro answer

### Requirement: Macro cadence is staggered timer plus events with data-LOD

The system SHALL re-ask macro intent for each AI zorro on a staggered 1s timer, and SHALL re-ask immediately on events: lobo entering fear range, HP falling below the hunger-priority threshold, fresh carrion entering perception, a kill resolving, or the current intent reaching its target or expiring. Zorros far from the player camera SHALL use a 3s timer instead of 1s.

#### Scenario: Staggered timer

- **WHEN** 4 zorros are active and 1s elapses
- **THEN** their re-asks spread across the window rather than all firing on the same frame

#### Scenario: Event re-ask on threat

- **WHEN** a lobo enters a zorro's fear range outside its timer slot
- **THEN** the system re-asks macro intent for that zorro immediately with a flee/refuge menu

#### Scenario: Data-LOD slowdown

- **WHEN** a zorro is far from the player camera
- **THEN** its timer cadence is 3s while on-screen zorros keep 1s

### Requirement: Candidate menu covers the full zorro kit with always-present wander

The candidate menu for a zorro SHALL be built from: pounce, hunt-pursuit, eat-carrion, seek-carrion, cede, cachecarrion, dendig, strike, drink-seek, flee-to-refuge, seek-prey, and wander. Wander SHALL always be present so the ranking always has an executable target. Stale answers (actor dead, target gone) SHALL resolve to continued steering or wander, never to a no-op freeze.

#### Scenario: Full verb coverage

- **WHEN** a sated high-HP zorro stands on an unceded carrion with cachecarrion and dendig off cooldown
- **THEN** its menu includes cede, cachecarrion, and dendig alongside eat and wander

#### Scenario: Stale answer hygiene

- **WHEN** a macro answer references a carrion consumed before the answer arrives
- **THEN** the zorro continues steering on its prior intent or wanders, and requests fresh intent on its next slot

### Requirement: Emocion is flavor only plus decision logging from day one

Each macro answer MAY carry an `emocion` label (e.g. Hambre, Miedo, Noble) that SHALL surface only in HUD/feed flavor and SHALL never gate execution. Every macro decision SHALL append a log entry with state snapshot, candidate menu, chosen index with probabilities, and outcome for future training.

#### Scenario: Emocion never blocks

- **WHEN** an answer arrives with choice eat-carrion and emocion Miedo
- **THEN** the zorro eats the carrion and the feed may show the emocion as text only

#### Scenario: Decision log completeness

- **WHEN** a macro choice is applied
- **THEN** the log holds the snapshot, the full menu, the chosen index with its probability distribution, and the later outcome
