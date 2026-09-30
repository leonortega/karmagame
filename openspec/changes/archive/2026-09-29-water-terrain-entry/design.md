## Context

See proposal.md (Why). Current state observed in code: `state.waters` holds `{kind, x, y, r}` seeded after plants in `seedFood` via `seedWaters` (`charcoR: 20`, `lagoR: 55`); `nearestWaterFor` already measures from the edge (`dist - r`) so drinking is shore-based for all species; `collectSolids`/`resolveCollisions` (utils.js) cover refuges, living plants, and rocks with a `skipRock` precedent for `topo`, applied in `movePlayer` and `updateAgents`; predators hit via `strikeContact` (reach ~ `radius + body/2`) and `killRange ~20` with no LOS contribution from water; `drawWaterField` draws a fixed-size medal + emoji. Counts already scale by area; water persists (re-seeded positions survive reincarnation by design).

## Goals / Non-Goals

**Goals:**
- Water becomes physical: solid for all but the whitelist, drinkable for all from the edge, hittable across the rim with existing combat math.
- One table for "who enters" so `pato` is a row later; no new AI targeting, no new HUD states.
- Water-only interiors via seed-order + avoidance, without changing density promises.

**Non-Goals:**
- No swimming gait, no drowning/wading/slowdown, no H-to-hide in water, no trophic-table change, no save-format change.
- No new species in this change (`pato` explicitly deferred).

## Decisions

- **Entry as data, not branches.** Add a whitelist table (e.g. `WATER_ENTER = { sapo: true }`) read at collision time. Alternative: `if (speciesKey === 'sapo')` inline — rejected, it hardcodes the one case the proposal says will grow.
- **Reuse the `skipRock` pattern.** Water entries join `collectSolids` output; callers pass `skipWater` for `sapo` (and for airborne `halcon`, mirroring its trunk-LOS exemption). Alternative: separate water-collision pass — rejected, two passes diverge and double per-tick cost.
- **`topo` stays blocked by water.** `skipRock` means "under earth", lakes are not earth; simplest consistent call. Alternative: topo tunnels under lakes — rejected, invents lakebed tunneling with no spec behind it.
- **No LOS change.** `losBlocked` keeps ignoring water (like rocks/plants); only trunks blind. Alternative: water breaks sight — rejected, flat water hiding a frog contradicts the "visible rim bite" decision.
- **Seed waters first, avoid second.** Move `seedWaters` before other scatters and gate every placer (food, refuges, rocks, agents, insects, seedlings, carrion drops/maturations) with an `insideWater(x, y, margin)` reject/nudge. Alternative: push-out at runtime only — rejected, it leaves plants/rocks visibly inside lakes.
- **Insect ring, not disc.** Bias point = `angle * (lake.r + margin + rand * lakeShore)` so the "shore buzzes" requirement can't place insects inside water. Alternative: keep disc bias + post-reject — rejected, it wastes rolls and thins the bias.
- **Render = blue disc scaled by `r` + kept emoji/label.** Grow `lagoR` (tune ~80-110, verify against travel-time density) and keep `charcoR` tiny; medal size follows `r`, glyph stays `WATER_ICON`. Alternative: drop emoji for pure blue — rejected, user explicitly kept it and it preserves the legend/readability tier.
- **Combat untouched.** `strikeContact`/`strikeAgents`/PRED rows unchanged; rim bites and "charco never safe" fall out of reach math. Alternative: water-camp timer like H-refuges — rejected, specs explicitly exclude it.

## Risks / Trade-offs

- [Risk] Bigger lagos overlap more map and squeeze other densities → Mitigation: exclusion-aware scatter with bounded retries + area-scaled counts unchanged; verify a drink stays within bounded travel time in playtest.
- [Risk] Thirsty non-swimmer AI oscillates at the shore (moveToward vs push-out) → Mitigation: edge is exactly drink range, so arrival = drinkable; existing `aiThirst` (drink when in range, else approach) already stabilizes there.
- [Risk] Sapo over-buffed (water + camouflage + toxin) → Mitigation: food stays on shore (must exit to eat), rim stays hittable, halcon still dives; no regen/immunity added.
- [Risk] Player reads shore-block as a bug → Mitigation: keep the blue-disc + label readability and the existing drink hint; no new UI chrome beyond what specs require.
- [Risk] Spawn retries cluster at map edges under exclusion pressure → Mitigation: cap retries, fall back to farthest-from-water candidate; densities are floors, not exact placements.

## Migration Plan

- No migration: no saved state, no API, no config format change. Rollback = revert TUNING/table/render deltas; specs are additive deltas on existing capabilities.
- Tuning knob check after implement: `lagoR`, insect ring margin, drink range untouched — confirm charco interior < predator reach and lago center > reach.
