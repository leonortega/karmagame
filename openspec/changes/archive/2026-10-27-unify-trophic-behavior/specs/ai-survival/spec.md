## MODIFIED Requirements

### Requirement: AI hides in refuges when hunted
When an animal whose species data can eat the agent is within perception - including AI-brained and possessed animals, not only a separately labeled predator - an AI grazer near a fitting refuge (<= hide-range) SHALL enter it: `hidden = true` with the refuge as `hideRef`, for up to `aiHideMax` seconds. The agent's own fear table still decides which species qualify. Frail animals SHALL weigh hiding over outrunning (they hide on weaker threat signals and at longer ranges than prime animals of the same species). While hidden, ground threats SHALL lose the agent per existing hide rules. The AI SHALL exit when danger passes or `aiHideMax` expires. Hunger and thirst SHALL keep draining while hidden.

#### Scenario: Raton hides from the fox
- **WHEN** a Zorro whose species data can eat a Raton is within perception of an AI Raton standing within hide-range of a burrow-M
- **THEN** the Raton enters the refuge, becomes untargeted per hide rules, and exits when the Zorro leaves or 5s pass

#### Scenario: Raton hides from a fauna fox
- **WHEN** an AI-brained Zorro (not the possessed agent) can eat an AI Raton standing within hide-range of a burrow-M
- **THEN** the Raton enters the refuge, becomes untargeted per hide rules, and exits when the Zorro leaves or 5s pass

#### Scenario: Old raton holes up earlier
- **WHEN** a frail AI Raton senses a prime Zorro at the edge of perception with a refuge in range
- **THEN** it hides while a prime Raton in the same spot keeps foraging until the threat closes

#### Scenario: Hiding costs food
- **WHEN** an AI stays hidden for 5s
- **THEN** its HP drained by hunger for those 5s and it did not eat

#### Scenario: Hiding costs water too
- **WHEN** an AI stays hidden for 5s without drinking
- **THEN** its sed drained alongside hunger and vida regen stayed suspended unless both needs held above threshold
