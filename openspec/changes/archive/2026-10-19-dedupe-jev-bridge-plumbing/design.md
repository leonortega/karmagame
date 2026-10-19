## Context

See proposal.md. Eight `karma_jev_<species>.gd` files each carry the same small helpers and near-identical batch envelopes; the copies already drifted into the target bug. Each file legitimately keeps its own schema, log flag, menu builder, and definition. `KarmaJev` is a thin facade over the eight classes. All classes are pure static `RefCounted` with no autoloads.

## Goals / Non-Goals

**Goals:**

- One home for plumbing that is identical by contract: readiness, max HP, intent application, candidate ids, mock choice, mock macro, and state text.
- One parameterized envelope for `build_batch` / `build_http_body_for` where the only real difference is the menu builder and species config.
- Prove byte-for-byte compatible envelopes with the existing tests before replacing duplicates.

**Non-Goals:**

- No change to menus, criteria labels, schemas, log flags, ranking, or cadence.
- No merge of the eight bridge files into one; per-species menu builders stay separate.
- No new enum or registry layer beyond the shared helper class.

## Decisions

- **New `KarmaJevBridge` static helper class.** It holds the truly identical helpers and the parameterized envelope. Alternative: put helpers on `KarmaJev`; rejected because `KarmaJev` is a facade and a facade that also does work is what this change is cleaning up.
- **Envelopes take a `Callable` menu builder plus a small species config.** Each species file passes its own menu builder and schema/log settings, so the envelope stays generic without a central species switch. Alternative: a central `match` on species inside the shared class; rejected because it hard-codes every species into one file and repeats the menu dispatch.
- **Fix at the shared intent helper.** The extracted intent helper includes the target field, so the target regression cannot recur in any of the eight call sites. Alternative: keep per-file helpers and only dedupe other functions; rejected because intent application is the highest-risk copy.
- **Migrate one species at a time, lowest-risk first.** Start with raton/ardilla/sapo/topo (no target semantics), then zorro/halcon (target semantics), then oruga/lobo. Each step keeps the full suite green. Alternative: rewrite all eight at once; rejected as an unreviewable diff and a hard bisect.

## Risks / Trade-offs

- [Risk] A generic envelope silently changes criteria labels or ordering -> Mitigation: assert envelope equality per species in tests before deleting each duplicate.
- [Risk] `Callable` indirection obscures a per-species special case -> Mitigation: keep any genuinely different behavior in the species file, not behind a flag in the shared code.
- [Risk] The refactor lands before the target fix -> Mitigation: treat `fix-jev-target-intent` as a prerequisite and assert the contact-kill tests in this change too.

## Bridge inventory (task 1.1)

Byte-identical copies (safe to replace with one shared function):

- `_verb_ready` — all eight files, including the missing-`verbCds` guard.
- `candidate_ids` — raton, ardilla, sapo, topo, zorro, oruga, lobo (halcon has no copy).
- `_max_hp` — zorro, halcon, lobo (`KarmaAI.ai_max_hp`).

Near-identical copies (same contract, only the species name/config literal differs):

- `_set_intent` — raton, ardilla, sapo, topo, oruga, lobo share one body; zorro/halcon use the equivalent early-assignment form. All eight already carry `target`.
- `mock_choice` / `halcon_mock_choice` — same algorithm, per-species pinned priority array.
- `mock_macro` / `mock_halcon_macro` — same shape, differing only in the local menu/choice/apply callables.
- `all_jev_<species>` — same filter, species literal differs.
- `build_batch` — raton, ardilla, sapo, topo, zorro, oruga, lobo; same dict shape (halcon has no copy).
- `build_http_body` — all eight; one-line delegate over the per-species collector.
- `build_http_body_for` / `build_halcon_http_body_for` — all eight; identical envelope, only menu/state-text callables differ.
- `state_text` / `halcon_state_text` — identical prefix through `threatened`, then a per-species tail plus `KarmaJev.age_text(snap)`.

Divergent (stays in the species file):

- `apply_answer` / `apply_halcon_answer` — shared preamble (`jev_emocion`, `target_gone` wander), then genuinely different verb handling per species.
- `build_state` / `build_halcon_state` — species-specific snapshots and need tokens.
- Menu builders, definitions, schemas, log flags, and per-species constants.

## Migration Plan

Refactor only; no data migration. Roll back per species by restoring that file's local helper while the shared class stays available.
