## Context

See proposal.md (Why). Current state: `KarmaJev.appraise_emocion(snapshot, kind)` reads `threatened`, then nut-carry, then `hungry`; only the ardilla and sapo bridges call it as a backfill (zorro/halcon/raton leave missing labels empty). Sapo snapshots carry `pressure_near` since `sapo-jev-decisions`; ardilla snapshots do not.

## Goals / Non-Goals

**Goals:**
- One-condition change with provably single-species impact.

**Non-Goals:**
- No new vocabulary (reuse `Miedo`), no ranker/mocked changes, no backfill added to zorro/halcon/raton (separate decision, explicitly out).

## Decisions

- **`pressure_near` joins the first check via missing-key-safe read.** `bool(snapshot.get("pressure_near", false))` alongside `threatened`: ardilla snapshots lack the key and evaluate identically to today (no test or behavior change there); sapo gains Miedo-under-pressure. Alternative (sapo-local appraisal function) rejected: it forks the shared rule a second time.
- **Order preserved: danger, then Esperanza, then Hambre.** Pressure is danger-equivalent, so it belongs in position one, not as a new branch. Alternative (pressure after hunger) rejected: it would keep reporting Hambre under threat — the exact log finding.

## Risks / Trade-offs

- [Risk] Ranker-supplied labels unaffected (backfill only fires on empty) → Mitigation: none needed; `emocion_source` in the log distinguishes both paths for verification.
- [Risk] Future snapshots adding `pressure_near` for other species change their flavor → Mitigation: that addition would be its own spec-visible change; nothing silent.

## Migration Plan

One-condition edit plus unit tests. Rollback is the condition back out (flavor-only; no save, sim, or log-schema impact).
