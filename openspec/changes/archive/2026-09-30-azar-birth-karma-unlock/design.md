## Context

See proposal.md Why. Current state: `judge()` in `src/script/shop.js` maps (karma, PA, deadForm) to a deterministic next form with player overrides (`pickT2` free, `chooseForm` 15 PA); start screen in `src/index.html` + `src/script/game.js` offers 8 pick buttons via `startRun(k)`; shop is one global `SHOP` array in `src/script/data.js` bought via `buyItem` in `shop.js` for player and AI alike. Tests in `test/shop.test.js` assert choice-based judgment. Zero dependencies, plain `<script>` globals; harness stubs DOM/canvas.

## Goals / Non-Goals

**Goals:**
- Karma-only unlock floor with uniform azar draw; PA fully out of judgment.
- Dramatic gods-reveal on both start and judgment with zero choice controls.
- Per-species 3-item shop catalogs reusing the existing wallet/owned/per-life machinery for player and AI.

**Non-Goals:**
- Rebalancing species stats, diets, verbs, PA income (~20/min), or karma carry (20%) — all unchanged.
- New art, sound, or animation framework; reveal is DOM + CSS classes only.
- Reroll, pity timers, or weighted draws — uniform draw, fate is final.

## Decisions

- **Pure `poolFor(karma)` + `drawFrom(pool, rand)` split.** `poolFor` is pure and table-driven (`T1POOL`, T2 list incl. Lobo, cutoffs -50/+50); `drawFrom` takes an injectable random so tests stub determinism while the game passes `Math.random`. Alternative (weighted draw) rejected: uniform is the laziest legible fate and matches "unlock floor" (F1 additive).
- **Delete, don't deprecate, the choice paths.** Remove `pickT2`, `chooseForm`, `pendingChoice`/`formChosen`, T2-pick and Choose-form buttons, `TUNING.chooseFormCost` gating, and the lateral-cycle index logic. Fewer branches beats dead UI. `judge()` returns `{ pool, next, reason }` where `next` is already drawn.
- **Reveal as progressive enhancement over settled state.** Set `pendingNext` synchronously at `showJudgment` (and start-draw at Nacer), then animate block highlighting (eligible lit, others dimmed; interval cycling with slowdown, ~1s) settling on the pre-drawn form. Tests assert pool + settled form without timers; animation never changes the outcome. Start screen: same block grid over all 8, one Nacer button.
- **`SHOP_BY_SPECIES` map replaces `SHOP`.** Shape `{ raton: [{id,name,cost,desc,effect} x3], ... }`; `buyItem(id)` resolves against `state.speciesKey` catalog (player) or `agent.speciesKey` (AI). Keep `owned`/`shopOpen`/no-debt/per-life semantics byte-identical so AI parity from `ai-karma` spec is free. Alternative (one catalog with species tags) rejected: map lookup is simpler at call sites.
- **Pattern 1 stat + 1 verb-upgrade + 1 signature per species, 50–80 PA.** Reuses proven mechanics (speed/vision/HP numbers, tongue/tremor/track/chorus magnitudes already in TUNING/VERB_DEFS) with new flavor rather than 24 novel systems. Pricing targets ~1 item/life at current PA income.

## Risks / Trade-offs

- [Risk] 24 items × effects × tests is the content iceberg → Mitigation: tasks ship catalog data first with shared-mechanic effects, then wire each effect to existing TUNING/verb magnitudes; ponytail-review before done.
- [Risk] Random Lobo/Halcón at life 1 or after good karma spikes power variance → Mitigation: accepted by design (Lobo normalized); hunger/drain rates already species-paced; no extra balancing in this change.
- [Risk] Reveal animation flakes tests or traps keyboard (R) during cycling → Mitigation: outcome settled synchronously, animation cosmetic only; R/Reencarnar active immediately.
- [Risk] Choice-removal breaks existing tests and muscle memory → Mitigation: rewrite `test/shop.test.js` judgment block to pool/draw assertions; start-screen test asserts single Nacer + uniform draw stub.

## Migration Plan

- Land pool/draw + reveal + start-azar + choice deletion first (judgment tests green), then catalog data + `buyItem` rewire + AI parity (shop tests green). No rollback beyond revert; no data migration (no persistence).
- `node --check` touched files → full suite green → no duplicate `function` names → index.html refs resolve.

## Open Questions

- Exact per-item effect numbers per species (magnitudes/CDs within the stat/verb-upgrade/signature pattern) — safely deferred to implementation tasks; specs constrain only pattern and 50–80 PA pricing.
