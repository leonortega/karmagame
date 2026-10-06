# ai-jev-halcon Specification

## Purpose

NanoJev-backed macro decisions let AI halcons choose from the same full verb menu as a human halcon, ranked in parallel by a local decision service while Godot keeps real-time steering and the dive/land cycle.

## Requirements

### Requirement: Halcon macro intent comes from NanoJev ranking over code-built candidates

The system SHALL obtain each AI halcon's macro intent by sending one batched NanoJev `Choice` request covering all AI halcons and applying the ranked winner. GDScript SHALL build the candidate menu per halcon from legal moves only (cooldown, range, diet, grounded/land state checked); NanoJev SHALL only rank, never invent moves. Every applied intent SHALL execute through the same functions as the player (`eat_carrion`, `cast_verb_for`, dive/hunt resolve).

#### Scenario: Batched parallel decision

- **WHEN** 3 AI halcons need macro intent in the same window
- **THEN** the system sends one batch request with 3 states and per-halcon candidates and applies one returned choice per halcon

#### Scenario: Illegal move is impossible by construction

- **WHEN** a halcon's dive is on cooldown
- **THEN** its candidate menu contains no dive entry, so no ranking can select it

#### Scenario: Player parity of effects

- **WHEN** the ranked winner is scare on a predator within strike range
- **THEN** the predator is pushed away and the halcon gains the same karma as a player scare, including adaptation multipliers

### Requirement: Micro steering never waits for the API

The system SHALL steer every AI halcon every physics tick toward its current intent, resolve dive kills on contact, land and eat carrion within eat range when grounded, drink water within drink range, and tick needs and cooldowns regardless of pending or failed macro answers.

#### Scenario: Movement continues during API latency

- **WHEN** a macro answer is pending for 500ms with intent seek-carrion
- **THEN** the halcon keeps moving toward the carrion each physics tick

#### Scenario: Dive kill resolves locally

- **WHEN** a halcon with hunt intent reaches dive range of an edible mate
- **THEN** the kill resolves that tick through the same hunt path as today, the halcon lands with `landT` set, without waiting for a new macro answer

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

### Requirement: Candidate menu covers the full halcon kit with always-present wander

The candidate menu for a halcon SHALL be built from: dive/hunt-pursuit, eat-carrion, seek-carrion, courtesy-share, scare, bone-drop, thermal, drink-seek, flee-to-refuge, and wander. Thermal SHALL only appear when the halcon can afford it (`pa >= costPa`); cooldown-gated verbs SHALL only appear off cooldown. Wander SHALL always be present so the ranking always has an executable target. Stale answers (actor dead, target gone) SHALL resolve to continued steering or wander, never to a no-op freeze. A pick that fails its affordability check at apply time SHALL resolve to wander and log `applied=false`.

#### Scenario: Unaffordable thermal is impossible by construction

- **WHEN** a halcon has less PA than the thermal cost
- **THEN** its candidate menu contains no thermal entry, so no ranking can select it

#### Scenario: Unaffordable pick logs honestly

- **WHEN** a macro answer picks thermal but the halcon's PA dropped below cost before apply
- **THEN** the halcon steers wander and the log records `applied=false` for that decision

#### Scenario: Full verb coverage

- **WHEN** a grounded sated halcon stands on carrion with courtesy and scare off cooldown
- **THEN** its menu includes courtesy-share and scare alongside eat and wander

#### Scenario: Stale answer hygiene

- **WHEN** a macro answer references a carrion consumed before the answer arrives
- **THEN** the halcon continues steering on its prior intent or wanders, and requests fresh intent on its next slot

#### Scenario: Hungry halcon sees food urgency

- **WHEN** a halcon's `hambre` is below `regenHambre` and carrion is near
- **THEN** its eat candidate label carries a hunger hint so the ranking can weigh need

### Requirement: Emocion is flavor only plus per-species decision logging

Each macro answer MAY carry an `emocion` label (e.g. Hambre, Miedo, Noble) that SHALL surface only in HUD/feed flavor and SHALL never gate execution. Every live macro decision SHALL append a log entry under schema `jev-halcon/v1` with state snapshot, candidate menu, chosen index with probabilities, and outcome to `user://logs/jev_halcon.log` only when the halcon log flag is on; mocked decisions SHALL never log. Costly verbs SHALL show their cost in the criteria label so the ranker can weigh affordability against the numeric `pa` in the snapshot.

#### Scenario: Emocion never blocks

- **WHEN** an answer arrives with choice eat-carrion and emocion Miedo
- **THEN** the halcon eats the carrion and the feed may show the emocion as text only

#### Scenario: Decision log isolation

- **WHEN** a live halcon choice is applied while the halcon log flag is on
- **THEN** the log holds the snapshot, the full menu, the chosen index with its probability distribution, and the later outcome in `jev_halcon.log`, and no entry appears in any other species file
