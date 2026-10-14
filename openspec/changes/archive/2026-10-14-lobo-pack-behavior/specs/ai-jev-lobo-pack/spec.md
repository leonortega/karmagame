## Purpose

Pack hunting and feeding let AI lobos act as the pack apex they are: sharing food with hungry packmates and ranging widely for carrion, so the migrated lobo kit is exercised in every run instead of idling on two-candidate menus.

## ADDED Requirements

### Requirement: Regurg reaches any hungry lobo packmate

The system SHALL let an AI lobo regurgitate for any hungry lobo packmate — company or fauna — within groom range when slot 2 is ready and its HP is above the regurg cost, through the same HP/karmic path as the player. The JEV candidate menu SHALL offer `regurg` for fauna packmates on the same terms as company mates.

#### Scenario: Fauna packmates feed each other

- **WHEN** two fauna lobos stand within groom range, one with HP above the regurg cost and slot 2 ready and the other hungry
- **THEN** the fed lobo gains HP and hambre through the same path as a company feed, and the feeder gains the same karma

#### Scenario: Menu offers fauna regurg

- **WHEN** an AI lobo's only hungry in-range packmate is a fauna lobo
- **THEN** its candidate menu includes `regurg` with that mate as target

### Requirement: Hungry seek ranges beyond perception

The system SHALL offer `seek_carrion` to a hungry AI lobo for carrion up to `wanderSeekRange` away (not just within 280 perception), mirroring the ladder's urgent-seek trek. The legal-only contract is unchanged: the candidate appears only when hungry and only for existing carrion.

#### Scenario: Distant carrion is seekers-eligible

- **WHEN** a hungry AI lobo has no carrion within perception but one lies within wander-seek range
- **THEN** its candidate menu includes `seek_carrion` with that carrion as target
