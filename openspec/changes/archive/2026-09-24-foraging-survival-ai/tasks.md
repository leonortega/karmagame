# Tasks: Foraging & Survival AI

## 1. Food seeking (TDD)

- [x] 1.1 Add TUNING: `forageRangeMult: 0.5`, `hungerPriority: 0.4`, `aiHideMax: 5`, `aiCoverRange: 250`, `lowHpPercept: 1.4`; `fruitRegrow` 90→45
- [x] 1.2 Test: `aiForage` walks a raton toward a bush 90px away (dentro de visión×0.5 = 95; 300px era inalcanzable — spec corregida en paralelo) — DONE
- [x] 1.3 Test: seek resolves into eating at eat-range (agent reaches bush and eats) — DONE
- [x] 1.4 Test: no food in forage range → idle jitter stays (no crash, no teleport) — DONE
- [x] 1.5 Implement `aiForage` + wire into all grazer functions (before idle fallthrough) — DONE
- [x] 1.6 Test: predator at low HP walks to carrion 200px away (carrion-first) — DONE
- [x] 1.7 Test: predator at high HP still hunts prey with both available — DONE
- [x] 1.8 Implement distant-carrion for carnivores (perception-scan, low-HP first) — DONE

## 2. Hunger priority (TDD)

- [x] 2.1 Test: raton at 30% HP skips grooming next to mate+food, eats instead — DONE
- [x] 2.2 Test: raton at 80% HP grooms as usual — DONE
- [x] 2.3 Test: ardilla at 35% HP carrying a nut drops it and eats — DONE
- [x] 2.4 Test: oruga/sapo hungry move (stillT reset) instead of curl/camouflage hold — DONE
- [x] 2.5 Implement priority gate in aiRaton/aiTopo/aiArdilla/aiOruga/aiSapo — DONE

## 3. Real hiding (TDD)

- [x] 3.1 Test: hunted raton near fitting refuge enters it (hidden=true, hideRef set) — DONE
- [x] 3.2 Test: ground predator loses hidden AI — DONE (presa oculta filtrada de `nearestAiPrey`; el halcón pica y sí la ve)
- [x] 3.3 Test: AI exits after aiHideMax (5s) even if danger remains — DONE
- [x] 3.4 Test: AI exits early when no hunter within perception — DONE
- [x] 3.5 Test: hunger drains while hidden (hp decreases during hide tick) — DONE
- [x] 3.6 Implement `aiTryHide`/`aiHideTick` + hunted-check wiring in grazer functions — DONE
- [x] 3.7 Test: fleeing AI bends toward a fitting refuge within aiCoverRange — DONE (zorro huye del lobo hacia un viejo roble que sí le cabe; y>10 y toRef<150 vs 176 recta)

## 4. Flora births (TDD)

- [x] 4.1 Test: matured seedlings spawn with full fruit (FRUIT_CAP por especie: berries/apples/carrots/mushrooms verificados) — DONE
- [x] 4.2 Test: fruitRegrow now 45 (existing regrow tests updated) — DONE
- [x] 4.3 Update flora tests asserting amount===1 births — DONE ("brote madura… con toda la fruta")

## 5. Verification gate

- [x] 5.1 `node --check` all touched files — DONE (ai.js, game.js, survival.test.js, flora.test.js)
- [x] 5.2 Full suite green — DONE (205/205: utils, world, state, eat, predators, shop, game, ai, flora, terrain, survival)
- [x] 5.3 No duplicate `function` names across `src/script/` — DONE (uniq -d vacío)
- [x] 5.4 `src/index.html` refs resolve — DONE
- [x] 5.5 `openspec validate foraging-survival-ai` clean — DONE
