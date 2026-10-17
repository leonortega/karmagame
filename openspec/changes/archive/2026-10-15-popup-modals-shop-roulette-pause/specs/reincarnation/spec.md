## MODIFIED Requirements

### Requirement: Judgment screen explains cause and outcome
The system SHALL show final Karma, survived time, the unlock reason citing the karma floor and eligible pool, the drama line "los dioses eligen que reencarnes en..." with one illuminated block per eligible species that cycles until the drawn form settles, the settled species/tier, and the last up-to-4 life events, with a Reincarnar button and R shortcut. No pick buttons and no reroll exist. The judgment modal SHALL freeze the sim identically to other modals, SHALL own key focus so world verbs and movement are swallowed while open, SHALL confirm rebirth only via Reincarnar button or R, and SHALL show a single Oruga block with no fake cycle WHEN the pool holds one entry (involution).

#### Scenario: Player understands why
- **WHEN** Vida reaches 0
- **THEN** the Judgment overlay appears showing stats, floor reason, eligible pool blocks, the cycling reveal settling on the drawn form, recent history, and a working reincarnate control

#### Scenario: No choice controls render
- **WHEN** any Judgment opens
- **THEN** no T2-pick buttons and no Choose-form buttons are shown or enabled

#### Scenario: Judgment freezes and owns focus
- **WHEN** the judgment modal is open
- **THEN** no hunger, predator, cooldown, or timer advances and no movement or verb key has any effect until Reincarnar or R

#### Scenario: Involution shows instantly
- **WHEN** a life ends with Karma -70
- **THEN** the judgment shows one Oruga block settled immediately with the involution reason and no cycling animation
