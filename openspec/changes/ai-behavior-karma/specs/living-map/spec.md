# Spec Delta: living-map

## Purpose

Deltas to the living-map capability for AI behavior and karma system. The previous non-goal "NPC fancy verbs: player-only" is reversed: NPC animals now perform all species-specific verbs.

## MODIFIED Requirements

### Requirement: Fancy verbs stay player-only
**Reason**: Reversed — NPC animals now perform all species-specific verbs (dig, groom, plant, shout, sense, carry, hide, curl, camouflage) as part of the AI behavior engine.
**Migration**: This requirement is removed and replaced by the `ai-species-behavior` and `ai-karma` capabilities. All NPC fancy verbs are now implemented for AI agents with the same mechanics as the player.

### Requirement: NPC fancy verbs stay player-only
- **WHEN** an AI agent is near a refuge, nut, or predator
- **THEN** it **now** digs, grooms, plants, shouts, senses, carries, hides via H-equivalent, curls, and camouflages according to its species behavior; it uses wander, graze, flee, hunt, strike, pounce, dive, and cede behaviors
- **Scenario**: AI Topo digs a burrow near a predator
  - **WHEN** an AI Topo agent's `digCd` is 0 and `dug` < 3
  - **THEN** a `burrow-M` refuge is created at the agent's position and the agent gains +3 karma
- **Scenario**: AI Sapo camouflages from Zorro
  - **WHEN** an AI Sapo agent is motionless for 2s outside a refuge
  - **THEN** `camouflaged()` returns true and Zorro predators do not track the agent
- **Scenario**: AI Ardilla carries and plants nuts
  - **WHEN** an AI Ardilla agent finds an oak with nuts
  - **THEN** it picks up a nut (`carriedNut: true`) and can plant it for +10 karma

## ADDED Requirements

### Requirement: AI agent visual indicators
Every AI agent rendered on the map SHALL display a live HP bar and karma number above it. The HP bar is proportional to `agent.hp / maxHp`. The karma number is an integer, green when positive, red when negative.

#### Scenario: AI agent rendered with live indicators
- **WHEN** an AI agent is on the map
- **THEN** a small HP bar and karma number are displayed above the agent sprite
- **WHEN** the agent's karma is positive
- **THEN** the karma number is rendered in green
- **WHEN** the agent's karma is negative
- **THEN** the karma number is rendered in red
