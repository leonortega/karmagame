## MODIFIED Requirements

### Requirement: Ardilla macro intent comes from NanoJev ranking over code-built candidates

The system SHALL obtain each AI ardilla's macro intent by sending one batched NanoJev `Choice` request covering all AI ardillas and applying the ranked winner. GDScript SHALL build the candidate menu per ardilla from legal moves only (edible-patch and oak diet, range, drink need, hunted state, carried-nut state checked); NanoJev SHALL only rank, never invent moves. Every applied intent SHALL execute through the same functions as the player (`eat_patch`, `bury_or_carry_nut`, drink/seek, flee/hide resolve, verbs through the same karma paths).

#### Scenario: Batched parallel decision

- **WHEN** 3 AI ardillas need macro intent in the same window
- **THEN** the system sends one batch request with 3 states and per-ardilla candidates and applies one returned choice per ardilla

#### Scenario: Illegal move is impossible by construction

- **WHEN** no edible patch is within contact range and the ardilla is sated
- **THEN** its candidate menu contains no eat entry, so no ranking can select it

#### Scenario: Player parity of effects

- **WHEN** the ranked winner is eat on an edible patch within eat range
- **THEN** the patch is fully consumed in one bite and the ardilla gains the same HP as a player eat