## Context

See proposal.md (Why). Current state: `spawn_insect_pt` tries the lago ring at `lakeInsectBias` 0.6, else uniform dry scatter (`scatter_dry`); `nudge_dry` keeps points out of water. Worlds seed ~24 insects (`scaled_count(6)`), cap/refill 10 per 12s (working tree). Charcos get no affinity at all.

## Goals / Non-Goals

**Goals:**
- ~88% of spawns water-associated with one new branch and one new key.

**Non-Goals:**
- No count/cadence changes (placement is the diagnosed bottleneck; numbers tune later with census evidence).
- No initial-seeding change (pre-existing `scaled_count(6)` logic untouched).
- No payoff, diet, or wander changes.

## Decisions

- **Chain: lago 0.6 → charco 0.7-of-remainder → uniform.** Total water-associated ≈ 0.88; lago keeps priority (bigger habitat, spec-pinned). Alternative (single any-water pick weighted by radius) rejected: lago priority would need re-derivation and the spec names lago bias explicitly.
- **Charco ring `r+8..r×4`, radius-relative.** A fixed shore width (120px) would scatter puddle insects across the map; relative geometry keeps charco rings tight with zero new geometry keys. Inner margin 8px matches the lago path (never inside water, `nudge_dry` as backstop).
- **One new `TUNING` key (`charcoInsectBias`), nothing else.** Range geometry derives from the water body itself.
- **Requirement header kept (`Lagos anchor...`).** Body now covers charcos; renaming the header would break MODIFIED header matching — accepted one-line staleness, flagged here instead of in the spec.

## Risks / Trade-offs

- [Risk] Charco rings overlap forage of non-insectivores harmlessly (insects are diet-gated per species) → Mitigation: none needed.
- [Risk] Topo feasts symmetrically → Mitigation: same shared supply as the cap change; intended.
- [Risk] Probabilistic placement is inherently statistical in tests → Mitigation: generous thresholds with sub-1% flake math on both sides (RED certain on old code, GREEN stable on new).

## Migration Plan

Branch plus key plus tests. Rollback is the branch out (falls back to lago-or-uniform exactly).
