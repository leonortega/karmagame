# vitals-water

## Purpose

Split survival into explicit needs (vida, hambre, sed, edad) with a threshold-gated vida algorithm, and add infinite charco/lago water terrain with lake-anchored insects, all drinkable through the existing E button.
## Requirements
### Requirement: Split needs model with passive edad
The system SHALL track per-agent `hambre` (0..100, 100 = full), `sed` (0..100, 100 = hydrated), and `edad` (seconds lived this life, increasing monotonically) alongside `vida` and `karma`. Hambre SHALL drain continuously at the species-paced hunger rate and refill on eating; sed SHALL drain continuously at a faster thirst rate and refill on drinking; edad SHALL increase with time and SHALL have no gameplay effect in this change (reserved hook for future speed/hunger modifiers). All three SHALL reset at the start of each life; karma carry rules are unchanged. The HUD SHALL display edad as per-species animal-years derived from lived seconds via a per-species seconds-per-year table alongside the raw seconds count; the elapsed run-time clock SHALL remain a separately labeled readout.

#### Scenario: Hunger and thirst drain while edad climbs
- **WHEN** the player survives 10 seconds without eating or drinking
- **THEN** hambre is lower by hunger-rate x time, sed is lower by thirst-rate x time (sed drops further), and edad is higher by 10 seconds

#### Scenario: Edad has no effect yet
- **WHEN** two animals of the same species have different edad values but equal hambre, sed, and damage history
- **THEN** their vida trajectories over the next tick are identical

#### Scenario: Needs reset each life
- **WHEN** the player reincarnates
- **THEN** the new life starts with full hambre and sed stocks and edad at zero, independent of the previous life's values

#### Scenario: Edad displays in animal-years
- **WHEN** the player looks at the edad readout after surviving N seconds
- **THEN** it shows the raw seconds plus N divided by that species seconds-per-year as animal-years

### Requirement: Threshold-gated vida regen and deficit drain
The system SHALL regenerate vida over time only when hambre is above `H_thresh` AND sed is above `S_thresh`; otherwise it SHALL drain vida with a deficit multiplier that grows as stocks empty. Predator, poison, and verb damage SHALL always subtract from vida directly regardless of needs. All healing SHALL cap at max vida and death SHALL occur at 0 vida with the existing Judgment sequence.

#### Scenario: Well-fed and watered regenerates
- **WHEN** hambre and sed are both above their thresholds for 10 seconds with no damage taken
- **THEN** vida is higher than at start by regen-rate x time, capped at max

#### Scenario: Starving or parched drains faster when emptier
- **WHEN** hambre is at 10 versus hambre at 50 (sed equal, both below threshold) over the same duration
- **THEN** the emptier animal loses more vida

#### Scenario: Damage bypasses needs
- **WHEN** a predator deals contact damage to a fully fed and watered animal
- **THEN** vida drops by the full hit amount immediately with no regen offset in that tick

### Requirement: Eat refills hambre and heals, drink refills sed and sips
The system SHALL refill hambre on every diet-valid eat (keeping all existing `FOODDEF` vida/PA payoffs) and SHALL refill sed plus grant a small direct vida sip on every drink. Off-diet and off-context E presses SHALL behave as today (hint, no effect).

#### Scenario: Berries fill the tank and heal
- **WHEN** a Raton eats sustainable berries
- **THEN** vida rises by the existing payoff capped at max, PA accrues as today, and hambre rises by the documented food value

#### Scenario: Drink sips vida and fills sed
- **WHEN** a thirsty animal drinks at a charco or lago edge within drink range
- **THEN** sed rises by the documented sip value and vida rises by the small sip heal capped at max

### Requirement: Infinite charcos and lagos as drinkable terrain
The system SHALL seed infinite water bodies as terrain (not depletable patches): `charcos` (tiny, scattered count) and `lagos` (large landscape anchors, few), with counts scaled by world area as densities like food and rocks. The lago radius SHALL be visibly larger than a charco so a lago reads as a lake and a charco as a puddle. Drinking SHALL work from the water edge within drink range for every species; water SHALL persist across reincarnation like refuges and rocks. Only water SHALL exist inside a charco or lago: food, refuges, rocks, agents, insects, seedlings, and carrion SHALL never spawn, mature, or drop inside water.

#### Scenario: Charco drinks at its edge
- **WHEN** the player presses E within drink range of a charco edge
- **THEN** a drink resolves with sed plus small vida gain and the charco remains fully available

#### Scenario: Lago drinks along its shore
- **WHEN** the player presses E at any point within drink range of a lago shore
- **THEN** a drink resolves exactly as at a charco, with the larger radius allowing more approach angles

#### Scenario: Water survives death
- **WHEN** a life ends and the player reincarnates
- **THEN** all charcos and lagos remain at the same positions

#### Scenario: Water holds nothing else
- **WHEN** the world seeds or respawns food, refuges, rocks, agents, insects, seedlings, or carrion
- **THEN** no entity is placed with its center inside any charco or lago radius

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

### Requirement: Amphibious entry with hittable shoreline
The system SHALL allow only amphibious species (`sapo` now; a future `pato` joins by table row, no logic change) to be inside charco/lago water; every other species SHALL be stopped at the shore but SHALL still drink from the edge. A `sapo` inside water at the border or in the lake SHALL remain hittable by `zorro` or `lobo` at the existing contact/kill ranges across the shoreline; trophic targeting SHALL NOT change (`zorro` hunts `sapo`, `lobo` only damages on opportunistic contact). Water SHALL NOT block line of sight.

#### Scenario: Sapo enters, raton stops
- **WHEN** a sapo moves into a lago and a raton moves into the same lago
- **THEN** the sapo continues inside while the raton resolves to the shore edge and can still drink with E

#### Scenario: Rim is dangerous, deep is safe
- **WHEN** a sapo sits just inside the shoreline within predator contact range and a zorro stands at the edge
- **THEN** the zorro can deal contact damage across the shore with the existing hit rules

#### Scenario: Charco never hides
- **WHEN** a sapo sits inside a charco
- **THEN** a zorro at the charco edge is always within contact range, so the charco grants no safety

#### Scenario: Trophic table frozen
- **WHEN** a lobo is on the map with a sapo in the water
- **THEN** the lobo does not begin a hunt for the sapo by water alone, though contact damage still applies on touch

### Requirement: E drinks or eats by need with kill priority
The system SHALL resolve E as: carnivore kill verbs first when a valid target is in range, otherwise drink when the animal is thirstier than hungry (sed deficit exceeds hambre deficit) and water is in drink range, otherwise eat when food is in eat range, otherwise the existing species fallback (dig/hint/nothing). Ties SHALL favor drinking since thirst drains faster. Halcon SHALL drink through the existing 1s landing window.

#### Scenario: Thirsty animal drinks first
- **WHEN** a Raton at sed 20 and hambre 70 presses E with both a berry bush and a charco in range
- **THEN** a drink resolves, not an eat

#### Scenario: Hungry animal eats first
- **WHEN** a Raton at hambre 20 and sed 80 presses E with both in range
- **THEN** an eat resolves, not a drink

#### Scenario: Kill still wins over thirst
- **WHEN** a Zorro with a valid pounce target presses E with water also in range
- **THEN** the pounce resolves before any drink
