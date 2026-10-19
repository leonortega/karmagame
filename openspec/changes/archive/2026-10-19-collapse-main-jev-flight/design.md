## Context

See proposal.md. `main.gd` owns single-flight JEV I/O. Today it declares eight groups of `_jev_<x>_agents` / `_menus` / `_snaps`, eight `_send_<species>_batch` functions, eight branches in `_on_jev_done`, and eight clear paths. `_jev_busy` and `_jev_last_species` are already shared, and `KarmaJev.pick_batch_species_8` already centralizes fairness. Only the per-species storage and dispatch are duplicated.

## Goals / Non-Goals

**Goals:**

- One in-flight record so send, apply, timeout, and clear share one code path.
- Keep fairness, cadence, telemetry (`poll_note`, `mark_served`), busy-skip accounting, and HTTP timeout semantics identical.
- Keep the diff reviewable in one sitting.

**Non-Goals:**

- No change to `KarmaJev.pick_batch_species_8`, `should_ask`, `mark_asked`, or per-species menus.
- No bridge-helper dedupe (owned by `dedupe-jev-bridge-plumbing`).
- No new fairness algorithm or cadence tuning.

## Decisions

- **One `_jev_flight` record plus the existing `_jev_busy` flag.** The record holds `species`, `agents`, `menus`, `snaps`, and `sent_at`; `_jev_busy` stays because busy-skip telemetry needs a cheap check before any work. Alternative: encode in-flight as an empty record; rejected because it moves busy checks into every call site and risks a missed skip counter.
- **Dispatch by species key at the edge, keep per-species body builders.** A single `_send_batch(species, due)` looks up the body builder through one `match` on species, so the duplicated storage and busy/clear bookkeeping disappear while each species' envelope stays in the bridge file that owns it. Alternative: move the envelopes into a generic builder now; rejected to keep this change independent of the bridge dedupe.
- **Keep thin per-species apply adapters behind one callback.** `_on_jev_done` reads `_jev_flight["species"]` and calls one `_apply_flight(result)` that switches to the existing `KarmaJev.apply_*` entry point. Alternative: inline all eight applies in the callback; rejected because it recreates the duplication in a harder-to-read place.
- **Clear through one function.** Timeout, error, `request_completed`, and death all call `_clear_jev_flight()`, which empties the record and resets `_jev_busy`. Alternative: leave per-branch clears; rejected because that is the exact place a field gets missed today.

## Risks / Trade-offs

- [Risk] A missed clear leaves the game stuck in `_jev_busy` -> Mitigation: one clear function used by every exit path, plus a gdUnit4 test that drives timeout, error, and success and asserts `_jev_busy` is false and the record is empty.
- [Risk] Per-species `jev_live` flags are set on send but expected cleared on apply -> Mitigation: keep the flag write in the shared send and the flag clear in the shared apply, and assert with a multi-species fairness test.
- [Risk] `_jev_flushed` counters key off species -> Mitigation: keep the counters unchanged and assert they still increment per species after the refactor.

## Migration Plan

Pure refactor; rollback is the previous duplicated block. Land `fix-jev-target-intent` first so the shared apply path does not preserve a known bug.
