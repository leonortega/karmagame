## 1. Modal shell with freeze and focus

- [x] 1.1 Add state flags (`paused`, birth intro `introDone`/`introNext`) alongside kept `shopOpen`/`pendingNext`/`pendingPool` with priority selector judgment > birth > pause > shop > play
- [x] 1.2 Build centered modal shell in HUD layer (dim + panel) with one-modal-at-a-time show/hide wired to selector
- [x] 1.3 Freeze sim while any modal is open (skip move, world update, JEV poll/flush, timers) while keeping redraw and HUD refresh
- [x] 1.4 Route `_unhandled_input` focus (verbs/movement swallowed under modal; `B` shop, `P`/`Esc` pause/close, `R` judgment-only, `1-3` shop buys, `1-5` verbs in play only)
- [x] 1.5 Cover selector, freeze, and focus with gdUnit4 tests (one behavior per test, red then green)

## 2. Shop popup

- [x] 2.1 Render shop modal rows from catalog (slot, name, cost, desc, owned/affordable/locked + PA wallet with icon)
- [x] 2.2 Wire `1-3` buys through ledger rules (deduct, reject poor/owned, never-negative, once per life) with no verb cast
- [x] 2.3 Close on `B`/`Esc`/button and resume sim exactly where play stopped

## 3. Birth roulette

- [x] 3.1 Pre-draw fresh-run form via azar over all 8 with no karma evaluation and store as intro result
- [x] 3.2 Render birth modal (`KARMA` + gods line + 8 emoji blocks + settle + dismiss) with display-only cycling highlight
- [x] 3.3 Dismiss to start play; block all world keys until dismissed

## 4. Judgment roulette

- [x] 4.1 Pre-draw at death via karma pool matrix (involution `[oruga]`, neutral T1, good T1+T2) with floor reason stored
- [x] 4.2 Render judgment modal (final Karma, time, reason, eligible-pool blocks, cycling settle, settled species/tier, last up-to-4 events, Reincarnar + `R`, no picks/reroll)
- [x] 4.3 Settle involution instantly with no cycle; confirm-only rebirth keeps persistent world and carried Karma/PA

## 5. Pause popup

- [x] 5.1 Toggle pause modal on `P` and `Esc` (Esc closes shop first) with resume on `P`/`Esc`/button
- [x] 5.2 Show species, PA, Karma, and controls recap in pause body

## 6. Verification

- [x] 6.1 Suite green headless, touched scripts parse, no duplicate globals, main scene runs with all four modals at both viewport sizes
- [x] 6.2 Ponytail-review pass over the diff; fix or explicitly defer each finding
