## Purpose

Give the world a weather rhythm: an independent global clock that produces dry spells and rain events, where rain refills charcos and lagos by rate x duration and triggers an insect boom.

## ADDED Requirements

### Requirement: Global weather clock with dry and rain phases
The system SHALL run one global weather clock independent of the year theme, alternating dry spells and rain events, each with a randomized duration. The clock SHALL advance with world time and SHALL produce a boolean "raining" state that applies to the whole map at once. Weather timing SHALL reset each life while water levels persist.

#### Scenario: Dry spell produces no rain
- **WHEN** the weather clock is in a dry spell
- **THEN** `raining` is false and no body refills

#### Scenario: Rain event begins
- **WHEN** a dry spell's timer elapses
- **THEN** a rain event starts with a randomized duration and `raining` is true for the whole map

#### Scenario: Rain ends
- **WHEN** a rain event's duration elapses
- **THEN** `raining` becomes false and the next dry spell begins

### Requirement: Rain refills water by rate and duration
While raining, the system SHALL raise every charco and lago `level` at a fixed rain rate per second, capped at that body's full capacity. A rain long enough to cover the deficit SHALL restore a body to 100%; a shorter rain SHALL leave it partially filled.

#### Scenario: Long rain restores a body
- **WHEN** a body below full capacity is rained on long enough for rate x duration to reach capacity
- **THEN** its level reaches full and stops there

#### Scenario: Short shower leaves it partial
- **WHEN** a body at half capacity is rained on for less than the time needed to refill
- **THEN** its level rises by rate x duration and stays below full

#### Scenario: Rain never overfills
- **WHEN** a body already at full capacity is rained on
- **THEN** its level stays at full

### Requirement: Rain spawns an insect burst
Rain SHALL trigger a burst of insects in addition to the normal respawn cadence, biased to the shore rings around charcos and lagos and never inside water. The burst SHALL temporarily allow the insect population to exceed its normal cap, then decay back toward the cap through the existing respawn rules.

#### Scenario: Rain brings bugs
- **WHEN** a rain event starts
- **THEN** a batch of insects appears around water shore rings far more than by the normal respawn window

#### Scenario: Burst never lands in water
- **WHEN** the rain insect burst places insects
- **THEN** every insect lands outside every water radius

#### Scenario: Burst is a spike, not a new normal
- **WHEN** the burst has passed and no rain is falling
- **THEN** the insect population decays back toward its normal cap through the existing respawn rules

### Requirement: Rain state is visible
The system SHALL show the current weather state to the player: a clear raining indicator while it rains and feedback when a rain event starts and ends.

#### Scenario: Player sees it raining
- **WHEN** a rain event is active
- **THEN** the HUD and/or canvas shows a raining state

#### Scenario: Rain start and end are announced
- **WHEN** a rain event starts or ends
- **THEN** the player event feed records the change
