# Tasks: AI Behavior & Karma System

## 1. Agent Karma Ledger & Global Functions

- [ ] 1.1 Add `karma`, `pa`, `owned`, `lifeLog` fields to `mkAgent` in `state.js` and `mkPredator` in `data.js`
- [ ] 1.2 Make `addKarma(n, msg, cls, agent?)` accept optional agent target; write to `agent.karma` when provided, `state.karma` otherwise
- [ ] 1.3 Make `addPa(n, agent?)` accept optional agent target
- [ ] 1.4 Make `record(msg, agent?)` accept optional agent target
- [ ] 1.5 Add `aiTryShout(agent)` function in `state.js` that mirrors `tryShout` but targets the agent's karma/PA
- [ ] 1.6 Run `node --check src/script/state.js` and full test suite to verify player code unchanged

## 2. Species-Specific AI Behavior Engine

- [ ] 2.1 Create `src/script/ai.js` with per-species AI functions: `aiOruga`, `aiSapo`, `aiRaton`, `aiArdilla`, `aiTopo`, `aiZorro`, `aiLobo`, `aiHalcon`
- [ ] 2.2 Implement `aiTopo(agent, dt)`: hunger, dig burrows (+3 karma), eat insects/patches/carrion
- [ ] 2.3 Implement `aiArdilla(agent, dt)`: hunger, carry nuts, plant for +10 karma, eat
- [ ] 2.4 Implement `aiOruga(agent, dt)`: hunger, curl when still (half damage), prudent nibble (+2 karma), eat leaves
- [ ] 2.5 Implement `aiSapo(agent, dt)`: hunger, camouflage when still, pest control (+3 karma per insect), eat insects
- [ ] 2.6 Implement `aiRaton(agent, dt)`: hunger, groom with mates (+5 karma), shout alert (+30 karma), eat
- [ ] 2.7 Implement `aiZorro(agent, dt)`: hunger, hunt AI fauna, pounce, cede kills (+15 karma), flee from lobo
- [ ] 2.8 Implement `aiLobo(agent, dt)`: hunger, hunt T2/zorro, strike predators (+20 karma), no fear
- [ ] 2.9 Implement `aiHalcon(agent, dt)`: hunger, hunt, dive-kill mates, strike lobo (+20 karma), must land to eat
- [ ] 2.10 Update `updateAgents(dt)` in `game.js` to call per-species AI functions instead of the simple graze loop
- [ ] 2.11 Run `node --check src/script/ai.js` and full test suite

## 3. AI Adaptation Buying

- [ ] 3.1 Implement `aiBuyAdaptation(agent)` in `ai.js`: evaluate needs, spend PA to buy most-needed item from SHOP
- [ ] 3.2 Add AI adaptation evaluation schedule: call `aiBuyAdaptation` periodically per agent
- [ ] 3.3 Ensure `owned` constraint and per-life cap enforced for AI
- [ ] 3.4 Add test for AI buying adaptation with sufficient PA
- [ ] 3.5 Add test for AI refusing unaffordable adaptation

## 4. AI Shout & Alert System

- [ ] 4.1 Implement `aiTryShout(agent)` — mirror `tryShout` but targets agent's karma/PA, `agent.shoutCd`, and `agent.lureTimer`
- [ ] 4.2 Add AI shout decision logic: agents with cooldown ready and appropriate species trigger shouts periodically
- [ ] 4.3 Ensure `companyAgents().forEach(m => m.saved = true)` and `state.lureTimer` use the agent's local state where possible (or shared state for lureTimer)
- [ ] 4.4 Add test for AI Ratón shout granting karma/PA to the AI
- [ ] 4.5 Add test for AI Zorro attempting shout (no effect)

## 5. Visual Indicators & HUD

- [ ] 5.1 Add live HP bar rendering over each agent in `draw.js` (proportional to `agent.hp / maxHp`)
- [ ] 5.2 Add karma number rendering over each agent (green for positive, red for negative)
- [ ] 5.3 Ensure HUD does not clutter — small font, offset above agent sprite
- [ ] 5.4 Add test that `render()` completes without error when agents have karma/PA

## 6. Update Loop Integration & Ecosystem Effects

- [ ] 6.1 Integrate AI AI function calls into `update(dt)` in `game.js` alongside `updatePredators`, `updateAgents`, `wanderMates`
- [ ] 6.2 Add karma ecosystem effects: high-karma (≥30) agents get 20% reduced predator perception; low-karma (≤-30) get 20% increased perception
- [ ] 6.3 Implement `aiEat(agent)` that calls species-specific eat functions with the agent as `forAgent`
- [ ] 6.4 Ensure AI cooldowns (`shoutCd`, `pounceCd`, `strikeCd`, `digCd`, `curlCd`, `groomCd`) are decremented in the per-tick loop
- [ ] 6.5 Ensure AI hunger applies (`a.hp -= TUNING.hungerPerSec * dt`) for all agent types

## 7. Tests

- [ ] 7.1 Create `test/ai.test.js` with tests for:
  - Agent karma/PA ledger initialization
  - Per-species AI behavior (topo digs, ardilla plants, oruga curls, sapo camouflages)
  - AI shout grants karma/PA to agent
  - AI adaptation buying
  - AI cede kills (+15 karma)
  - AI predator kill verbs
  - AI starvation → carrion
  - Karma ecosystem effects (perception modifiers)
- [ ] 7.2 Update `test/state.test.js` for agent-targeted `addKarma`/`addPa`/`record`
- [ ] 7.3 Update `test/game.test.js` for new `updateAgents` behavior
- [ ] 7.4 Run full suite green

## 8. Verification Gate

- [ ] 8.1 `node --check src/script/ai.js`
- [ ] 8.2 `node --check src/script/state.js`
- [ ] 8.3 `node --check src/script/game.js`
- [ ] 8.4 `node --check src/script/predators.js`
- [ ] 8.5 Full test suite green (`node --test test/*.test.js`)
- [ ] 8.6 No duplicate `function` names across `src/script/`
- [ ] 8.7 `src/index.html` refs resolve
