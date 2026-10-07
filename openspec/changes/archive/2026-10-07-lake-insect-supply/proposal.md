## Why

Live `jev-sapo.log` telemetry shows AI sapos hungry for 76 straight seconds with `insect_near=false` in every snapshot: 6 insects max on a 3200×2400 map respawning one per 20s cannot feed sapo + topo insectivores, so sapo JEV menus never offer food and rank threat verbs by default. The supply — not the menu — is the bottleneck.

## What Changes

- Raise the global insect cap `insectMax` 6 → 10 and quicken the respawn cadence `insectRespawn` 20s → 12s. Lake-shore bias, shore ring, wander, payoffs, and all other tuning stay exactly as today.
- Expected effect: ~3× encounter odds per perception check, concentrated by the unchanged 0.6 lake bias where sapos already go to drink; no map-gen, diet, or payoff changes.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `vitals-water`: the "Lagos anchor insect density" requirement keeps its bias/shore/wander/payoff behavior with a higher cap and quicker cadence.

## Impact

- Affected code: `KarmaData.TUNING` two numbers only (`insectMax`, `insectRespawn`).
- Tests: world-sim tests for cap saturation and cadence (no test pins the old numbers today).
- No species, verb, JEV, HUD, or payoff changes; topo benefits identically through the same shared supply (intended, same diet).
