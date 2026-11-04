## Why

Predator kill verbs (Zorro pounce, Halcón dive, Lobo cull, and AI hunting) currently deal
`victim_maxHp × attacker_force × victim_frailty`. For a prime attacker against a prime
victim that is the victim's entire health bar, so every such kill is a one-shot and the
victim never gets the escape window the senescence spec promises. Player-facing contact
bites, by contrast, chip with the `PRED` damage table, so the two paths disagree about
how lethal a predator is.

## What Changes

- **Kill-verb base is recalculated from the matchup**, not from the victim's whole HP:
  `base = PRED[attacker].damage × (attacker_size / victim_size)`. Damage then keeps the
  existing `× attacker_force(age) × victim_frailty(age)` scaling, so age still cuts both
  ways.
- **Same formula for player and AI**: `ai_hunt_eat`, `_verb_pounce`, `_verb_dive`,
  `_verb_cull`, and `pounce_kill`/`dive_kill` all switch to the new base. No separate
  AI lethality.
- **Some victims still die in one hit**: a size/strength advantage (e.g. a size-3
  predator on a size-1 prey) can push damage to or above the victim's HP; comparable or
  larger victims usually survive the first hit and get a decision-gated escape window.
- **Contact bites (`strike_contact`) are unchanged**: they keep the absolute `PRED`
  damage they already use.
- **No new fields beyond reusing existing `PRED.damage` and `SPECIES.size`**: the base is
  derived, not stored.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `karma-core`: kill-verb damage base changes from `victim_maxHp` to
  `PRED[attacker].damage × (attacker_size / victim_size)`; lethality becomes
  matchup-dependent.
- `animal-senescence`: "Two-sided force damage" base for kill paths is redefined as
  above; age scaling and escape-window rules unchanged.
- `ai-species-behavior`: carnivore hunt lethality is matchup-dependent (one-shot only on a
  real size/strength advantage), not guaranteed for prime predators.
- (none additional — `karma-verbs` already requires failed kill verbs to deal partial
  age-scaled damage; only the documented base for those verbs changes, captured in
  `karma-core`.)

## Impact

- Affected code: `scripts/karma_eat.gd` (`pounce_kill`, `dive_kill`, `resolve_strike`
  callers), `scripts/karma_game.gd` (`_verb_pounce`, `_verb_dive`, `_verb_cull`,
  `ai_hunt_eat` via `karma_ai.gd`), `scripts/karma_ai.gd` (`ai_hunt_eat`).
- Affected specs: `openspec/specs/karma-core`, `animal-senescence`,
  `ai-species-behavior`, `karma-verbs`.
- Affected tests: senescence kill-verb tests and any assertion that assumes a prime
  predator one-shots a prime victim; updated to the matchup-derived base.
- No new autoloads, no engine changes; numbers stay in `KarmaData`.
