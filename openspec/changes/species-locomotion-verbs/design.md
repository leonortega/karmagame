# Design: Species Locomotion & Karma Verbs

## Context

One movement model for all: `movePlayer` (game.js) applies velocity while a direction key is held; `effSpeed()` only varies a scalar. AI agents move by direct position nudges inside their species functions (`aiForage`, `aiFlee`, `aiHuntEat`, wander jitter). Karma verbs are hand-wired per species across game.js/state.js (`tryShout` on Q, grooming in aiRaton, digging in aiTopo, planting in aiArdilla/aiHalcon dive, ceding in aiZorro).

## Goals / Non-Goals

- Goals: a gait per species (player + AI through one shared step), a 5-verb species action bar on keys 1–5, real costs (vida/PA) with per-verb cooldowns, context-conditional karma, AI parity, data-table-first per repo convention.
- Non-Goals: per-species shop items (deferred), new map/terrain, reworking predator chase rules, animations beyond draw hooks, keys beyond 1–5.

## Decisions

### D1. Locomotion = data table + one stepper (Strategy-via-table)
`LOCO` table in data.js keyed by species: `{ mode, cadence, cost }`. One function `locoStep(actor, wish, dt)` in game.js consumes it. Modes:
- `hop` (sapo): impulse burst then forced pause (jump arc drawn as offset in draw.js)
- `inchworm` (oruga): slow stretch, freeze, burst forward
- `scurry` (raton): continuous, high turn responsiveness (current behavior, tuned)
- `bound` (ardilla): continuous but modulated (gallop envelope), climbs keep working
- `tunnel` (topo): continuous at ×0.8 while "submerged" (draw hook: mound + dust), ignores rock collision underground
- `glide` (halcon): air = smooth, grounded = ×0.5 (existing), dive on prey unchanged
- `trot` (zorro, lobo): continuous; chase multipliers unchanged

`locoStep` returns the effective velocity multiplier per tick (0..1 envelope). Existing call sites keep their math; the envelope multiplies `speed` before movement. AI species functions call `locoStep` for their own displacement so gaits are ecosystem-wide; `aiForage`/`aiFlee`/`aiHuntEat` move through the same helper (`moveToward(a, tx, ty, mult, dt)`).

### D2. Verb bar = data table + dispatch (Command-via-table)
`VERB_DEFS[speciesKey] = [{ id, name, desc, slot(1-5), cd, costHp, costPa }]` (5 per species, 40 total). `VERB_FN[id](ctx)` in game.js implements each effect; `castVerb(slot)` resolves current species + slot, checks cd/costs, executes, records to ledger (`addKarma(msg, cls, agent)` pattern from ai-behavior-karma). Keys 1–5: if `state.shopOpen` → existing buy path (1–4); else → `castVerb`. E/Q/B/H/V/C unchanged. Q keeps the legacy shout for its four karma-core species (topo included — his slot 1 is his own aerate verb, so shout stays a Q-only capability for him); sapo/raton/ardilla slot-1 verbs double as their alert.

### D3. Costs & karma are per-verb data, not vibes
Each verb defines `costHp`/`costPa` (real cost decision) and karma outcomes live in the verb implementation, gated by context checks (`karmaIf` helpers). Death by verb cost goes through the normal death path (judgment screen). Cooldowns tick in the existing per-agent cooldown loop (`aiBase` list + player state cooldowns).

### D4. AI parity through one hook
`aiMaybeVerb(a)` in ai.js: per-species context rules (hp thresholds, hunger, nearby entities) call the same `castVerbFor(a, slot)` core the player uses. One rule per verb, table-driven where possible; species functions call it before idle fallthrough. Existing AI verbs (shout, aerate, plant, cede, groom) migrate INTO verb slots and keep their karma values — one implementation each.

### D5. The 40 verbs (species → slots 1–5)

