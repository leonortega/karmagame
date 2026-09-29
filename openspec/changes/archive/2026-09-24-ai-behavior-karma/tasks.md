# Tasks: AI Behavior & Karma System

> **Status: DONE (2026-09-24).** Suite 148/0 green. Tareas completadas con la Convención del repo
> (tablas PRED-first, globales compartidos, español en logs). Desviaciones aceptadas:
> `-1.x` como archivo único `src/script/ai.js` (tablas `AI_BY_SPECIES`/`AI_SHOUTERS` en vez de switch);
> karma de buenas acciones de grazer vive en `eat.js` (mismo núcleo que el jugador, `forAgent`);
> `aiBuyAdaptation` llamada desde `aiBase` cada `TUNING.aiBuyEvery` (10s);
> grito IA gated a peligro cercano (rol hunter < `shoutLureRange`); halcón IA caza fauna talla ≤2
> (regla de `edibleAgentFor`); ajustes de señuelo/pounce direccionales con knockback nulo en IAs.

## 1. Agent Karma Ledger & Global Functions

- [x] 1.1 Add `karma`, `pa`, `owned`, `lifeLog` fields to `mkAgent` in `state.js` and `mkPredator` in `data.js`
- [x] 1.2 Make `addKarma(n, msg, cls, agent?)` accept optional agent target; write to `agent.karma` when provided, `state.karma` otherwise
- [x] 1.3 Make `addPa(n, agent?)` accept optional agent target
- [x] 1.4 Make `record(msg, agent?)` accept optional agent target
- [x] 1.5 Add `aiTryShout(agent)` function in `state.js` that mirrors `tryShout` but targets the agent's karma/PA
- [x] 1.6 Run `node --check src/script/state.js` and full test suite to verify player code unchanged

## 2. Species-Specific AI Behavior Engine

- [x] 2.1 Create `src/script/ai.js` with per-species AI functions: `aiOruga`, `aiSapo`, `aiRaton`, `aiArdilla`, `aiTopo`, `aiZorro`, `aiLobo`, `aiHalcon`
- [x] 2.2 Implement `aiTopo(agent, dt)`: hunger, dig burrows (+3 karma), eat insects/patches/carrion
- [x] 2.3 Implement `aiArdilla(agent, dt)`: hunger, carry nuts, plant for +10 karma, eat
- [x] 2.4 Implement `aiOruga(agent, dt)`: hunger, curl when still (half damage), prudent nibble (+2 karma), eat leaves
- [x] 2.5 Implement `aiSapo(agent, dt)`: hunger, camouflage when still, pest control (+3 karma per insect), eat insects
- [x] 2.6 Implement `aiRaton(agent, dt)`: hunger, groom with mates (+5 karma), shout alert (+30 karma), eat
- [x] 2.7 Implement `aiZorro(agent, dt)`: hunger, hunt AI fauna, pounce, cede kills (+15 karma), flee from lobo
- [x] 2.8 Implement `aiLobo(agent, dt)`: hunger, hunt T2/zorro, strike predators (+20 karma), no fear
- [x] 2.9 Implement `aiHalcon(agent, dt)`: hunger, hunt, dive-kill mates, strike lobo (+20 karma), must land to eat
- [x] 2.10 Update `updateAgents(dt)` in `game.js` to call per-species AI functions instead of the simple graze loop
- [x] 2.11 Run `node --check src/script/ai.js` and full test suite

## 3. AI Adaptation Buying

- [x] 3.1 Implement `aiBuyAdaptation(agent)` in `ai.js`: evaluate needs, spend PA to buy most-needed item from SHOP
- [x] 3.2 Add AI adaptation evaluation schedule: call `aiBuyAdaptation` periodically per agent
- [x] 3.3 Ensure `owned` constraint and per-life cap enforced for AI
- [x] 3.4 Add test for AI buying adaptation with sufficient PA
- [x] 3.5 Add test for AI refusing unaffordable adaptation

## 4. AI Shout & Alert System

- [x] 4.1 Implement `aiTryShout(agent)` — mirror `tryShout` but targets agent's karma/PA, `agent.shoutCd`, and `agent.lureTimer`
- [x] 4.2 Add AI shout decision logic: agents with cooldown ready and appropriate species trigger shouts periodically
- [x] 4.3 Ensure `companyAgents().forEach(m => m.saved = true)` and `state.lureTimer` use the agent's local state where possible (or shared state for lureTimer)
- [x] 4.4 Add test for AI Ratón shout granting karma/PA to the AI
- [x] 4.5 Add test for AI Zorro attempting shout (no effect)

## 5. Visual Indicators & HUD

- [x] 5.1 Add live HP bar rendering over each agent in `draw.js` (proportional to `agent.hp / maxHp`)
- [x] 5.2 Add karma number rendering over each agent (green for positive, red for negative)
- [x] 5.3 Ensure HUD does not clutter — small font, offset above agent sprite
- [x] 5.4 Add test that `render()` completes without error when agents have karma/PA

## 6. Update Loop Integration & Ecosystem Effects

- [x] 6.1 Integrate AI AI function calls into `update(dt)` in `game.js` alongside `updatePredators`, `updateAgents`, `wanderMates`
- [x] 6.2 Add karma ecosystem effects: high-karma (≥30) agents get 20% reduced predator perception; low-karma (≤-30) get 20% increased perception
- [x] 6.3 Implement `aiEat(agent)` that calls species-specific eat functions with the agent as `forAgent`
- [x] 6.4 Ensure AI cooldowns (`shoutCd`, `pounceCd`, `strikeCd`, `digCd`, `curlCd`, `groomCd`) are decremented in the per-tick loop
- [x] 6.5 Ensure AI hunger applies (`a.hp -= TUNING.hungerPerSec * dt`) for all agent types

## 7. Tests

- [x] 7.1 Create `test/ai.test.js` with tests for:
  - Agent karma/PA ledger initialization
  - Per-species AI behavior (topo digs, ardilla plants, oruga curls, sapo camouflages)
  - AI shout grants karma/PA to agent
  - AI adaptation buying
  - AI cede kills (+15 karma)
  - AI predator kill verbs
  - AI starvation → carrion
  - Karma ecosystem effects (perception modifiers)
- [x] 7.2 Update `test/state.test.js` for agent-targeted `addKarma`/`addPa`/`record`
- [x] 7.3 Update `test/game.test.js` for new `updateAgents` behavior
- [x] 7.4 Run full suite green

## 8. Verification Gate

- [x] 8.1 `node --check src/script/ai.js`
- [x] 8.2 `node --check src/script/state.js`
- [x] 8.3 `node --check src/script/game.js`
- [x] 8.4 `node --check src/script/predators.js`
- [x] 8.5 Full test suite green (`node --test test/*.test.js`)
- [x] 8.6 No duplicate `function` names across `src/script/`
- [x] 8.7 `src/index.html` refs resolve
