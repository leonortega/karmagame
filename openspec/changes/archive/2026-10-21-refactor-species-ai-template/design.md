## Context

Eight species AI scripts (`scripts/karma_ai_<species>.gd`) each implemented a `step_jev` function with the same ordered skeleton: update needs, run the base AI tick, tick the JEV intent, evaluate interrupt gates, apply steering, fall back to a live wander intent, and finally fall back to the mock macro. The copies had drifted: four species shared a byte-identical gate block, two shared a generic hunt/chase steering block, and the rest kept genuinely different gates or steering rules. The draw/HUD path also recomputed the agent HP fraction inline in two places.

Constraints: the simulation is pure static functions over `Dictionary` state with no autoloads, `KarmaData.TUNING` holds every number, and the JEV wire format and save shape are frozen. Behavior must stay identical, so the consolidation has to be a pure structural change that the existing suite can certify.

See proposal.md for the motivation.

## Goals / Non-Goals

**Goals:**

- Write the shared JEV step order exactly once and make each species' deviation explicit.
- Keep species-specific gates and steering in the species file, where they are read next to that species' behavior.
- Collapse the duplicated agent HP-fraction rule into one draw-layer helper.
- Remove the remaining per-tick list allocations on the agent, hide, distant and respawn paths.
- Leave the observable decision order, tuning, protocol and save shape untouched.

**Non-Goals:**

- No tuning rebalance, no new AI behavior, no new species.
- No change to the JEV protocol, mock macro selection, save shape or HUD layout.
- No unification of the species ladder steps (`step_ladder`): the shared prefix is two lines and the tails plus side effects differ per species, so a template there would cost more than it saves.
- No restructuring of `KarmaJev` bridge plumbing (covered by the earlier `dedupe-jev-bridge-plumbing` change).

## Decisions

1. **Template function with injected callables** (`KarmaAI.jev_step(state, a, dt, gates, steer, mock)`) instead of an abstract base class. GDScript has no abstract classes or virtual methods; a base class would need per-species overrides anyway, which is the same surface area with more ceremony. The alternative of one large string-dispatch function was rejected because it loses the typed signature of each hook and reintroduces a per-tick string compare on the hot path.

2. **The template lives in `KarmaAI`, not `KarmaJev`.** `KarmaAI` owns the per-tick AI order; `KarmaJev` owns the wire format and the decision bridge. Putting the step order in the protocol layer would invert that dependency.

3. **Gates stay per-species where they diverge.** `jev_gates_common` covers only raton, topo, sapo and oruga, whose gate blocks were byte-identical (hide tick, hunted-and-hiding, thirst, urgent seek). Ardilla keeps its extra `carriedNut` rule and halcon keeps its strike/thirst/grounded/urgent ordering; zorro and lobo keep their own. Merging the divergent ones would have hidden real behavior differences behind a boolean flag.

4. **The shared gate helper sits on `KarmaAI`, so callers pass `Callable(KarmaAI, "jev_gates_common")`.** A per-species wrapper method that only forwards to it would have re-created the duplication this change removes.

5. **Steering is shared only where the rules match.** `KarmaJev.steer_intent(state, a, dt, hunt_kinds, chase_key, flee_moves)` captures the generic intent handling (eat / seek carrion / hunt-chase / flee) used by zorro and lobo, which differ only in their hunt kinds, chase multiplier and flee flag. Raton, topo, sapo, oruga, ardilla and halcon steer differently (carry rules, strike rules, pest-specific targets) and keep local implementations.

6. **`KarmaDraw.hp_frac_for_agent(a)` owns the agent HP fraction.** `KarmaDraw.hp_frac(hp, max_hp)` stays as the pure numeric helper for callers that already know the maximum; only the agent-specific combination moved.

7. **Squared distances wherever a distance is only compared.** `sqrt` is kept only where the magnitude is needed (movement normalization, collision response). This is the same rule the earlier `optimize-hot-paths` change applied to the world queries.

## Risks / Trade-offs

- **Ordering drift in the template.** A species that previously interleaved gates and steering differently could change behavior when moved onto the shared order. Halcon is the known case (strike, thirst, grounded, urgent). Mitigation: the full suite plus the species pins run after every adoption step, and the halcon gate ordering is asserted by its existing tests.
- **Injected callables hide the call graph.** A reader can no longer see the gate/steer/mock wiring by following one function body. Mitigation: the callables are named at the call site in each species file and the template signature fixes their roles.
- **The shared gate helper invites future edits to a global rule.** Mitigation: species-specific gates remain the extension point, and the shared helper is documented as the identical-four case only.
- **Structural change without a spec delta.** Mitigation: `skip_specs: true` is set in `.openspec.yaml`; the change is certified by the 612-case suite and the headless scene smoke instead of by new behavioral requirements.
