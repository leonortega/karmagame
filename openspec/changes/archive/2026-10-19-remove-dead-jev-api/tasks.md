## 1. Prove what is actually dead

- [x] 1.1 Produce a reference report for each candidate API, helper, and constant across `scripts/` and `tests/`, including quoted-name calls.
- [x] 1.2 Separate candidates into three batches: unused `KarmaJev` wrappers, obsolete batch pickers and their tests, and dead helpers/constants in data/draw/state/predators.
- [x] 1.3 Flag anything referenced by an active spec or a currently disabled fallback and exclude it from this change.
- [x] 1.4 Run the full suite once to record a green baseline.

## 2. Remove in batches

- [x] 2.1 Remove the unused `KarmaJev` wrappers and run the full suite.
- [x] 2.2 Remove the obsolete `pick_batch_species*` APIs and update or delete the tests that only covered them, then run the full suite.
- [x] 2.3 Remove the confirmed dead helpers and constants and run the full suite.
- [x] 2.4 Confirm `KarmaJev` still routes every live delegate used by production code.

## 3. Verification and cleanup

- [x] 3.1 Run GDScript diagnostics on every touched script and confirm no parse or type errors.
- [x] 3.2 Run the full gdUnit4 suite and confirm no live-behavior test regressed.
- [x] 3.3 Boot the main scene once and confirm JEV behavior and world rendering are unchanged.
- [x] 3.4 Run `ponytail-review` over the diff and fix or explicitly defer every finding.
