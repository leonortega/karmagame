## MODIFIED Requirements

### Requirement: Mixed-species population composition by density

The system SHALL seed and maintain a mixed-species population scaled to world area: at least one agent of every playable grazer kind (oruga, sapo, raton, ardilla, topo), at least one airborne halcon and at least two carnivores (zorro and lobo) whenever the world area supports them, with per-species target counts defined as densities (agents per unit area). Lobos SHALL be maintained as a pack of at least two: initial seeding and the respawn top-up SHALL keep no fewer than two fauna lobos so pack verbs stay reachable in every run.

#### Scenario: All playable grazers present

- **WHEN** a life starts
- **THEN** at least one agent of each grazer kind (oruga, sapo, raton, ardilla, topo) exists in the roster

#### Scenario: Predator presence by tier

- **WHEN** the player species is Tier 2
- **THEN** at least one zorro and one lobo agent exist; if the player is lobo, at least one zorro exists

#### Scenario: Densities scale with area

- **WHEN** the world area increases versus baseline
- **THEN** agent counts scale proportionally so per-agent food availability stays comparable

#### Scenario: Lobo pack floor

- **WHEN** a life starts or the respawn window elapses with fewer than two fauna lobos alive
- **THEN** the roster is topped up to at least two fauna lobos, so AI regurg and pack hunting stay reachable
