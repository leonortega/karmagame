## 1. Baseline the bridge contracts (characterization)

- [x] 1.1 Inventory each duplicated function across the eight bridge files and record which copies are byte-identical, near-identical, or divergent.
- [x] 1.2 Add or extend gdUnit4 tests that pin candidate ids, batch envelopes, state text, mock selection, and per-species apply results for every species.
- [x] 1.3 Confirm the target-intent contact-kill tests from `fix-jev-target-intent` are present and green before refactoring.
- [x] 1.4 Run the focused tests and confirm they pass on the current duplicated implementation.

## 2. Extract the shared helper class

- [x] 2.1 Add `KarmaJevBridge` with the identical helpers: readiness, max HP, target-preserving intent application, candidate ids, mock choice, mock macro, and state text.
- [x] 2.2 Replace the duplicated helpers in the four simplest species first (raton, ardilla, sapo, topo) and keep the suite green.
- [x] 2.3 Replace the helpers in zorro and halcon and confirm the target contact-kill tests still pass.
- [x] 2.4 Replace the helpers in oruga and lobo and keep the suite green.

## 3. Parameterize the batch envelopes

- [x] 3.1 Add a shared envelope that takes the species config and a `Callable` menu builder, keeping criteria labels and ordering identical.
- [x] 3.2 Migrate one species envelope, assert byte-for-byte compatibility, then migrate the remaining species one at a time.
- [x] 3.3 Delete the now-unused local helpers from each species file without touching its menu builder, schema, or log flag.

## 4. Verification and cleanup

- [x] 4.1 Run the full gdUnit4 suite and confirm every species bridge, cadence, and logging test is green.
- [x] 4.2 Run GDScript diagnostics on every touched bridge file and confirm no parse or type errors and no duplicate global `class_name` or `func` collisions.
- [x] 4.3 Boot the main scene once and confirm live JEV batches resolve for all enabled species.
- [x] 4.4 Run `ponytail-review` over the diff and fix or explicitly defer every finding.
