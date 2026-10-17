## REMOVED Requirements

### Requirement: Infinite water bodies dot the map
**Reason**: Water is now finite and drains as animals drink, so a water body's rendered size and availability depend on its current level rather than being a fixed, always-full terrain feature.
**Migration**: Positions, density scaling, and persistence are unchanged; rendering now follows "Water bodies render at their current level" and availability follows `vitals-water`.

## ADDED Requirements

### Requirement: Water bodies render at their current level
The system SHALL render each charco and lago as a blue body scaled to its current water level, keeping its distinct water glyph and label on top, so a drained lago reads as a smaller lake and a drained charco as a shrinking puddle. A body at zero level SHALL read as an empty basin (no water color) while still showing its placement. The system SHALL also render the active rain state on the canvas while a rain event is falling.

#### Scenario: A depleted body reads smaller
- **WHEN** a lago or charco has drained below full
- **THEN** its rendered water body is visibly smaller than at full level

#### Scenario: A dry body reads as an empty basin
- **WHEN** a body's level reaches zero
- **THEN** it renders as an empty basin with no water fill, still showing its glyph and label

#### Scenario: Rain is visible on the map
- **WHEN** a rain event is active
- **THEN** the canvas shows a rain state over the world

#### Scenario: Water is still reachable by density
- **WHEN** the possessed agent crosses the enlarged world at its species speed
- **THEN** drinkable charcos or lagos lie within a bounded travel time comparable to food proportions, because counts scale with area
