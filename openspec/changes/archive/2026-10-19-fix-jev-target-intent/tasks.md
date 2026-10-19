## 1. Regression tests first (red)

- [x] 1.1 Add a gdUnit4 test that applies a ranked zorro pounce/hunt answer from a real menu and asserts `jev_intent` retains the selected prey target.
- [x] 1.2 Add a gdUnit4 test that runs zorro micro steering after that applied intent and asserts the prey is killed on contact and carrion is spawned.
- [x] 1.3 Add the equivalent applied-intent plus contact-kill tests for halcon dive.
- [x] 1.4 Run the focused tests and confirm they fail for the missing target, not for setup or menu legality.

## 2. Preserve target in the bridge

- [x] 2.1 Update zorro intent application so a non-null selected target is stored in `jev_intent`.
- [x] 2.2 Apply the identical change to halcon intent application.
- [x] 2.3 Run the focused tests and confirm the new contact-kill tests pass without changing steering thresholds or menus.

## 3. Verification and cleanup

- [x] 3.1 Run the full gdUnit4 suite and confirm no existing zorro/halcon menu, apply, cadence, or logging test regresses.
- [x] 3.2 Run GDScript diagnostics on both touched scripts and confirm no parse or type errors.
- [x] 3.3 Boot the main scene once and confirm normal play with zorro/halcon AI enabled.
- [x] 3.4 Run `ponytail-review` over the diff and fix or explicitly defer every finding.
