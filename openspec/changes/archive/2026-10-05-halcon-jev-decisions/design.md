## Context

See proposal.md Why. Current state: `KarmaJev` is zorro-only — `SCHEMA_VERSION = "jev-zorro/v1"`, `JEV_LOG_PATH = "user://logs/jev_zorro.log"`, single `state["jev_log"]` capped at 200, single `_jev_flushed` counter in `Main`, and `log_decision()` with no species parameter called only from `_on_jev_done` (live answers). `KarmaAI._ai_halcon` is a synchronous ladder (strike-nearby, thirst, grounded eat/unground, hunt size<=2 within 200px, seek carrion, wander) with `grounded`/`landT` state. Only `Main` owns I/O (no autoloads); simulation stays pure static funcs on `Dictionary` state.

## Goals / Non-Goals

**Goals:**
- One log file, one schema, one compile-time flag per converted species; debugging halcon never shows zorro entries.
- Halcon macro intent at full-kit parity through the existing single-batch-per-window path.
- Mock halcon path preserves F5 movement parity with zero log output.

**Non-Goals:**
- No lobo or grazer conversion; no sidecar protocol change (same `Choice` shape, same `http://192.168.100.80:8766/api/evaluate`).
- No runtime log toggle UI; no log rotation beyond the per-file cap.
- No training pipeline; files are append-only JSONL for later collection.

## Decisions

- **Species-keyed logging, not tagged-single-file.** `JEV_LOG_PATH_FOR(species)` returns `user://logs/jev_<species>.log`; `LOG_JEV_ENABLED(species)` reads per-species consts (`LOG_JEV_ZORRO`, `LOG_JEV_HALCON`); `log_decision()` takes species first and returns early when disabled so nothing is buffered. Flush keeps one `_jev_flushed_<species>` counter each and loops only over enabled species. Alternative (single `jev_all.log` with species column) rejected: it mixes training data and still pays memory for silenced species.
- **Schema per animal.** `SCHEMA_VERSION_FOR(species)` returns `jev-<species>/v1`; entries carry their own schema string so `jev_halcon.log` never inherits a zorro label. Zorro keeps `jev-zorro/v1` byte-identical for existing collectors.
- **Halcon bridge mirrors zorro, halcon-shaped.** `halcon_definition()` from `VERB_DEFS["halcon"]` + `SPECIES["halcon"]` + shared TUNING slice; `build_halcon_menu()` covers dive/hunt, eat/seek-carrion, courtesy-share (grounded on carrion, off cooldown), scare (predator within 60px, strike off cooldown), bone-drop, thermal, drink-seek, flee/hide, wander-always; `build_halcon_state()` adds `grounded` + `landT` to the standard snapshot. Stale targets (dead actor, eaten carrion) fall to prior intent or wander.
- **Micro keeps the land cycle local.** `_ai_halcon_jev` ticks needs/cooldowns, resolves drink-in-range and grounded eat/unground synchronously, then steers intent (dive uses halcon 60px kill range and sets `grounded` + `landT` on kill, eat seeks carrion and grounds on arrival). Macro answers only replace `jev_intent` with TTL; `jev_live` pendings wander without logging.
- **Mock explicitly silent.** `mock_halcon_macro()` applies through player paths but never calls `log_decision`; tests assert empty buffers after mock applies. This codifies the current zorro mock behavior instead of leaving it accidental.
- **Thermal gated on affordability, honestly logged.** Live logs showed a no-op loop: thermal offered without a PA check, picked at ~0.65 by the stock checkpoint, then failing the `pa >= costPa` check in `apply_halcon_answer` and falling back to wander with `applied=true` while no cooldown was ever set — so it was re-offered every window for 150s. The menu now requires `pa >= costPa` (same shape as the zorro dendig HP check), and the apply-time fallback returns `applied=false` so training data records what actually executed. Alternative (removing thermal from the kit) rejected: it is a real player verb, the fault was legality, not the verb.
- **Cost visible to the ranker.** Only thermal has a PA cost in the halcon kit; its criteria label carries the cost (`-15 PA`) next to the numeric `pa` already in the state snapshot, mirroring the zorro cache fullness hint. No protocol change: labels are plain strings inside the existing `criteria` map.
- **Fair polls across species.** `_jev_poll` used to serve zorro first and return, so once appetite-based hunger made every wandering zorro due every frame, the halcon branch never ran (live symptom: healthy zorro traffic, zero halcon batches, no errors). Polls now collect both due lists and send one batch per frame alternating via `pick_batch_species`. The hunger re-ask is edge-triggered (`jev_was_hungry` in `mark_asked`, mirroring the carrion counter) so steady hunger rides the stagger timer instead of bypassing it.
- **Thirst emergency in shared micro.** Water bodies are sparse (~8 on 7.68M px2, typical nearest ~490px) against a 170px scout ceiling, so thirsty animals routinely found nothing and dehydrated. `ai_seek_water` now falls back to the nearest water at any distance when nothing is in range; all ladders and both JEV micros inherit it with no menu or order changes (thirst still runs after hide/flee reflexes).

## Risks / Trade-offs

- [Risk] Halcon stock checkpoint plays poorly (never saw dive/land game) → Mitigation: legality-first menus, wander always executable, log everything live for the training follow-up.
- [Risk] Two-species batch doubles sidecar load → Mitigation: keep one HTTP call per window with per-species state lists, keep short `state_text`, skip single-candidate menus locally, keep 1s/3s LOD cadence per agent.
- [Risk] Per-species flush counters drift (one file errors, other advances) → Mitigation: independent counters and independent `ensure_log_ready` per file; a failed file blocks only its own species.
- [Trade-off] Compile-time flags need recompile to isolate logs → Accepted: matches existing `USE_JEV` style, zero runtime UI cost, decided in exploration.

## Migration Plan

- Additive: new halcon bridge funcs + new per-species log helpers; zorro call sites migrate to `..._for("zorro")` equivalents with identical output.
- Rollback: flip `USE_JEV_HALCON` / `LOG_JEV_HALCON` off to restore `_ai_halcon` ladder; delete `jev_halcon.log` safely (training-only, outside saves).
- No data migration: log files are not read back by the game.
