## 1. Test baseline

- [x] 1.1 Reconcile `test_log_flags_default_on` to the current flags, then to oruga-only, keeping the suite green
- [x] 1.2 Scaffold `tests/test_karma_jev_oruga.gd` with helpers (`_fresh_oruga_state`, `_ai_oruga` with zeroed `verbCds`) mirroring `test_karma_jev_sapo.gd`

## 2. Bridge tests (red then green, one behavior per test)

- [x] 2.1 Menu: always has wander; eat offered on contact leaves; seek_food only when hungry; drink only below drink threshold
- [x] 2.2 Menu: flee offered when hunted with fitting refuge; silk gated on hunter-150px + cooldown + HP; nectar gated on hunter-150px + cooldown + HP + PA; leafroll gated on clump-in-eatRange + cooldown
- [x] 2.3 Menu never offers prudent or bristle (player-only exclusion test)
- [x] 2.4 `mock_choice` prefers eat over drink/flee/silk/leafroll/nectar/seek_food/wander; `mock_macro` sets intent and never logs
- [x] 2.5 `apply_answer`: eat eats contact leaves (incl. auto prudentKarma); stale/dead target falls back to wander; unaffordable nectar burns nothing; silk/nectar/leafroll cast instantly then wander
- [x] 2.6 `build_state` snapshot fields + `state_text` summary; HTTP body matches server contract; single-candidate agents skipped

## 3. Bridge implementation

- [x] 3.1 Create `scripts/karma_jev_oruga.gd` (`KarmaJevOruga`): definition, menu, state, mock, apply, batch, HTTP body per sapo template with oruga verbs
- [x] 3.2 Verify bridge tests green

## 4. Micro-steering tests + implementation

- [x] 4.1 `step_ladder` parity tests: contact eat, urgent seek, hide-before-steer (copied from current `_ai_oruga` behavior)
- [x] 4.2 `step_jev` guard tests: hide-tick, hunted-hide, thirst, urgent-seek run before steering; `jev_live` without intent holds wander; fallback to mock
- [x] 4.3 `steer_intent` tests: eat moves then eats on contact; drink/seek/flee move toward intent; wander accumulates `stillT` without travel (curl preserved)
- [x] 4.4 Create `scripts/karma_ai_oruga.gd` (`KarmaAIOruga`) and delegate `KarmaAI._ai_oruga` to it; verify AI tests green

## 5. Facade + batch wiring

- [x] 5.1 `KarmaJev` facade: `USE_JEV_ORUGA`, `LOG_JEV_ORUGA`, `schema/log/path_for("oruga")`, oruga delegates, `pick_batch_species_8` with rotation + longest-waiting tests
- [x] 5.2 `main.gd`: `o_due` poll, `_send_oruga_batch`, `is_oruga` done-branch (apply + `log_decision` as `jev-oruga/v1`), flush + clear entries; `_jev_flushed` gains oruga key
- [x] 5.3 Flip flags so only `LOG_JEV_ORUGA` is true; log isolation tests (live logs, mock never logs, other species silent)
- [x] 5.4 Back off skipped-empty picks (`mark_asked` on empty-body early return in all 8 `_send_*_batch` funcs) so wander-only species can't freeze rotation and starve the others (found live: oruga/zorro/halcon at zero sends while sated)

## 6. Verification gate

- [x] 6.1 Full gdUnit4 suite green; touched scripts parse; no duplicate global `class_name`/`func` collisions
- [x] 6.2 `openspec validate --change ai-jev-oruga` passes; main scene runs from F5 and `user://logs/jev_oruga.log` receives live entries
- [x] 6.3 `ponytail-review` pass over the diff; fix or explicitly defer each finding
