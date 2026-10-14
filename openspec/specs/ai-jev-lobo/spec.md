# ai-jev-lobo Specification

## Purpose

NanoJev-backed macro decisions let AI lobos choose from the same apex menu as a human lobo — hunt T2 and zorros, carrion feeding, strike, regurg pack sharing plus alarm — ranked in parallel by a local decision service while Godot keeps real-time steering.

## Requirements

### Requirement: Lobo macro intent comes from batched NanoJev ranking

The system SHALL obtain each AI lobo's macro intent by sending one batched NanoJev `Choice` request covering all AI lobos and applying the ranked winner. GDScript SHALL build the candidate menu per lobo from legal moves only (carrion diet, eat range, drink need, verb cooldowns and HP costs checked); NanoJev SHALL only rank, never invent moves. Every applied intent SHALL execute through the same functions as the player (`eat_carrion`, drink/seek, hunt resolve, verbs through the same karma paths). `howl` (slot 1), `escort` (slot 4), and `cull` (slot 5) SHALL never be offered: they are player-only today, so the ranker is never offered a move the AI cannot legally execute.

#### Scenario: Ranked hunt resolves like the player

- **WHEN** an AI lobo is hungry with edible prey in perception and the sidecar ranks `hunt` first
- **THEN** the lobo pursues and kills on contact through the same hunt path as today, spawning carrion

#### Scenario: Ranker never invents moves

- **WHEN** the sidecar answers with a kind absent from the offered menu
- **THEN** the choice clamps to wander and the lobo keeps steering instead of freezing

#### Scenario: Player-only verbs never offered

- **WHEN** an AI lobo needs a menu under any state
- **THEN** no `howl`, `escort`, or `cull` candidate appears, since those verbs return false for agents

### Requirement: Lobo micro steering never waits

The system SHALL steer every AI lobo every physics tick toward its current intent, resolve contact kills locally, eat contact carrion within eat range, trek to distant food when hungry, drink water within drink range, strike hunters within strike range, and tick needs and cooldowns regardless of pending or failed macro answers. The wander tail SHALL follow the zorro pattern: fall through to pack/hunt reflexes via the shared verb path, else steer toward the nearest point of interest via `wander_poi`, else a short random step — lobo has no fears and no hide behavior, so purposeful wandering per `ai-species-behavior` is preserved.

#### Scenario: Contact kill resolves locally

- **WHEN** an AI lobo with a pending macro answer reaches kill range of an edible target
- **THEN** the kill resolves that tick through the same hunt path as today, without waiting for the answer

#### Scenario: Movement continues during API latency

- **WHEN** a macro answer is pending with intent seek-carrion
- **THEN** the lobo keeps moving toward the carrion each physics tick

#### Scenario: Wander travels to points of interest

- **WHEN** an AI lobo holds a wander intent with no food, water, or trigger nearby
- **THEN** it steers toward the nearest point of interest (food, water, company) instead of freezing

### Requirement: Lobo intent cadence with event re-asks

The system SHALL re-ask macro intent for each AI lobo on a staggered 1s timer, and SHALL re-ask immediately on events: fresh carrion entering perception, HP falling below the hunger-priority threshold, a hungry packmate entering regurg range, strike/regurg resolving, a kill resolving, or the current intent reaching its target or expiring — at most once per agent per `jevReaskBackoff` window (0.5s). Lobos far from the player camera SHALL use a 3s timer instead of 1s. Lobo batches SHALL join the Main-owned single-flight batch path with fair cross-species scheduling so no species starves another.

#### Scenario: Fresh carrion re-asks promptly

- **WHEN** a fresh carrion appears in an AI lobo's perception outside its timer slot and the backoff window has elapsed
- **THEN** a re-ask fires on the next poll without waiting for the timer slot

#### Scenario: Far lobos poll slower

- **WHEN** an AI lobo is farther than half the view diagonal from the player camera
- **THEN** its timer re-asks every 3s instead of every 1s

### Requirement: Lobo candidate menu

The candidate menu for a lobo SHALL be built from: eat (carrion within eat range), seek-carrion (distant carrion when hungry), hunt (visible edible prey — tier-2 agents and zorros — within perception), drink-seek (water when below the drink threshold), strike (hunter within strike range with strike off cooldown and slot 3 ready), regurg (hungry same-species mate within groom range with slot 2 ready and HP above the regurg cost), alarm (hunter within lure range with shout off cooldown), and wander. Wander SHALL always be present so the ranking always has an executable target. Stale answers (actor dead, target gone, carrion already eaten) SHALL resolve to continued steering or wander, never to a no-op freeze.

#### Scenario: Menu holds a legal-only set

- **WHEN** an AI lobo with strike on cooldown and no hunter nearby needs a menu
- **THEN** strike is absent, regurg appears only with a hungry packmate in range and HP above its cost, and wander is always present

#### Scenario: Stale answer hygiene

- **WHEN** a macro answer references a carrion consumed before the answer arrives
- **THEN** the lobo continues steering on its prior intent or wanders, and requests fresh intent on its next slot

### Requirement: Lobo emocion flavor and decision log

Each macro answer MAY carry an `emocion` label that SHALL surface only in HUD/feed flavor and SHALL never gate execution; when the answer carries none, the bridge SHALL appraise one locally from the snapshot (same rule as the other species: fear on threat/pressure, urgency on floor hunger, hunger otherwise). Every live macro decision SHALL append a log entry under schema `jev-lobo/v1` with state snapshot, candidate menu, chosen index with probabilities, and outcome to `user://logs/jev_lobo.log` only when the lobo log flag is on; mocked decisions SHALL never log.

#### Scenario: Emocion never gates

- **WHEN** a live answer carries an unknown or empty `emocion`
- **THEN** the intent still applies fully and the label only flavors the feed

#### Scenario: Disabled log stays silent and cheap

- **WHEN** the lobo log flag is off
- **THEN** no entry is buffered, no file is touched, and no memory grows
