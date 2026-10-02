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
- **Mid-life shop** — buy temporary adaptations (speed, stamina, senses)
- **Zero dependencies** — just Godot 4.7 (GL Compatibility)

## How to Play

1. Open `project.godot` in Godot 4 and press **F5** (or run `scenes/main.tscn`)
2. You are born as a random species — explore

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

## Tests

gdUnit4 (v6) suite in `tests/` — open the project in Godot and run the
gdUnit4 dock, or from headless:

```bash
godot --headless --path . --test
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
  karma_ai.gd     — per-species agent behavior
  karma_game.gd   — world clock, flora, verbs, tick
  karma_draw.gd   — icon/size/legend lookups (pure)
  karma_hud.gd    — HUD row builders (pure)
  main.gd         — Main node: input, tick, render, HUD
scenes/main.tscn
tests/            — gdUnit4 parity suite
openspec/         — behavior specs + change archive
```

Behavioral numbers live in `KarmaData.TUNING` — do not rebalance outside a spec change.

## License

Private
