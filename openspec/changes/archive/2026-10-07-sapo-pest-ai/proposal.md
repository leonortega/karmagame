## Why

The sapo `pest` verb (slot 2, "Come plagas") is player-only: `call_verb` returns `false` for any AI agent, while AI sapos still earn the same +3 pest-control karma passively through `ai_grazer_eat` → `eat_insect`. This violates `karma-verbs` req 3 (AI agents SHALL cast their own verbs through the same core) and blocks the future sapo JEV menu, where the ranker can only offer verbs the AI can legally execute.

## What Changes

- `pest` becomes AI-handleable (mirror, no rebalance): for agents it eats the nearest insect within tongue range (`tongueRange` + 40 with `tonguePlus`) through the existing `eat_insect` path (+10 vida, +3 pest karma, same as player and same as ladder eating today).
- Same cooldown and costs as the player (8s, 0 vida / 0 PA) enforced through the existing `cast_verb_for` gate; failure (no insect in range) returns `false` without burning cooldown or paying costs.
- Ladder order for sapo becomes toxin (danger) → pest (food) → burrow-in / chorus (hide / social), after the unchanged survival reflexes (hide, thirst, contact tongue-eat, forage trek).
- No tuning numbers change; no other verb changes (croak, burrowin, toxin, chorus untouched; oruga `prudent` noted as fast-follow, out of scope).

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `karma-verbs`: `pest` SHALL succeed for AI sapo agents via the same verb core with identical cooldown, costs, and karma.

## Impact

- Affected code: `scripts/karma_game.gd` (`call_verb` `pest` branch), `scripts/karma_ai.gd` (`ai_maybe_verb` sapo branch order).
- Tests: gdUnit4 ladder tests for pest success/failure and cooldown behavior (mocked state only, no live HTTP).
- No API, save, HUD, or JEV wire changes; sapo JEV menu offering `pest` is a separate future change built on top of this one.
