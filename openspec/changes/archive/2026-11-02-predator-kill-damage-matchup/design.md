## Context

See proposal.md — Why. The change touches the kill-verb damage base in `scripts/karma_eat.gd`,
`scripts/karma_game.gd`, and `scripts/karma_ai.gd`. No new autoloads or engine changes; numbers
stay in `KarmaData` and the derived base reuses `PRED.damage` and `SPECIES.size`.

## Goals / Non-Goals

**Goals:**
- Make kill-verb lethality depend on the size/strength matchup instead of always consuming the
  victim's whole HP bar.
- Keep one code path for player and AI (parity), reusing the existing `resolve_strike` and
  age scaling.
- Preserve the escape window, invulnerability, and cooldown mechanics unchanged.

**Non-Goals:**
- No changes to contact bites (`strike_contact`), which already use absolute `PRED` damage.
- No new tuning constants: the base is derived from existing `PRED.damage` and `SPECIES.size`.
- No changes to AI decision logic beyond the damage value it already receives.

## Decisions

### D1: Kill-verb base is `PRED[attacker].damage × (attacker_size / victim_size)`
- **Choice**: Replace `base = eff_max_hp_for(victim)` with
  `base = PRED[attacker].damage * (SPECIES[attacker].size / SPECIES[victim].size)` in every
  kill path, then keep `scaled_damage(base, attacker, victim)`.
- **Rationale**: `PRED.damage` already encodes species strength; the size ratio encodes the
  natural advantage of a larger predator over smaller prey. Together they make a size-3
  predator lethal to size-1 prey in one hit while leaving comparable or larger victims alive.
  Age scaling (`attacker_force`, `victim_frailty`) is untouched, so old predators still fail
  on prime prey.
- **Alternatives considered**: (a) A fixed percentage of victim HP (0.28/0.32/0.30) — simpler
  but makes every victim require ~3–4 hits, removing legitimate one-shots and weakening the
  ecosystem. (b) Keeping `victim_maxHp` and only gating by age — the current behavior, which
  is the bug being fixed. Rejected in favor of the matchup-derived base.

### D2: Centralize the base in a helper
- **Choice**: Add `KarmaData.kill_damage_base(attacker, victim) -> float` returning
  `PRED[attacker].damage * (SPECIES[attacker].size / SPECIES[victim].size)` (with fallback
  rows), and have callers pass its result as `base` to `resolve_strike`/`pounce_kill`/
  `dive_kill`.
- **Rationale**: Keeps the formula in one place, makes tests reference the same expression,
  and avoids duplicating the size-ratio logic across `karma_eat`, `karma_game`, and
  `karma_ai`.

### D3: Contact bites stay absolute
- **Choice**: `strike_contact` keeps `scaled_damage(t["damage"], p, victim)` with the
  absolute `PRED` damage. Do not apply the size ratio there.
- **Rationale**: Contact bites are a repel/chip verb, not a kill verb, and their current
  tuning is intentional. Changing them would expand scope and re-tune player-facing damage
  unrelated to this change.

### D4: Player and AI share the helper
- **Choice**: `ai_hunt_eat`, `_verb_pounce`, `_verb_dive`, `_verb_cull`, and
  `pounce_kill`/`dive_kill` all call `kill_damage_base`. No AI-specific branch.
- **Rationale**: Parity is the stated goal; the only difference between player and AI today
  is the base value, which this removes.

## Risks / Trade-offs

- [Risk] Some matchups that were previously guaranteed kills now require 2–4 hits; predators
  may spend more cooldowns and carrion could become scarcer. [Mitigation] The size ratio
  preserves one-shots for genuine size advantages (e.g. zorro/halcón vs oruga/sapo), and
  the invulnerability window already gives prey an escape chance only when the hit is
  non-lethal.
- [Risk] Senescence tests assert exact damage values from the old `victim_maxHp` base and
  will need updating to `kill_damage_base`. [Mitigation] Tasks list them; apply phase
  updates assertions to the new expression rather than weakening them.
- [Risk] `SPECIES.size` is an integer; the ratio may produce fractional bases. [Mitigation]
  `scaled_damage` already returns a float and `resolve_strike` compares against `victim.hp`;
  no rounding is applied before the lethality check, matching existing behavior.

## Migration Plan

1. Add `KarmaData.kill_damage_base(attacker, victim)`.
2. Switch the five kill paths to pass it as `base`.
3. Update affected gdUnit4 assertions to the new base.
4. Sync delta specs into main specs on archive.

Rollback: revert the helper and the five call sites; delta specs are removed on archive
revert.

## Open Questions

- None. All decisions resolved above.
