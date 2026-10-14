## Why

Live `jev_lobo.log` telemetry shows the lobo migration works (fair scheduling, legal-only menus, sane picks) but also shows its ceiling: with a single lobo on the map, menus collapse to 2 candidates, the `regurg` pack verb can never fire (it needs a hungry same-species packmate), and a hungry lobo's `seek_carrion` lost to `wander` with no Godot-side explanation. Lobo is a pack apex — a lone wolf cannot exercise the kit we migrated.

## What Changes

- Raise the lobo population floor from 1 to 2 (`POP.faunaFloor`), so initial seeding and the 20s respawn top-up maintain at least two fauna lobos and pack verbs become reachable in every run. Assumption: exactly 2 (the minimal "more than 1"); matches the zorro floor.
- Widen AI `regurg` targeting from company-only mates to any hungry lobo packmate (company or fauna) within groom range, in both the verb and the JEV menu gate, so two fauna lobos can feed each other.
- Enrich the lobo candidate menu so thin states offer more: `seek_carrion` extends beyond 280 perception up to `wanderSeekRange` when hungry (mirroring the `ai_urgent_seek` trek the ladder already does), keeping the legal-only contract.
- Probe the t=408 wander-over-seek pick as an investigation task: it may conclude ranker-side working-as-intended (wander tail travels to POIs anyway) with no Godot change.

## Capabilities

### New Capabilities

- `ai-jev-lobo-pack`: pack hunting and feeding behavior for AI lobos — regurg to any hungry lobo packmate, enriched seek gating, and the wander/seek probe conclusion.

### Modified Capabilities

- `living-map`: lobo population floor raised from 1 to 2 so packs exist in every run (seed + respawn top-up).

## Impact

- Modified: `scripts/karma_data.gd` (`POP.faunaFloor` lobo 1→2), `scripts/karma_game.gd` (`_verb_regurg` target set), `scripts/karma_jev_lobo.gd` (menu gates), `tests/test_karma_jev_lobo.gd` (+ pack coverage), specs `living-map` delta.
- No tuning value changes besides the floor count; no sidecar protocol changes; no HUD changes.
- Balance note: two apex predators instead of one — more hunt pressure on T2/zorros; accepted per the user's "more than 1 lobo" direction.
