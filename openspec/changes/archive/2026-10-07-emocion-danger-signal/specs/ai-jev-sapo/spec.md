## Purpose

Local emocion appraisal for sapo macro decisions stays truthful under threat: hunter pressure reads as fear even when the trophic threat flag cannot fire.

## ADDED Requirements

### Requirement: Pressure appraises Miedo
When a macro answer carries no `emocion` label, the locally appraised fallback SHALL return `Miedo` whenever hunter pressure is near, checked in the same first position as the trophic threat flag; carrying or handling a nut SHALL appraise `Esperanza`, hunger SHALL appraise `Hambre`, and none of these SHALL appraise anything otherwise. The label SHALL surface only in HUD/feed flavor and SHALL never gate execution.

#### Scenario: Pressure reads as fear

- **WHEN** a label-less answer reaches a sapo with hunter pressure near
- **THEN** the appraised label is `Miedo` even while the sapo is also hungry

#### Scenario: Calm hunger reads as hunger

- **WHEN** a label-less answer reaches a sapo with no pressure and no threat nearby
- **THEN** the appraised label stays `Hambre` exactly as today
