## Why

The HUD promises actions that do nothing (R alive, V/Q/C for species that lack them), shows PA/time/edad as bare numbers, renders verbs 1-5 as one wrapping line, and the left-panel other-animals feed only surfaces some species (zorro paths) without identifying who acted. Players misread tier as input ("Ardilla T1 - Q listo") and cannot tell at a glance what they can do, how old they are, or what the rest of the ecosystem just did.

## What Changes

- Right-panel controls become per-species (BASE + species extras) with live cooldown counters in the same `(Ns)` style as the verb bar; R is removed from the in-life panel (reincarnation stays on the Judgment screen only).
- Species/tier label is split from cooldown state so tier no longer reads as an input.
- PA gets icon + emphasis (color/size) and remains a plain number otherwise; time gets a clear label; edad keeps counting seconds internally but displays per-species animal-years (display-only, no gameplay effect).
- Verb bar 1-5 renders as a vertical list (one item per line) showing name + cooldown and keeping existing cost-dim behavior.
- Left-panel `otherLog` surfaces karma events for ALL agent species with an emoji-first prefix (`emoji + existing text`); roster block (`otherPanel`) is unchanged; player `#log` is unchanged; only karma entries are logged (no eat/drink firehose).

## Capabilities

### New Capabilities

- `hud-clarity`: per-species controls with cooldowns, PA emphasis, animal-years edad display, vertical verb list. Covers the new presentation contract in one place.

### Modified Capabilities

- `ecosystem-2d`: controls hint is no longer a fixed list with one entry per key; it is per-species with cooldown state. HUD section gains PA emphasis, labeled time, split species/tier vs cooldowns, vertical verb list.
- `vitals-water`: edad display gains a per-species seconds-to-years mapping (display-only; `edad` still increases monotonically with no gameplay effect).
- `karma-verbs`: verb bar presentation changes from inline spans to vertical list (behavior, costs, cooldowns unchanged).
- `ai-karma`: AI karma entries in the left-panel feed cover all agent species (no silent empty-string drops) and carry an emoji-first prefix identifying the actor.

## Impact

- Touched: `src/index.html` (controls container, HUD labels, verbBar markup), `src/css/style.css` (verb list, PA emphasis, controls dim), `src/script/hud.js` (render controls/verbs/PA/time/edad, otherLog prefix), `src/script/data.js` (controls table, SEC_PER_YEAR table), `src/script/state.js` (addKarma emoji prefix + non-empty AI messages), `src/script/ai.js` (AI shout/hunt messages), `test/` harness + suite (update/extend HUD and feed tests).
- No new deps, no engine change, no balance change (edad stays display-only, `effAgeMult()` stays 1.0).
