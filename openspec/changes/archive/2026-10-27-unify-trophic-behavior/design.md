## Context

See `proposal.md` - Why for the regression. The current code has three disjoint ideas:

- `KarmaPredators.update_predators` walks `KarmaState.hunter_agents` (`role == "hunter"`) and runs `step_predator`: needs, cooldowns, fear, camp, thirst, player targeting, AI-prey strikes, contact damage, feast.
- `KarmaGame.update_agents` walks every agent and runs `KarmaAI.ai_step` for all except `role == "hunter"`. Species AI (Jev menus or ladder) hunts AI prey through `nearest_ai_prey`/`KarmaJev*` and never the possessed player.
- The player is not in `agents`. `possess_member` copies `x`/`y` to `px`/`py` and erases the census member; `state` carries a second body (`hp`, `hambre`, `sed`, `edad`, verbs, hidden, ...).

`KarmaData.DIET` and `KarmaData.PRED` already describe predation. `zorro`/`lobo`/`halcon` have `DIET` entries with `"mates"`; `zorro`/`lobo`/`saponpc` also have `PRED` rows. `halcon` has no `PRED` row and falls back to `KarmaData.PRED_FALLBACK`/`SPECIES.vision`. `saponpc` is a sapo with its own `type` and `PRED` row, spawned only for T0 and counted against the sapo census slot.

Constraints: `tests/test_karma_senescence.gd:281-328` requires exactly one age/needs tick per animal per world update and names the T0 pressure body; `update_agents` duplicates the agent array because kills mutate it; all numbers stay in `KarmaData.TUNING`; no rebalancing.

## Goals / Non-Goals

**Goals:**

- One agent model for every animal, including the possessed player.
- One behavior step per animal per tick, with one needs/age tick.
- Predation from species data per pair, not from `role`/`kind`/`type`.
- Remove `saponpc`, the T0 scripted spawn/respawn, and the sapo census reservation.
- Remove `role`/`kind`/`type` as behavior selectors and fields.
- Keep hiding, camouflage, curl, bristle, invulnerability, age-scaled damage, camp, carrion, Jev verbs, and shop behavior.
- Keep T0 pressure without a special morph: rolled halcon and contact snap zorro are the pressure.

**Non-Goals:**

- Tuning or balance changes.
- Merging the six species JEV menus or the two AI-prey hunt implementations.
- New species, actions, or content.
- Save migration (no save with this shape).
- Per-agent `hideRef` is required, not optional, once the player is an agent; it is part of the action state.

## Decisions

### 1. One agent record; species data is data, not a role

Every animal is a dictionary in `state["agents"]`:

```gdscript
{
  "speciesKey": "zorro", "brain": "AI",  # or "PLAYER"
  "x": 0.0, "y": 0.0, "face": {"x": 1.0, "y": 0.0},
  "hp": 100.0, "hambre": 100.0, "sed": 100.0, "edad": 0.0,
  # action state: mode, restT, satedT, cooldowns, hidden, hideRef, ...
}
```

`speciesKey` selects a `KarmaData.SPECIES` row and therefore its stats, diet, legal actions, and sprite. It is a data key, not a behavior label. `brain` is the controller: `PLAYER` reads input, `AI` runs the species policy. There is no `role`, `kind`, or `type` field, and no `saponpc` entry.

Company/fauna queries derive from species + brain:

- company: `speciesKey == player_species and brain != "PLAYER"`.
- fauna: `speciesKey != player_species and brain != "PLAYER"`.
- threat/prey: `can_eat(other, self)`.

The player account (`karma`, `pa`, `owned`, `lifeLog`, `feed`) stays top-level because it is the player's judgment ledger, not a body property. The possessed agent is the player's body.

Alternatives considered:

- Keep `role` for spawn provenance only. Rejected: the labels already drift from behavior and every consumer can derive the same answer from species + brain.
- Keep `saponpc` as a data row without a `type`. Rejected: it is a second sapo species in disguise; the T0 pressure it provides already exists in rolled halcon/zorro.
- Keep `type` as a variant key. Rejected: with `saponpc` gone it is identical to `speciesKey` for every animal.

### 2. One action pipeline, controller split only

`KarmaGame.update` does one pass:

```gdscript
for a in agents.duplicate():
    KarmaGame.step_agent(state, a, dt, solids)
```

`step_agent`:

1. Ticks needs/age/proximity once (the only needs/age owner).
2. If `brain == "PLAYER"`, consumes the intents queued by `main.gd`'s `_unhandled_input` and runs the same action/verb executors.
3. Else runs the species AI policy (`KarmaAI.ai_step` / species step).
4. Both paths call the same action/verb executors (`KarmaEat`, verbs, strike, hide, etc.).

The existing `update_predators` pass and the `role != "hunter"` skip are deleted. `restT`/`satedT`/cooldowns are ticked in `step_agent`, not twice. `update_agents` keeps `.duplicate()` because kills mutate the roster.

Alternatives considered:

- Keep `step_predator` as a scripted path for `saponpc`. Rejected: `saponpc` is removed.
- Keep `update_predators` and add all carnivores to it. Rejected: double needs/aging and a second movement owner.
- Fold JEV menus into one generic brain. Rejected: large, high-risk; the controller split already gives one pipeline.

### 3. Trophic checks are per pair, not per category

Add pure helpers in `KarmaPredators`:

```gdscript
static func can_eat(actor_species: String, target_species: String, dist: float) -> bool
static func can_eat_agent(actor: Dictionary, target: Dictionary) -> bool
```

`can_eat` reads the actor's species trophic row:

