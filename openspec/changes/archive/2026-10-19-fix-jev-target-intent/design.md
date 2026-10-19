## Context

See proposal.md. Both `KarmaJevZorro` and `KarmaJevHalcon` already accept a `target` parameter in `_set_intent`, and both micro-steering functions read `intent["target"]` for pounce/hunt/dive. The helper currently builds `jev_intent` without that key, so the apply path silently drops it. Existing tests set `jev_intent` directly and therefore cover steering, but not the bridge from a ranked menu to steering.

## Goals / Non-Goals

**Goals:**

- Make the apply path preserve the target identity that the candidate menu already carries.
- Prove the full path with gdUnit4 tests: menu -> ranked answer -> applied intent -> contact kill.
- Keep the change minimal and shared in shape between zorro and halcon.

**Non-Goals:**

- No candidate-menu, ranking, cadence, logging, tuning, or steering changes.
- No new abstraction over the two bridges; the dedupe change owns shared plumbing.
- No runtime profiling or balance work.

## Decisions

- **Fix at the `_set_intent` boundary.** Add the target when one is supplied, instead of changing every call site or the steering branches. The helper is the single conversion point from a ranked candidate to `jev_intent`, and both species use it consistently. Alternative: pass target through a separate `jev_target` field; rejected because steering already reads `target` and would still need touching.
- **Include the key only when non-null.** Wander and immediate verbs have no target; keeping their intent shape unchanged avoids needless state growth and matches existing tests. Alternative: always write `"target": null`; rejected because it changes serialized/logged intent shape for no behavior gain.
- **Use contact-kill tests rather than only shape assertions.** A test that asserts `jev_intent.target == prey` is necessary but not sufficient; the regression test also runs one physics tick and asserts the prey is consumed and carrion spawned. This proves the target survives to the code that needs it.

## Risks / Trade-offs

- [Risk] A test only checks the intent dictionary and passes while steering still clears it -> Mitigation: include the contact-kill assertion in the same test group.
- [Risk] The fix accidentally adds a target to immediate eat/cede intents -> Mitigation: only write the key when the parameter is non-null; leave immediate-verb tests unchanged.
- [Risk] Duplicate logic between zorro and halcon diverges later -> Mitigation: keep the edits identical and let `dedupe-jev-bridge-plumbing` extract the shared helper afterward.

## Migration Plan

No data or save migration. Rollback is the two-line helper change plus the new tests.
