## Context

See proposal.md (Why). Current state: `call_verb` `pest` returns `KarmaEat.eat_as_sapo(state)` for the player and `false` for any agent (`scripts/karma_game.gd`); AI sapos eat insects (with the same +3 karma via `eat_insect`) only through the survival reflexes `ai_grazer_eat(tongueRange)` and `ai_forage` in `_ai_sapo` (`scripts/karma_ai.gd`). `cast_verb_for` already gates cooldown/costs and only burns them when `call_verb` returns true, so a `false` return is a free no-op fallthrough. No tuning numbers change.

## Goals / Non-Goals

**Goals:**
- One door for both: AI `pest` resolves through the same `eat_insect` payoff the player and the ladder use.
- Ladder stays survival-first: hide, thirst, contact tongue-eat, and forage trek keep running before any verb attempt.
- Future JEV-ready: once this lands, `karma_jev_sapo` can offer `pest` as a legal instant-cast candidate with no further verb changes.

**Non-Goals:**
- No economy change (no sweep, no bonus, no range change beyond existing `tonguePlus`).
- No other verb touched (croak, burrowin, toxin, chorus; oruga `prudent` is a noted fast-follow, explicitly out of scope).
- No JEV wiring in this change (no menu, state, batch, or `main.gd` poll edits).

## Decisions

- **Mirror, don't invent (pest = nearest insect in tongue range + `eat_insect`).** Alternative (pest as multi-insect sweep or bonus karma) rejected: it rebalances the karma economy and contradicts the preserved `pest +3` value in `karma-verbs`.
- **Range read from the same source as the ladder.** Both the verb and `_ai_sapo` step 7 use `tongueRange (+40 tonguePlus)`; the ranker and the reflex can never disagree about reach. Alternative (hardcode 90px in the verb) rejected: it would silently break `tonguePlus` parity.
- **Ladder order toxin → pest → burrow/chorus.** Toxin outranks food (60px hunter kills faster than hunger); pest outranks hide/social (food before later, zero cost so it can never kill; matches `ai-survival` hunger-priority). Alternative (pest first) rejected: defense must win at 60px.
- **Failure burns nothing.** Rely on the existing `cast_verb_for` guard (`if not call_verb: return false` before costs/CD) rather than adding a new pre-check. Matches toxin-with-no-hunter and chorus-with-no-choir behavior.

## Risks / Trade-offs

- [Risk] Double-eat perception (contact-eat step 7 and pest both eat insects) → Mitigation: ordering guarantees only one acts per tick (reflexes return DONE before verbs run); per-tick payoff is identical whichever door fires.
- [Risk] Moving-target staleness (insects wander) between legality check and eat → Mitigation: `eat_insect` on a stale/missing target returns false, which the verb propagates as failure with no cooldown burn.
- [Risk] Scope creep into `prudent`/JEV → Mitigation: proposal non-goals list them; tasks carry no JEV or `main.gd` items.
