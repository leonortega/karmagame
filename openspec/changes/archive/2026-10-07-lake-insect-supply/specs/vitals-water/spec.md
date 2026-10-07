## MODIFIED Requirements

### Requirement: Lagos anchor insect density
The system SHALL bias insect spawns to a shore ring around lagos so lake shores visibly hold more insects than open ground, respawning one insect every 12s up to a global cap of 10; insects SHALL never spawn inside water, SHALL then wander as today and remain edible for Sapo/Topo with unchanged payoffs.

#### Scenario: Lake shore buzzes

- **WHEN** insects respawn with a lago on the map
- **THEN** new insects appear biased to the shore ring around the lago far more often than at uniform random points, and never inside the water

#### Scenario: Lake insects stay edible

- **WHEN** a Sapo tongues an insect near a lago
- **THEN** the insect is consumed with the standard +10 vida/+3 PA and pest-control karma

#### Scenario: Supply saturates at the cap

- **WHEN** the world runs with fewer insects than the cap and no predation for over a minute
- **THEN** the insect count climbs by one per respawn window and never exceeds 10
