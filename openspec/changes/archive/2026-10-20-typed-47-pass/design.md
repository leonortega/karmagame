## Context

See proposal.md. The simulation is pure static functions over a `Dictionary` state. Many locals, loop variables, arrays, and dictionary values are untyped, so shape errors surface only at runtime. `main.gd` also assembles movement axes manually and reads camera/facing from `{x, y}` dictionaries. The game runs on Godot 4.7, which supports typed arrays, typed dictionaries, and `static var`.

## Goals / Non-Goals

**Goals:**

- Catch state-shape mistakes at parse time in the slices that are safe to type.
- Make the pure data boundaries self-describing without changing any value.
- Keep each slice file-local so a bad annotation is easy to bisect.

**Non-Goals:**

- No change to state keys, dictionary shapes visible to other files, or save format.
- No performance rewrite (that is `hot-path-agent-queries`).
- No new class hierarchy, `Resource` migration, or autoload.

## Decisions

- **Type locally, not globally, first.** Add types to function parameters, returns, and locals inside one file at a time. Alternative: type the whole state `Dictionary` up front; rejected because heterogeneous agent dictionaries would need a full data-model change, not a typing pass.
- **Type arrays only when the element type is uniform.** Use `Array[Dictionary]` for agent/carrion lists and leave genuinely mixed arrays untyped. Alternative: force a type everywhere; rejected because it would produce unsafe casts and false confidence.
- **`Vector2` for position-only values.** Convert camera and facing reads to `Vector2` where the value is only a point/direction, keeping the state key and dictionary shape unchanged at the boundary. Alternative: convert every `{x, y}` in state; rejected as a behavior-risk refactor outside a typing pass.
- **`Input.get_vector` for movement axes.** Replace manual axis assembly with the engine helper while preserving the same deadzone and normalization. Alternative: keep manual assembly; rejected because the helper is the documented 4.x path and removes repeated clamp/normalize code.

## Risks / Trade-offs

- [Risk] A too-narrow type rejects valid heterogeneous state -> Mitigation: one file per slice, full suite after each, revert the slice on failure.
- [Risk] `Vector2` conversion changes a rounding or equality path -> Mitigation: keep dictionary boundaries unchanged and convert only where values are immediately consumed.
- [Risk] `Input.get_vector` changes deadzone feel -> Mitigation: assert the same output for representative stick and key states before swapping.

## Migration Plan

Refactor only. Slices are independent and revertible one file at a time.
