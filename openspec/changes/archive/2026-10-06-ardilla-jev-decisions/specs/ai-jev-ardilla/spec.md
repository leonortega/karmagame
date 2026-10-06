## Purpose

NanoJev-backed macro decisions let AI ardillas choose from the same climber menu as a human ardilla — including two-phase nut carrying across intents — ranked in parallel by a local decision service while Godot keeps real-time steering.

## ADDED Requirements

### Requirement: Ardilla macro intent comes from NanoJev ranking over code-built candidates

The system SHALL obtain each AI ardilla's macro intent by sending one batched NanoJev `Choice` request covering all AI ardillas and applying the ranked winner. GDScript SHALL build the candidate menu per ardilla from legal moves only (edible-patch and oak diet, range, drink need, hunted state, carried-nut state checked); NanoJev SHALL only rank, never invent moves. Every applied intent SHALL execute through the same functions as the player (`eat_patch`, `bury_or_carry_nut`, drink/seek, flee/hide resolve, verbs through the same karma paths).

#### Scenario: Batched parallel decision

- **WHEN** 3 AI ardillas need macro intent in the same window
- **THEN** the system sends one batch request with 3 states and per-ardilla candidates and applies one returned choice per ardilla

#### Scenario: Illegal move is impossible by construction

- **WHEN** no edible patch is within contact range and the ardilla is sated
- **THEN** its candidate menu contains no eat entry, so no ranking can select it

#### Scenario: Player parity of effects

- **WHEN** the ranked winner is eat on an edible patch within eat range
- **THEN** the patch loses one fruit and the ardilla gains the same HP as a player eat

### Requirement: Nut carrying survives across intents

Carried-nut state SHALL live on the agent, not in the intent: an ardilla that picks up a nut and whose intent then expires or is replaced SHALL still carry the nut, and its next menu SHALL offer burying. A hungry carrier SHALL eat the nut (dropping it) exactly as the ladder does today, through the same path.

#### Scenario: Carry persists past intent expiry

- **WHEN** an ardilla picks up a nut and its carry intent expires before it buries
- **THEN** `carriedNut` stays true and the rebuilt menu offers bury-nut

#### Scenario: Hungry carrier eats the nut

- **WHEN** a nut-carrying ardilla's `hambre` drops below 100 with no better food taken
- **THEN** it eats the carried nut (clearing `carriedNut`) instead of burying it

#### Scenario: Bury plants the future forest

- **WHEN** the ranked winner is bury-nut with `carriedNut` true
- **THEN** the nut is buried through the same path as the player: `saplings` increments, an oak-tree seedling spawns, and the ardilla gains the same karma

### Requirement: Micro steering never waits for the API

The system SHALL steer every AI ardilla every physics tick toward its current intent, eat contact patches, trek to distant food when hungry, drink water within drink range, hide/flee when hunted (climb-only refuges included via the existing fit check), and tick needs and cooldowns regardless of pending or failed macro answers. Wander intent SHALL fall through to the social-verb path (groom/share) when not hungry so no karma behavior is lost.

#### Scenario: Movement continues during API latency

- **WHEN** a macro answer is pending for 500ms with intent seek-food
- **THEN** the ardilla keeps moving toward the food each physics tick

#### Scenario: Contact eat resolves locally

- **WHEN** an ardilla with eat intent reaches eat range of an edible patch
- **THEN** the eat resolves that tick through the same eat path as today, without waiting for a new macro answer

#### Scenario: Social verbs survive JEV mode

- **WHEN** an ardilla steers wander intent near a company mate while not hungry
- **THEN** the groom/share path still triggers with the same karma and cooldowns as the ladder

### Requirement: Macro cadence is staggered timer plus events with data-LOD

The system SHALL re-ask macro intent for each AI ardilla on a staggered 1s timer, and SHALL re-ask immediately on events: predator pressure entering range, fresh food entering perception, nut pickup or burial, or the current intent reaching its target or expiring. Ardillas far from the player camera SHALL use a 3s timer instead of 1s. Ardilla batches SHALL join the Main-owned batch path with an explicit per-species scheduling function (no generalized N-way picker, per the per-species-everything stance) so no species starves another.

#### Scenario: Staggered timer

- **WHEN** 4 ardillas are active and 1s elapses
- **THEN** their re-asks spread across the window rather than all firing on the same frame

#### Scenario: Event re-ask on nut pickup

- **WHEN** an ardilla picks up a nut outside its timer slot
- **THEN** the system re-asks macro intent for that ardilla immediately with a bury-nut menu

#### Scenario: Data-LOD slowdown

- **WHEN** an ardilla is far from the player camera
- **THEN** its timer cadence is 3s while on-screen ardillas keep 1s

### Requirement: Candidate menu covers the climber kit with always-present wander

The candidate menu for an ardilla SHALL be built from: eat (contact edible patch or nut), seek-food (distant edible patch when hungry), carry-nut (oak with nuts near, hands empty), bury-nut (`carriedNut` true), bark (oak in range off cooldown), falsecache (hunter in distraction range off cooldown), tailflick (danger near), drink-seek (water when below the drink threshold), flee-to-refuge (when hunted, climb-only refuges included), and wander. Wander SHALL always be present so the ranking always has an executable target. Stale answers (actor dead, target gone, nut eaten) SHALL resolve to continued steering or wander, never to a no-op freeze.

#### Scenario: Carrier chooses burial over meal

- **WHEN** a nut-carrying ardilla stands on an edible patch with a free bury spot
- **THEN** its menu includes both eat and bury-nut alongside wander

#### Scenario: Stale answer hygiene

- **WHEN** a macro answer references an oak harvested before the answer arrives
- **THEN** the ardilla continues steering on its prior intent or wanders, and requests fresh intent on its next slot

### Requirement: Emocion is flavor only plus per-species decision logging

Each macro answer MAY carry an `emocion` label that SHALL surface only in HUD/feed flavor and SHALL never gate execution. Every live macro decision SHALL append a log entry under schema `jev-ardilla/v1` with state snapshot, candidate menu, chosen index with probabilities, and outcome to `user://logs/jev_ardilla.log` only when the ardilla log flag is on; mocked decisions SHALL never log.

#### Scenario: Emocion never blocks

- **WHEN** an answer arrives with choice bury-nut and emocion Miedo
- **THEN** the ardilla buries the nut and the feed may show the emocion as text only

#### Scenario: Decision log isolation

- **WHEN** a live ardilla choice is applied while the ardilla log flag is on
- **THEN** the log holds the snapshot, the full menu, the chosen index with its probability distribution, and the later outcome in `jev_ardilla.log`, and no entry appears in any other species file
