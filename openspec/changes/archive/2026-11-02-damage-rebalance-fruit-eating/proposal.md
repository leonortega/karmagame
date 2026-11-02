## Why

Fruit patches currently take several bites to deplete, and predator contact damage uses a single fixed base per species that is not tuned to nature-like outcomes (e.g. an eagle should take roughly a third of a toad's life in one strike). Players and AI also face inconsistent feedback: partial bites leave plants alive with no karma cost, so the "last fruit" selfish-act penalty only triggers on the final nibble.

## What Changes

- **Fruit eating becomes one bite**: for fruit-eating species (ratón, ardilla, topo, and any non-leaf fruit patch), a single `eat_patch` call consumes the entire remaining patch, kills the plant, applies the last-fruit karma penalty (-15, player only), and grants nutrition summed across all consumed fruits (sustainable fruits at food HP/PA plus the final-fruit bonus of 20 HP). Leaves (oruga) and mimic/toxic-shroom logic are unchanged.
- **Seed drops preserved**: the number of seed-sprout rolls per patch matches the number of fruits consumed, so forest renewal rates are unchanged.
- **Predator contact damage retuned**: `KarmaData.PRED` damage bases adjusted to nature-like values (zorro 28, lobo 38, halcón 30) for prime-vs-prime contact bites; age scaling via `scaled_damage` is unchanged. The percentage-based `damagePct` model is considered but deferred (see design.md).
- **AI parity**: AI grazers consume the whole patch in one bite through the same `eat_patch` path; player-parity scenarios updated.
- **Tests**: gdUnit4 suites that assume multi-bite consumption are updated to the one-bite expectation.

## Capabilities

### New Capabilities

- None — all work fits inside existing capabilities.

### Modified Capabilities

- `karma-core`: Sustainable eating vs last-fruit selfish act — a single bite now consumes the whole patch and triggers the last-fruit penalty.
- `flora-lifecycle`: Last-fruit message promises recovery — consuming a fruit patch (one bite) now always kills the plant and logs the recovery promise.
- `ai-jev-raton`: Player parity of effects scenario reflects full-patch consumption.
- `ai-jev-ardilla`: Player parity of effects scenario reflects full-patch consumption.

## Impact

- Affected code: `scripts/karma_eat.gd` (`eat_patch`), `scripts/karma_data.gd` (`PRED` damage values), tests `test_karma_systems.gd`, `test_karma_flora_pacing.gd`, `test_karma_jev_raton.gd`, `test_karma_jev_ardilla.gd`, and the four modified delta specs.
- No new autoloads, no engine changes; numbers stay in `KarmaData` per repo rule.
- Behavior change is externally visible (more HP per bite, -15 karma per patch, fewer bites), so tests and specs are updated rather than kept green as-is.