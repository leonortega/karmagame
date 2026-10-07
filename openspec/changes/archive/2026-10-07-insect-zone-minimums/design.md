## Context

See proposal.md (Why). Current state (working tree): `spawn_insect_pt` chains lago ring → charco ring → uniform; `age_world` respawns one per 12s below cap 10; world gen seeds `scaled_count(6)` via the same lottery. Minimums need determinism the lottery cannot give.

## Goals / Non-Goals

**Goals:**
- Guaranteed floors with the existing geometry; lottery survives only for headroom.

**Non-Goals:**
- No cadence, wander, payoff, diet, or never-inside-water changes.
- No per-body quotas (round-robin/random spread is enough; zones are collective).
- No initial-seeding distribution beyond the minimums (headroom fills through the normal cadence, exercising the refill path from tick one).

## Decisions

- **Refill priority: charco-short → lago-short → lottery-under-cap.** Short means zone count below minimum. The first short zone in that order takes the spawn; a satisfied world behaves exactly like today. Alternative (weighted lottery toward short zones) rejected: probabilities still admit droughts, which is the complaint.
- **Cap 40 (minimums 30 + headroom 10).** Headroom preserves today's uniform stragglers and absorbs the initial-seeding overshoot nowhere — seeding targets exactly the minimums (10 + 20). Alternative (cap == 30) rejected: zero room for uniform spawns makes the lottery branch dead code.
- **Zone test is pure distance: charco `r×4`, lago `r+lakeShore`, counted independently.** Overlaps count for both (rare; keeps the helper branchless). One helper (`zone_counts` beside the spawn code) serves refill, seeding checks, and tests.
- **Absent kinds skip silently.** No charcos → charco minimum unfillable; the refill falls through to lago/lottery. Tests pin this so dry maps never stall respawn.
- **Seed minimums round-robin at world gen.** Deterministic start composition (hunting from tick one); headroom accrues through cadence. Alternative (keep scaled lottery seeding) rejected: a fresh world could open below its own minimums for minutes.

## Risks / Trade-offs

- [Risk] 30–40 wandering insects cost per-tick updates → Mitigation: trivial next to agents/predators (same move math, no AI).
- [Risk] Topo/sapo feast both inflate → Mitigation: intended shared abundance; same payoffs, no karma change.
- [Risk] Existing cap-10 tests encode the old ceiling → Mitigation: updated in place as part of this change (they test the old numbers, not contracts).

## Migration Plan

Zone helper + refill priority + seeding + cap, each under its tests, suite green throughout. Rollback is the priority branch out (plain cap lottery returns).
