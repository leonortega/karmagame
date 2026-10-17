## Why

The Godot port kept the JS simulation rules but lost the JS moments: birth draws, death judgments, and shop buys apply instantly and silently while the world keeps running. Players get consequences with no ceremony and can die while shopping. A shared modal layer with birth/judgment roulettes, a real shop popup, and pause restores that UX.

## What Changes

- Add one centered modal overlay (dim + panel) that shows exactly one of: shop, birth roulette, judgment roulette, pause.
- Shop becomes a true popup: species catalog (3 items, costs, owned/affordable states), `1-3` buys, `B`/`Esc` closes.
- Birth intro on every fresh run: `KARMA` title + `los dioses han elegido que nazcas como:` + 8-emoji roulette cycling until the pre-drawn azar form settles + dismiss to start.
- Judgment on death: `los dioses han elegido que reencarnes como:` + karma-weighted roulette over the eligible pool only, plus final Karma, time, floor reason, settled species/tier, last up-to-4 life events, Reincarnar button + `R`. Involution (`[oruga]`) shows instantly with no fake cycle.
- Pause popup: `P`/`Esc` toggles, shows resume + controls recap; safe to open mid-life.
- Modal-open freezes the sim (hunger, predators, agents, JEV, timers) but keeps rendering; world verbs and movement keys are swallowed while any modal is open. Number-key focus: `1-5` verbs in play, `1-3` buys in shop, nothing elsewhere.

## Capabilities

### New Capabilities

- `game-modals`: shared modal shell + birth intro roulette + pause popup + freeze/focus contract binding shop/judgment presentation together.

### Modified Capabilities

- `reincarnation`: harden judgment modal contract (freeze, focus, single-entry involution, confirm-only rebirth, no picks/reroll).
- `karma-verbs`: clarify number-key focus across modals (verbs `1-5` in play, shop buys `1-3` when shop open, all verbs swallowed under any modal).
- `hud-clarity`: move shop from right-panel text rows to centered modal; controls/verb/shop rendering reflects modal state.

## Impact

- `scripts/main.gd`: HUD `CanvasLayer` center modal, `_unhandled_input` focus router, `_physics_process` freeze gate, `_refresh_hud`/`_draw` dim.
- `scripts/karma_shop.gd`, `karma_state.gd`: draw-first RNG (`draw_start_form`/`judge`) unchanged; `shopOpen`/`paused`/`intro` flags drive modal selection.
- `scripts/karma_hud.gd`, `karma_draw.gd`: modal row builders reuse `SPECIES_ICON`, `SHOP_BY_SPECIES`, `VERB_DEFS`.
- `tests/`: gdUnit4 coverage for pool selection, freeze, key focus, buy rules, involution edge, dismiss/confirm paths.
