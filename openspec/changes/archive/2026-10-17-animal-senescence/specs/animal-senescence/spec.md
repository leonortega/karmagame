## Purpose

Gives every animal a per-species aging arc where years reduce speed, force, and recovery until natural death, so prime-vs-old matchups resolve through damage instead of scripts.

## ADDED Requirements

### Requirement: Per-species senescence stages and lifespan

The system SHALL define a per-species senescence row (lifespan in animal-years, prime span, per-stat decay rates and floors for speed, attack force, vida-regen, and action/cooldown time, plus victim frailty growth) alongside the seconds-per-year table. Age stage SHALL derive from animal-years lived this life: prime, worn, frail. All numbers SHALL live in documented tuning (no magic numbers).

#### Scenario: Short-lived crashes fast, apex lasts

- **WHEN** an oruga and a lobo reach the same animal-years value in the frail band
- **THEN** the oruga is nearer its lifespan cap than the lobo and decays harder per year

#### Scenario: Stages advance monotonically

- **WHEN** an animal survives without eating or drinking
- **THEN** its stage never moves backward within the life and resets at reincarnation

### Requirement: Age-scaled speed, recovery, and action times

The system SHALL scale effective movement velocity, vida-regen rate, and verb/action cooldowns and durations by the attacker's age stage and species multipliers. Older SHALL mean slower steps, weaker regen, and longer times to dig, groom, channel thermals, howl, and escort. Gait modes SHALL NOT change (hop stays hop, inchworm stays inchworm) — only magnitude and timing scale.

#### Scenario: Old legs lose the open-field race

- **WHEN** a frail raton and a prime raton hold the same direction with equal needs
- **THEN** the prime raton covers more distance over the same time

#### Scenario: Old topo digs slower

- **WHEN** a frail topo with dig ready digs versus a prime topo
- **THEN** the frail topo's cooldown or channel is longer by the documented age factor

### Requirement: Two-sided force damage

The system SHALL resolve every damaging kill path (predator contact bites, zorro pounce, halcon dive, lobo cull, defensive strikes) as `damage = base x attacker_force(age stage, species) x victim_frailty(age stage, species)`. Attacker force SHALL fall with age; victim frailty SHALL rise with age. Curl halving, bristle reflection, and invulnerability windows SHALL apply to the scaled result, not the base.

#### Scenario: Old zorro fails on prime raton

- **WHEN** a frail zorro pounces a prime raton at full vida
- **THEN** the scaled damage is below the raton's current vida and no kill resolves

#### Scenario: Prime hunter punishes old prey

- **WHEN** a prime zorro bites a frail raton with the same base damage
- **THEN** the dealt damage exceeds the same bite against a prime raton

### Requirement: Failed kills wound and open an escape window

The system SHALL treat `damage >= victim current vida` as the only instakill: the victim dies, a fresh carrion spawns, and wasteful-kill karma applies as today. When `damage < victim vida`, the victim SHALL take the partial damage, the attacker SHALL burn its cooldown, and the victim SHALL get a decision-gated escape chance: player victims decide freely, AI victims flee or hide only if their decision layer selects it. Failed kills SHALL NOT grant feast heals or sated state.

#### Scenario: Failed pounce wounds and chases

- **WHEN** a frail zorro pounces a prime raton and damage falls short of its vida
- **THEN** the raton loses exactly the scaled damage, the zorro enters pounce cooldown with no heal, and the raton may flee or hide on its next decision

#### Scenario: Lethal damage still kills outright

- **WHEN** scaled damage meets or exceeds victim vida
- **THEN** the victim dies, carrion spawns, and killer gains follow the existing needed-vs-wasteful rule

### Requirement: Natural death by old age

The system SHALL kill by age: when lived animal-years reach the species lifespan, the animal dies with the normal death path (carrion for AI, Judgment with a "vejez" reason for the player). Well-fed sheltered animals SHALL still die at the cap; nothing outlives its species.

#### Scenario: Sheltered elder dies anyway

- **WHEN** a frail animal with full hambre and sed reaches its lifespan in animal-years
- **THEN** it dies of age even with no damage, hunger, or predator involved

#### Scenario: Age death leaves remains and judgment

- **WHEN** the player dies of age
- **THEN** the Judgment screen cites old age and reincarnation proceeds as with any death
