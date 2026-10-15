## Why

Eleven of forty species verbs grant only self karma/PA/vision (or set a flag nobody reads) with no write to the shared world or another animal, and fourteen slots hard-reject IA agents. This breaks the core fiction: every animal action should leave a trace the forest can see, and IA and player must run the same table.

## What Changes

- Rework the 11 self-only verbs so each writes the world or another body, keeping the species-true fantasy (no fire-starting sapos):
  - sapo `chorus` summons nearby sapos toward the caller's water instead of solo karma.
  - raton/ardilla `groom` cleans the mate (removes mimic/toxin effect + small heal) instead of solo karma.
  - raton `scout` drops a scent-post entity sharing reveal with mates in radius instead of solo `revealT`.
  - halcon `thermal` projects a circling-shadow mark that scatters prey and is visible to others instead of solo `thermalT`.
  - ardilla `bark` consumes oak stock and sets a stripped state with regrow timer instead of free PA/karma.
  - topo `worm` unearths a real insect entity from refuge soil on a refuge charge instead of healing from air.
  - topo `tunneline` links two dug burrows (or raises capacity) instead of setting unread `firm`.
  - oruga `silk` leaves a sticky thread entity that slows the hunter instead of self-teleport only.
  - sapo `burrowin` leaves a wallow pit entity (sip + slows ground hunters) instead of vanishing with no entity.
  - oruga `bristle` stings immediately (hunter `restT` now) instead of an armed-only flag.
  - lobo `escort` shepherds the mate toward cover and deters nearby hunters instead of self-walk plus later karma.
- Remove all `if a != null: return false` player-only guards; every verb branches on actor instead of refusing IA.
- Every reworked verb SHALL be JEV-handleable: offerable in the species candidate menu from legal moves only, rankable by the sidecar, and applicable through the same functions as the player with stale-answer fallback to continued steering or wander.
- Merge or differentiate the E-duplicates (`prudent`/`pounce`/`dive` equal `E`) so no slot is a bare alias.
- **BREAKING**: karma/PA-only casts no longer succeed alone; each reworked verb requires its world/other precondition (choir in range, mate in range, oak with stock, refuge with charge, hunter in range) and fails without costs/cooldown otherwise, same as `pest`/toxin rules today.

## Capabilities

### New Capabilities

- None — all work fits inside the existing verb contract.

### Modified Capabilities

- `karma-verbs`: every verb must write the shared world or another animal (entity add/remove/mark, HP/hambre move, displacement, restT/saved/rallyT/ceded, shared reveal); karma/PA/vision alone no longer satisfy a verb; all verbs universal for IA and player through the same core; every verb handleable by the JEV AI (legal-only menus, same apply path, wander fallback, fail-without-burn on stale/illegal picks).

## Impact

- Affected code: `scripts/karma_data.gd` (VERB_DEFS costs/cooldowns/descs), `scripts/karma_game.gd` (`call_verb` + 11 `_verb_*` bodies), `scripts/karma_eat.gd` (oak/refuge stock helpers if needed), per-species JEV menu builders plus the Main-owned single-flight batch path (offer reworked verbs, state need-tokens, fair scheduling unchanged).
- Tests: gdUnit4 verb suites per species (player + agent parity, fail-without-precondition, no cooldown/cost burn on fail) plus JEV menu/apply suites (legal-only menus, ranked apply through player functions, stale-answer wander fallback, affordability recheck at apply).
- No new autoloads, no engine changes; numbers stay in `KarmaData.TUNING` per repo rule.
