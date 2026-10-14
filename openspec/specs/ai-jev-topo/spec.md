# ai-jev-topo Specification

## Purpose

NanoJev-backed macro decisions let AI topos choose from the same burrower menu as a human topo — aerate, tunneline, worm, larder plus hybrid insect/carrot foraging — ranked in parallel by a local decision service while Godot keeps real-time steering.

## Requirements
### Requirement: Topo macro intent comes from batched NanoJev ranking
The system SHALL obtain each AI topo's macro intent by sending one batched NanoJev `Choice` request covering all AI topos and applying the ranked winner. GDScript SHALL build the candidate menu per topo from legal moves only (hybrid insect + edible-patch diet, eat range, drink need, hunted state, dug-refuge proximity, verb cooldowns checked); NanoJev SHALL only rank, never invent moves. Every applied intent SHALL execute through the same functions as the player (`eat_insect`, `eat_patch`, drink/seek, flee/hide resolve, verbs through the same karma paths). `nestdig` (slot 5) SHALL never be offered: it is player-only today, so the ranker is never offered a move the AI cannot legally execute.

#### Scenario: Ranked worm rescue
- **WHEN** an AI topo is hungry with a dug refuge nearby and the sidecar ranks `worm` first
- **THEN** the topo eats a worm for vida and hambre through the same path as the player's slot 3, with no cooldown burned on failure

#### Scenario: Ranker never invents moves
- **WHEN** the sidecar answers with a kind absent from the offered menu
- **THEN** the choice clamps to wander and the topo keeps steering instead of freezing

### Requirement: Topo micro steering never waits
The system SHALL steer every AI topo every physics tick toward its current intent, eat contact insects and edible patches within eat range, trek to distant food when hungry, drink water within drink range, hide/flee when hunted, and tick needs and cooldowns regardless of pending or failed macro answers. The wander tail SHALL follow the ardilla pattern: steer toward the nearest point of interest via `wander_poi`, else a short random step — never accumulating stillness (topo has no stillness-gated defense), so purposeful wandering per `ai-species-behavior` is preserved.

#### Scenario: Contact eat resolves locally
- **WHEN** an AI topo with a pending macro answer touches an insect or edible patch within eat range
- **THEN** it eats immediately without waiting for the answer, through the same functions as the player

#### Scenario: Wander travels to points of interest
- **WHEN** an AI topo holds a wander intent with no food, water, or trigger nearby
- **THEN** it steers toward the nearest point of interest (food, water, cover, company) instead of freezing or accumulating stillness

### Requirement: Topo intent cadence with event re-asks
The system SHALL re-ask macro intent for each AI topo on a staggered 1s timer, and SHALL re-ask immediately on events: predator pressure entering range, fresh insects or edible patches entering perception, aerate/tunneline/worm/larder resolving, or the current intent reaching its target or expiring — at most once per agent per `jevReaskBackoff` window (0.5s). Topos far from the player camera SHALL use a 3s timer instead of 1s. Topo batches SHALL join the Main-owned single-flight batch path with fair cross-species scheduling so no species starves another.

#### Scenario: Threat re-asks promptly
- **WHEN** a hunter enters fear range of an AI topo holding a food intent and the backoff window has elapsed
- **THEN** a re-ask fires on the next poll without waiting for the timer slot

#### Scenario: Far topos poll slower
- **WHEN** an AI topo is farther than half the view diagonal from the player camera
- **THEN** its timer re-asks every 3s instead of every 1s

### Requirement: Topo candidate menu
The candidate menu for a topo SHALL be built from: eat (insect or edible patch within eat range), seek-food (distant insect or edible patch when hungry), drink-seek (water when below the drink threshold), flee-to-refuge (when hunted, size-2 refuges included via the existing fit check), aerate (slot 1 off cooldown, instant-cast digs burrow-M), tunneline (dug refuge within eat range with slot 2 off cooldown), worm (dug refuge within eat range with slot 3 off cooldown, hungry), larder (slot 4 off cooldown: insect within eat range to store, or stored larder with a hungry mate/self in range to share), alarm (hunter within lure range with shout off cooldown), and wander. Wander SHALL always be present so the ranking always has an executable target. Stale answers (actor dead, target gone, food already eaten, refuge gone) SHALL resolve to continued steering or wander, never to a no-op freeze.

#### Scenario: Menu holds a legal-only set
- **WHEN** an AI topo with no dug refuge nearby and aerate on cooldown needs a menu
- **THEN** tunneline and worm are absent, aerate is absent, larder appears only with a storable insect or a sharing target, and wander is always present

#### Scenario: Nestdig never offered
- **WHEN** an AI topo needs a menu under any state
- **THEN** no `nestdig` candidate appears, since the verb returns false for agents

### Requirement: Topo emocion flavor and decision log
Each macro answer MAY carry an `emocion` label that SHALL surface only in HUD/feed flavor and SHALL never gate execution; when the answer carries none, the bridge SHALL appraise one locally from the snapshot (same rule as the other species: fear on threat/pressure, urgency on floor hunger, hunger otherwise). Every live macro decision SHALL append a log entry under schema `jev-topo/v1` with state snapshot, candidate menu, chosen index with probabilities, and outcome to `user://logs/jev_topo.log` only when the topo log flag is on; mocked decisions SHALL never log.

#### Scenario: Emocion never gates
- **WHEN** a live answer carries an unknown or empty `emocion`
- **THEN** the intent still applies fully and the label only flavors the feed

#### Scenario: Disabled log stays silent and cheap
- **WHEN** the topo log flag is off
- **THEN** no entry is buffered, no file is touched, and no memory grows
