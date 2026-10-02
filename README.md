# Karma MVP (Godot 4)

A 2D ecosystem survival experience where your actions shape your next life — now a
pure Godot 4 project (ported from the vanilla JS prototype with full behavioral parity).

Play as creatures in a living world: forage, hunt, hide, and survive. Your karma
(good or bad deeds) determines what you become when you reincarnate.

## Features

- **8 species** across 3 tiers — from caterpillar to wolf
- **Karma system** — eat wisely, defend prey, avoid waste; reap rewards or suffer consequences
- **Reincarnation** — judgment after death shapes your next form
- **Predator/prey AI** — dynamic ecosystem with hunting, fleeing, and social behavior
- **NanoJev zorro brains** — AI zorros pick from the full 5-verb player menu, ranked in parallel by a local decision model (see `AI` below)
- **Mid-life shop** — buy temporary adaptations (speed, stamina, senses)
- **Zero Godot dependencies** — just Godot 4.7 (GL Compatibility); the optional JEV sidecar runs outside the engine

## How to Play

1. (Optional, for AI zorros) Start the NanoJev sidecar and note its URL — default `http://192.168.100.80:8766` (see `scripts/karma_jev.gd` → `JEV_URL`)
2. Open `project.godot` in Godot 4 and press **F5** (or run `scenes/main.tscn`)
3. You are born as a random species — explore

Without the sidecar the game still plays: zorros fall back to the deterministic mocked brain and keep steering, hunting, and eating.

### Controls

| Key | Action |
|-----|--------|
| WASD / Arrows | Move |
| E | Eat / Hunt |
| Q | Shout (attracts attention) |
| H | Hide |
| V | Sense (tremor/track) |
| C | Carry / Bury (squirrel) |
| B | Open shop |
| 1-5 | Species verbs |
| R | Reincarnate (at judgment) |

## AI (NanoJev zorros)

Each AI zorro splits its brain in two: **micro** steering every physics tick
(move, contact kills, drink, flee — never waits) and **macro** intent
(hunt, cede, cache, dendig, strike, …) ranked by the sidecar. Godot builds the
legal candidate menu per zorro and sends one batched `Choice` request per
window; the model only ranks, never invents moves. Cadence is a staggered 1s
timer plus event re-asks (threat, hunger, fresh carrion) with 3s data-LOD far
from the camera.

Every macro decision is appended as JSONL to
`%APPDATA%\Godot\app_userdata\karmagame-godot\logs\jev_zorro.log`
(one line per decision: menu, choice, probabilities, outcome).

## Tests

gdUnit4 suite in `tests/` (incl. `test_karma_jev.gd` for the JEV bridge —
mocked answers only, no live HTTP). Run from the gdUnit4 dock, or headless:

```powershell
$env:GODOT_BIN = "<path-to>\Godot_v4.7.2-stable_win64_console.exe"
& $env:GODOT_BIN --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```

## Structure

```
project.godot
scripts/
  karma_data.gd   — species, diet, tuning, shop tables
  karma_utils.gd  — helpers (scatter, needs, collisions, LOS)
  karma_state.gd  — game state, karma/PA ledger, refuge, shout
  karma_predators.gd — trophic chain + hunter AI
  karma_eat.gd    — eating, hunting, drinking, burrow, sense
  karma_shop.gd   — judgment pools + adaptation catalog
  karma_ai.gd     — per-species agent behavior (zorro: micro/macro split)
  karma_jev.gd    — zorro JEV bridge: menu/state builders, answer applier, batch + log helpers (pure)
  karma_game.gd   — world clock, flora, verbs, tick
  karma_draw.gd   — icon/size/legend lookups (pure)
  karma_hud.gd    — HUD row builders (pure)
  main.gd         — Main node: input, tick, render, HUD, JEV HTTP client + log flush
scenes/main.tscn
tests/            — gdUnit4 parity suite (incl. test_karma_jev.gd)
openspec/         — behavior specs + change archive (see `ai-jev-zorro`)
```

Behavioral numbers live in `KarmaData.TUNING` — do not rebalance outside a spec change.

## License

Private
