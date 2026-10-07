## Purpose

Local emocion appraisal stays truthful at the hunger floor: a starving animal reads as urgent no matter its temperament.

## ADDED Requirements

### Requirement: Floor hunger appraises Urgencia
When a macro answer carries no `emocion` label and the agent's `hambre` sits at or below 30, the locally appraised fallback SHALL return `Urgencia`, checked after danger (`Miedo`) and before `Esperanza`/`Hambre`. The label SHALL surface only in HUD/feed flavor and SHALL never gate execution.

#### Scenario: Starving reads as urgent

- **WHEN** a label-less answer reaches an agent with `hambre` 25, whatever its caution traits
- **THEN** the appraised label is `Urgencia`, not `Hambre`

#### Scenario: Fed stays quiet

- **WHEN** a label-less answer reaches an agent with `hambre` 80 and no pressure, threat, or carried nut
- **THEN** the appraised label stays `Hambre` exactly as today