- **sapo**: 1 croak-alert (existing croak/shout) · 2 pest-sweep (existing +3, eats insect) · 3 burrow-in (enter soft ground, short hide) · 4 toxin-flare (predator very close: +karma, costs hp, chance to break hunt) · 5 coro-de-croak (chorus: karma scaled by nearby sapo company joining in; real frog choruses)
- **oruga**: 1 nibble-prudent (existing +2, sustainable bite) · 2 seda-cuerda (silk bungee: drop away from a hunting predator on a thread; costs hp; real silk-drop escape) · 3 néctar-para-hormigas (secrete honeydew: attract an insect ally that distracts a hunting predator for a few seconds; costs hp+pa; +karma; real ant–caterpillar mutualism) · 4 enrollar-hoja (near a leaf clump: roll a temporary oruga-only shelter; +karma for habitat-building; real leaf-rollers) · 5 erizar-espinas (bristle flare: next predator strike recoils damage; costs hp; real urticating caterpillars). Freeze-camouflage remains her innate still-creature trait in code (not a verb); molt and frass-feed dropped as too passive.
- **raton**: 1 alarm-shout (existing +30) · 2 seed-cache (bury a fruit seed: plantKarma-lite +karma, drops seedling) · 3 groom (existing +5) · 4 tunnel-scout (brief reveal of nearby predators/refuges: +prudent karma, costs pa) · 5 share-bite (feed a hungry congénere: +karma, -own food value)
- **ardilla**: 1 tail-flick (alarm signal: shouts without lure cost — no predator lure, smaller karma) · 2 plant-oak (existing carry/plant +10) · 3 false-cache (decoy cache: nearby predators/competitors waste time; +karma) · 4 bark-harvest (gather from oak without eating: +pa, small karma) · 5 groom (existing +5)
- **topo**: 1 aerate (existing +3) · 2 tunnel-line (dug refuge becomes reinforced: refuge lasts/holds better +karma) · 3 worm-rescue (find earthworm in fresh dirt: food +pa) · 4 despensa-de-lombrices (store a paralyzed worm in a personal larder; eat from it later or share with a hungry conspecific for karma; real mole larders) · 5 nest-dig (extra refuge, costs hp)
- **halcon**: 1 dive-strike (existing pounce/strike vs hunters +karma) · 2 thermal-soar (circle up: brief vision boost, costs pa) · 3 cortesía-de-carroña (leave your last kill unguarded for scavengers: next carrion from your kills is shared, +karma; anchor: your fresh carrion) · 4 scare-off (scatter small birds/fauna without killing: +karma, no carrion) · 5 bone-drop (drop bone/prey remnant: feeds ground fauna below, +karma)
- **zorro**: 1 mouse-pounce (leap at nearest prey in range: existing hunt eat with jump arc) · 2 cache-carrion (bury carrion for later: personal stash, +pa next eat) · 3 cede-prey (existing +15) · 4 den-dig (create burrow-M refuge, costs hp) · 5 strike (existing ahuyenta +5/+20)
- **lobo**: 1 howl (pack rally: mates/packmates gain brief speed, +karma) · 2 regurgitate-feed (feed a hungry packmate/conspecific: -own hp-value, +karma big) · 3 strike (existing +20 lobo) · 4 escolta (bodyguard a threatened congénere: karma when the protected mate survives the threat; real pack escort behavior) · 5 cull-weak (hunt the sickest nearby fauna: bonus karma if target hp < 30%, normal kill otherwise)

### D6. HUD
Verb bar strip in hud.js: 5 slots showing `[1..5] name (cd)` for current species; grayed when on cooldown or unaffordable. Draw hooks: hop offset, inchworm squash, tunnel mound (draw.js).

## Risks / Trade-offs

- 40 verbs is the bulk; TDD species by species keeps each diff small. Karma economy risk is contained by reusing existing values (shout 30, plant 10, aerate 3, groom 5, cede 15, strike 5/20, prudent 2, pest 3) and adding new ones in TUNING.
- Locomotion envelopes can break chase/flee/forage test timings → all cadence constants in TUNING; gait affects magnitude/feel, tests assert positions with the envelope active.
- `tunnel` ignoring rocks must respect `solidRefuge`/`solidPlant` semantics (only rock circles ignored, refuges/plants still interact).

## Migration Plan

1. Locomotion table + `locoStep` + `moveToward` helper; rewire movePlayer and AI movement; all suites green (no behavior change beyond cadence).
2. Verb infra: VERB_DEFS, castVerb/castVerbFor, key routing, HUD bar, aiMaybeVerb.
3. Migrate existing verbs into slots (shout, aerate, plant, cede, groom, pest, prudent, strike, pounce) — pure refactor, karma values identical, suites green.
4. Add new verbs species by species with TDD (sapo → oruga → raton → ardilla → topo → halcon → zorro → lobo).

## Open Questions

- None — scope, keys, costs, and AI parity locked with the user.
