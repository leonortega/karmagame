## 1. Fair-share scheduler (TDD)

- [x] 1.1 Longest-waiting picker unit tests (RED) then GREEN in `KarmaJev` (extend `pick_batch_species_4` with last-served map; update existing rotation tests)
- [x] 1.2 Wire last-served tracking through `Main` sends, full gdUnit4 suite green

## 2. Re-ask backoff (TDD)

- [x] 2.1 Backoff unit tests (event re-ask suppressed inside window, fires after; timer path unchanged) then GREEN (`TUNING["jevReaskBackoff"]` + `should_ask`/`mark_asked`)
- [ ] 2.2 Full suite green plus F5 churn check (no same-agent asks <0.5s apart across `jev_*.log` runs)

## 3. Carry salience and telemetry contract (TDD)

- [x] 3.1 Carry/bury criteria-label hints with menu-legality tests (`(hunted!)` precedent; no menu/odds/tuning changes)
- [x] 3.2 Telemetry contract tests (`poll_note` busy/sent/error coverage, `jev_poll.json` shape on flush)
- [ ] 3.3 Full suite green plus F5 live verify (`(hunted!)`/carry labels in log, poll file present, oak-adjacent carry watch)

## 4. Local emocion appraisal (added scope, user-requested 2026-10-06)

- [x] 4.1 Appraisal table unit tests (RED) then GREEN (`KarmaJev.appraise_emocion`: threatened→Miedo, nut→Esperanza, hungry→Hambre, calm→empty)
- [x] 4.2 Ranker-wins + source marking (`emocion_source` ranker/local through parse→log; ardilla apply fills empty only)
