# Proposal: Species Locomotion & Karma Verbs

## Why

Every animal moves the same way today: hold a direction, slide at `effSpeed()`. A sapo glides like a mouse; an oruga cruises like a fox. Real animals have signature gaits — frogs jump, caterpillars inchworm, moles tunnel. Movement should *feel* like the animal.

Karma is equally generic: species-share a pool of verbs (shout, groom, aerate, plant, cede) gated in code, with no dedicated per-species action bar. Each real animal has its own ecological role, and that role is the game's karma currency.

## What Changes

- **Locomotion per species**: 8 movement modes replace uniform sliding — sapo hops (impulse+pause), oruga inchworms (burst+stop), ratón scurries, ardilla bounds, topo tunnels low and steady, halcón glides, zorro/lobo trot. Player AND AI move through one shared locomotion step so gaits are ecosystem-wide.
- **Karma verb bar 1–5**: each species gets 5 species-real verbs (40 total) drawn from actual animal behavior. Keys 1–5 cast verbs; when the shop overlay (B) is open, 1–5 buy shop items instead (context routing).
- **Real costs**: verbs cost vida and/or PA with per-verb cooldowns; karma pays out when used in the right context (e.g. regurgitate feeds a hungry packmate, culling targets the weak).
- **Full AI parity**: AI agents of each species cast their own verbs contextually through the same verb table and cooldowns (same parity standard as foraging-survival-ai).
- Shop stays global and unchanged (swift/stomach/nose/voice); per-species PA upgrades are explicitly deferred.

## Capabilities

### New: species-locomotion
Per-species movement modes driven by a LOCO data table + one shared stepping function. Covers player and AI, cadence envelopes, and interactions with existing systems (hide, grounded, chase multipliers, solids).

### New: karma-verbs
The 1–5 verb bar: VERB_DEFS data table per species, VERB_FN dispatch, context routing with the shop, real costs, cooldowns, context-conditional karma, and AI parity.

## Impact

- `src/script/data.js`: LOCO + VERB_DEFS tables, new TUNING keys.
- `src/script/game.js`: locomotion stepping in movePlayer + moveAgent helper; verb routing in keydown; VERB_FN map.
- `src/script/ai.js`: aiMaybeVerb helper + species wiring.
- `src/script/eat.js`: no changes (E stays).
- `src/css/style.css`: verb bar HUD + hop/inch visuals hooks (draw.js).
- Risks: existing speed-based tests (chase/flee/forage timings) must stay green — envelopes are calibrated in TUNING, not hardcoded; 40 verbs are the bulk of the change and land species by species under TDD.
