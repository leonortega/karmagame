## 1. Senescence foundation

- [x] 1.1 Add failing gdUnit4 tests for stage derivation (prime/worn/frail) from animal-years for oruga, raton, and lobo
- [x] 1.2 Implement SENESCENCE rows in TUNING plus pure stage/multiplier helpers (speed, force, regen, action-time, frailty)
- [x] 1.3 Scale eff_speed and vida-regen by age with tests (frail slower and weaker than prime at equal needs)
- [x] 1.4 Implement natural death at species lifespan with "vejez" judgment reason and carrion, tested fed and sheltered

## 2. Unified age-scaled damage and failed kills

- [x] 2.1 Add failing tests then implement scaled_damage (base x attacker_force x victim_frailty) for old-zorro/prime-raton and prime-zorro/old-raton pairs
- [x] 2.2 Route strike_contact through scaled damage keeping curl-halve, bristle-reflect, and invuln on the scaled result
- [x] 2.3 Convert pounce, dive, cull, ai_hunt_eat, and hunter strike/feast to damage rolls: kill plus carrion iff damage meets or exceeds current vida, else partial damage with cooldown burned and no feast heal or sated state
- [x] 2.4 Add failing then passing tests for the failed-pounce chase window (wounded victim alive, attacker on cooldown, escape decidable)

## 3. Hunter mortality and ecosystem top-up

- [x] 3.1 Route role-hunter predators through needs plus age drain so they starve, weaken, and die like all agents (removing needs-immunity)
- [x] 3.2 Extend respawn top-up and census floors to hunters including the lobo pack floor, tested for predator-wave regeneration

## 4. Action-time aging and locomotion

- [x] 4.1 Scale verb cooldowns and durations by caster age (dig, groom, thermal, howl, escort, sense) with costs and karma unchanged
- [x] 4.2 Scale the shared locomotion envelope by age keeping gait modes unchanged, with prime-vs-prime chase parity and old-hunter-loses-young tests

## 5. Age-aware decisions

- [x] 5.1 Make micro reflexes age-aware: frail hides earlier and biases harder to cover, old weak hunters prefer carrion and refuse unwinnable hunts when carrion is perceived
- [x] 5.2 Carry age signals (self stage, threat and prey stages, force and frailty hints) through every species JEV snapshot, state text, and menu with wander fallback preserved

## 6. HUD and verification gate

- [x] 6.1 Show the age-stage signal in the edad readout alongside animal-years and raw seconds
- [x] 6.2 Run the full gdUnit4 suite green, a ponytail-review pass over the diff with findings fixed or deferred, a duplicate class_name and func collision check, and a main-scene F5 run
