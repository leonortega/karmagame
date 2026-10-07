## MODIFIED Requirements

### Requirement: Lagos anchor insect density
The system SHALL bias insect spawns to shore rings around water so shores visibly hold more insects than open ground: lago ring with probability `lakeInsectBias` (ring `r+8..r+lakeShore`), else charco ring with probability `charcoInsectBias` (ring `r+8..r×4`, tight to the puddle), else uniform dry scatter; respawning one insect every 12s up to a global cap of 10; insects SHALL never spawn inside water, SHALL then wander as today and remain edible for Sapo/Topo with unchanged payoffs.

#### Scenario: Lake shore buzzes

- **WHEN** insects respawn with a lago on the map
- **THEN** new insects appear biased to the shore ring around the lago far more often than at uniform random points, and never inside the water

#### Scenario: Lake insects stay edible

- **WHEN** a Sapo tongues an insect near a lago
- **THEN** the insect is consumed with the standard +10 vida/+3 PA and pest-control karma

#### Scenario: Supply saturates at the cap

- **WHEN** the world runs with fewer insects than the cap and no predation for over a minute
- **THEN** the insect count climbs by one per respawn window and never exceeds 10

#### Scenario: Charco rims buzz too

- **WHEN** insects spawn with charcos on the map and no lago wins the roll
- **THEN** new insects appear biased to tight rings around charcos far more often than at uniform random points, and never inside the water
