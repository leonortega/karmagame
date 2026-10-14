## Context

See proposal.md (Why) and `specs/ai-jev-oruga/spec.md` for the behavior contract. Current state: `KarmaAI._ai_oruga` is the only inline ladder left (in `scripts/karma_ai.gd`); all seven siblings follow the Option B split — per-species `KarmaAI<Species>.step_jev` + `KarmaJev<Species>` bridge, Main-owned single-flight batch (`pick_batch_species_7` + 7-deep done-branch), per-species `LOG_JEV_*` flags with only lobo on. Constraints: no magic numbers (all ranges/costs from `KarmaData.TUNING` / `VERB_DEFS`), simulation stays pure static funcs on `Dictionary` state, `_physics_process` for movement, `Main` owns all I/O (HTTP + log flush).

## Goals / Non-Goals

**Goals:**

- Oruga macro intent ranked by NanoJev from a code-built legal menu; micro steering every tick that never blocks on answers.
- Stillness-gated curl defense preserved (sapo wander pattern, not topo/lobo POI travel).
- Single-species observation window: only `jev_oruga.log` grows.

**Non-Goals:**

- No agent-side bristle reversal (`strike_agents` untouched); no `TUNING` rebalancing; no Main batch refactor (explicit `pick_batch_species_8` per the per-species-everything stance); no HUD/feed format changes (`emocion` stays flavor-only).

## Decisions

1. **Mirror `karma_jev_sapo.gd` as the bridge template (over topo/lobo).**
   Sapo is the closest sibling: leaves/insect single-food grazer, tongue/eat-range contact pattern, pressure-gated flee + burrow verb, and — critically — the stillness-accumulating wander tail. Topo/lobo templates would import POI travel that breaks curl. Menu/state/mock/apply/batch/HTTP functions copy sapo's structure with oruga verbs swapped in.

2. **Menu-complete without prudent/bristle (option A).**
   `eat` already pays `prudentKarma` via `eat_sustainable`, so a separate `prudent` candidate would split the ranker vote between duplicates. `bristle` has no agent execution path (`_verb_bristle` returns false for agents; `strike_agents` never checks it). Alternatives considered: (a) prudent-as-instant-verb — rejected, duplicates eat with no new information for the log; (b) full-five with bristle reversal — rejected for this change, it needs new predator combat semantics and belongs in a follow-up driven by the oruga logs.

3. **Nectar offered as instant-cast with affordability gates (sapo-toxin pattern).**
   Menu includes `nectar` only when a hunter is within 150px, slot 3 is off cooldown, and HP + PA cover costs; apply re-checks affordability and falls back to wander without burning anything. Mirrors how sapo gates toxin, keeping the ranker honest.

4. **Steering order: hide → hunted/hide → thirst → urgent_seek → steer_intent → jev_live-hold → mock.**
   Same guard prefix as the ladder and sapo (`ai_hide_tick`, `is_hunted`+`ai_try_hide`, `ai_thirst`, `ai_urgent_seek`) so safety reflexes outrank ranked intent. `steer_intent` handles `eat` (contact `eat_patch` else move toward target, `stillT = 0` on motion), `seek_food`/`drink`/`flee` (drink-then-move, motion resets stillness), and default wander (accumulate `stillT`, return true — never travel). `mock_choice` order: `eat, drink, flee, silk, leafroll, nectar, seek_food, wander`.

5. **Batch: extend, don't refactor (`pick_batch_species_8`, one more done-branch).**
   The 7-deep nested ternary in `_on_jev_done` and the `pick_batch_species_N` ladder are ugly but load-bearing convention; a generalized scheduler would violate the per-species-everything stance and touch all species at once. Oruga gets `o_due` / `_send_oruga_batch` / `is_oruga` branch / flush + clear entries following the lobo block verbatim. Fair rotation reuses `_pick_best` with `jev_last_served`.

6. **Log flag flip: `LOG_JEV_ORUGA = true`, all others false.**
   `log_decision` + `_jev_flush_log` already key off `log_enabled(species)`; the only change is flag values plus the existing `test_log_flags_default_on` expectation updated to oruga-only. Mock path never logs (no `log_decision` call in `mock_macro`).

## Risks / Trade-offs

- [Risk] `_on_jev_done` 8-deep nesting misroutes a batch → Mitigation: copy the lobo branch exactly (menu/snap/apply/log per-species vars), plus `test_pick_batch_8` rotation test and per-species `log_triple_schema_path_and_flag` test.
- [Risk] `test_log_flags_default_on` currently expects ardilla-on while code has lobo-on (stale from an earlier migration) → Mitigation: first task reconciles the test to oruga-only before flipping flags, keeping the suite green.
- [Risk] Leafroll self-shelter loop (AI creates `orugaOnly` refuge, then flees into it) inflates `flee` wins in the log → Mitigation: accept and observe — the log window exists to reveal exactly this; `build_state` includes `clump_near` and `pressure_near` so the loop is visible in snapshots.
- [Risk] Oruga slowness (speed 80, vision 130) means `seek_food` intents expire before arrival (ttl 5s) → Mitigation: same ttl as siblings for comparability; re-ask on target-reached/expiry covers it; log shows seek-vs-wander ratio for tuning later.
- [Trade-off] Keeping `bristle` player-only leaves AI orugas without their thorn answer — accepted; the log will show whether deaths happen with HP to spare, which is the evidence a bristle follow-up needs.
