## MODIFIED Requirements

### Requirement: Lifelike animal rendering
The system SHALL draw every world entity as a cohesive emoji glyph over a solid opaque color medal with a size tier by category: animals at animal size with per-species offsets (medal in species color), plants/foods at food size (medal in type color), terrain and small decor at terrain size, except landmark trees (old-oak, hollow-tree) which render larger as landscape anchors. Each form SHALL use its established species emoji, each food its food emoji, each refuge/rock/seedling its terrain emoji, rendered through shared helpers that apply category size, medal backing, shadow, and facing. Vector portrait painters SHALL NOT be the primary sprite. Info overlays SHALL remain: label pills with food counts and refuge names, HP bars with karma over agents, predator outline rings, reveal/tracking rings, vision circle, meadow, and grid. Depleted patches SHALL render a cross with a recovering tag, carrion SHALL use a per-stage icon (fresh, stale, rotten) with a freshness label, and oak-tree seedlings SHALL render as a young tree. Predator NPCs SHALL reuse their species emoji at animal size with a red outline and warning glyph. The legend and game-state warning texts are UI chrome and remain text.

#### Scenario: Silhouettes differ
- **WHEN** all seven forms stand side by side
- **THEN** each is recognizable by its emoji glyph without reading the HUD

#### Scenario: The map reads at a glance
- **WHEN** any gameplay moment is frozen
- **THEN** foods, refuges, rocks, and animals are identifiable by emoji kind and size tier, not only by color

#### Scenario: Size tiers by category
- **WHEN** an animal, a food patch, and a rock appear together
- **THEN** the animal glyph renders largest, the food glyph medium, and the rock/decor glyph smallest, except landmark trees (old-oak, hollow-tree) which render larger as landscape anchors

#### Scenario: Apex reads larger than prey
- **WHEN** a Lobo and an Oruga appear together
- **THEN** the Lobo emoji renders larger than the Oruga emoji within the animal band
