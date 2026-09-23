# Karma MVP

A vanilla JS browser game — a 2D ecosystem survival experience where your actions shape your next life.

Play as creatures in a living world: forage, hunt, hide, and survive. Your karma (good or bad deeds) determines what you become when you reincarnate.

## Features

- **8 species** across 3 tiers — from caterpillar to wolf
- **Karma system** — eat wisely, defend prey, avoid waste; reap rewards or suffer consequences
- **Reincarnation** — judgment after death shapes your next form
- **Predator/prey AI** — dynamic ecosystem with hunting, fleeing, and social behavior
- **Mid-life shop** — buy temporary adaptations (speed, stamina, senses)
- **Zero dependencies** — pure HTML/CSS/JS, runs in any browser

## How to Play

1. Run `.\serve.bat` to start the local server on `:8000`
2. Open `http://localhost:8000`
3. Choose your first life and explore

### Controls

| Key | Action |
|-----|--------|
| WASD / Arrows | Move |
| E | Eat / Hunt |
| Q | Shout (attracts attention) |
| H | Hide |
| V | Sense (tremor/track) |
| C | Carry / Bury |
| B | Open shop |
| R | Reincarnate (at judgment) |

## Tests

```bash
node --test test/utils.test.js test/world.test.js test/state.test.js test/eat.test.js test/predators.test.js test/shop.test.js test/game.test.js
```

## Structure

```
src/
  css/style.css
  script/
    data.js       — species, diet, tuning, shop tables
    utils.js      — helpers
    state.js      — game state
    predators.js  — AI predators
    eat.js        — eating mechanics
    shop.js       — shop system
    hud.js        — HUD rendering
    game.js       — main loop
    draw.js       — canvas drawing
test/             — Node test suite
openspec/         — Spec-driven change tracking
```

## License

Private
