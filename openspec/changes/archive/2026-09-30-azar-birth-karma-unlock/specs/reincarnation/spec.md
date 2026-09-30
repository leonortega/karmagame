## MODIFIED Requirements

### Requirement: Judgment matrix maps karma and current PA balance to next tier
The system SHALL compute the eligible reincarnation pool from final Karma only (PA ignored, dead form ignored) as: pool {oruga} WHEN Karma ≤ -50 (involution); pool {sapo, raton, ardilla, topo} WHEN -50 < Karma < +50 (T1 full, no cycle order); pool {sapo, raton, ardilla, topo, halcon, zorro, lobo} WHEN Karma ≥ +50 (additive floor: good karma adds T2, never guarantees it). The system SHALL then draw one form uniform-azar from the pool; Lobo draws like any T2 with no exception. The first life is pure azar over all 8 species and never evaluates the matrix.

#### Scenario: Involution as punishment
- **WHEN** a life ends with Karma -70 (any PA, any dead form)
- **THEN** the drawn next form is Oruga with an involution reason citing Karma ≤ -50

#### Scenario: Neutral draws any T1
- **WHEN** a life ends with Karma +10 as Ratón with any PA
- **THEN** the drawn next form is one of Sapo, Ratón, Ardilla, Topo with a neutral reason citing the unlocked T1 pool, and the dead form does not bias the draw

#### Scenario: High karma unlocks but does not guarantee T2
- **WHEN** a life ends with Karma +60
- **THEN** the draw comes from the 7-member pool including Halcón, Zorro and Lobo, with a reason citing Karma ≥ +50 unlocking T2

#### Scenario: First life is pure azar
- **WHEN** the run starts via the single Nacer action
- **THEN** the first life begins as a uniform-azar draw over all 8 species with no karma or PA evaluated

### Requirement: Karma carries 20% and remaining PA persists
The system SHALL start the next life with Karma equal to 20% of the previous final Karma (rounded) and SHALL carry the remaining PA balance unchanged as shop wallet only (spent PA never returns; PA never gates the pool).

#### Scenario: Soft redemption across lives
- **WHEN** a life ends with Karma +50 or -50
- **THEN** the next life starts at Karma +10 or -10 respectively with identical PA

#### Scenario: Spending never affects the pool
- **WHEN** a life earns 120 PA but spends 50 mid-life
- **THEN** Judgment draws the pool from Karma alone; the remaining 70 PA carries as shop wallet

### Requirement: Judgment screen explains cause and outcome
The system SHALL show final Karma, survived time, the unlock reason citing the karma floor and eligible pool, the drama line "los dioses eligen que reencarnes en..." with one illuminated block per eligible species that cycles until the drawn form settles, the settled species/tier, and the last up-to-4 life events, with a Reincarnar button and R shortcut. No pick buttons and no reroll exist.

#### Scenario: Player understands why
- **WHEN** Vida reaches 0
- **THEN** the Judgment overlay appears showing stats, floor reason, eligible pool blocks, the cycling reveal settling on the drawn form, recent history, and a working reincarnate control

#### Scenario: No choice controls render
- **WHEN** any Judgment opens
- **THEN** no T2-pick buttons and no Choose-form buttons are shown or enabled

### Requirement: Reincarnation keeps persistent world
The system SHALL keep the persistent world across reincarnation (food, carrion, agents carry over; saplings convert in place); the first life starts via azar startRun() with no matrix evaluation. The new life restores full Vida, resets life timer and per-life history, adaptations, carried nut, and dug burrows, and applies carried Karma/PA.

#### Scenario: World survives death
- **WHEN** the player confirms reincarnation
- **THEN** uneaten food, unconsumed carrion, and surviving AI agents remain in the same world; the new life starts with full Vida and carried Karma/PA

#### Scenario: Planted saplings convert in place
- **WHEN** a life ended with 2 sapling carry banked
- **THEN** the next world holds those saplings converted to berry bushes and sapling carry resets to 0

## REMOVED Requirements

### Requirement: Judgment offers lateral form choice for PA
**Reason**: Azar replaces negotiation; no picks and no reroll by design.
**Migration**: Delete `pickT2`/`chooseForm` paths, T2-pick and Choose-form buttons, and the 15 PA cost; PA remains only as the adaptation shop wallet.
