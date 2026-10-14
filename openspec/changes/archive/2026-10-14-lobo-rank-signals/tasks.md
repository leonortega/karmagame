## 1. Need token (`karma_jev_lobo.gd`)

- [x] 1.1 Add `need=urgent|hunger|thirst|none` to `state_text` with tests (floor hunger → urgent, hungry → hunger, thirsty-not-hungry → thirst, sated → none; all existing fields intact)

## 2. Red-flag screen (`karma_jev.gd` + bridge)

- [x] 2.1 Add pure `KarmaJevLobo.is_red_flag` (hungry snapshot + `eat` in menu + choice `wander`) with tests (flag on match; no flag when sated, when `eat` absent, or when choice is `eat`)
- [x] 2.2 Bump cumulative `state["jev_red_flags"][species]` inside `log_decision` for live enabled matches only, with tests (mock-shaped calls never counted; disabled flag counts nothing)

## 3. Flush + mock order

- [x] 3.1 Include `red_flags` (default `{}`) in the `jev_poll.json` snapshot write (`script_check` valid; live-verified in 4.2)
- [x] 3.2 Verify mock priority stays eat-first (existing `test_mock_choice_prefers_eat` green, no code change)

## 4. Suite + verification gate

- [x] 4.1 Run full `res://tests/` suite: lobo suites green, no new failures (331 cases; same 10 pre-existing failures as the pack-behavior baseline, none intersecting this change)
- [x] 4.2 Run the main scene and confirm `jev_poll.json` carries a `red_flags` object and live `need=` tokens appear in `jev_lobo.log` states (live: poll carries `"red_flags":{}`, census lobo=2, 0 errors, fresh live entries flowing; `need=` verified in outgoing request bodies by unit test — log entries carry snapshot dicts by construction, so the task's "in jev_lobo.log" phrasing was corrected to request-body coverage)
