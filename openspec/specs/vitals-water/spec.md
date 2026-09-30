# vitals-water

## Purpose

Split survival into explicit needs (vida, hambre, sed, edad) with a threshold-gated vida algorithm, and add infinite charco/lago water terrain with lake-anchored insects, all drinkable through the existing E button.
## Requirements
### Requirement: Split needs model with passive edad
The system SHALL track per-agent `hambre` (0..100, 100 = full), `sed` (0..100, 100 = hydrated), and `edad` (seconds lived this life, increasing monotonically) alongside `vida` and `karma`. Hambre SHALL drain continuously at the species-paced hunger rate and refill on eating; sed SHALL drain continuously at a faster thirst rate and refill on drinking; edad SHALL increase with time and SHALL have no gameplay effect in this change (reserved hook for future speed/hunger modifiers). All three SHALL reset at the start of each life; karma carry rules are unchanged.

#### Scenario: Hunger and thirst drain while edad climbs
- **WHEN** the player survives 10 seconds without eating or drinking
- **THEN** hambre is lower by hunger-rate x time, sed is lower by thirst-rate x time (sed drops further), and edad is higher by 10 seconds

#### Scenario: Edad has no effect yet
- **WHEN** two animals of the same species have different edad values but equal hambre, sed, and damage history
- **THEN** their vida trajectories over the next tick are identical

#### Scenario: Needs reset each life
- **WHEN** the player reincarnates
- **THEN** the new life starts with full hambre and sed stocks and edad at zero, independent of the previous life's values

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
The system SHALL seed infinite water bodies as terrain (not depletable patches): `charcos` (small drink radius, scattered count) and `lagos` (large drink radius, few), with counts scaled by world area as densities like food and rocks. Drinking SHALL work from the water edge within drink range for every species; water SHALL persist across reincarnation like refuges and rocks.

#### Scenario: Charco drinks at its edge
- **WHEN** the player presses E within drink range of a charco edge
- **THEN** a drink resolves with sed plus small vida gain and the charco remains fully available

#### Scenario: Lago drinks along its shore
- **WHEN** the player presses E at any point within drink range of a lago shore
- **THEN** a drink resolves exactly as at a charco, with the larger radius allowing more approach angles

#### Scenario: Water survives death
- **WHEN** a life ends and the player reincarnates
- **THEN** all charcos and lagos remain at the same positions

### Requirement: Lagos anchor insect density
The system SHALL bias insect spawns near lagos so lakes hold visibly more insects than open ground, while keeping the existing global respawn cadence and cap; insects SHALL then wander as today and remain edible for Sapo/Topo with unchanged payoffs.

#### Scenario: Lake shore buzzes
- **WHEN** insects respawn with a lago on the map
- **THEN** new insects appear biased within lake-shore range far more often than at uniform random points

#### Scenario: Lake insects stay edible
- **WHEN** a Sapo tongues an insect near a lago
- **THEN** the insect is consumed with the standard +10 vida/+3 PA and pest-control karma

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
