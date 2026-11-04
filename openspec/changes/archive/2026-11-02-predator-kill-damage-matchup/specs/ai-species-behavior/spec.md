## MODIFIED Requirements

### Requirement: AI predators use full kill verbs
Predator agents (zorro, lobo, halcon) use their full kill verbs against AI and player agents: pounce (zorro), dive (halcon), strike (halcon vs predator), and cede (zorro). All kill verbs follow the same matchup-derived values as the player: base = `PRED[attacker].damage × (attacker_size / victim_size)`, scaled by age, so a kill resolves only when scaled damage meets or exceeds the victim's vida.

#### Scenario: AI Zorro pounces on AI Ratón
- **WHEN** an AI Zorro agent is adjacent to an AI Ratón agent and `pounceCd` is 0
- **THEN** the Ratón takes matchup-scaled damage; if lethal it dies, a carrion spawns, and the Zorro gains HP per `pounceHp`, otherwise it survives wounded and may flee or hide

#### Scenario: AI Halcon dive-kills AI mate
- **WHEN** an AI Halcon agent dives on an adjacent AI company agent
- **THEN** the mate takes matchup-scaled damage; if lethal a carrion spawns at the kill position
