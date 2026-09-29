# Spec Delta: solid-terrain

## Purpose

The map is physical: static elements (trees, rocks, plants) block movement for every brain, and trunks block ground-predator line of sight. The forest becomes terrain you navigate, not a picture you float over. The Halcón, hunting from the sky, is exempt from trunk LOS.

## ADDED Requirements

### Requirement: Static elements are solid to every agent
Refuge trees (old-oak, hollow-tree, thorn-bush), dug burrows, rocks, and living fruiting plants (bushes, shrubs, carrot patches, mushroom clusters, oak clumps) SHALL block movement. Collision SHALL resolve with circular push-out so agents slide around solids instead of sticking. Dead plants (no fruit) SHALL stop being solid. Leaf clumps, insects, and carrion SHALL remain walk-through.

#### Scenario: Player cannot walk through a trunk
- **WHEN** the player moves into an old-oak trunk
- **THEN** position resolves to the circle edge and movement slides tangentially around it

#### Scenario: AI does not phase through plants
- **WHEN** an AI grazer wanders into a berry bush
- **THEN** it is pushed out of the bush's solid radius like the player

#### Scenario: Dead plants release their space
- **WHEN** a bush is stripped dead
- **THEN** agents move through its tile until it regrows

### Requirement: Rocks obstruct
The system SHALL spawn sparse rocks (scaled by area) as decorative solids that block movement but not line of sight.

#### Scenario: Rock blocks, never hides
- **WHEN** an agent path crosses a rock
- **THEN** movement resolves around it while predators still perceive targets behind it

### Requirement: Trunks break ground-predator line of sight
Old-oak and hollow-tree trunks SHALL block perception between a ground predator (zorro, lobo, saponpc) and a target when a trunk overlaps the straight segment between them. The Halcón SHALL NOT lose targets to trunks (flies over). Rocks and plants SHALL NOT block LOS.

#### Scenario: Cover behind a trunk
- **WHEN** a Ratón stands with a hollow-tree between it and a pursuing Zorro
- **THEN** the Zorro loses the target and does not hunt it while the segment stays blocked

#### Scenario: The sky ignores wood
- **WHEN** a Halcón hunts a target behind a trunk
- **THEN** perception is unchanged; only the old-oak canopy rule (existing) still applies

### Requirement: Elements are recognizable by silhouette
Every food plant SHALL render a distinct glyph per kind: berries as a green mat with red berry dots, apples as a small canopy with red fruit, carrots as orange triangles at soil level, mushrooms as cap+stem, nuts as a trunk with brown ovals, leaves as a leaf fan. All species SHALL render eyes oriented to facing. Refuges SHALL render readable shapes: burrow as a mound with a dark hole, hollow-tree as trunk with knothole, thorn-bush as spiky cluster, old-oak as large canopy with trunk shadow. The ground SHALL show grass tufts and small flowers (deterministic per tile, no shimmer).

#### Scenario: Foods differ without color alone
- **WHEN** all six plant kinds are on screen in greyscale
- **THEN** each is still distinguishable by glyph shape

#### Scenario: Facing reads from eyes
- **WHEN** a Ratón changes movement direction
- **THEN** its eye dots move to the new facing side
