## MODIFIED Requirements

### Requirement: Eat refills hambre and heals, drink refills sed and sips
The system SHALL refill hambre on every diet-valid eat (keeping all existing `FOODDEF` vida/PA payoffs). On every drink the system SHALL refill `sed`, grant the small direct vida sip, and debit the drunk water body's `level` by that drinker species' sip cost. A drink SHALL resolve only when the body has `level > 0`; off-diet and off-context E presses SHALL behave as today (hint, no effect).

#### Scenario: Berries fill the tank and heal
- **WHEN** a Raton eats sustainable berries
- **THEN** vida rises by the existing payoff capped at max, PA accrues as today, and hambre rises by the documented food value

#### Scenario: Drink sips vida and fills sed
- **WHEN** a thirsty animal drinks at a charco or lago edge within drink range and the body has water
- **THEN** sed rises by the documented sip value, vida rises by the small sip heal capped at max, and the body's level drops by that species' sip cost

#### Scenario: Drink refuses a dry body
- **WHEN** an animal presses a drink at a body whose level is zero
- **THEN** no sed or vida is gained and the body is not chosen as a drink target

## REMOVED Requirements

### Requirement: Infinite charcos and lagos as drinkable terrain
**Reason**: Water is now finite. Charcos and lagos deplete as animals drink and refill only through rain, so the guarantee that they are non-depletable terrain no longer holds.
**Migration**: The geometry, density scaling, edge drinking, persistence, and "water holds nothing else" rules are preserved by the "Charcos and lagos persist with geometry" requirement below; depletion, per-species cost, and dry behavior are defined by "Finite charcos and lagos depleted by drinking" and "Dry water is an empty basin, not a drink".

## ADDED Requirements

### Requirement: Charcos and lagos persist with geometry
The system SHALL seed charcos (tiny, scattered) and lagos (large landscape anchors, few) with counts scaled by world area as densities, and the lago radius SHALL remain visibly larger than a charco. Drinking SHALL work from the water edge within drink range for every species while the body holds water. Water bodies SHALL persist across reincarnation at the same positions with their current level, like refuges and rocks. Only water SHALL exist inside a body that holds water: food, refuges, rocks, agents, insects, seedlings, and carrion SHALL never spawn, mature, or drop inside its radius.

#### Scenario: Charco and lago drink at their edge
- **WHEN** the player presses E within drink range of a charco or lago edge while it holds water
- **THEN** a drink resolves with sed plus small vida gain, at both sizes

#### Scenario: Water survives death with its level
- **WHEN** a life ends and the player reincarnates
- **THEN** all charcos and lagos remain at the same positions with the levels they held

#### Scenario: Water holds nothing else
- **WHEN** the world seeds or respawns food, refuges, rocks, agents, insects, seedlings, or carrion
- **THEN** no entity is placed with its center inside the radius of any body that holds water

### Requirement: Finite charcos and lagos depleted by drinking
The system SHALL track a finite water `level` for every charco and lago, measured against a full capacity that scales with the body's size (a lago holds far more than a charco). Every drink SHALL debit that drinker species' configured sip cost, so a higher-cost species empties a body in fewer drinks than a lower-cost species. The last drop SHALL be drinkable: a body with a positive level below one sip cost SHALL still grant the full drink and then read dry. A body SHALL never hold a negative level.

#### Scenario: A drink lowers the level
- **WHEN** an animal drinks at a body with level above the species' sip cost
- **THEN** the level drops by exactly that species' sip cost

#### Scenario: A costlier drinker drains faster
- **WHEN** two species with different sip costs drink repeatedly at identical fresh bodies
- **THEN** the higher-cost species empties its body in fewer drinks

#### Scenario: The last drop still heals
- **WHEN** an animal drinks at a body whose remaining level is less than its sip cost
- **THEN** it gains the full sed and vida sip and the body's level becomes zero

#### Scenario: Level never goes negative
- **WHEN** any drink resolves at a body
- **THEN** the resulting level is at least zero

### Requirement: Dry water is an empty basin, not a drink
A body at zero level SHALL remain a static solid of its full radius (so non-amphibious movement is still blocked and no entity spawns inside it), SHALL NOT be selected as a drink target by the player or by any AI, and SHALL be refillable by rain back toward full.

#### Scenario: Dry basin still blocks
- **WHEN** a non-amphibious animal walks toward a dry body
- **THEN** it is stopped at the body's edge exactly as when the body held water

#### Scenario: Player cannot drink from a dry body
- **WHEN** the player presses a drink while only dry bodies are in range
- **THEN** no drink resolves

#### Scenario: AI ignores dry water
- **WHEN** an AI animal is thirsty and the only water in reach is dry
- **THEN** it does not target that body and instead seeks other water or keeps its existing behavior

#### Scenario: Rain refills a dry body
- **WHEN** a dry body is rained on long enough
- **THEN** its level rises back toward full and it becomes drinkable
