## 1. Core damage helper

- [x] 1.1 Add `KarmaData.kill_damage_base(attacker, victim) -> float` returning `PRED[attacker].damage * (SPECIES[attacker].size / SPECIES[victim].size)` with fallback rows.
- [x] 1.2 Parse-check `scripts/karma_data.gd`.

## 2. Kill-verb call sites

- [x] 2.1 Update `KarmaAI.ai_hunt_eat` to pass `KarmaData.kill_damage_base(a, prey)` to `resolve_strike`.
- [x] 2.2 Update `KarmaGame._verb_pounce` to pass `KarmaData.kill_damage_base(a, prey)`.
- [x] 2.3 Update `KarmaGame._verb_dive` to pass `KarmaData.kill_damage_base(a, prey)`.
- [x] 2.4 Update `KarmaGame._verb_cull` AI branch to pass `KarmaData.kill_damage_base(a, sick)`.
- [x] 2.5 Update `KarmaEat.pounce_kill` and `KarmaEat.dive_kill` to use `kill_damage_base(attacker, victim)` for their `base`.
- [x] 2.6 Parse-check `scripts/karma_eat.gd`, `scripts/karma_game.gd`, and `scripts/karma_ai.gd`.

## 3. Tests

- [x] 3.1 Update senescence kill-verb assertions to use `KarmaData.kill_damage_base(...)` instead of `eff_max_hp_for(victim)`.
- [x] 3.2 Update `test_lethal_strike_on_player` expectations if the player-facing bite path is affected (contact bites unchanged; verify).
- [x] 3.3 Run gdUnit4 suite and confirm full test count with no silent suite aborts.

## 4. Specs and docs

- [x] 4.1 Sync delta specs into main specs on archive.
- [x] 4.2 Update README aging/death wording if it references the old base. (no change needed)
