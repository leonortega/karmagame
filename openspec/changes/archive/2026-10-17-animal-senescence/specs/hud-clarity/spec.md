## MODIFIED Requirements

### Requirement: Animal-years edad display
The system SHALL display edad as per-species animal-years derived from lived seconds via a per-species seconds-per-year table plus an age-stage signal (prime/worn/frail, shown to the player in Spanish as joven/maduro/frágil) reflecting the `animal-senescence` decay state, SHALL keep counting `edad` in seconds internally with full gameplay effect, and SHALL keep the elapsed-time clock as a separately labeled run clock.

#### Scenario: Raton age reads in raton years
- **WHEN** a raton has lived 40 seconds at 20 seconds-per-year
- **THEN** the edad readout shows approximately 2 raton-years alongside the raw seconds

#### Scenario: Edad stays display-only
- **WHEN** two animals of the same species differ only in edad
- **THEN** the old display-only rule no longer applies: readouts now carry the age-stage signal and vida trajectories differ by age per `animal-senescence`

#### Scenario: Edad shows the age stage, not just years
- **WHEN** a frail animal and a prime animal of the same species show their edad readouts
- **THEN** each readout carries its age-stage signal (prime/worn/frail), so the frail one and the prime one are distinguishable at any equal or unequal year count
