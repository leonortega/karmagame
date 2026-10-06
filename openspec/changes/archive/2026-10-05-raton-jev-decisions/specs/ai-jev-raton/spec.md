## Purpose

NanoJev-backed macro decisions let AI ratons choose from the same grazer menu as a human raton, ranked in parallel by a local decision service while Godot keeps real-time steering and the groom/share social verbs.

## ADDED Requirements

### Requirement: Raton macro intent comes from NanoJev ranking over code-built candidates

The system SHALL obtain each AI raton's macro intent by sending one batched NanoJev `Choice` request covering all AI ratons and applying the ranked winner. GDScript SHALL build the candidate menu per raton from legal moves only (edible-patch diet, range, drink need, hunted state checked); NanoJev SHALL only rank, never invent moves. Every applied intent SHALL execute through the same functions as the player (`eat_patch`, drink/seek, flee/hide resolve, social verbs through the same karma paths).

#### Scenario: Batched parallel decision

- **WHEN** 3 AI ratons need macro intent in the same window
- **THEN** the system sends one batch request with 3 states and per-raton candidates and applies one returned choice per raton

#### Scenario: Illegal move is impossible by construction

- **WHEN** no edible patch is within contact range and the raton is sated
- **THEN** its candidate menu contains no eat entry, so no ranking can select it

#### Scenario: Player parity of effects

- **WHEN** the ranked winner is eat on an edible patch within eat range
- **THEN** the patch loses one fruit and the raton gains the same HP as a player eat

### Requirement: Micro steering never waits for the API

The system SHALL steer every AI raton every physics tick toward its current intent, eat contact patches, trek to distant food when hungry, drink water within drink range, hide/flee when hunted, and tick needs and cooldowns regardless of pending or failed macro answers. Wander intent SHALL fall through to the social-verb path (groom/share) when not hungry so no karma behavior is lost.

#### Scenario: Movement continues during API latency

- **WHEN** a macro answer is pending for 500ms with intent seek-food
- **THEN** the raton keeps moving toward the food each physics tick

#### Scenario: Contact eat resolves locally

- **WHEN** a raton with eat intent reaches eat range of an edible patch
- **THEN** the eat resolves that tick through the same eat path as today, without waiting for a new macro answer

#### Scenario: Social verbs survive JEV mode

- **WHEN** a raton steers wander intent near a company mate while not hungry
- **THEN** the groom/share path still triggers with the same karma and cooldowns as the ladder

### Requirement: Macro cadence is staggered timer plus events with data-LOD

The system SHALL re-ask macro intent for each AI raton on a staggered 1s timer, and SHALL re-ask immediately on events: predator pressure entering range, fresh food entering perception, or the current intent reaching its target or expiring. Ratons far from the player camera SHALL use a 3s timer instead of 1s. Raton batches SHALL share the single-batch-per-window path with fair cross-species scheduling so no species starves another.

#### Scenario: Staggered timer

- **WHEN** 4 ratons are active and 1s elapses
- **THEN** their re-asks spread across the window rather than all firing on the same frame

#### Scenario: Event re-ask on threat

- **WHEN** a hunter enters a raton's fear range outside its timer slot
- **THEN** the system re-asks macro intent for that raton immediately with a flee/refuge menu

#### Scenario: Data-LOD slowdown

- **WHEN** a raton is far from the player camera
- **THEN** its timer cadence is 3s while on-screen ratons keep 1s

### Requirement: Candidate menu covers the grazer kit with always-present wander

The candidate menu for a raton SHALL be built from: eat (contact edible patch), seek-food (distant edible patch when hungry), drink-seek (water when below the drink threshold), flee-to-refuge (when hunted), alarm-call (hunter within lure range with shout off cooldown), groom (company mate within groom range), seed-cache (edible flora with spare fruit in range), and wander. Wander SHALL always be present so the ranking always has an executable target. Stale answers (actor dead, target gone) SHALL resolve to continued steering or wander, never to a no-op freeze. Groom SHALL keep its 3s-continuous timer (no instant karma); alarm and seed-cache SHALL pay through the same verb paths as the player with identical karma and cooldowns.

#### Scenario: Hungry raton seeks distant food

- **WHEN** a hungry raton has no contact patch but an edible patch is inside forage range
- **THEN** its menu includes seek-food alongside wander

#### Scenario: Social raton grooms by choice

- **WHEN** a raton stands within groom range of a company mate
- **THEN** its menu includes groom, and applying it steers the raton to stay near the mate with karma granted only after 3s continuous proximity through the same timer as today

#### Scenario: Threatened raton alarms by choice

- **WHEN** a hunter is inside lure range and the raton's shout is off cooldown
- **THEN** its menu includes alarm-call, and applying it grants the same karma and cooldown as the ladder shout

#### Scenario: Stale answer hygiene

- **WHEN** a macro answer references a patch harvested before the answer arrives
- **THEN** the raton continues steering on its prior intent or wanders, and requests fresh intent on its next slot

### Requirement: Emocion is flavor only plus per-species decision logging

Each macro answer MAY carry an `emocion` label that SHALL surface only in HUD/feed flavor and SHALL never gate execution. Every live macro decision SHALL append a log entry under schema `jev-raton/v1` with state snapshot, candidate menu, chosen index with probabilities, and outcome to `user://logs/jev_raton.log` only when the raton log flag is on; mocked decisions SHALL never log.

#### Scenario: Emocion never blocks

- **WHEN** an answer arrives with choice eat and emocion Miedo
- **THEN** the raton eats the patch and the feed may show the emocion as text only

#### Scenario: Decision log isolation

- **WHEN** a live raton choice is applied while the raton log flag is on
- **THEN** the log holds the snapshot, the full menu, the chosen index with its probability distribution, and the later outcome in `jev_raton.log`, and no entry appears in any other species file
