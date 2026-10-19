## MODIFIED Requirements

### Requirement: Zorro macro intent comes from NanoJev ranking over code-built candidates

The system SHALL obtain each AI zorro's macro intent by sending one batched NanoJev `Choice` request covering all AI zorros and applying the ranked winner. GDScript SHALL build the candidate menu per zorro from legal moves only (cooldown, range, diet, HP-cost checked); NanoJev SHALL only rank, never invent moves. Every applied intent SHALL execute through the same functions as the player (`eat_carrion`, `cede_carrion`, `cast_verb_for`, pounce/hunt resolve). When the winning candidate references a prey or carrion target, the applied intent SHALL retain that target so micro steering can resolve contact effects instead of clearing the intent.

#### Scenario: Batched parallel decision

- **WHEN** 3 AI zorros need macro intent in the same window
- **THEN** the system sends one batch request with 3 states and per-zorro candidates and applies one returned choice per zorro

#### Scenario: Illegal move is impossible by construction

- **WHEN** a zorro's pounce is on cooldown
- **THEN** its candidate menu contains no pounce entry, so no ranking can select it

#### Scenario: Player parity of effects

- **WHEN** the ranked winner is cede on a carrion within eat range at HP at or above the wasteful threshold
- **THEN** the carrion is marked ceded and the zorro gains the same karma as a player cede, including adaptation multipliers

#### Scenario: Applied prey intent retains its target

- **WHEN** a zorro applies a ranked pounce or hunt candidate
- **THEN** its `jev_intent` retains the candidate's prey target, and micro steering can chase and kill that prey on contact
