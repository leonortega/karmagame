## Context

See proposal.md (Why). Live telemetry (`jev_poll.json` + `jev_lobo.log`) shows the `ai-jev-lobo` migration healthy: 4 fair sends per species, 0 errors, legal-only menus. It also shows the ceiling: a 1-lobo map yields 2-candidate menus and `regurg` can never fire (it needs a hungry same-species mate in groom range, and `_verb_regurg` only scans `company_agents`). Population floors live in `KarmaData.POP.faunaFloor` (lobo: 1); `seed_fauna` + `respawn_missing` (20s top-up) enforce them, so a floor change is self-maintaining.

## Goals / Non-Goals

**Goals:**

- Every run holds at least two fauna lobos so pack verbs are reachable with or without a lobo player.
- AI `regurg` (verb + menu) treats fauna lobos as packmates on the same terms as company mates.
- Hungry `seek_carrion` ranges to `wanderSeekRange`, matching the ladder's urgent-seek trek the JEV driver already runs as a reflex.
- A recorded verdict on the t=408 wander-over-seek pick (ranker-side vs Godot-side).

**Non-Goals:**

- No new verbs, no sidecar protocol changes, no tuning changes besides the floor count.
- No changes to howl/escort/cull player-only status.
- No rebalancing of hunt pressure beyond accepting two apexes (stated in proposal).

## Decisions

### 1. Floor 2, not more

Why: the user asked for "more than 1"; 2 is the minimum that unlocks the pack, matches the zorro floor, and minimizes added hunt pressure. Alternative (3+) was rejected without telemetry showing 2 is insufficient.

### 2. Widen `_verb_regurg` mate scan to fauna lobos

Why: the verb is the single source of truth — the ladder (`ai_maybe_verb`), the JEV menu gate, and `apply_answer` all funnel through `cast_verb_for(state, a, 2)`. Widening the scan inside the verb fixes all three call sites at once and keeps player parity (player regurg already scans company mates; agents gain fauna mates, a superset with identical cost/karma). Alternative (menu-only widening with verb unchanged) was rejected: the menu would offer a move the verb then refuses.

### 3. Seek range = `wanderSeekRange` when hungry, perception otherwise

Why: mirrors `ai_urgent_seek` (the reflex that already treks to distant food at floor hunger) and reuses an existing tuning key instead of adding one. Contact-`eat` gating (eatRange) is unchanged, so the legal-only contract holds.

### 4. Probe first, then decide on wander/seek

Why: the t=408 pick (wander 0.74 over seek 0.26, hungry, water nearby) is fully explainable Godot-side (hunger dominated thirst per `seeks_water`; wander tail travels to POIs), so the likely verdict is ranker-side working-as-intended. The probe task replays the snapshot shape in a test to confirm no Godot-side gate suppressed `seek_carrion`; if it finds one, it becomes a menu fix in this change, otherwise no Godot change.

## Risks / Trade-offs

- [Risk] Two apexes double T2/zorro hunt pressure → Mitigation: accepted explicitly; census in `jev_poll.json` makes pressure observable per run.
- [Risk] Regurg widening lets AI lobos feed fauna mates the player might be hunting → Mitigation: same HP cost and karma as today; behavior matches company feeds.
- [Risk] Wider seek menus send slightly more lobo batches → Mitigation: single-flight + fair-share already bound this; `<2-criteria` skip unchanged.

## Migration Plan

No data migration. Floor change applies to new lives at seed time and to running maps at the next 20s respawn top-up. Rollback is revert; no persistent state depends on the new menu entries.

## Open Questions

- If pack telemetry shows 2 lobos still rarely interact (map is 3200×2400), consider a pack-cohesion survey as a separate change — not this one.
