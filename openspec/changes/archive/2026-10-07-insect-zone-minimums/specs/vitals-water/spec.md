## MODIFIED Requirements

### Requirement: Lagos anchor insect density
The system SHALL bias insect spawns to shore rings around water so shores visibly hold more insects than open ground: lago ring with probability `lakeInsectBias` (ring `r+8..r+lakeShore`), else charco ring with probability `charcoInsectBias` (ring `r+8..r×4`, tight to the puddle), else uniform dry scatter; respawning one insect every 12s up to a global cap of 40; insects SHALL never spawn inside water, SHALL then wander as today and remain edible for Sapo/Topo with unchanged payoffs. Charco zones (within `r×4` of any charco) SHALL hold at least 10 insects and lago zones (within `r+lakeShore` of any lago) at least 20: each respawn SHALL first refill a short zone directly, and world generation SHALL seed both minimums (round-robin across bodies of each kind, skipping kinds absent from the map).

#### Scenario: Lake shore buzzes

- **WHEN** insects respawn with a lago on the map
- **THEN** new insects appear biased to the shore ring around the lago far more often than at uniform random points, and never inside the water

#### Scenario: Lake insects stay edible

- **WHEN** a Sapo tongues an insect near a lago
- **THEN** the insect is consumed with the standard +10 vida/+3 PA and pest-control karma

#### Scenario: Supply saturates at the cap

- **WHEN** the world runs with fewer insects than the cap and no predation for over a minute
- **THEN** the insect count climbs by one per respawn window and never exceeds 40

#### Scenario: Charco rims buzz too

- **WHEN** insects spawn with charcos on the map and no lago wins the roll
- **THEN** new insects appear biased to tight rings around charcos far more often than at uniform random points, and never inside the water

#### Scenario: Short zones refill first

- **WHEN** charco zones hold 9 insects with the respawn window elapsed
- **THEN** the new insect spawns in a charco ring even though the bias lottery was not consulted

#### Scenario: New worlds start stocked

- **WHEN** a run generates with charcos and lagos present
- **THEN** it holds at least 10 insects in charco zones and 20 in lago zones from the start
