## Why

T1/T2 players are effectively invulnerable to the carnivores that should pressure them. Fauna zorros, lobos, and halcones are `role="fauna"`, so the only pass that can damage the possessed player (`update_predators` over `hunter_agents`) never sees them; the separate species-AI pass hunts AI agents but never the player.

The deeper problem is the model, not the wiring: animals carry three overlapping labels (`role`, `kind`, `type`), behavior is selected from those labels, the player is a special non-agent at `px`/`py`/`hp`/..., and a T0-only `saponpc` morph exists to patch a missing pressure source. Hunting is not a role; it is the pair `(actor, target)` - what the actor can eat. Every animal should run the same action model: species data defines legal actions and parameters, `brain` selects input vs AI, and needs/age tick once per animal per world update.

The regression probe is unchanged: a fauna Zorro adjacent to a T1 player for 400 ticks leaves HP at `100.0` (0 drops), while the same Zorro under `step_predator` deals `28` damage.

## What Changes

- **One agent model.** Every animal, player included, is an entry in `state["agents"]` with a species data key, position, facing, HP, hambre, sed, edad, brain, and its own action state. No `role`, `kind`, or `type` label; no `saponpc`.
- **One action pipeline.** Each tick every agent runs exactly one step. `brain="PLAYER"` selects actions from input; `brain="AI"` runs the species action policy. Both execute the same action/verb/micro-action table; species data only supplies parameters and legal actions.
- **Trophic per pair.** `can_eat(actor, target)` derives from species data (diet, prey tiers/sizes, carrion, mates). No predator category and no separate predator pass; AI menus and threat scans filter candidates through the pair check.
- **Player is an agent.** `possess_member` keeps the census member and flips its brain to `PLAYER`; it no longer erases the body or copies fields. The player body/needs/age/action state live on that agent. Player ledger (`karma`, `pa`, `owned`, `lifeLog`) remains the player account. Company is derived as same-species AI agents; fauna as other-species AI agents.
- **Remove `saponpc`.** Delete `seed_foes`, the T0 reserve/respawn special case, the sapo census reservation, and the `saponpc` data row. T0 pressure comes from rolled fauna (halcon's size rule and zorro contact snap); T0 softening applies to those rolled animals.
- **Remove `type`.** Key trophic data by species. Halcon gets a species trophic row using its existing effective values plus a prey-size rule, so its behavior is unchanged and no special case remains.
- **Remove `role`/`kind`.** Company/fauna/threat queries derive from species + brain; no agent carries a behavior label.
- **BREAKING state shape.** The possessed agent's body fields are the source of truth. Top-level player body fields (`px`, `py`, `hp`, `hambre`, `sed`, `edad`, verb cooldowns, hidden/hideRef, and related body state) are replaced by accessors on the possessed agent; there is no permanent duplicate mirror. Player account/UI fields (`karma`, `pa`, `owned`, `lifeLog`, shop/intro/pause) stay top-level.

**Non-goals:** no tuning or balance changes; no new species or actions; no removing species data (species stays the data key, not a role); no JEV menu consolidation; no save migration (there is no save with this shape).

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `living-map`: the roster requirement is actually implemented - the possessed census member stays in `agents`, no role/kind/type labels, company/fauna derived, and the shared hunger-eat-die loop is role-free.
- `ecosystem-2d`: hunting becomes per-pair trophic data; the possessed agent is prey by species; one step per animal; `saponpc`, scripted pressure, and `type` branches are removed.
- `ai-survival`: hide/flee triggers generalize from "role-hunter" to any animal whose species data can eat the agent.
- `ecosystem-census`: no `saponpc`/T0 scripted pressure; hunter-mouth counts use species trophic data; the sapo slot is no longer reserved.

## Impact

- `scripts/karma_state.gd`: one agent roster, possession without erase, derived company/fauna, accessors, spawn/respawn without `saponpc`/`type`.
- `scripts/karma_game.gd`: one `step_agent` loop; player brain; no `update_predators`; no role skip.
- `scripts/karma_predators.gd`: per-pair `can_eat`/`can_eat_agent`, species-keyed trophic data, no `predator_type`/`is_predator`/`saponpc` branch.
- `scripts/karma_data.gd`: delete the `saponpc` row; key `PRED` by species; add halcon's existing effective row/size rule; no `TUNING` change.
- `scripts/karma_ai*.gd`, `karma_utils.gd`, `karma_jev_*.gd`: threat/hide/flee scans use the pair check; the possessed agent uses input, not AI.
- `scripts/karma_eat.gd`, `karma_shop.gd`, `karma_hud.gd`, `karma_draw.gd`, `main.gd`: player body access through the possessed agent; no role/type labels.
- `tests/`: role/kind/type/saponpc fixtures removed; new roster, possession, no-label, T0-pressure, player-prey, and single-tick tests.
- No new dependencies; all numbers stay in `KarmaData.TUNING`.
