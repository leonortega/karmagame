## MODIFIED Requirements

### Requirement: Verbs cost vida or PA and pay contextual karma
Each verb SHALL apply its declared costs before its effect, and karma payouts SHALL be context-conditional (e.g. regurgitate requires a hungry conspecific, cull-weak pays bonus karma when the target's HP is below 30%). Costs that bring Vida to 0 SHALL trigger the normal death path. Existing verb karma values SHALL be preserved when migrating (shout +30, plant +10, aerate +3, groom +5, cede +15, strike +5/+20, prudent +2, pest +3). Every verb SHALL additionally write the shared world or another animal (entity added, removed, or marked; HP/hambre moved; another body displaced; hunter given restT; mate given saved/rallyT/cleanse; carrion flagged ceded; shared reveal left in the world). Karma, PA, vision, self-heal, self-hide, or self-teleport alone SHALL NOT satisfy a verb. A cast whose world/other precondition is absent SHALL fail without paying costs, starting cooldown, or granting karma/PA/vida.

#### Scenario: Paying real costs
- **WHEN** the oruga casts seda-cuerda
- **THEN** its Vida drops by the verb's costHp and PA by costPa before the effect resolves

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

### Requirement: AI casts the same verbs contextually
AI agents of each species SHALL cast their own verbs through the same VERB_FN/castVerbFor core with the same cooldowns and costs, driven by per-verb context rules (hunger, nearby entities, threat state) evaluated before idle fallthrough in the species AI functions. No verb SHALL refuse an IA actor: every verb branches on actor instead of returning false for agents, and player and agent casts of the same verb SHALL produce the same world outcome with the same costs, cooldowns, and karma values in the caster's ledger. E-duplicates SHALL NOT remain bare aliases: prudent, pounce, and dive either gain their own world/other effect or are replaced.

#### Scenario: The mole aerates on its own
- **WHEN** an AI topo with cooldown ready stands on fresh ground
- **THEN** it casts aerate through the same code path as the player and earns the same karma

#### Scenario: Parity of effects and ledgers
- **WHEN** an AI ardilla casts plant-oak
- **THEN** the world outcome (seedling, oak growth) matches the player's verb and the karma lands in the agent's ledger

#### Scenario: No player-only verbs remain
- **WHEN** an AI halcon with thermal ready and prey in range casts thermal
- **THEN** the same circling-shadow mark appears as for the player and the same cooldown starts

#### Scenario: AI failure matches player failure
- **WHEN** an AI lobo casts escort with no threatened mate in range
- **THEN** nothing moves, no cooldown starts, and no karma is granted, exactly as for the player

## ADDED Requirements

### Requirement: Social verbs touch the other body
Chorus and groom SHALL move more than karma: chorus SHALL steer nearby conspecifics toward the caller's water (or leave a foam ring that slows ground hunters crossing it); groom SHALL cleanse the mate (remove mimic/toxin effect) and grant the mate a small heal. A cast with no mate in range SHALL fail without costs, cooldown, or karma.

#### Scenario: Chorus summons
- **WHEN** a sapo casts chorus with two conspecifics in range
- **THEN** both conspecifics steer toward the caller's water and the caller gains karma per singer

#### Scenario: Groom cleans
- **WHEN** a raton casts groom on a mate carrying a mimic/toxin effect
- **THEN** the effect is removed from the mate, the mate gains a small heal, and the caster gains karma

### Requirement: Radar verbs leave a shared mark
Scout and thermal SHALL leave a mark the pack can use: scout SHALL drop a scent-post entity sharing reveal with mates in radius while it lasts; thermal SHALL project a circling-shadow mark that scatters prey in its disc and is visible to others. Solo vision with no shared mark SHALL NOT grant karma.

#### Scenario: Scout shares reveal
- **WHEN** a raton casts scout with a mate in radius
- **THEN** a scent post appears and the mate shares the reveal for its duration

#### Scenario: Thermal scatters
- **WHEN** a halcon casts thermal over prey
- **THEN** a shadow mark appears and prey in its disc flees

### Requirement: Harvest verbs consume stock
Bark SHALL consume oak stock and set a stripped state with a regrow timer; worm SHALL unearth a real insect entity from refuge soil on a refuge charge (the charge is consumed). Healing or PA with no stock consumed SHALL fail without costs, cooldown, or karma.

#### Scenario: Bark wounds the oak
- **WHEN** an ardilla casts bark on an oak with stock
- **THEN** the oak loses stock, gains a stripped state, and the caster gains PA and karma

#### Scenario: Worm spends the refuge
- **WHEN** a topo casts worm on a refuge with charge
- **THEN** the charge is consumed, an insect entity appears, and eating it grants vida

### Requirement: Escape and guard verbs touch hunter or mate
Silk SHALL leave a sticky thread entity slowing the hunter that crosses it; burrowin SHALL leave a wallow pit entity (sip plus slows ground hunters); bristle SHALL sting immediately (hunter in range gains restT now); escort SHALL shepherd the mate toward cover and deter nearby hunters. Self-move, self-hide, or an armed-only flag with no immediate hunter/mate write SHALL fail without costs, cooldown, or karma.

#### Scenario: Silk snares
- **WHEN** an oruga casts silk with a hunter in range
- **THEN** the oruga displaces and a thread entity appears that slows the hunter crossing it

#### Scenario: Burrowin leaves a wallow
- **WHEN** a sapo casts burrowin
- **THEN** the sapo hides and a wallow pit entity appears that others can sip from and that slows ground hunters

#### Scenario: Escort guards
- **WHEN** a lobo casts escort on a threatened mate
- **THEN** the mate is shepherded toward cover and nearby hunters are deterred

### Requirement: Tunnel verbs build the network
Tunneline SHALL link two dug burrows (travel between them) or raise a burrow's capacity; a write-only flag SHALL NOT count. A cast with no second burrow or capacity to raise SHALL fail without costs, cooldown, or karma.

#### Scenario: Tunneline links burrows
- **WHEN** a topo casts tunneline with two dug burrows in range
- **THEN** both burrows join one network and the caster gains karma

### Requirement: Every reworked verb is JEV-handleable
Every reworked verb SHALL be offerable in its species JEV candidate menu from legal moves only (cooldown, range, stock/charge, hunter/mate precondition, HP/PA affordability checked at menu build), rankable by the sidecar which SHALL only rank and never invent moves, and applicable through the same functions as the player. Wander SHALL always be present so the ranking always has an executable target. Stale answers (actor dead, target gone, stock eaten, refuge gone) and picks failing affordability at apply time SHALL resolve to continued steering or wander with no costs burned and no karma granted, never to a no-op freeze. The state text sent to the ranker SHALL carry the need behind the verb (hunger/thirst/pressure/charge) so ranking can weigh it.

#### Scenario: Legal-only menus
- **WHEN** an AI ardilla with bark on cooldown or no oak stock in range needs a menu
- **THEN** bark is absent, wander is present, and no ranking can select bark

#### Scenario: Ranked apply matches player outcome
- **WHEN** the sidecar ranks groom first for an AI raton with a fouled mate in range
- **THEN** the mate is cleansed and healed through the same path as the player and karma lands in the agent's ledger

#### Scenario: Stale answers fall back to wander
- **WHEN** a ranked worm pick reaches an AI topo whose refuge charge was spent before apply
- **THEN** the topo keeps steering or wanders with no HP, PA, cooldown, or karma change
