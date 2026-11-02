## MODIFIED Requirements

### Requirement: Raton macro intent comes from NanoJev ranking over code-built candidates

The system SHALL obtain each AI raton's macro intent by sending one batched NanoJev `Choice` request covering all AI ratons and applying the ranked winner. GDScript SHALL build the candidate menu per raton from legal moves only (edible-patch diet, range, drink need, hunted state checked); NanoJev SHALL only rank, never invent moves. Every applied intent SHALL execute through the same functions as the player (`eat_patch`, drink/seek, flee/hide resolve, social verbs through the same karma paths).

#### Scenario: Batched parallel decision

- **WHEN** 3 AI ratons need macro intent in the same window
- **THEN** the system sends one batch request with 3 states and per-raton candidates and applies one returned choice per raton

#### Scenario: Illegal move is impossible by construction

- **WHEN** no edible patch is within contact range and the raton is sated
- **THEN** its candidate menu contains no eat entry, so no ranking can select it

#### Scenario: Player parity of effects

- **WHEN** the ranked winner is eat on an edible patch within eat range
- **THEN** the patch is fully consumed in one bite and the raton gains the same HP as a player eat