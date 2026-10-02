## Why

AI zorros use 2 of their 5 player verbs and a hardcoded priority ladder (`karma_ai.gd:_ai_zorro`), so they never play like a human zorro (no cachecarrion, dendig, or strike-as-choice). A LAN NanoJev sidecar (`POST http://192.168.100.80:8766/api/evaluate`) can rank per-zorro intents in parallel while Godot keeps 60Hz steering, giving full verb parity for one species first.

## What Changes

- Add a zorro decision bridge: per-tick GDScript builds the legal candidate menu for each AI zorro, batches all zorros into one NanoJev `Choice` call, applies the winner via the existing player code paths (`eat_carrion`, `cede_carrion`, `cast_verb_for`).
- Split zorro brain into micro (every physics tick, no API wait: steering, contact kills, drink-in-range, flee-lobo, cooldown/need ticks) and macro (API-timed intent: hunt / carrion / cede / cache / dendig / strike / drink-seek / refuge-seek / wander).
- Run macro on staggered 1s timer per zorro plus immediate re-ask on events (lobo within fear range, HP below hunger threshold, fresh carrion in perception, kill resolved, intent reached/expired); data-LOD slows off-camera zorros to 3s.
- Return `emocion` alongside choice for HUD/feed flavor only; it never gates execution.
- Record decision logs (state, candidates, choice, outcome) from day one for future training; stock checkpoint is expected to be weak until zorro episodes are collected.
- Scope strictly to zorro; other 7 species keep the current ladder unchanged.

## Capabilities

### New Capabilities

- `ai-jev-zorro`: NanoJev-backed macro decisions for AI zorros (batch contract, candidate menu, micro/macro split, cadence, logging).

### Modified Capabilities

- `ai-species-behavior`: zorro clause of `updateAgents` delegates intent to JEV ranking instead of the hardcoded ladder; outcomes (kill/carrion/karma values) unchanged.

## Impact

- Affected code: `scripts/karma_ai.gd` (`_ai_zorro`, `ai_maybe_verb` zorro branch), `scripts/main.gd` (owns tick + bridge calls, no autoload), new static helper (e.g. `KarmaJev`) plus HTTP client to local sidecar.
- Systems: F5 dev now requires the NanoJev service running for zorro intent; micro steering still runs at 60Hz without answers. gdUnit4 zorro tests need deterministic mocked answers.
- Dependencies: zero new Godot addons; external dev-only sidecar `serve_decisions.py` + `unified-games-v1` checkpoint (CUDA host).
