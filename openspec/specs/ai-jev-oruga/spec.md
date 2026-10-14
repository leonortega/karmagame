# ai-jev-oruga Specification

## Purpose

NanoJev-backed macro decisions let AI orugas choose from the same leaf-eater menu as a human oruga — eat, silk escape, ant-ally nectar, and leafroll shelter — ranked in parallel by a local decision service while Godot keeps real-time steering and stillness-gated curl defense.

## Requirements

### Requirement: Oruga macro intent comes from batched NanoJev ranking

The system SHALL obtain each AI oruga's macro intent by sending one batched NanoJev `Choice` request covering all AI orugas and applying the ranked winner. GDScript SHALL build the candidate menu per oruga from legal moves only (leaves diet, eat range, drink need, hunted state, clump proximity, verb cooldowns and HP/PA costs checked); NanoJev SHALL only rank, never invent moves. Every applied intent SHALL execute through the same functions as the player (`eat_patch`, drink/seek, flee/hide resolve, verbs through the same karma paths). `prudent` (slot 1) SHALL never be offered separately because `eat_patch` already pays `prudentKarma` automatically on sustainable leaves eating; `bristle` (slot 5) SHALL never be offered because it is player-only today (no agent-side reversal exists in predator contact), so the ranker is never offered a move the AI cannot legally execute.

#### Scenario: Ranked silk escape

- **WHEN** an AI oruga holds a hunter within 150px with slot 2 off cooldown and HP above its cost, and the sidecar ranks `silk` first
- **THEN** the oruga teleports away from the hunter through the same silk path as the player's slot 2, with HP cost and cooldown applied

#### Scenario: Ranker never invents moves

- **WHEN** the sidecar answers with a kind absent from the offered menu
- **THEN** the choice clamps to wander and the oruga keeps steering instead of freezing

#### Scenario: Unaffordable nectar is never offered

- **WHEN** an AI oruga cannot afford the nectar HP or PA cost
- **THEN** the `nectar` candidate is absent from its menu, and a stale pick that fails affordability at apply time resolves to wander without burning HP, PA, or cooldown

### Requirement: Oruga micro steering never waits

The system SHALL steer every AI oruga every physics tick toward its current intent, eat contact leaves within eat range, trek to distant leaves when hungry, drink water within drink range, hide/flee when hunted, and tick needs and cooldowns regardless of pending or failed macro answers. The wander tail SHALL keep accumulating `stillT` instead of traveling (curl requires motionlessness per `ai-species-behavior`), so no stillness-gated defense is lost to JEV steering.

#### Scenario: Contact eat resolves locally

- **WHEN** an AI oruga with a pending macro answer touches edible leaves within eat range
- **THEN** it eats immediately without waiting for the answer, through the same `eat_patch` path as the player (including automatic `prudentKarma` on sustainable bites)

#### Scenario: Wander accumulates stillness without travel

- **WHEN** an AI oruga holds a wander intent with no food, water, or trigger nearby
- **THEN** it accumulates `stillT` in place (curl path) instead of steering to points of interest or random-walking

### Requirement: Oruga intent cadence with event re-asks

The system SHALL re-ask macro intent for each AI oruga on a staggered 1s timer, and SHALL re-ask immediately on events: predator pressure entering range, fresh edible leaves entering perception, silk/nectar/leafroll resolving, or the current intent reaching its target or expiring — at most once per agent per `jevReaskBackoff` window (0.5s). Orugas far from the player camera SHALL use a 3s timer instead of 1s. Oruga batches SHALL join the Main-owned single-flight batch path with fair cross-species scheduling so no species starves another.

#### Scenario: Threat re-asks promptly

- **WHEN** a hunter enters fear range of an AI oruga holding a food intent and the backoff window has elapsed
- **THEN** a re-ask fires on the next poll without waiting for the timer slot

#### Scenario: Far orugas poll slower

- **WHEN** an AI oruga is farther than half the view diagonal from the player camera
- **THEN** its timer re-asks every 3s instead of every 1s

### Requirement: Oruga candidate menu covers the AI-legal kit

The candidate menu for an oruga SHALL be built from: eat (edible leaves patch within eat range), seek-food (distant edible leaves patch when hungry), drink-seek (water when below the drink threshold), flee-to-refuge (when hunted, size-1 and `orugaOnly` refuges included via the existing fit check), silk (hunter within 150px with slot 2 off cooldown and HP above its cost, instant-cast), nectar (hunter within 150px with slot 3 off cooldown and HP plus PA above its costs, instant-cast), leafroll (leaf clump within eat range with slot 4 off cooldown, instant-cast creating an `orugaOnly` refuge), and wander. Wander SHALL always be present so the ranking always has an executable target. Stale answers (actor dead, target gone, patch already eaten) SHALL resolve to continued steering or wander, never to a no-op freeze. Labels SHALL carry urgency hints at floor need so the ranking can weigh urgency the way halcon hunger hints do: the eat label appends a hunger hint whenever hambre sits at or below regenHambre, the drink label appends a thirst hint whenever sed sits at or below regenSed, and the seek-food label appends a hunger hint (it is only offered when hungry; the hint fires at the floor). Labels SHALL never gate execution: kinds, legality gates, and affordability checks are untouched.

#### Scenario: Menu always has wander

- **WHEN** an AI oruga has no food, water, pressure, clump, or ready verb
- **THEN** its menu contains exactly one candidate (`wander`) so the ranker always has an executable target

#### Scenario: Silk needs a hunter in range

- **WHEN** no hunter sits within 150px of an AI oruga, or slot 2 is on cooldown, or HP cannot cover its cost
- **THEN** the `silk` candidate is absent from its menu

#### Scenario: Leafroll needs a clump in range

- **WHEN** no leaf clump sits within eat range of an AI oruga, or slot 4 is on cooldown
- **THEN** the `leafroll` candidate is absent from its menu

#### Scenario: Eat label plain when sated

- **WHEN** an AI oruga holds contact leaves with hambre above regenHambre
- **THEN** its eat candidate label carries no hunger hint

#### Scenario: Eat and drink labels hint need at floor

- **WHEN** an AI oruga holds contact leaves with hambre at or below regenHambre, or drinkable water with sed at or below regenSed
- **THEN** the matching candidate label carries the hunger or thirst hint so the ranking can weigh need

### Requirement: Oruga log is the only JEV log on

Each macro answer MAY carry an `emocion` label that SHALL surface only in HUD/feed flavor and SHALL never gate execution; when the answer carries none, the bridge SHALL appraise one locally from the snapshot (same rule as the other species: fear on threat/pressure, urgency on floor hunger, hunger otherwise). Every live macro decision SHALL append a log entry under schema `jev-oruga/v1` with state snapshot, candidate menu, chosen index with probabilities, and outcome to `user://logs/jev_oruga.log` only when the oruga log flag is on; mocked decisions SHALL never log. While this change is active, the oruga log flag SHALL be the only JEV log flag on (zorro, halcon, raton, ardilla, sapo, topo, lobo all off).

#### Scenario: Live decision logs under oruga schema

- **WHEN** a live oruga macro answer is applied with the oruga log flag on
- **THEN** one entry with schema `jev-oruga/v1` is buffered for `user://logs/jev_oruga.log` with snapshot, menu, choice, probs, and applied outcome

#### Scenario: Mock path never logs

- **WHEN** an oruga macro intent comes from the local mock fallback
- **THEN** no log entry is buffered regardless of the log flag

#### Scenario: Other species stay silent

- **WHEN** any non-oruga live macro decision applies while this change is active
- **THEN** no log entry is buffered for that species
