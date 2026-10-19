## 1. Baseline and slice order

- [ ] 1.1 Confirm the full gdUnit4 suite is green before typing starts.
- [ ] 1.2 Order the work as independent file slices, starting with pure data helpers (`karma_utils`, `karma_data`) and ending with `main.gd`.
- [ ] 1.3 For each slice, confirm the file has no untyped boundary that another change (`hot-path-agent-queries`, `dedupe-jev-bridge-plumbing`) is actively rewriting; defer overlapping slices until that change lands.

## 2. Type the simulation slices

- [ ] 2.1 Type parameters, returns, and locals in `karma_utils` and `karma_data` and keep the suite green.
- [ ] 2.2 Type `karma_state`, `karma_eat`, and `karma_shop` slice by slice and keep the suite green.
- [ ] 2.3 Type `karma_ai`, `karma_predators`, and `karma_game` slice by slice and keep the suite green.
- [ ] 2.4 Type `karma_draw` and `karma_hud` lookups and keep the suite green.

## 3. Type the scene-owned slice

- [ ] 3.1 Convert camera and facing position-only values to `Vector2` where immediately consumed, keeping the state key and dictionary shape unchanged.
- [ ] 3.2 Replace manual movement axis assembly with `Input.get_vector` while preserving deadzone and normalization, and pin the before/after output for representative inputs.
- [ ] 3.3 Type the remaining `main.gd` locals and loop variables and keep the suite green.

## 4. Verification and cleanup

- [ ] 4.1 Run the full gdUnit4 suite after every slice and confirm no behavior test regressed.
- [ ] 4.2 Run GDScript diagnostics on every touched script and confirm no parse or type errors and no duplicate global names.
- [ ] 4.3 Boot the main scene once and confirm normal play for at least two species, including movement and camera follow.
- [ ] 4.4 Run `ponytail-review` over the diff and fix or explicitly defer every finding.
