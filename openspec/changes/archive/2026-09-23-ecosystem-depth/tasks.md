# Tasks

## 1. Chain AI foundation

- [x] 1.1 Add `PREDATORS` chain table (Zorro: hunts T0/T1 + mates, fears Lobo; Lobo: hunts T2 + grounded Halcón + Zorro, fears nothing) with tier spawn table (T0: 2 Zorro; T1: 2 Zorro; T2: 1 Zorro + 1 Lobo) and verify `node --check game.js` passes and spawn counts match player tier headlessly
- [x] 1.2 Implement predator states wander/hunt/flee with flee hysteresis (flee latches until threat > 1.5× perception) and verify a Zorro abandons a chase to flee an approaching Lobo and does not oscillate
- [x] 1.3 Implement camp state (pursuer waits ~3s at refuge of hidden player, then wanders) and verify hidden player is safe after camp expires while hunger kept draining

## 2. Playable Zorro + Sapo + Topo (one animal per task)

- [x] 2.1 Implement Zorro form (T2, size 3, speed 185, Pounce dash-kill on E with 6s cooldown spawning fresh carrion, no shout) and verify Pounce kills a mate, spawns carrion, and respects cooldown
- [x] 2.2 Implement wasteful-kill rule (kill at Vida ≥ 80% max → −10 karma, gain capped) and verify clean kill at 50% grants no karma change while sport kill at 90% logs −10
- [x] 2.3 Implement Topo form (T1, size 2, shout allowed, contextual-E Dig: burrow-M at position, 20s cooldown, max 3 per life, cleared on death) and verify dig limits and cleanup
- [x] 2.4 Implement Sapo form (T1, size 1, slow, tongue eats fruit at 90px with normal last-fruit karma rules, croak counts as shout) and verify ranged eat plus last-fruit −15 karma via tongue

## 3. Refuges and hiding

- [x] 3.1 Spawn refuge entities per life (3 burrow-S max1, 3 burrow-M max2, 2 hollow-tree max2 climbers-only, 2 thorn-bush max2) with render states and verify counts plus Ardilla-only hollow-tree fit
- [x] 3.2 Implement H hide/exit with size-fit check, frozen move/eat while hidden, hunger draining, refuge prompt HUD, and death-while-hidden opening judgment, and verify Zorro gets a does-not-fit message at burrow-M

## 4. Bad food and Halcón landing

- [x] 4.1 Implement carrion entity with rot clock (fresh +20 / stale +8 after 30s / rotten −25 after 60s, visible states, cap 5 with oldest-rotten-first removal, mate respawn 1 per 45s max 4) fed only by kills, and verify each stage plus zero karma change throughout
- [x] 4.2 Implement mimic fruit (1 per 3rd bush, darker tint, −20 Vida no karma) plus Keen nose exact reveal in vision, and verify base tint is subtle but the reveal marks unambiguously
- [x] 4.3 Implement Halcón auto-land on E near food (1s grounded immobile vulnerable, move takes off) and verify a Lobo can damage it inside the window

## 5. Matrix v2, judgment UI, balance

- [x] 5.1 Implement matrix v2 (dual free T2 pick Halcón/Zorro; Oruga + karma ≥ +20 → Sapo; T1 cycle Ratón → Ardilla → Topo → Sapo; Halcón/Zorro/Sapo neutral → Ratón) with T2 pick buttons and Choose-form (15 PA) offering any T1 pool member, and verify all six transitions headlessly
- [x] 5.2 Split `game.js` if it exceeds ~900 lines (extract chain/refuge/carrion entities) and verify `node --check` passes on all files
- [x] 5.3 Playtest balance pass (Zorro vs Lobo speeds, carrion economy, camp 3s feel, mimic rate) and record the Águila verdict (needed or land-to-eat suffices) in the task result for the next change — VEREDICTO: land-to-eat + Lobo bastan (halcón 215 > lobo 195 en persecución; zorro base 185 no escapa sin zarpas/camp, presión intencionada); Águila diferida a un cambio futuro
- [x] 5.4 Run `openspec validate "ecosystem-depth" --strict` plus the headless harness extended with chain/refuge/carrion asserts, and verify zero failures
