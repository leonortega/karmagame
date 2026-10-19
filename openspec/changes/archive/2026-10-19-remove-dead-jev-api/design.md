## Context

See proposal.md. `KarmaJev` exposes delegates that no longer have production callers, plus obsolete batch pickers; several neighboring scripts carry unused helpers and constants. Some of these names appear only in tests. GDScript also allows name-based calls, so "unused" must be proven by scanning for both the identifier and its string form.

## Goals / Non-Goals

**Goals:**

- Remove only APIs with zero production and zero test-relevant callers, in small reviewable batches.
- Keep obsolete test coverage from pinning dead APIs alive: update or delete those tests in the same batch.
- End with a facade that reads as the live JEV surface.

**Non-Goals:**

- No behavior, menu, ranking, or cadence change.
- No removal of spec-protected fallbacks (for example the ladder/refuge fallback path) without a spec decision.
- No renaming or reorganizing live APIs.

## Decisions

- **Prove zero references before each removal batch.** Scan `scripts/` and `tests/` for the bare name and for the quoted name (covers `call("...")` and `has_method`). Alternative: delete from the audit list directly; rejected because the audit list is static analysis, not a runtime guarantee.
- **Batch by owner and by risk.** First unused `KarmaJev` wrappers, then obsolete picker APIs and their tests, then dead helpers/constants in the data/draw/state/predator files. Each batch ends with the full suite green. Alternative: one cleanup commit; rejected because a failure would not localize.
- **Delete, do not deprecate.** These APIs have no external consumers and no save/network contract. Alternative: keep wrappers with a deprecation note; rejected because it preserves exactly the noise this change removes and no consumer would ever see the note.
- **Keep the live delegates untouched.** `KarmaJev` remains the entry point for real callers; only unreferenced delegates go.

## Risks / Trade-offs

- [Risk] A dynamic call hides a real caller -> Mitigation: quoted-name scan before each batch and a full-suite run after.
- [Risk] Removing a constant that a future spec expects -> Mitigation: leave anything referenced by an active spec or a currently skipped fallback and note it for a separate spec decision.
- [Risk] Test deletion hides a real behavior gap -> Mitigation: delete only tests for removed APIs; keep every test that exercises a live entry point.

## Migration Plan

Refactor only; rollback is the removed batch. No consumer migration required.