- `diet` entries (plants, carrion, insects) decide flora/scavenging.
- `preyTiers` (zorro 0-1, lobo 2) or `preySizes` (halcon 1-2) decide animal prey.
- `fears` decides flee reactions.
- The 2+ size-difference rule (optimal foraging) stays a single shared check, not a species special case.

No `is_predator`/`predator_type` category. An animal "hunts" only when a candidate passes `can_eat`; a scan that finds no candidate costs nothing.

`KarmaData.PRED` is keyed by `speciesKey` (`zorro`, `lobo`, `halcon`) and no longer by `type`. The halcon row uses its current effective values (perception from `SPECIES.vision`, damage `15`, body `18`, `preySizes [1, 2]`, no fears) so behavior is unchanged. The `saponpc` row is deleted. `edible_for`/`edible_agent_for` take species keys; their `saponpc` special case and the halcon hard-code are replaced by row data.

Alternatives considered:

- Keep a `predator` flag and a predator pass. Rejected: the category is the source of the current bug.
- Derive `type` from `speciesKey` at call sites. Rejected: a rename, not a model change.

### 4. T0 pressure without a special morph

`seed_foes` and the `respawn_missing` saponpc branch are deleted. `seed_fauna` no longer subtracts one sapo for T0. T0 pressure is:

- halcon: rolled at its census floor, hunts size 1-2 prey (including oruga), so the oruga start is pressured.
- zorro: hunts tiers 0-1 but only snaps at contact range across a 2-size gap; it does not begin a distant chase.
- lobo: does not begin hunts against T0/T1 by spawn/water pressure; contact damage still applies.

The T0 softening requirement changes accordingly: no extra scripted predator, rolled fauna offset from prey clusters, and the same lobo restriction. This removes a data row and a spawn path without changing any `TUNING` number. If playtesting shows T0 is too quiet, that is a separate balance change, not a hidden morph.

### 5. Player is the possessed agent; no duplicate body

`possess_member`:

```gdscript
for a in agents:
    if a.speciesKey == state.speciesKey and a.brain != "PLAYER":
        a.brain = "PLAYER"
        return a
```

It does not erase the member, copy fields, or spawn a body. The player body is that agent. Top-level body fields are removed and replaced by accessors:

```gdscript
static func player(state: Dictionary) -> Dictionary
static func px(state: Dictionary) -> float
static func py(state: Dictionary) -> float
```

Reads become `KarmaState.px(state)` / `KarmaState.player(state)["hp"]`; writes mutate the agent. `main.gd`, HUD, draw, shop, verbs, eat, and tests migrate in the same change. `state["speciesKey"]`/`state["sp"]` remain only as the player's immutable species identity (not body state), so body values still have one owner. `state["possessed"]` (currently unused) is deleted.

`respawn_missing` no longer adds `1` for the player species because the possessed member is already counted in `agents`; this fixes a latent double count. `distant_pt` reads the possessed agent's position through `player(state)`.

Company/fauna use the derived queries; `spawn_company`/`spawn_fauna` stop writing `role` and `kind`.

Alternatives considered:

- Keep `px`/`py` mirrored from the agent each tick. Rejected: two sources drift, especially during verbs and damage.
- Keep the player out of `agents` and add a virtual prey path. Rejected: it is the current special case and cannot satisfy "all animals do actions".
- Move the player ledger into the agent now. Rejected for this change: it is orthogonal to behavior and increases the diff; the ledger stays the player account.

### 6. TDD order

Phase A - model and cull:

1. Red: no `saponpc`, no `type`/`role`/`kind`; halcon still hunts; T0 pressure from rolled fauna.
2. Red: per-pair `can_eat` for zorro/lobo/halcon; player as a carnivore target by species.
3. Green: species-keyed trophic data, one `step_agent`, delete `update_predators`/role skip, delete `seed_foes`/respawn special case.

Phase B - player as agent:

4. Red: possessed member stays in `agents` with `brain="PLAYER"`; no duplicate body; company/fauna derived; respawn count correct.
5. Red: player damage/hunger/aging/verbs read and write the possessed agent; one tick.
6. Green: accessors, migrate call sites, delete top-level body fields and `possessed`.

Every step keeps the suite green; apply guidance loads `tdd-workflow` and `safe-refactor` and judges each diff through `solid`/`clean-code`/`ponytail`.

## Risks / Trade-offs

- **Large state-shape diff** - stage 2 touches ~160 player-field call sites. Mitigation: accessors first, mechanical migration, tests after each module; no permanent mirror.
- **Double action/needs** - `step_agent` owns needs/age/cooldowns and movement once; tests assert one tick per animal, including the possessed agent.
- **Halcon loses predation** - its species row carries the existing effective damage/body/perception and `preySizes`; unit tests cover halcon true, oruga false, and the size gap.
- **T0 becomes quiet or harsh** - pressure moves from `saponpc` to rolled halcon/zorro. The census still rolls halcon at its floor; tests assert presence and the lobo restriction. Any tuning is a separate change.
- **Player death/judgment** - the possessed agent is removed from the roster on death; judgment reads the player account, not the body. Tests cover death, respawn, and no duplicate body.
- **Per-pair scan cost** - scans are bounded by perception and existing candidate lists; no new global pass. If needed, cache a species-level `hasAnimalPrey` flag, never an agent label.
- **Stale LSP false errors** - refresh Godot editor diagnostics before trusting results.

## Migration Plan

Code-only; no save migration. Phase A can land green before Phase B, but the change is not complete until the possessed agent is the only player body. Rollback is a revert of the change commit. All `KarmaData.TUNING` values stay unchanged; the only data edits are deleting `saponpc` and adding the halcon species row with its current effective values.
