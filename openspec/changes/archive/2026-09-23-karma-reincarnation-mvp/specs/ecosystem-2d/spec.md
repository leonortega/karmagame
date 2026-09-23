# Spec Delta

## Purpose

Provide the explorable 2D ecosystem (map, food, threats, controls, feedback) where karma decisions happen through visible movement, eating, and alerting.

## ADDED Requirements

### Requirement: Bounded world with camera follow
The system SHALL confine play to a bounded 2D world with obstacles-free movement and SHALL keep the camera centered on the player within world bounds.

#### Scenario: Movement stays in bounds
- **WHEN** the player moves toward any world edge for an extended time
- **THEN** the creature stops at the boundary and never leaves the world

### Requirement: Keyboard controls for move, eat, shout, shop
The system SHALL support WASD/arrows for movement, E for eat/strike, Q for shout, B to open/close the mid-life shop, number keys 1-4 to buy shop items, and R to reincarnate from the Judgment screen.

#### Scenario: Basic control mapping
- **WHEN** the user presses movement, E, Q, B, number, or R keys in their valid contexts
- **THEN** the corresponding move, eat/strike, shout, shop toggle, purchase, or reincarnate action occurs

### Requirement: Bushes hold finite fruit and die permanently
The system SHALL spawn 7 living bushes with 3 fruits each per life and SHALL mark a bush permanently dead (grey, no fruit) once its last fruit is eaten.

#### Scenario: Bush exhaustion is permanent for the life
- **WHEN** all fruits of a bush are consumed
- **THEN** the bush remains dead with zero fruit until the next reincarnation generates a fresh world

### Requirement: Predators wander and chase with contact damage
The system SHALL spawn 3 predators that wander when the player is far, chase when the player is within range (or lured), and deal 28 contact damage with 1s player invulnerability afterwards. Oruga lives SHALL face faster predators.

#### Scenario: Chase and bite
- **WHEN** the player enters predator perception range
- **THEN** at least one predator pursues, and on contact Vida drops by 28 and further hits are ignored for 1s

### Requirement: Congeners wander and flee when saved
The system SHALL spawn 4 congeners that wander normally and flee from predators after a successful shout.

#### Scenario: Alert saves congeners
- **WHEN** the player shouts successfully
- **THEN** congeners switch to fleeing behavior away from predators

### Requirement: HUD and cause-effect log are always visible
The system SHALL display species/tier, Vida with max, Karma value with polarity, PA, elapsed time, shout cooldown state, and the last 5 cause-effect log entries with good/bad/info polarity.

#### Scenario: Player reads consequences
- **WHEN** any karma-relevant event occurs
- **THEN** the HUD values update immediately and a new log entry appears at the top describing cause and effect

### Requirement: Mid-life shop runs in real time
The system SHALL open the shop overlay on B without pausing the world (predators keep hunting, hunger keeps draining), SHALL close it on B, number-key purchase, or Escape, SHALL list each item with cost, effect, and affordable/owned state, and SHALL log every purchase as a cause-effect entry.

#### Scenario: Shopping under pressure
- **WHEN** the player opens the shop while a predator chases
- **THEN** the predator keeps moving and can still deal contact damage while the overlay is open

#### Scenario: Death wins over shop
- **WHEN** Vida reaches 0 while the shop overlay is open
- **THEN** the shop closes and the Judgment screen appears instead
