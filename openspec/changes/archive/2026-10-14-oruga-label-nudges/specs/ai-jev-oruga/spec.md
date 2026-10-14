## MODIFIED Requirements

### Requirement: Oruga candidate menu covers the AI-legal kit

The candidate menu for an oruga SHALL be built from: eat (edible leaves patch within eat range), seek-food (distant edible leaves patch when hungry), drink-seek (water when below the drink threshold), flee-to-refuge (when hunted, size-1 and `orugaOnly` refuges included via the existing fit check), silk (hunter within 150px with slot 2 off cooldown and HP above its cost, instant-cast), nectar (hunter within 150px with slot 3 off cooldown and HP plus PA above its costs, instant-cast), leafroll (leaf clump within eat range with slot 4 off cooldown, instant-cast creating an `orugaOnly` refuge), and wander. Wander SHALL always be present so the ranking always has an executable target. Stale answers (actor dead, target gone, patch already eaten) SHALL resolve to continued steering or wander, never to a no-op freeze. Labels SHALL carry urgency hints at floor need so the ranking can weigh urgency the way halcon hunger hints do: the eat label appends a hunger hint whenever hambre sits at or below regenHambre, the drink label appends a thirst hint whenever sed sits at or below regenSed, and the seek-food label appends a hunger hint (it is only offered when hungry; the hint fires at the floor). Labels SHALL never gate execution: kinds, legality gates, and affordability checks are untouched.

#### Scenario: Menu always has wander

- **WHEN** an AI oruga has no food, water, pressure, clump, or ready verb
- **THEN** its menu contains exactly one candidate (`wander`) so the ranker always has an executable target

#### Scenario: Silk needs a hunter in range

- **WHEN** no hunter sits within 150px of an AI oruga, or slot 2 is on cooldown, or HP cannot cover its cost
- **THEN** the `silk` candidate is absent from its menu

#### Scenario: Leafroll needs a clump in range

- **WHEN** no leaf clump sits within eat range of an AI oruga, or slot 4 is on cooldown
- **THEN** the `leafroll` candidate is absent from its menu

#### Scenario: Eat label plain when sated

- **WHEN** an AI oruga holds contact leaves with hambre above regenHambre
- **THEN** its eat candidate label carries no hunger hint

#### Scenario: Eat and drink labels hint need at floor

- **WHEN** an AI oruga holds contact leaves with hambre at or below regenHambre, or drinkable water with sed at or below regenSed
- **THEN** the matching candidate label carries the hunger or thirst hint so the ranking can weigh need
