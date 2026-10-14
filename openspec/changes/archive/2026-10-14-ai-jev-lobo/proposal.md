## Why

Lobo is the last AI species still running ladder logic while all six other JEV species (zorro, halcon, raton, ardilla, sapo, topo) choose macro intent from the same verb menu as the player, ranked by NanoJev. Migrating lobo closes the set so every AI predator plays by player-parity rules with micro steering that never waits for the ranker.

## What Changes

- AI lobo macro intent comes from one batched NanoJev `Choice` request per poll window, ranking a code-built legal-only candidate menu; NanoJev ranks, never invents moves.
- Micro steering runs every physics tick regardless of pending/failed macro answers: move toward intent, contact-kill resolution through the same hunt path as the player, drink in range, needs/cooldown ticking.
- Candidate menu covers the AI-executable lobo kit: eat, seek-carrion, hunt, drink-seek, strike, regurg, alarm, wander (wander always present). Player-only verbs (howl, escort, cull) are never offered, same precedent as topo `nestdig`.
- Cadence matches the other species: staggered 1s timer (3s far-LOD), event re-asks bounded by `jevReaskBackoff` 0.5s, fair-share single-flight scheduling across now seven species.
- Per-species decision log `jev-lobo/v1` to `user://logs/jev_lobo.log` behind a compile-time flag; `emocion` is flavor only; mocked decisions never log.

## Capabilities

### New Capabilities

- `ai-jev-lobo`: NanoJev-backed macro decisions for AI lobos with the same contract as the other six species (legal-only menu, micro-never-waits, cadence + events + LOD, full-kit coverage minus player-only verbs, emocion + logging).

### Modified Capabilities

- `ai-species-behavior`: the lobo AI function splits into micro steering every tick plus macro intent from NanoJev ranking per `ai-jev-lobo`, using the same hunt/carrion/karma values as the player.
- `ai-jev-cadence`: fair-share batch scheduling, backoff, and poll telemetry cover seven JEV species (adds lobo alongside the existing six).

## Impact

- New: `scripts/karma_jev_lobo.gd`, `scripts/karma_ai_lobo.gd`, `tests/test_karma_jev_lobo.gd`, `openspec/specs/ai-jev-lobo/spec.md`.
- Modified: `scripts/karma_ai.gd` (lobo dispatcher to Strategy), `scripts/karma_jev.gd` (facade delegates, `USE_JEV_LOBO`, `LOG_JEV_LOBO`, `pick_batch_species_7`), `scenes/main.gd` (lobo due set, send batch, answer branch, flush list, flight clear), specs `ai-species-behavior` and `ai-jev-cadence` deltas.
- No tuning value changes, no verb mechanic changes, no HUD changes beyond existing emocion flavor surface.
