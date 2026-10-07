## Purpose

NanoJev-backed macro decisions let AI sapos choose from the same tongue-insectivore menu as a human sapo — including the toxin/burrow/chorus threat verbs — ranked in parallel by a local decision service while Godot keeps real-time hopping, tongue grabs, and stillness camouflage.

## ADDED Requirements

### Requirement: Sapo macro intent comes from batched NanoJev ranking
The system SHALL obtain each AI sapo's macro intent by sending one batched NanoJev `Choice` request covering all AI sapos and applying the ranked winner. GDScript SHALL build the candidate menu per sapo from legal moves only (insect diet, tongue range with `tonguePlus`, drink need, hunted state, verb cooldowns and HP-costs checked); NanoJev SHALL only rank, never invent moves. Every applied intent SHALL execute through the same functions as the player (`eat_insect`, drink/seek, flee/hide resolve, verbs through the same karma paths).

#### Scenario: Ranked tongue hunt
- **WHEN** an AI sapo is hungry with insects in forage range and the sidecar ranks `seek_food` first
- **THEN** the sapo steers toward that insect and eats it on contact for +10 vida and +3 pest-control karma, exactly as the player's tongue grab pays

#### Scenario: Ranker never invents moves
- **WHEN** the sidecar answers with a kind absent from the offered menu
- **THEN** the choice clamps to wander and the sapo keeps steering instead of freezing

### Requirement: Sapo micro steering never waits
The system SHALL steer every AI sapo every physics tick toward its current intent, eat contact insects within tongue range, trek to distant insects when hungry, drink water within drink range, hide/flee when hunted, and tick needs and cooldowns regardless of pending or failed macro answers. The wander tail SHALL keep accumulating `stillT` instead of traveling (camouflage requires motionlessness per `ai-species-behavior`), so no stillness-gated defense is lost to JEV steering.

#### Scenario: Contact grab resolves locally
- **WHEN** an AI sapo with a pending macro answer touches an insect within tongue range
- **THEN** it eats the insect immediately without waiting for the answer

#### Scenario: Wander keeps stillness
- **WHEN** an AI sapo holds a wander intent with no food, water, or trigger nearby
- **THEN** it accumulates `stillT` toward camouflage instead of traveling to a point of interest

### Requirement: Sapo intent cadence with event re-asks
The system SHALL re-ask macro intent for each AI sapo on a staggered 1s timer, and SHALL re-ask immediately on events: predator pressure entering range, fresh insects entering perception, toxin/burrow/chorus resolving, or the current intent reaching its target or expiring — at most once per agent per `jevReaskBackoff` window (0.5s). Sapos far from the player camera SHALL use a 3s timer instead of 1s. Sapo batches SHALL join the Main-owned single-flight batch path with fair cross-species scheduling so no species starves another.

#### Scenario: Threat re-asks promptly
- **WHEN** a hunter enters fear range of an AI sapo holding a food intent and the backoff window has elapsed
- **THEN** a re-ask fires on the next poll without waiting for the timer slot

#### Scenario: Far sapos poll slower
- **WHEN** an AI sapo is farther than half the view diagonal from the player camera
- **THEN** its timer re-asks every 3s instead of every 1s

### Requirement: Sapo candidate menu
The candidate menu for a sapo SHALL be built from: eat (insect within tongue range), seek-food (distant insect when hungry), pest (insect within tongue range with slot 2 off cooldown, instant-cast), drink-seek (water when below the drink threshold), flee-to-refuge (when hunter pressure is near, size-1 refuges included), burrow-in (pressure in fear range with slot 3 off cooldown), toxin (hunter within 60px with slot 4 off cooldown and HP above its cost), croak (hunter within lure range with shout off cooldown), chorus (sapo choir within groom range with slot 5 off cooldown), and wander. Wander SHALL always be present so the ranking always has an executable target. Stale answers (actor dead, target gone, insect already eaten) SHALL resolve to continued steering or wander, never to a no-op freeze. Toxin SHALL NOT be offered or applied when the sapo cannot afford its vida cost; a pick that fails affordability at apply time SHALL resolve to wander.

#### Scenario: Menu holds a legal-only set
- **WHEN** an AI sapo on cooldown for toxin with no choir nearby needs a menu
- **THEN** toxin and chorus are absent, pest appears only with an insect in tongue range, and wander is always present

#### Scenario: Unaffordable toxin fails safe
- **WHEN** a ranked toxin pick reaches an AI sapo whose vida no longer covers the cost
- **THEN** the sapo keeps steering (wander) with no karma, no cost, and no cooldown burned

### Requirement: Sapo emocion flavor and decision log
Each macro answer MAY carry an `emocion` label that SHALL surface only in HUD/feed flavor and SHALL never gate execution; when the answer carries none, the bridge SHALL appraise one locally from the snapshot (same rule as the other species). Every live macro decision SHALL append a log entry under schema `jev-sapo/v1` with state snapshot, candidate menu, chosen index with probabilities, and outcome to `user://logs/jev_sapo.log` only when the sapo log flag is on; mocked decisions SHALL never log.

#### Scenario: Emocion never gates
- **WHEN** a live answer carries an unknown or empty `emocion`
- **THEN** the intent still applies fully and the label only flavors the feed

#### Scenario: Disabled log stays silent and cheap
- **WHEN** the sapo log flag is off
- **THEN** no entry is buffered, no file is touched, and no memory grows
