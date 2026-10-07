## Context

See proposal.md (Why). Current state: four species own the full JEV shape (`karma_ai_<sp>.gd` Strategy + `karma_jev_<sp>.gd` bridge + facade delegates + `main.gd` poll/batch/apply/flush + `ai-jev-<sp>` spec + tests), but the four are mutually divergent (see verification notes in the change discussion: halcon-prefixed names, raton underscore-privates, emocion backfill only in ardilla, halcon missing `build_batch`/`candidate_ids`). Sapo runs the inline `_ai_sapo` ladder; its verbs are all AI-executable since `sapo-pest-ai`, so the menu has no illegal candidates. `main.gd` polls four due-lists through `pick_batch_species_4` with `jev_last_served` fairness.

## Goals / Non-Goals

**Goals:**
- Fifth copy of the proven shape, reconciled to the newest (ardilla) conventions so the set converges instead of diverging further.
- Sapo-specific behavior preserved: hop envelope, tongue reach, stillness camouflage, toxin HP cost.

**Non-Goals:**
- No changes to the four existing species' menus, specs, flags, or log behavior.
- No tuning numbers; no `TUNING` additions (reuse `tongueRange`, `eatRange`, `drinkRange`, `aiFearRange`, `aiCoverRange`, `groomRange`, `shoutLureRange`, `jevReaskBackoff`).
- No resolution of the ardilla spec-text vs picker-code tension beyond what the sapo slice needs (recorded as follow-up).

## Decisions

- **Generic bridge names (`build_menu`, `mock_choice`, `apply_answer`), public `step_jev`/`steer_intent`.** Follows zorro/raton/ardilla (3-to-1 over halcon prefixes; raton underscore-privates are the outlier). Alternative (halcon-style prefixes) rejected: it deepens the split the next migration must reconcile again.
- **Emocion backfill via `appraise_emocion` (ardilla precedent).** Zorro/halcon/raton leave missing labels empty; sapo follows the newest behavior so feed flavor is consistent for the species under active shakeout.
- **Scheduler: extend the existing picker to five species with the same least-recently-served rule.** Satisfies `ai-jev-cadence` req 1 ("waiting longest") unchanged for a wider due set; per-species `sent` counters gain sapo. Alternative (per-species explicit schedulers per the ardilla spec-text stance) rejected for this slice: it refactors all four incumbents' poll path for zero behavioral gain. The spec-text/code tension is noted as a follow-up, not solved here.
- **`LOG_JEV_SAPO := true`, `USE_JEV_SAPO := true`.** Log-on follows the newest species (ardilla) and buys shakeout telemetry; one-line flip later. Ladder stays as the fallback behind the flag and mocked macro covers sidecar-down play, same as incumbents.
- **Wander tail accumulates `stillT`, never POI-travels.** Unlike raton/ardilla wander fallthrough (which travels), sapo camouflage requires motionlessness and `ai-species-behavior` exempts sapo at the terminal tail. The `steer_intent` default branch keeps stillness; the defense counts as the deed.
- **Insect targets re-validated at apply.** Insects wander every tick, so menu-time targets may be gone by answer time: missing/stale targets resolve to continued steering or wander, never freeze, with no cooldown burned.
- **Toxin gated twice (menu + apply, halcon-thermal pattern).** Offered only with slot 4 ready and HP above cost; a pick failing affordability at apply resolves to wander with `applied=false`.
- **Pest is instant-cast with wander-after; mock prefers `eat` over `pest`.** Movement preserves the chase; the instant verb is the backup. Chorus stays rare by construction (choir-gated) and remains ladder-castable.

## Risks / Trade-offs

- [Risk] Insect volatility makes menus stale faster than static-patch species → Mitigation: membership re-check in `state.insects` at apply; event re-ask on fresh insects in perception.
- [Risk] Five-way single-flight starves someone under continuous due → Mitigation: least-recently-served fairness already bounds this; `jev_poll.json` `sent` counters (now incl. sapo) prove it in live logs.
- [Risk] Chorus almost never legal; ranker rarely sees social play → Mitigation: accepted (same as today); ladder fallthrough keeps chorus karma reachable.
- [Risk] Verification gate is red for unrelated reasons → Mitigation: four pre-existing failures halt their suites at first failure, masking ~70 tests (see change discussion). New `test_karma_jev_sapo.gd` must be green standalone; full-green gate depends on fixing those blockers separately.

## Migration Plan

Land behind `USE_JEV_SAPO=true` with ladder fallback and mocked macro intact — sidecar-down play is unchanged. Rollback is the flag to `false` (one line, no save-format or spec-state migration involved). No deployment steps; Godot project, no backend.
