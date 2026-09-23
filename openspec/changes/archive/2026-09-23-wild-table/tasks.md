# Tasks

## 1. Diet gate + realism rules

- [x] 1.1 Implement hard diet gate (`canEat` matrix: Oruga leaves; Sapo insects; Ratón berries/apples/carrots/mushrooms/nuts; Ardilla berries/apples/mushrooms/nuts; Topo carrots/insects/nuts; Halcón/Zorro carrion/mates) with off-diet refusal + throttled hint, and verify every allowed and refused pair headlessly
- [x] 1.2 Implement size-gated predation (ignore diff ≥ 2 sizes, contact snap < 25px) plus Sapo-NPC (speed 70, hunts oruga-player, 10-dmg scare snap) with T0 spawn 1 Zorro + 1 Sapo-NPC, and verify Zorro ignores distant Oruga but snaps on touch
- [x] 1.3 Extend wasteful-kill rule to Halcón dive-kills and verify sport dive at 90% logs −10 while needed dive stays clean

## 2. Vegetarian menu entities

- [x] 2.1 Rename fruit to berries and add apple shrubs (3×2, +22/+8, Ardilla/Ratón) plus oak clumps (2×3 nuts, +18/+5, Ardilla/Ratón/Topo) with last-fruit guilt intact, and verify payoffs and bush/shrub death headlessly
- [x] 2.2 Add carrot patches (2×3, +18/+5, Ratón/Topo), mushroom clusters (4×2, +10, toxic 1-in-4 at −20 with tint + Keen-nose reveal), leaf-clumps (4×3, +12/+3 Oruga-only, regrow 1/60s, karma-exempt), and wandering insects (6, +10/+3 Sapo/Topo, respawn 1/20s max 6), and verify each spawn count, payoff, and exemption headlessly

## 3. New verbs (C carry, V sense, passives)

- [x] 3.1 Implement C carry/bury for Ardilla (pick up, drop, bury → Plant +10 karma + sapling carry, cap +3) with sapling bushes in world reset, and verify plant banks karma and next life holds 9 bushes max
- [x] 3.2 Implement V species-sense (Topo Tremor 3s reveal/25s cd; Zorro Track carrion outline 5s/30s cd) with HUD cooldown, and verify reveal contents and cooldowns headlessly
- [x] 3.3 Implement passives: Ratón Squeeze (size-1 refuge fit), Sapo Camouflage (motionless 2s drops Zorro NPC pursuit only), Oruga Curl (motionless halves damage, 20s cd), Halcón Dive (E on mate ≤60px kills + carrion), Ratón Groom (+5 karma after 3s near mate, 30s cd), Topo Aerate (+3 per burrow), Halcón Lobo-strike (+20), Zorro Cede (+15, carrion stays), and verify each headlessly

## 4. Lifelike art + density + verify

- [x] 4.1 Implement `drawSpecies` (7 silhouettes + facing + time wiggle) with predator NPC reuse (red outline + scale) and distinct food art per catalog row, and verify visually by opening `index.html` with each form on screen
- [x] 4.2 Density/balance pass (leaf/insect counts vs hunger for Oruga/Sapo lives, apple scarcity, mimic+toxic combined unfairness) with full diet lives playable end-to-end, and record per-diet survivability numbers in the task result — RESULTADO (bot greedy sin defensa, 4 corridas, techo 300s): oruga 18-64s karma+ (prudente OK), sapo 5-86s, ratón 27-92s karma-100 (glotón), ardilla 24-80s, topo 8-64s, zorro 3-74s, halcón 22-300s. Fuentes cerradas (rebrote/cede/strike-cd). Supervivencia = piso, no veredicto: el bot no huye/esconde/grita/tienda. Fragilidad presa intencionada (refugios = respuesta). Falta playtest humano de feel
- [x] 4.3 Split `game.js` past ~900 lines (extract foods/draw entities) if needed and verify `node --check` passes on all files
- [x] 4.4 Run `openspec validate "wild-table" --strict` plus extended headless harness (diet matrix, size-gate, all verbs, all deeds, saplings), and verify zero failures
