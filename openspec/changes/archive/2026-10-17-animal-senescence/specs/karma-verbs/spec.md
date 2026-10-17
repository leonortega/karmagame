## MODIFIED Requirements

### Requirement: Verbs cost vida or PA and pay contextual karma
Each verb SHALL apply its declared costs before its effect, SHALL scale cooldowns and channel durations by caster age stage per `animal-senescence` (old animals act slower; costs unchanged), and karma payouts SHALL be context-conditional (e.g. regurgitate requires a hungry conspecific, cull-weak pays bonus karma when the target's HP is below 30%). Costs that bring Vida to 0 SHALL trigger the normal death path. Existing verb karma values SHALL be preserved when migrating (shout +30, plant +10, aerate +3, groom +5, cede +15, strike +5/+20, prudent +2, pest +3). Every verb SHALL additionally write the shared world or another animal (entity added, removed, or marked; HP/hambre moved; another body displaced; hunter given restT; mate given saved/rallyT/cleanse; carrion flagged ceded; shared reveal left in the world). Karma, PA, vision, self-heal, self-hide, or self-teleport alone SHALL NOT satisfy a verb. A cast whose world/other precondition is absent SHALL fail without paying costs, starting cooldown, or granting karma/PA/vida. Failed kill verbs SHALL deal partial age-scaled damage and burn cooldown with no feast heal.

#### Scenario: Paying real costs
- **WHEN** the oruga casts seda-cuerda
- **THEN** its Vida drops by the verb's costHp and PA by costPa before the effect resolves

#### Scenario: Old hands are slower
- **WHEN** a frail topo casts aerate versus a prime topo with the same cooldown ready
- **THEN** the frail cast carries the longer age-scaled cooldown before it can cast again

#### Scenario: Context gates the reward
- **WHEN** the lobo uses regurgitate-feed with no hungry conspecific nearby
- **THEN** the verb fails without paying its costs or granting karma

#### Scenario: Death by cost is judged
- **WHEN** a verb cost reduces Vida to 0
- **THEN** the Judgment sequence opens as with any death

#### Scenario: Solo karma does not satisfy a verb
- **WHEN** a sapo casts chorus with no conspecific in range
- **THEN** the cast fails without paying costs, starting cooldown, or granting karma

#### Scenario: Solo radar does not satisfy a verb
- **WHEN** a raton casts scout with no mate to share it with
- **THEN** no reveal is left in the world and no karma is granted

### Requirement: Every reworked verb is JEV-handleable
Every reworked verb SHALL be offerable in its species JEV candidate menu from legal moves only (cooldown, range, stock/charge, hunter/mate precondition, HP/PA affordability checked at menu build), rankable by the sidecar which SHALL only rank and never invent moves, and applicable through the same functions as the player. Wander SHALL always be present so the ranking always has an executable target. Stale answers (actor dead, target gone, stock eaten, refuge gone) and picks failing affordability at apply time SHALL resolve to continued steering or wander with no costs burned and no karma granted, never to a no-op freeze. The state text sent to the ranker SHALL carry the need behind the verb (hunger/thirst/pressure/charge) plus age signals (self stage, hunter/prey age stage, frailty/force hint) so ranking can weigh age.

#### Scenario: Legal-only menus
- **WHEN** an AI ardilla with bark on cooldown or no oak stock in range needs a menu
- **THEN** bark is absent, wander is present, and no ranking can select bark

#### Scenario: Ranked apply matches player outcome
- **WHEN** the sidecar ranks groom first for an AI raton with a fouled mate in range
- **THEN** the mate is cleansed and healed through the same path as the player and karma lands in the agent's ledger

#### Scenario: Stale answers fall back to wander
- **WHEN** a ranked worm pick reaches an AI topo whose refuge charge was spent before apply
- **THEN** the topo keeps steering or wanders with no HP, PA, cooldown, or karma change

#### Scenario: Ranker sees age
- **WHEN** a frail AI raton wounded by a failed pounce needs a menu with a prime zorro near and a refuge in range
- **THEN** its state text carries its frail stage and the hunter's prime stage so flee-to-refuge can outrank wandering
