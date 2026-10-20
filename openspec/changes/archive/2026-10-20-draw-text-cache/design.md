## Context

See proposal.md. `main.gd._draw()` runs every frame and calls `_pill` for every visible label; `_pill` shapes text with `font.get_string_size` and draws it with `draw_string`. Agent draws call `KarmaDraw.species_medal`, which parses a color string from `KarmaData.SPECIES` on every agent. There is no canvas legend: it was removed by `2026-10-19-remove-dead-jev-api`, and the ecosystem-2d spec forbids drawing one, so legend rendering stays out of scope. Rendering must stay visually identical.

## Goals / Non-Goals

**Goals:**

- Shape each distinct label once per changed string/size instead of once per frame.
- Parse each species color once instead of once per agent draw.

**Non-Goals:**

- No font, size, color, position, or layout change.
- No change to world state, camera math, or label visibility.
- No new asset or theme dependency.

## Decisions

- **Cache shaped labels keyed by text plus size.** Keep a bounded map from `text|size` to the shaped text object and its measured size, and evict entries that are not used for a full draw pass (or cap by count) so long runs cannot grow without bound. Alternative: cache all strings forever; rejected because label text includes counts that change.
- **Precompute species colors once.** Build the species color map from `KarmaData.SPECIES` at first use and read from the map afterward, keeping the same fallback color. Alternative: convert the data table to `Color` values; rejected because `KarmaData` is gameplay data and should stay display-agnostic.
- **No cache when the label set is small.** The cache only activates above a threshold so tiny scenes keep the current straight-line path. Alternative: always cache; rejected because a map with three labels would pay map overhead for nothing.

## Risks / Trade-offs

- [Risk] A cache keyed on text keeps stale width after a font or DPI change -> Mitigation: include size in the key and clear the cache when the fallback font changes.
- [Risk] Unbounded cache growth from count labels -> Mitigation: cap the map and clear on overflow; test a run with changing counts.

## Migration Plan

Refactor only; rollback is the draw helpers. No data migration.
