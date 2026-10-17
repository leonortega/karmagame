## Context

See proposal.md (Why) and specs (animal-senescence + 7 deltas) for scope. Current state shaping this design:

- `edad` ticks in `KarmaUtils.update_needs` and `KarmaPredators.step_predator` but only displays via `SEC_PER_YEAR` / `animal_years`; `eff_age_mult()` is a dead `1.0` stub.
- Kills are split: `strike_contact` uses flat `PRED.damage` numbers, while pounce / dive / cull / `ai_hunt_eat` / `strike_agents` delete agents outright with no damage roll.
- Role-hunter predators are explicitly needs-immune per `living-map`; removing that deletes the pressure floor.
- JEV `build_state` / `state_text` / menus carry hunger/threat/cooldowns but no age; micro reflexes (`ai_flee`, hide, scavenge-first) cannot see frailty.
- Numbers live in `KarmaData.TUNING` (no magic numbers); sim is pure static funcs on Dictionary state; only `Main` owns I/O.

## Goals / Non-Goals

**Goals:**

- One age pipeline (stage from animal-years) feeding speed, regen, force, frailty, and action times for player, fauna, company, and hunters alike.
- One damage rule (`base x attacker_force x victim_frailty`, lethal iff `>=` current vida) on every kill path, with failed kills wounding into a decision-gated chase.
- Hunters mortal to needs and age, with respawn keeping the ecosystem alive.
- Decisions (micro + JEV) able to see and weigh age without the ranker inventing moves.

**Non-Goals:**

- No base-number rebalance (`FOODDEF`, `PRED.damage`, chase multipliers stay; age scales around them).
- No new verbs, no cast-time channel mechanic (cooldown/duration scaling only).
- No sidecar/ranker logic changes (GDScript menus/snapshots only; ranker still ranks).
- No HUD redesign beyond the age-stage signal.

## Decisions

- **SENESCENCE table in TUNING + pure helpers.** One row per species: lifespan (animal-years), prime/worn boundaries, per-stat decay (speed floor, force floor, regen floor, action-time growth, frailty growth). Helpers derive stage and each multiplier from `(species, edad_secs)` via `animal_years`. Alternative (one global decay curve) rejected: it cannot express oruga-crash vs lobo-cliff, which the request explicitly wants.
- **Unified `scaled_damage(base, attacker, victim)` used everywhere.** Applied in `strike_contact`, pounce, dive, cull, `ai_hunt_eat`, `strike_agents`/`feast`. Curl halving, bristle reflection, and invuln windows apply to the scaled result. Alternative (age only on bites, kills stay instant) rejected: it keeps the exact old-zorro-kills-prime-raton behavior the exploration ruled out.
- **Failed-kill semantics: wound + cooldown + no feast.** Victim `hp -= scaled`, attacker burns its cooldown, no heal/sated/carrion; escape is decided by the existing layer (player free choice; AI via flee/hide/JEV with new age inputs). Alternative (whiff with no damage) rejected: user chose partial damage + escape attempt.
- **Hunters routed through the same needs+age drain.** Reuse `update_needs`-equivalent deficit logic for role-hunters (drain, regen-gating, age death) instead of a parallel system; extend `respawn_missing`/census top-up to hunters so predator waves regenerate. Alternative (hunters age but never starve) rejected: user removed needs-immunity entirely.
- **Cooldown/duration scaling, costs frozen.** `digCd`, `groomTime`, `thermalTime`, `howlTime`, `escortTime`, sense cds start longer / last longer with age; `costHp`/`costPa` and karma payouts unchanged so economy specs hold. Alternative (slower channels with interrupt) rejected as a new mechanic beyond this change.
- **Age inputs, not age overrides, for decisions.** Micro: frail hides earlier, biases harder to cover, scavenges first, skips unwinnable pounces when carrion is perceived. Macro: `build_state`/`state_text` gain self stage + threat/prey stage + force/frailty hint; legality gates unchanged (wander always present). Alternative (hard-coded old=hides, young=flees) rejected: it bypasses the ranker and breaks JEV-handleability.

## Risks / Trade-offs

- [Risk] Predators starve/age out and the map goes quiet → Mitigation: hunter respawn top-up + lobo-pack floor extended to hunters; tune lifespans so pressure waves, not gaps.
- [Risk] Age inverts tuned chases (Raton 190 vs Zorro 185 + chaseMult assumed prime-vs-prime) → Mitigation: floors keep prime-vs-prime identical to today; only cross-stage chases differ; add chase-matrix tests.
- [Risk] JEV schema churn across 8 species bridges → Mitigation: additive snapshot fields only; stale clients ignore them; menus keep wander fallback.
- [Risk] Test surface explodes (8 species x 3 stages x attacker/victim pairs) → Mitigation: TDD per behavior with representative pairs (old-zorro/prime-raton, prime-zorro/old-raton, frail-topo dig, hunter starvation), not the full matrix.
- [Risk] Pre-existing `KarmaModals` LSP breakage in `main.gd`/tests (unrelated to this change) confuses verification → Mitigation: record as pre-existing, do not fix here; gate on the senescence test files + unchanged suite baseline.

## Migration Plan

- Ship as pure addition with prime-stage multipliers at 1.0: year-zero behavior identical to today; decay and lifespan engage only as `edad` grows.
- Rollback: zero the decay rows (or lifespan to infinity) — single TUNING change restores immortal behavior without code revert.
- Archive order: `animal-senescence` creates the capability; the 7 deltas land on their specs; no data migration (ages reset each life).

## Open Questions

- Exact lifespan/decay numbers per species (oruga 4yr vs lobo 12yr sketch in specs): gameplay tuning during apply, recorded as a spec-table change if adjusted.
- HUD stage glyph/text choice (e.g. "viejo" tag vs icon): presentation detail, must not change the stage signal requirement.
