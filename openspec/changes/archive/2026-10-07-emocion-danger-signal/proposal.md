## Why

Live `jev-sapo.log` shows `emocion: Hambre` with `emocion_source: local` on every decision: the sidecar never supplies an emocion label, and the shared local appraisal only knows `threatened` — which the trophic size rule keeps false for sapo forever. The snapshot already carries the live danger signal (`pressure_near`, added by `sapo-jev-decisions`), but the appraisal ignores it, so feed flavor is monotonous and misleading under threat.

## What Changes

- The shared `appraise_emocion` fallback treats hunter pressure like the trophic threat flag: `pressure_near` true appraises `Miedo`, checked in the same first position as `threatened`, via a missing-key-safe read.
- Only sapo behavior changes: sapo is today the sole snapshot carrying `pressure_near` (ardilla snapshots lack the key and evaluate identically to today — provably no behavior change there; zorro/halcon/raton don't backfill at all).

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `ai-jev-sapo`: the emocion-flavor requirement gains the pressure rule — a label-less answer under hunter pressure appraises `Miedo` instead of `Hambre`.

## Impact

- Affected code: one condition in `KarmaJev.appraise_emocion` (`scripts/karma_jev.gd`).
- Tests: direct unit tests of the pure appraisal function (danger → Miedo, hungry-only → Hambre, neither → empty) plus one bridge backfill test through `apply_answer`.
- No menu, steering, logging, payoff, or other-species changes.
