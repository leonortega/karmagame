## Context

See proposal.md (Why). Current state: `scripts/karma_game.gd:356 call_verb` dispatches 40 verbs; 14 bodies start with `if a != null: return false`, so IA can never cast them. Eleven bodies grant only self karma/PA/vision (`chorus`, `groom` x2, `scout`, `thermal`, `bark`, `worm`, `tunneline`/`firm`, `silk`, `burrowin`, `bristle`, `escort`). Precondition-fail without burn is already the established pattern (`pest`, toxin, regurg). Numbers live in `KarmaData.TUNING`; simulation stays pure static funcs on Dictionary state; only `Main` owns I/O.

## Goals / Non-Goals

**Goals:**
- Every verb writes the world or another body on success, with a shared fail-without-burn rule.
- One code path for player and agent per verb (remove the `a != null: false` wall).
- Every reworked verb is JEV-handleable through the existing per-species batch path (legal-only menus, same apply functions, wander fallback).
- Species-true replacements reusing existing entity patterns (refuge with ttl, scent/scent-like marks, carrion `ceded`, `restT`, `saved`/`rallyT`).

**Non-Goals:**
- No rebalancing of costs/cooldowns/karma beyond what preconditions require (TUNING values stay unless a new stock needs a timer).
- No new autoloads, no engine/render changes, no JEV scheduler redesign (single-flight + fair cross-species scheduling + 1s/3s cadence + backoff unchanged).
- No shop/E/Q/H/V/C changes.

## Decisions

- **Branch, don't gate, on actor.** Each reworked `_verb_*` takes `(state, a)` and resolves `px/py/target` from `a` when non-null, else player fields. Alternative (separate AI verbs) rejected: it re-creates the two-table drift this change removes.
- **Reuse entity shapes, add three small ones.** Scent post, silk thread, and wallow pit follow the existing refuge shape (`{type, x, y, ttl}` + one behavior flag) so `age_world` expiry, `collect_solids`/movement, and HUD pills need no new systems. Thermal shadow reuses the reveal/track ring pattern as a ground disc. Alternative (new Resource types) rejected as over-engineering for timed marks.
- **Stocks ride on existing fields.** Oak stripped state and refuge worm-charge reuse `amount`/`regrowT`-style counters already used by flora regrow, so no migration. `firm` is retired (or repurposed as network link) rather than given a reader nobody asked for.
- **Keep fail-without-burn universal.** Every reworked verb returns false with no cooldown/cost/karma when its world/other precondition is absent, matching `pest`/toxin. Alternative (partial costs on fail) rejected: it punishes scouting intent.
- **E-duplicates differentiated, not deleted.** `prudent`/`pounce`/`dive` keep their slots but gain the same precondition discipline as their E chain (or a distinct world write where the slot fantasy demands it), so key bindings and the 5-row bar stay stable.
- **JEV menus extend, scheduler untouched.** Each reworked verb gains a menu builder checking the same precondition as its apply (cooldown, range, stock/charge, hunter/mate presence, HP/PA affordability) plus a need token in the state text; ranked picks apply through the player functions with an affordability recheck, stale picks fall back to steering/wander with `applied=false` in the species log. Single-flight batching, fair scheduling, timer cadence, and backoff stay as specified in `ai-jev-cadence`.

## Risks / Trade-offs

- [Risk] New entities clutter the map/solids → Mitigation: short ttls, caps mirroring `seedlingMax`/`carrionCap`, marks excluded from solids unless they must block.
- [Risk] IA spams reworked verbs once universal → Mitigation: keep existing cooldowns/costs; context gates (hunger, range, charges) already throttle, same as toxin/regurg.
- [Risk] `firm` removal breaks a save/reader we missed → Mitigation: grep `firm` before removal; if any reader exists, keep it as the capacity flag for the tunnel network.
- [Risk] Escort/shepherd moves mates in ways players find paternalistic → Mitigation: short displacement toward nearest cover only, same clamp/collision path as `move_toward`.

## Migration Plan

- Pure additive behavior change behind the same keys/slots; no save migration (run state is per-life). Rollback is reverting the change directory plus the touched scripts.
- JEV side: menu builders gain the reworked verbs with the same preconditions as apply; no new batch kinds, no schema change beyond the existing per-species `jev-<species>/v1` entries.

## Open Questions

- None that change specs, approach, or tasks. Timer/cap numbers for the three new marks will be set from existing analogues (`leafrollTtl`, `revealTime`, `groomRange`) during implementation.
