## MODIFIED Requirements

### Requirement: Vida drains with hunger and triggers judgment at zero
The system SHALL decrease hambre and sed continuously over time at species-paced rates derived from life expectancy, SHALL regenerate Vida over time only when hambre is above `H_thresh` AND sed is above `S_thresh`, SHALL otherwise drain Vida with a deficit multiplier that grows as stocks empty, and SHALL trigger the Judgment sequence when Vida reaches 0. The hambre drain rate SHALL equal the global base rate multiplied by the possessed species' hunger multiplier and the sed drain rate SHALL be a documented multiple of it: short-lived forms drain faster, long-lived forms drain slower. Default multipliers SHALL keep the Ratón near the historic baseline pace. Edad SHALL increase with time with no effect on this requirement.

#### Scenario: Hunger depletes vida
- **WHEN** the player survives 10 seconds with hambre or sed below threshold at its species drain rates
- **THEN** Vida is lower than at start by the deficit-multiplied drain over that time and the creature remains alive while Vida > 0

#### Scenario: Death opens judgment
- **WHEN** Vida reaches 0 for any reason
- **THEN** the game pauses the life loop and opens the Judgment screen instead of respawning silently

#### Scenario: Short-lived starves faster than apex
- **WHEN** an Oruga and a Lobo both go unfed and unwatered for 30 seconds below threshold
- **THEN** the Oruga has lost more Vida than the Lobo

#### Scenario: Lobo anchor vive 30 minutos
- **WHEN** a Lobo sits below threshold for 1800 seconds with no damage
- **THEN** its total Vida loss equals its max Vida (species-rate × time ≈ 160), i.e. it starves at ~30 minutes, and every other species scales by its own multiplier

#### Scenario: Fed and watered regenerates instead of draining
- **WHEN** the player keeps hambre and sed both above threshold for 10 seconds with no damage taken
- **THEN** Vida is higher than at start by regen-rate × time, capped at max
