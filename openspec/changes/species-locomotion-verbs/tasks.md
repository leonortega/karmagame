# Tasks: Species Locomotion & Karma Verbs

## 1. Locomotion (TDD)

- [x] 1.1 Test: sapo hop — impulse bursts + forced pause, never steady slide — DONE (loco.test.js: ≥3 saltos, ≥2 pausas, <38/40 en movimiento)
- [x] 1.2 Test: oruga inchworm — stretch-freeze-burst cycles, slower average than raton — DONE (≥8 congelamientos/60; 6s < 60% de ratón)
- [x] 1.3 Test: continuous modes stay continuous (raton scurry, ardilla bound, halcon glide air, zorro/lobo trot) — DONE (0 parones en 20 ticks)
- [x] 1.4 Test: halcon grounded stays half speed through the envelope — DONE (locoMult('halcon', true) = 0.5; estado.test re-homed)
- [x] 1.5 Test: AI uses the same envelope — DONE (moveToward unidad: cadencia sapo idéntica; aiForage avanza locoT del agente)
- [x] 1.6 Test: topo tunnels under a rock (rock ignored underground; refuges/plants still solid) — DONE (cruza la roca; el refugio lo frena)
- [x] 1.7 Test: hidden creatures are frozen regardless of gait — DONE (refugio a px+30: fuera del círculo sólido, dentro de hideRange)
- [x] 1.8 Test: zorro trot + chase multiplier still catches a scurrying raton — DONE (lobo alcanza y mata en 20 ticks)
- [x] 1.9 Implement: LOCO table + TUNING cadence constants in data.js; `locoMult` + `moveToward` in game.js; rewire movePlayer — DONE (hop 0.5/0.6s, inchworm 1.3/0.35s, tunnel ×0.8; effSpeed sin ×0.5, es de la marcha)
- [x] 1.10 Rewire AI displacement through moveToward — DONE (aiHuntEat, aiForage, aiSeekCarrion, aiFlee; resolución de sólidos sigue en updateAgents)

## 2. Verb infrastructure (TDD)

- [x] 2.1 Test: VERB_DEFS has exactly 5 verbs per species × 8 (slots 1–5, cd/costs/name present) — DONE (verb.test.js)
- [x] 2.2 Test: castVerb pays costs, sets cooldown, executes effect (topo slot 1 = aerate +3) — DONE (migrado con valor intacto; contexto imposible ⇒ ni coste ni cd)
- [x] 2.3 Test: routing — shop open: 1–4 buy and no verb; dead or on-cooldown: no-op — DONE (la tienda ya se guardaba con shopOpen)
- [x] 2.4 Test: cost that reaches Vida 0 opens Judgment (normal death path) — DONE (seda con 4 hp: el coste drena y el bucle juzga)
- [x] 2.5 Implement: VERB_DEFS + castVerb in game.js, keydown routing, HUD verb bar (5 slots, cd/affordable states) — DONE (VERB_DEFS en data.js; castVerb+VERB_FN en game.js; verbCds[5] en state + tick en update; #verbBar en hud/css/index; coste: PA sin deuda, vida puede llegar a 0)

## 3. Migrate existing verbs into slots (refactor: identical values)

- [x] 3.1 slot 1 = existing shout for raton/topo/sapo (Q rebinds to slot 1); ardilla slot 1 = new tail-flick and Q rebinds to it — DONE PARCIAL: ratón 1 delega en tryShout (karma+PA+lure intactos, test verificado); topo mantiene su grito en Q (spec sellada karma-core) y su slot 1 es airear; ardilla 1 (tail-flick) llega en sección 4
- [x] 3.2 Migrate: groom (raton/ardilla s5), aerate (topo s1), plant-oak (ardilla s2), pest-sweep (sapo s2), prudent-nibble (oruga s1), cede-prey (zorro s3), strike (zorro s5, lobo s3), dive-strike (halcon s1), mouse-pounce (zorro s1) — karma values unchanged. NOT migrated: oruga freeze-camouflage (remains her innate still-creature trait in code, not a verb) — DONE (jugador): aerate→digBurrow, alarm→tryShout, pest→eatAsSapo, prudent→eatAsGrazer, plantoak→carryAction, cede→cedeCarrion (extraída), pounce→eatAsZorro, dive→eatAsHalcon; groom social instantáneo +2 (el de 3s de karma-core queda intacto); strike (zorro 5/lobo 3) y fixes de returns faltantes en pounceKill/diveKill/strikePredator llegan con 3.3
- [ ] 3.3 AI: aiMaybeVerb + species wiring; aiShoutIfReady/aiTopo-dig/aiArdilla-plant/aiZorro-cede cast verbs through the core — suites green

## 4. New verbs, species by species (TDD)

- [ ] 4.1 sapo: burrow-in (soft-ground hide), toxin-flare (breaks hunt near predator, costs hp), coro-de-croak (chorus with nearby sapo company: karma scaled by singers)
- [ ] 4.2 oruga: seda-cuerda (silk bungee drop from a hunting predator, costs hp), néctar-para-hormigas (honeydew attracts an insect ally that distracts a hunter, costs hp+pa, +karma), enrollar-hoja (temporary oruga-only shelter near a leaf clump, +karma), erizar-espinas (next predator strike recoils, costs hp)
- [ ] 4.3 raton: seed-cache (bury seed, plantKarma-lite), tunnel-scout (brief reveal of predators/refuges, costs pa), share-bite (feed hungry congénere, +karma)
- [ ] 4.4 ardilla: false-cache (decoy cache misleads nearby hunters, +karma), bark-harvest (+pa from oak, small karma)
- [ ] 4.5 topo: tunnel-line (reinforce a dug refuge, +karma), worm-rescue (food+pa from fresh dirt), despensa-de-lombrices (worm larder: store, eat later, or share with hungry conspecific for karma), nest-dig (extra refuge, costs hp)
- [ ] 4.6 halcon: thermal-soar (vision boost, costs pa), nest-repair (near old-oak, long cd), scare-off (scatter fauna without kill, +karma), bone-drop (feeds ground fauna, +karma)
- [ ] 4.7 zorro: cache-carrion (personal stash, next eat bonus), den-dig (burrow-M refuge, costs hp)
- [ ] 4.8 lobo: howl (pack speed rally, +karma), regurgitate-feed (hungry conspecific required, big karma), escolta (bodyguard a threatened congénere: karma when the protected mate survives), cull-weak (bonus karma vs hp<30% prey)

## 5. Verification gate

- [ ] 5.1 `node --check` all touched files
- [ ] 5.2 Full suite green (`node --test test/*.test.js`)
- [ ] 5.3 No duplicate `function` names across `src/script/`
- [ ] 5.4 `src/index.html` refs resolve
- [ ] 5.5 `openspec validate species-locomotion-verbs` clean + ponytail-review pass on final diff
