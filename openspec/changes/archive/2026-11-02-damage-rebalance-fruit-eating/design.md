## Context

See proposal.md — Why. The change touches `scripts/karma_eat.gd` (`eat_patch`), `scripts/karma_data.gd` (`PRED` damage bases), and the four delta specs above. No new autoloads or engine changes.

## Goals / Non-Goals

**Goals:**
- Make fruit-patch consumption a single bite that depletes the plant, with nutrition summed across consumed fruits and the last-fruit karma penalty.
- Retune predator contact damage bases to nature-like fixed values (zorro 28, lobo 38, halcón 30).
- Keep leaves, mimic, and toxic-shroom paths unchanged.
- Preserve seed-sprout counts and regrow timing.

**Non-Goals:**
- No percentage-based `damagePct` model (deferred; see Decisions).
- No changes to pounce/dive (already percentage-based on victim max HP).
- No rebalance of FOODDEF values or TUNING HP constants.
- No changes to AI decision logic beyond player-parity scenario wording.

## Decisions

### D1: One bite consumes the whole patch, nutrition = (n-1) sustainable + last fruit

- **Choice**: For non-leaf fruit patches, set `amount = 0`, `alive = false`, heal `(amount-1)*foodHp + lastFruitHp`, refill hambre by the same, grant `(amount-1)*foodPa` PA (player only), apply `-15` karma (player only), and drop a seed `amount` times.
- **Rationale**: Reuses existing `lastFruitHp`/`lastFruitKarma` constants and the sustainable payoff table; a single-fruit patch still yields the historic last-fruit result (20 HP, -15 karma), so existing single-fruit expectations hold. Keeps AI parity (HP/hambre only, no PA/karma) consistent with current `eat_patch` rules.
- **Alternatives considered**: (a) Sum only (`foodHp * amount`) — simpler but discards the last-fruit bonus and breaks single-fruit expectations (20 → 15 HP). (b) Percentage-based nutrition — no benefit. Rejected in favor of preserving constants and existing single-fruit behavior.

### D2: Leaves, mimic, and toxic shrooms stay on the old path

- **Choice**: Branch in `eat_patch`: leaves keep `amount -= 1` + `eat_sustainable`; mimic/toxic-shroom keep their single-fruit decrement and toxicity handling.
- **Rationale**: Leaves regrow differently and are exempt from karma; mimic/toxic logic is explicitly out of scope per the proposal. Keeps the change minimal and avoids altering prudent-karma behavior for oruga.

### D3: Seed drops loop `amount` times

- **Choice**: Call `KarmaGame.drop_seed` once per consumed fruit.
- **Rationale**: Preserves the historic seed-sprout rate (one roll per fruit eaten) so forest renewal is unchanged despite fewer bites.

### D4: Predator damage stays fixed-base (defer percentage-based)

- **Choice**: Adjust `PRED` damage bases (zorro 28 unchanged, lobo 35→38, halcón 15→30) and keep `strike_contact` using `scaled_damage(t["damage"], ...)`.
- **Rationale**: Satisfies the nature-like table example (halcón vs sapo ≈ 30 damage ≈ 37.5% of 80 HP) with the smallest change; age scaling preserved. The `damagePct` percentage model is deferred because it would require rewriting senescence damage tests and the `t["damage"]` contract used across tests.
- **Alternatives considered**: Percentage-based `damagePct` (halcón 0.30, zorro 0.28, lobo 0.32) — more flexible but breaks the existing test contract and adds a new field; deferred to a follow-up change if finer per-target control is needed.

### D5: AI parity via unchanged `eat_patch` path

- **Choice**: No changes to AI callers; they already route through `KarmaEat.eat_patch`. Only scenario wording in `ai-jev-raton`/`ai-jev-ardilla` changes.

## Risks / Trade-offs

- [Risk] One-bite consumption makes every fruit eat a -15 karma act, increasing karma cost for players and removing sustainable (karma-neutral) fruit eating for non-leaves. [Mitigation] Intended by proposal; leaves remain karma-neutral for oruga; documented in specs.
- [Risk] Tests asserting multi-bite consumption (`test_sustainable_eat_pays`, `test_karma_jev_*`) break and must be rewritten. [Mitigation] Tasks list them explicitly; apply phase updates in the same change.
- [Risk] Seed drop loop calls `drop_seed` N times per bite, slightly increasing RNG calls. [Mitigation] Bounded by fruit cap (≤ 3 for most kinds); negligible.
- [Risk] Halcon damage 15→30 doubles halcón bite damage; senescence tests for halcón may need review. [Mitigation] Only zorro damage is asserted in senescence tests; apply phase checks halcón-related tests.

## Migration Plan

1. Update `eat_patch` in `scripts/karma_eat.gd`.
2. Update `PRED` damage values in `scripts/karma_data.gd`.
3. Update affected gdUnit4 tests.
4. Archive the change (syncs delta specs into main specs).

Rollback: revert the two script edits and test edits; delta specs are removed on archive revert.

## Open Questions

- None. All decisions resolved above.