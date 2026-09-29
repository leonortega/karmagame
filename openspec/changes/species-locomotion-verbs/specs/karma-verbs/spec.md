# Spec Delta: karma-verbs

## Purpose

Each species gets a 5-verb action bar on keys 1–5 drawn from real animal behavior. Verbs cost vida/PA with per-verb cooldowns, pay karma in the right context, and are cast by AI agents of the same species through the same table — the action bar is each animal's ecological role made playable.

## ADDED Requirements

### Requirement: Five species verbs on keys 1–5
The game SHALL define `VERB_DEFS[speciesKey]` with exactly 5 verbs per species (slot 1–5), each with name, description, cooldown, and real costs (`costHp`, `costPa`). Keys 1–5 SHALL cast the matching verb; when the shop overlay is open, keys 1–4 SHALL keep buying shop items instead. E/Q/B/H/V/C behavior SHALL be unchanged.

#### Scenario: Cast a verb
- **WHEN** the player as topo presses 1 with the shop closed and cooldown ready
- **THEN** the aerate verb executes, its cooldown starts, and its costs are paid

#### Scenario: Shop keeps its keys
- **WHEN** the player presses 2 while the shop overlay is open
- **THEN** the shop buys Estómago grande as before, and no verb is cast

#### Scenario: Dead form cannot cast
- **WHEN** the player presses any verb key while dead or while the verb is on cooldown
- **THEN** nothing happens

### Requirement: Verbs cost vida or PA and pay contextual karma
Each verb SHALL apply its declared costs before its effect, and karma payouts SHALL be context-conditional (e.g. regurgitate requires a hungry conspecific, cull-weak pays bonus karma when the target's HP is below 30%). Costs that bring Vida to 0 SHALL trigger the normal death path. Existing verb karma values SHALL be preserved when migrating (shout +30, plant +10, aerate +3, groom +5, cede +15, strike +5/+20, prudent +2, pest +3).

#### Scenario: Paying real costs
- **WHEN** the oruga casts seda-cuerda
- **THEN** its Vida drops by the verb's costHp and PA by costPa before the effect resolves

#### Scenario: Context gates the reward
- **WHEN** the lobo uses regurgitate-feed with no hungry conspecific nearby
- **THEN** the verb fails without paying its costs or granting karma

#### Scenario: Death by cost is judged
- **WHEN** a verb cost reduces Vida to 0
- **THEN** the Judgment sequence opens as with any death

### Requirement: AI casts the same verbs contextually
AI agents of each species SHALL cast their own verbs through the same VERB_FN/castVerbFor core with the same cooldowns and costs, driven by per-verb context rules (hunger, nearby entities, threat state) evaluated before idle fallthrough in the species AI functions.

#### Scenario: The mole aerates on its own
- **WHEN** an AI topo with cooldown ready stands on fresh ground
- **THEN** it casts aerate through the same code path as the player and earns the same karma

#### Scenario: Parity of effects and ledgers
- **WHEN** an AI ardilla casts plant-oak
- **THEN** the world outcome (seedling, oak growth) matches the player's verb and the karma lands in the agent's ledger
