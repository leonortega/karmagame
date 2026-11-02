## MODIFIED Requirements

### Requirement: Sustainable eating vs last-fruit selfish act
The system SHALL grant food-specific Vida/PA only to diet-listed eaters (berries +15/+5, apples +22/+8, carrots +18/+5, mushrooms +10/+0, leaves +12/+3, nuts +18/+5, insects +10/+3), SHALL refuse off-diet attempts with no effect plus a hint message, and SHALL, for any non-leaf fruit patch, consume the entire remaining patch in a single bite: the plant dies, Karma drops by 15 (player only), and nutrition equals (amount-1) sustainable fruits (each at its food HP/PA) plus the final-fruit bonus of 20 Vida (no PA on the final fruit). AI grazers receive Vida and hambre only, with no PA or karma. Leaf-clumps are exempt: they regrow 1 leaf per 60s, keep multi-bite sustainable eating, and never trigger karma.

#### Scenario: Apple pays richer
- **WHEN** a non-leaf fruit patch containing apples is consumed in one bite
- **THEN** each non-final apple contributes +22 Vida and +8 PA toward the total, alongside the final-fruit bonus

#### Scenario: Sustainable eat
- **WHEN** the player eats berries from a bush with 3 fruits remaining
- **THEN** all 3 fruits are consumed in one bite, the bush dies, Vida rises by 50 (2 x 15 + 20, capped at max), PA rises by 10 (2 x 5), and Karma drops by 15

#### Scenario: Selfish last fruit
- **WHEN** the player eats the only berry of a living bush
- **THEN** Vida rises by 20 (capped at max), Karma drops by 15, and that bush never regrows fruit

#### Scenario: Off-diet refused
- **WHEN** a Zorro uses E on berries
- **THEN** nothing is consumed, no values change, and a hint message appears

#### Scenario: Leaves exempt
- **WHEN** an Oruga strips a leaf-clump bare
- **THEN** no karma changes and leaves regrow over time