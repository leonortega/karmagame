## ADDED Requirements

### Requirement: Wander travel is purposeful

Whenever an agent (AI fauna, company mate, or hunter acting without a hunt target) has no other intent, deed, or reflex to execute, it SHALL steer toward the nearest point of interest instead of random-walking: nearest edible food first, else nearest water, else nearest fitting cover, else nearest company, else a short random step only when nothing qualifies. This changes movement targets only: no karma, cost, cooldown, or gait changes. The possessed (player-controlled) agent is exempt and keeps free control. Oruga and sapo are exempt at the terminal wander tail: their stillness-gated defenses (curl, camouflage per `ai-species-behavior`) require motionlessness, so they keep accumulating stillness instead of traveling — the defense counts as the deed.

#### Scenario: Idle grazer heads for food

- **WHEN** a raton with wander intent has no contact food but an edible patch lies within the TUNING wander-seek range
- **THEN** it moves toward that patch each tick instead of drifting randomly

#### Scenario: Thirsty wanderer heads for water

- **WHEN** a wandering agent has no edible food in range but water is the nearest point of interest
- **THEN** it moves toward that water each tick

#### Scenario: Nothing nearby, small step

- **WHEN** a wandering agent has no food, water, cover, or company anywhere in range
- **THEN** it takes a short random step (bounded jitter, same as today) rather than freezing

#### Scenario: Player control untouched

- **WHEN** the possessed agent holds no direction
- **THEN** it stays put exactly as today; purposeful travel never moves the player

#### Scenario: Stillness defenses keep their stillness

- **WHEN** an oruga or sapo with wander intent has no food, water, or other trigger
- **THEN** it keeps accumulating stillness (curl/camouflage path) instead of traveling
