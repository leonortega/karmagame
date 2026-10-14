## Context

See proposal.md (Why). Current state: five species own the full JEV shape (`karma_ai_<sp>.gd` Strategy + `karma_jev_<sp>.gd` bridge + facade delegates + `main.gd` poll/batch/apply/flush + `ai-jev-<sp>` spec + tests). Topo still runs the inline `_ai_topo` ladder in `scripts/karma_ai.gd:463-485` with `ai_maybe_verb` order worm → tunneline → aerate → larder (`scripts/karma_ai.gd:289-298`); all four burrow verbs are AI-executable today, while slot 5 `nestdig` returns false for agents (`scripts/karma_game.gd:499-501`), so the menu simply excludes it — no verb unlock needed (unlike sapo-`pest`). `main.gd` polls five due-lists through `pick_batch_species_5` with `jev_last_served` fairness.

## Goals / Non-Goals

**Goals:**
- Sixth copy of the proven shape, reconciled to the newest (sapo/ardilla) conventions so the set converges instead of diverging further.
- Topo-specific behavior preserved: tunnel envelope (0.8x), hybrid insect + carrot/nut diet, dug-refuge-gated worm/tunneline, larder store/share, shout-as-alarm.

**Non-Goals:**
- No changes to the five existing species' menus, specs, flags, or log behavior.
- No tuning numbers; no `TUNING` additions (reuse `eatRange`, `drinkRange`, `aiFearRange`, `aiCoverRange`, `groomRange`, `shoutLureRange`, `jevReaskBackoff`).
- No `nestdig`-for-AI unlock; slot 5 stays player-only.
- No resolution of the ardilla spec-text vs picker-code tension beyond what the topo slice needs (same stance as sapo: extend the shared picker).

## Decisions

- **Generic bridge names (`build_menu`, `mock_choice`, `apply_answer`), public `step_jev`/`steer_intent`.** Follows zorro/raton/ardilla/sapo (4-to-1 over halcon prefixes). Alternative (halcon-style prefixes) rejected: it deepens the split the next migration must reconcile again.
- **Extract `KarmaAITopo` Strategy from inline `_ai_topo`.** Topo (like oruga/lobo) still lives inline in `karma_ai.gd`; the five migrated species each own `karma_ai_<sp>.gd` with `step` → `step_ladder` (frozen current behavior) + `step_jev` + `steer_intent`. Alternative (leave inline + branch) rejected: it breaks the per-species-everything stance and makes the next extraction harder.
- **Emocion backfill via `KarmaJev.appraise_emocion` (ardilla/sapo precedent).** Covers fear on threat/pressure, urgency on floor hunger, hunger otherwise. Flavor-only, never gates.
- **Scheduler: extend the existing picker to six species with the same least-recently-served rule.** Satisfies `ai-jev-cadence` ("waiting longest") unchanged for a wider due set; per-species `sent` counters gain topo. Alternative (per-species explicit schedulers per the ardilla spec-text stance) rejected for this slice: it refactors all five incumbents' poll path for zero behavioral gain.
- **`LOG_JEV_TOPO := true`, `USE_JEV_TOPO := true`.** Log-on follows the newest species (sapo/ardilla) and buys shakeout telemetry; one-line flip later. Ladder stays as the fallback behind the flag and mocked macro covers sidecar-down play, same as incumbents.
- **Wander tail POI-travels (ardilla pattern), never accumulates stillness.** Topo has no stillness-gated defense (unlike sapo camouflage / oruga curl), and its ladder already travels via `wander_poi`. The `steer_intent` default branch keeps POI-travel + jitter; purposeful wandering is preserved.
- **Hybrid eat: insects first (contact), then edible patches — same order as `ai_grazer_eat`.** Menu offers a single `eat` kind pointing at whichever contact food exists (insect preferred when both in range, matching the ladder's insect-first order); `seek_food` likewise targets the nearest hungry-range food of either kind. Alternative (separate `eat_insect` / `eat_patch` kinds) rejected: it doubles the ranker's food vocabulary for zero player-visible difference.
- **Burrow verbs gated by dug-refuge proximity (ladder parity).** `tunneline`/`worm` offered only with a dug refuge within eat range; `worm` additionally requires hunger; `aerate` offered on slot-1 readiness alone (it creates the refuge); `larder` offered on slot-4 readiness with either a storable insect in range or a sharing target. Stale dug targets re-checked at apply; failures resolve to wander with no cooldown burned.
- **`alarm` in the menu (raton precedent), not just background `ai_base` reflex.** Topo is in `AI_SHOUTERS` and `ai_base` auto-shouts; offering `alarm` makes the shout option rankable (hunter in lure range + shout ready) instead of invisible. Apply routes through `cast_verb_for` slot 1-equivalent shout path like raton `alarm`.
- **Mock order: eat > drink > flee > alarm > worm > aerate > tunneline > larder > seek_food > wander.** Contact survival first, escape second, burrow economy third, seek last — mirrors the ladder's eat-first, verb-last priority with flee promoted above economy (same promotion raton/ardilla mocks use).

## Risks / Trade-offs

- [Risk] Dug-refuge gating makes tunneline/worm rarely legal on fresh maps → Mitigation: accepted (same as today); aerate creates the refuge the others need, and the ranker learns the chain.
- [Risk] Hybrid eat target goes stale between menu and answer (insects wander, patches deplete) → Mitigation: membership re-check in `state.insects` / patch alive+amount at apply; event re-ask on fresh food in perception.
- [Risk] Six-way single-flight starves someone under continuous due → Mitigation: least-recently-served fairness already bounds this; `jev_poll.json` `sent` counters (now incl. topo) prove it in live logs.
- [Risk] Larder share target gone at apply (mate moved/died) → Mitigation: re-validate mate in company roster at apply; resolve to wander with no state mutated.
