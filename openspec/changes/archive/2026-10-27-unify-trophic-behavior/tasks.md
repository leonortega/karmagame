## 1. Baseline and red tests

- [x] 1.1 Run the full gdUnit4 suite and record the green baseline (test count, errors, failures, orphans) before editing.
- [x] 1.2 Add a failing regression test: a fauna Zorro in contact range of a non-hidden, non-curled, non-invulnerable T1 player drops the possessed agent's Vida by 28 and sets the 1s invulnerability window.
- [x] 1.3 Add failing single-step tests: one `KarmaGame.update` advances a fauna Zorro's `edad` by `dt` exactly once; the possessed agent's needs/age advance exactly once; no animal is stepped twice.
- [x] 1.4 Add failing model tests: no agent carries `role`, `kind`, or `type`; no `saponpc` row or spawn exists; zorro, lobo, and halcon pass `can_eat` for their species prey; oruga/raton/topo do not; halcon keeps its size rule through data.
- [x] 1.5 Add failing T0-pressure tests: a T0 oruga start gets no `saponpc`; rolled halcon is present; zorro only snaps at contact across the size gap; lobo does not begin a T0/T1 hunt by spawn pressure.
- [x] 1.6 Add failing possession tests: `possess_member` keeps the census member, sets `brain="PLAYER"`, does not erase it, and does not create a second body; `respawn_missing` counts the possessed member once.

## 2. Data model and cull

- [x] 2.1 Delete the `saponpc` row from `KarmaData.PRED`; key `PRED` by species; add halcon's row with its current effective values and `preySizes [1, 2]`; no `TUNING` value changes.
- [x] 2.2 Delete `seed_foes`, the `respawn_missing` saponpc branch, and the `seed_fauna` T0 sapo reservation; add/keep census tests for rolled counts.
- [x] 2.3 Remove `type` from `mk_predator`/`spawn_fauna`/agent creation and every `a["type"]` read; `speciesKey` is the only species key.
- [x] 2.4 Replace `predator_type`/`is_predator` with per-pair `can_eat(actor_species, target_species, dist)` and `can_eat_agent(actor, target)`; delete the `saponpc` and halcon special cases in `edible_for`/`edible_agent_for`.
- [x] 2.5 Move zorro/lobo/halcon player and AI-prey targeting onto `can_eat_agent`; preserve hiding, camouflage, curl, bristle, invulnerability, camp, carrion, and age-scaled damage.
- [x] 2.6 Delete `update_predators`, its `KarmaGame.update` call, and the `role != "hunter"` skip in `update_agents`; route every agent through one `step_agent` with needs/age/cooldowns ticked once.
- [x] 2.7 Delete `hunter_agents`/`all_hunters` and rewrite `distant_pt`, `wander_mates`, `nearest_hunter`, and threat scans to the derived pair/species queries; no role/kind/type grep hits remain in `scripts/`.

## 3. Player as the possessed agent

- [x] 3.1 Change `possess_member` to keep the member and set `brain="PLAYER"`; seed/roster tests assert exactly one PLAYER brain and one body.
- [x] 3.2 Add `KarmaState.player(state)`, `px(state)`, `py(state)` and migrate body reads/writes in `karma_game.gd`, `karma_predators.gd`, `karma_eat.gd`, `karma_ai*.gd`, `karma_jev_*.gd`, `karma_hud.gd`, `karma_draw.gd`, `karma_shop.gd`, `main.gd`, and tests.
- [x] 3.3 Remove top-level player body fields (`px`, `py`, `face`, `moved`, `hp`, `hambre`, `sed`, `edad`, `invuln`, verb cooldowns, `hidden`, `hideRef`, `bristled`, `grounded`, `cam`, `carriedNut`, and related body state) from `blank_state`; keep the player account/UI fields.
- [x] 3.4 Delete the unused `possessed` key; fix `respawn_missing` to count the possessed member once; make `distant_pt` use the possessed agent's position.
- [x] 3.5 Derive company as same-species AI agents and fauna as other-species AI agents; remove `role`/`kind` from `spawn_company`/`spawn_fauna` and every query.
- [x] 3.6 Run player input through `step_agent` with `brain="PLAYER"`; ensure the player uses the same action/verb executors as AI and is skipped by `KarmaAI.ai_step`.
- [x] 3.7 Update death/judgment/respawn: the possessed agent is removed from the roster, the player account survives judgment, and no duplicate body remains.
- [x] 3.8 Update HUD/draw/debug labels to species + brain; no "hunter"/"saponpc" labels.

## 4. Cleanup and verification

- [x] 4.1 Grep guard: no `saponpc`, `role ==`, `kind ==`, `type ==`, `hunter_agents`, `all_hunters`, `include_kind`, `predator_type`, or `is_predator` remains in `scripts/` or `tests/` (except historical comments that are removed).
- [x] 4.2 Confirm only `KarmaData.TUNING` numbers and the intended trophic data changed; diff the player field shape against `blank_state`; no hidden duplicate body fields.
- [x] 4.3 Run the full gdUnit4 suite green, refresh Godot diagnostics to 0 errors, and run the main scene from F5 with no runtime errors.
- [x] 4.4 Run `ponytail-review` over the diff; fix or explicitly defer each finding.
- [x] 4.5 Re-check the four delta specs against final behavior; run `openspec validate unify-trophic-behavior` and record completion evidence (skills loaded, test counts, regression probe numbers).

