# Proposal: AI Behavior & Karma System

## Why

CPU animals are static map decorations — they graze and die without exhibiting the species-specific behaviors that define them. The player alone has access to dig, carry, curl, camouflage, groom, shout, and perform species-specific good deeds. Meanwhile, the karma system is exclusive to the player. This makes the ecosystem feel hollow and breaks the game's core premise: every animal has a nature that should manifest in behavior.

## What Changes

- **All 8 species get full AI behavior**: Topo digs burrows, Ardilla carries/plants nuts, Oruga curls for half-damage, Sapo camouflages and does pest control, Ratón grooms with mates and can shout, Zorro/Lobo/Halcon use all kill verbs and cede kills.
- **AI karma/PA ledger**: Every agent gets its own `karma`, `pa`, `owned`, and `lifeLog`. AI earn karma from good deeds and spend it on adaptations automatically.
- **AI shout/alert**: AI animals trigger the shout mechanic, alerting predators and scattering mates — with karma/PA rewards going to the AI agent.
- **AI auto-adaptations**: AI spend PA to buy shop items internally (no UI), choosing adaptations that suit their needs.
- **Karma ecosystem effects**: High-karma AI are harder to hunt and attract mates; low-karma AI are more vulnerable.
- **Visual indicators**: Live HP bar and karma number displayed over every animal.
- **Global functions become agent-targeted**: `addKarma`, `addPa`, `record` accept an optional agent target.

## Capabilities

### New Capabilities
- `ai-karma`: AI animals have karma/PA ledgers, perform species-specific good deeds, shout to alert ecosystem, and auto-purchase adaptations.
- `ai-species-behavior`: Every species has a full AI behavior engine — grazers eat, dig, curl, camouflage, carry, groom; predators hunt, pounce, dive, strike, cede.

### Modified Capabilities
- `living-map`: The requirement "NPC fancy verbs stay player-only" is replaced. NPC animals now perform all species-specific verbs (dig, groom, plant, shout, sense, carry, hide, curl, camouflage).
- `karma-core`: The requirement "NPC agents share the hunger-eat-die loop" is expanded — NPC agents now also earn and spend karma/PA, perform good deeds, and trigger ecosystem effects.

## Impact

- **`src/script/state.js`**: `mkAgent` gains karma/pa/owned/lifeLog fields; `addKarma`, `addPa`, `record` become agent-targeted.
- **`src/script/eat.js`**: Species-specific eat functions (`eatAsZorro`, `eatAsTopo`, etc.) become callable for AI; `digBurrow`, `carryAction` gain AI variants.
- **`src/script/game.js`**: `updateAgents` rewritten as species-aware AI engine; `groomTick`, `wanderMates` updated for AI; new `updateAgentsAI(dt)` per species.
- **`src/script/predators.js`**: Predator AI gains cede-kill and karma-strike behavior.
- **`src/script/data.js`**: `mkPredator` gains karma/pa fields; new agent-level state defaults.
- **`src/script/hud.js`**: New rendering for animal live bars and karma numbers.
- **`test/`**: New tests for AI behavior engine, AI karma mechanics, species-specific AI actions.
