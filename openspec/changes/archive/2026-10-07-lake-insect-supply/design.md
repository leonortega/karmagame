## Context

See proposal.md (Why). Current state: `KarmaData.TUNING` holds `insectMax: 6`, `insectRespawn: 20.0`, `lakeInsectBias: 0.6`, `lakeShore: 120.0`; `KarmaGame.age_world` respawns one insect per window up to the cap via `spawn_insect_pt` (lake-biased). No test pins either number; all insectivore tests set `state["insects"]` explicitly. Density math: 6 insects over 7.68M px² with a ~23k px² sapo perception disc makes encounters ~1%-order per check — the log's 76s drought is the expected outcome, not a bug.

## Goals / Non-Goals

**Goals:**
- Lift encounter odds ~3× with the smallest behavior surface: two numbers, same code paths.

**Non-Goals:**
- No forage/perception changes (global `forageRangeMult` affects every species — rejected).
- No extra lagos or bias changes (map-gen churn for no proven need — rejected).
- No slower insects or payoff changes (changes catchability/economy for topo too — rejected).

## Decisions

- **Cap 10, cadence 12s; everything else frozen.** Alternatives above rejected per Non-Goals. Topo shares the gain through the identical shared supply — intended, same diet, same payoffs.
- **Sapos meet insects at lakes without new steering.** Sapo thirst drains 2× hunger, so sapos already trek to water; the unchanged 0.6 bias keeps the new supply where sapos drink. No AI changes needed.

## Risks / Trade-offs

- [Risk] More insects trivialize sapo hunger → Mitigation: cap 10 is still sparse (~1 per 768k px² uniform); watch live logs, tune once with evidence.
- [Risk] Topo economy inflates symmetrically → Mitigation: same +10/+3 payoffs, no karma change; accepted as shared-supply behavior.

## Migration Plan

Two-number `TUNING` edit with the new world-sim tests green. Rollback is the two numbers back (no save-format or spec-state migration).
