# Design: Readable Forest & Solid Terrain

## Context

Movement is two `clamp` calls against world bounds; nothing else obstructs. `draw.js` renders every food as `patchDots` (a circle in a per-kind color), species silhouettes without eyes, refuges as circles with a dark center, and a bare 80px grid floor. Perception checks are pure distance (`nearestFrom`, `nearestVictimKarmaAware`, `playerEdibleFor` + `dp < perception`) — geometry other than range does not exist. The user approved: all static elements solid, every brain collides, trunks break ground-predator LOS (halcón exempt), and a full legibility pass.

## Goals / Non-Goals

**Goals:**
- One solids list; one push-out function used by every mover; nobody phases through trees, rocks, or plants.
- Trunk LOS makes cover tactical for ground predators; halcón stays the sky counter.
- A player can identify every element by silhouette at gameplay zoom.

**Non-Goals:**
- No pathfinding/A* — agents may hug a trunk; slide handles it (ponytail ceiling).
- No per-pixel collision — circles only.
- No animation/state changes — pure spatial + render work.
- No sprite atlas/asset pipeline — stays procedural canvas.

## Decisions

### 1. Solids derived from existing state, not a parallel registry
A solid is any existing entity with a radius: refuges (per type), plants (per kind, small), rocks (new array). `collectSolids()` builds the list each physics pass from `state.refuges/plants/rocks` — no duplicated ownership, plants that die naturally stop being solid. Rocks get `state.rocks = [{x,y,r}]` at `seedTerrain`.

**Alternative rejected**: registering solid flags on entities at spawn. Two sources of truth for the same radius; drift.

### 2. Push-out with slide, applied post-move
After any mover updates position: for each solid within `r_s + r_a`, push the agent out along the center line and let the tangential component of motion survive (standard circle resolve). One function `resolveCollisions(a)` called from `movePlayer`, `updateAgents`, `updatePredators`, `aiFlee`, `aiHuntEat`. Player radius = `sp.radius`; AI agents likewise from SPECIES.

**Alternative rejected**: pre-move blocking (test-then-reject). Causes sticky corners; resolve+slide is smoother and shorter.

### 3. LOS as segment-circle intersection, ground predators only
`losBlocked(pred, target)`: sample the segment pred→target against solid trunks only (old-oak, hollow-tree, rocks are low). Applied in `pickTarget` (player hunt + mate stalk) and `strikeAgents` victim scan. Halcón skips the check entirely. Sampling ~8 points per segment keeps it cheap and trivially correct — no analytic geometry needed.

**Alternative rejected**: exact segment-circle math (discriminant). Correct but more code for zero visible difference at these speeds.

### 4. Food glyphs as a dispatch table, not more patchDots
`drawPatch(p)` switches on `p.kind` to a per-kind glyph (mata for berries, canopy+apples for shrubs, soil line + orange triangle for carrots, cap+stem for mushrooms, trunk+nut ovals for oaks, leaf fan for clumps). Same shape of loop as today, one branch per kind. `dead` plants render as greyed trunk/stem remnants.

**Alternative rejected**: keep patchDots with per-kind offset hacks. That's how the illegibility happened.

### 5. Eyes + facing on every species, decor deterministic
Eyes drawn inside `drawSpecies` after body (two dark dots toward facing, plus pupils). Grass tufts/flowers use a fixed pseudo-random function of tile coords (`hash(x,y)`) so the floor doesn't shimmer per frame — same trick as `scatter` but stable.

**Alternative rejected**: `Math.random()` per frame per tuft. Shimmering floor = visual noise, the opposite of legibility.

## Risks / Trade-offs

- **[Risk] AI pathing against solids**: a hunter may stall sliding around a trunk while prey circles. Mitigation: slide keeps tangential motion; wander waypoints re-roll when unreachable (`Math.hypot(p.wx-p.x,p.wy-p.y)<20` already re-rolls). Accept visible hugging (ponytail ceiling).
- **[Risk] Solids at spawn overlap agents**: seed positions use `scatter` which may drop a plant on a spawn point. Mitigation: push-out resolves on first tick; also spawn-time nudge if overlapping a refuge.
- **[Risk] LOS sampling misses thin obstructions**: trunks have r≥12 and segments sample 8+ points — misses are sub-pixel scale; fine.
- **[Risk] Render cost**: glyph dispatch + decor adds draw calls. Grass decor only draws tiles near camera; glyphs are 2-4 primitives per plant. Fine at current entity counts.

## Migration Plan

Static game. Verification: `node --check` touched files → full suite green → no duplicate functions → index.html refs. Rollback: revert change files.

## Open Questions

- Should burrows (player-dug) be solid? They're refuges — design says yes (a mound you can't walk through), confirm in playtest.
- Do rocks ever become gameplay (sense-pulse echo, halcón perch)? Deferred — decorative-solid for now.
