## MODIFIED Requirements

### Requirement: Split needs model with passive edad
The system SHALL track per-agent `hambre` (0..100, 100 = full), `sed` (0..100, 100 = hydrated), and `edad` (seconds lived this life, increasing monotonically) alongside `vida` and `karma`. Hambre SHALL drain continuously at the species-paced hunger rate and refill on eating; sed SHALL drain continuously at a faster thirst rate and refill on drinking; edad SHALL increase with time and SHALL scale speed, attack force, vida-regen, and action/cooldown times per the species senescence row, with victim frailty rising with age (see `animal-senescence`). All three SHALL reset at the start of each life; karma carry rules are unchanged. The HUD SHALL display edad as per-species animal-years derived from lived seconds via a per-species seconds-per-year table alongside the raw seconds count plus an age-stage signal; the elapsed run-time clock SHALL remain a separately labeled readout.

#### Scenario: Hunger and thirst drain while edad climbs
- **WHEN** the player survives 10 seconds without eating or drinking
- **THEN** hambre is lower by hunger-rate x time, sed is lower by thirst-rate x time (sed drops further), and edad is higher by 10 seconds

#### Scenario: Edad weakens the old
- **WHEN** two animals of the same species differ only in edad (prime vs frail) with equal hambre, sed, and damage history
- **THEN** the frail animal moves slower, regenerates less vida, hits softer, takes more damage, and acts slower over the next ticks

#### Scenario: Edad has no effect yet
- **WHEN** two animals of the same species have different edad values but equal hambre, sed, and damage history
- **THEN** the old no-effect rule no longer applies: the frail animal's vida trajectory is worse (slower regen, softer hits, higher frailty) per `animal-senescence`

#### Scenario: Needs reset each life
- **WHEN** the player reincarnates
- **THEN** the new life starts with full hambre and sed stocks and edad at zero, independent of the previous life's values

#### Scenario: Edad displays in animal-years
- **WHEN** the player looks at the edad readout after surviving N seconds
- **THEN** it shows the raw seconds plus N divided by that species seconds-per-year as animal-years
