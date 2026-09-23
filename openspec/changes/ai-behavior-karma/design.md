# Design: AI Behavior & Karma System

## Context

See proposal.md for motivation. Current state (from `living-map` design): `state` is a single player object; `addKarma`/`addPa`/`record` write exclusively to `state`; `updateAgents` is a simple hunger→eat→die loop; all species-specific verbs (dig, curl, camouflage, carry, groom, shout) are player-gated. The `design.md` explicitly lists "NPC fancy verbs: player-only" as a Non-Goal, which this change reverses. The `update()` loop in `game.js` runs `groomTick`, `updatePredators`, `updateAgents`, `wanderMates` sequentially. Predators already have a state machine (wander/hunt/flee/camp); grazers have none.

## Goals / Non-Goals

**Goals:**
- Every AI agent exhibits species-appropriate behavior matching the player's full kit.
- AI agents have karma/PA ledgers and earn/spend karma identically to the player.
- AI auto-buy adaptations from the shop using PA (no UI, internal logic).
- AI shout to alert the ecosystem, with karma/PA rewards to the AI.
- Karma levels affect ecosystem interactions (high-karma animals are harder prey, attract mates).
- Visual indicators (live bar + karma number) over every animal.

**Non-Goals:**
- AI UI shop overlay: AI buy internally; no DOM buttons for NPCs.
- AI judgment/reincarnation: Only the player undergoes judgment; AI that die just become carrion.
- Spatial indexing optimization: Current nearest-from scans are sufficient at current agent counts.
- Multiplayer or network behavior.
- AI that possess other AI or transfer karma between agents (except mate attraction).

## Decisions

### 1. Agent-targeted global functions
`addKarma(n, msg, cls, agent?)`, `addPa(n, agent?)`, `record(msg, agent?)` accept an optional agent parameter. When `agent` is omitted, they write to `state` (player) as before. When provided, they write to `agent.karma`, `agent.pa`, `agent.lifeLog`. This preserves all existing player code and tests while enabling AI karma.

**Alternative rejected**: Duplicating karma functions for AI. Two implementations would drift.

### 2. Species-specific AI update function per agent
Each agent in `updateAgents(dt)` calls its species-specific AI function:
```
switch(speciesKey) {
  case 'oruga':  aiOruga(agent, dt); break;
  case 'sapo':   aiSapo(agent, dt); break;
  case 'raton':  aiRaton(agent, dt); break;
  case 'ardilla': aiArdilla(agent, dt); break;
  case 'topo':   aiTopo(agent, dt); break;
  case 'zorro':  aiZorro(agent, dt); break;
  case 'lobo':   aiLobo(agent, dt); break;
  case 'halcon': aiHalcon(agent, dt); break;
}
```
Each function handles hunger, species-specific behavior, and death. This keeps the loop structure but makes it species-aware.

**Alternative rejected**: A single generic AI with behavior flags. That would lose species-specific nuance and require complex state machines.

### 3. AI adaptation buying: internal PA spend
AI periodically evaluate their PA and buy the most-needed adaptation. Logic:
- If HP < 50% and `stomach` not owned and PA ≥ cost → buy `stomach`
- If speed matters (being chased) and `swift` not owned and PA ≥ cost → buy `swift`
- If vision needed and `nose` not owned and PA ≥ cost → buy `nose`
- If shout cooldown frequent and `voice` not owned and PA ≥ cost → buy `voice`

AI buy one adaptation per life (same as player `owned` constraint).

**Alternative rejected**: AI as shop UI with auto-click. That conflates display with logic.

### 4. AI karma ecosystem effects
When an AI agent's karma is computed, it affects interactions:
- **High karma (≥ 30)**: Predators have 20% reduced perception of this agent; mates are attracted (companyAgents within range gain `saved: true` more readily).
- **Low karma (≤ -30)**: Predators have 20% increased perception; agents flee more readily.
- **Neutral**: No modifier.

This is computed in `edibleAgentFor` and `nearestPredOf` lookups, not as a separate system.

**Alternative rejected**: Karma as a visible status bar that players can click/interact with. Too complex for MVP.

### 5. AI shout uses same `tryShout` logic
AI call `aiTryShout(agent)` which uses the same `addKarma(TUNING.shoutKarma, ...)` / `addPa(TUNING.shoutPa)` / `companyAgents().forEach(m => m.saved = true)` / `state.lureTimer = lure` pattern, but targeting the agent's karma/PA. The shout cooldown is per-agent (`agent.shoutCd`).

**Alternative rejected**: Separate AI shout function. Would duplicate the shout logic and drift from player behavior.

### 6. Visual indicators drawn in `render()`
Live bar + karma number drawn over each animal in the render loop, using the same `drawSpecies` + text overlay pattern. Color-coded: green karma bar, red when negative.

**Alternative rejected**: Separate HUD panel per animal. Would clutter the screen with 20+ panels.

## Risks / Trade-offs

- **[Risk] Function name duplication**: Adding `aiOruga`, `aiSapo`, etc. alongside `eatAsOruga`, etc. — but `eatAs*` functions are player-input wrappers; AI functions are behavior engines. Different namespaces. `node --check` + verification gate will catch any duplicate `function` names.
- **[Risk] Performance**: 20+ agents each doing nearest-from scans per frame. Mitigation: keep existing perception ranges; no spatial index needed yet. Profile after implementation.
- **[Risk] AI adaptation buying creates power imbalances**: AI with `stomach` survive longer and dominate the ecosystem. Mitigation: AI buy one adaptation per life (same cap as player); balance via tuning.
- **[Risk] `addKarma` agent-targeting changes all call sites**: Mitigation: keep `agent` parameter optional; existing calls without it still work. Migrate tests file-by-file.
- **[Risk] AI karma values visible to player may be confusing**: Mitigation: simple text overlay; `karma` number shown as integer.

## Migration Plan

No deployment (static game, `serve.bat`). Rollback: revert change files. Verification: `node --check` touched files → full suite green → no duplicate `function` names → `src/index.html` refs resolve.

## Open Questions

- **AI adaptation buying frequency**: How often should AI evaluate and buy? Every few seconds? Per hunger cycle? Tuning parameter.
- **AI karma visibility threshold**: Should low-karma animals show as "dangerous" to the player? Or is the karma number enough?
- **AI mate attraction by karma**: Should high-karma animals attract more mates, or just have mates flee-toward them? Current design says "attract" but the `wanderMates` function could be enhanced.
- **AI death and karma**: When an AI dies, does its karma transfer or persist? Design says it just becomes carrion (no reincarnation for AI). Its `lifeLog` is lost.
