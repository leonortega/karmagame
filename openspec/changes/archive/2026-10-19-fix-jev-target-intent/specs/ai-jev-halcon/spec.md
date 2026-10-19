## MODIFIED Requirements

### Requirement: Halcon macro intent comes from NanoJev ranking over code-built candidates

The system SHALL obtain each AI halcon's macro intent by sending one batched NanoJev `Choice` request covering all AI halcons and applying the ranked winner. GDScript SHALL build the candidate menu per halcon from legal moves only (cooldown, range, diet, grounded/land state checked); NanoJev SHALL only rank, never invent moves. Every applied intent SHALL execute through the same functions as the player (`eat_carrion`, `cast_verb_for`, dive/hunt resolve). When the winning candidate references a prey or carrion target, the applied intent SHALL retain that target so micro steering can resolve contact effects instead of clearing the intent.

#### Scenario: Batched parallel decision

- **WHEN** 3 AI halcons need macro intent in the same window
- **THEN** the system sends one batch request with 3 states and per-halcon candidates and applies one returned choice per halcon

#### Scenario: Illegal move is impossible by construction

- **WHEN** a halcon's dive is on cooldown
- **THEN** its candidate menu contains no dive entry, so no ranking can select it

#### Scenario: Player parity of effects

- **WHEN** the ranked winner is scare on a predator within strike range
- **THEN** the predator is pushed away and the halcon gains the same karma as a player scare, including adaptation multipliers

#### Scenario: Applied dive intent retains its target

- **WHEN** a halcon applies a ranked dive candidate
- **THEN** its `jev_intent` retains the candidate's prey target, and micro steering can dive, kill that prey, and land on contact
