# Karma (Godot 4) — a living ecosystem run by NanoJev

A 2D ecosystem survival game where **every animal on the map — not just you — decides,
eats, hunts, hides, and earns karma**. The decisions of the AI fauna come from
**NanoJev**, a local decision-model service that ranks each animal's legal moves in
parallel. NanoJev is the heart of the project: once the world's animals think well
enough to live, feeding themselves and sustaining the ecosystem, the karma loop, the
food web, the weather, and every other mechanic finally have someone to act on.

Pure Godot 4.7 (GL Compatibility). No engine add-ons required; the NanoJev sidecar
is optional and runs outside the engine.

---

## Why NanoJev is the center of the project

A karma game is only as alive as its actors. If the other animals are scripted props
that stand still or drift in a straight line, then "good deeds," "predator pressure,"
"scarcity," and "reincarnation" are just trees falling in an empty forest — you act,
nothing reacts, and none of the mechanics mean anything.

NanoJev fixes that. It is a **decision model, not a puppeteer**: Godot builds each
animal's *legal* candidate menu (cooldowns, range, diet, HP/PA cost all checked) and
NanoJev only **ranks** those candidates. The model can never invent a move the animal
could not legally make on its own — which means a NanoJev-driven wolf plays by exactly
the same rules, menus, and karma payoffs as you do. That parity is what makes the
ecosystem trustworthy, and it is why every other mechanic in this README matters:
NanoJev animals are the ones who drain the charcos, strip the bushes, rot the carrion,
ride out the rains, and buy adaptations with the PA they earned.

**Fallback:** no sidecar, no problem. The game still plays — each species falls back
to a deterministic mocked brain and keeps steering, hunting, and eating. NanoJev is
the reasoning layer, never a runtime dependency.

---

## The two-brain split

Every NanoJev species runs two brains at once, so decision quality never costs
responsiveness:

- **Micro — every physics tick, never waits.** Steering, contact kills, drinking,
  fleeing, need and cooldown ticking. This runs locally in Godot and keeps going
  regardless of a pending or failed macro answer. Movement latency from the model is
  invisible to the animal's body.
- **Macro — intent, ranked by NanoJev.** The animal's *intent* (hunt, cede, cache,
  dendig, strike, flee, seek, wander, …) is requested on a cadence and applied as the
  steering target.

**Cadence.** A staggered 1-second timer (3 seconds when far from the camera, to save
data), plus **event re-asks** — threat entering range, hunger transition, fresh carrion,
a kill resolving, a nut pickup, intent reaching its target or expiring — throttled to
at most one re-ask per agent per 0.5s (`jevReaskBackoff`) so threat churn stays bounded.

**Fair-share batching.** All animals in a species share one single-flight batch request
per window. When several species are due, the batch is given to the species that has
waited longest since it was last served, so no continuously-due species can starve
another. This covers seven batch species — zorro, halcón, ratón, ardilla, sapo, topo,
lobo — with oruga bridged alongside them.

**Emocion is flavor only.** Answers may carry a label (`Hambre`, `Miedo`, `Urgencia`,
`Esperanza`) that surfaces only as HUD/feed text. It never gates execution — the
animal does the ranked move regardless of the mood attached to it.

**Observability.** Every live macro decision can be logged per species
(`user://logs/jev_<species>.log`, schema `jev-<species>/v1`) with the full state
snapshot, the candidate menu, the chosen index with its probability distribution, and
the outcome. Logging is opt-in per species (compile-time flags, off by default), and
mocked decisions never log. A poll snapshot (`user://logs/jev_poll.json`, overwritten
every flush) carries scheduler health — busy-skips, sends per species, errors — plus a
census of insects, carrion, and agents, so an empty log can be told apart from a dead
population. Red-flag counters surface screened patterns (e.g. a hungry lobo offered
`eat` but ranking `wander`).

---

## The world those brains live in

- **Bounded, bigger, persistent.** A 3200×2400 world with a camera that follows the
  possessed agent. Food, refuges, and animals are seeded **by density**, so travel
  time to reachable resources stays proportional as the world grows.
  *(why it matters: the map is a place you learn, not a room that resets; scavenging
  routes and safe refuges are worth remembering.)*
- **One unified roster.** Every animal — player and CPU alike — is an agent with
  species, position, facing, HP, hambre, sed, edad, and a brain (PLAYER or AI). You
  possess exactly one; you can start as any species. *(why it matters: there is no
  "NPC tier." The wolf that hunts you uses the same body model you do.)*
- **Persistent across reincarnation.** Positions and levels of the world's resources
  survive your death, like refuges and rocks. *(why it matters: your choices have
  consequences the next life inherits — you can over-hunt a valley and be born into
  the aftermath.)*

---

## Survival mechanics

### Needs and vitals

Every animal tracks **vida** (health), **hambre** (fullness), **sed** (hydration), and
**edad** (seconds lived). Hambre and sed drain continuously at species-paced rates
(short-lived forms drain faster, long-lived slower); hambre refills by eating, sed by
drinking. Vida regenerates **only** when both hambre and sed are above their thresholds;
otherwise it drains faster the emptier your stocks. Damage from predators, poison, and
verbs always subtracts directly, bypassing needs.

**Why it matters:** the needs model turns every mechanic into a clock. You cannot
turtle forever — you must leave cover, drink, and eat, and each of those trips spends
the very safety the refuge gave you.

### Aging and death

Each species has a senescence arc: **prime → worn → frail → natural death** ("vejez"
judgment). Age scales speed, recovery, and action/cooldown times, and it cuts both ways —
force and frailty multiply damage, so an old animal hits softer and takes more. A failed
kill **wounds** the prey instead of script-killing it and opens an escape window.

**Why it matters:** prime-vs-old matchups resolve through actual damage and positioning,
not invisible stat comparisons. An oruga living long enough to die of old age is a real
outcome, not a corner case.

---

## Karma, PA, and reincarnation

### A universal karma ledger

Karma is **-100…+100** and belongs to **every** animal, not just you. Good deeds pay:
sustainable eating, defending the weak, altruistic shouts, signature species deeds.
Wasteful kills cost. Hard diet restrictions are enforced. **PA** rewards survival time
and is a wallet you spend — never a debt you go into.

**Why it matters:** because AI agents keep their own karma and PA, the world has moral
texture everywhere you look. The animal you cede a carrion to has a history; the one
you scare may have been the honest one. Karma is a physics of the ecosystem, not a
meter bolted onto the player.

### Judgment and rebirth

On death, a **judgment matrix** maps your karma and PA balance to your next body through
a **fated draw** (a birth roulette over the eligible pool of forms). **20% of karma
carries** into the next life; remaining PA persists. The judgment screen explains cause
and outcome.

**Why it matters:** death is legible and progressive. You always know *why* you became
what you became, and the karma you banked keeps nudging your odds — a slow, readable
ladder from caterpillar to wolf rather than a slot machine.

---

## Species and their roles

Eight species across three tiers, each an ecological role made playable:

| Tier | Species | Role |
|------|---------|------|
| 0 | oruga (caterpillar) | leaf-eater; stillness-gated curl defense, silk escape, ant-allies, leafroll |
| 1 | sapo (toad) | amphibious insectivore; tongue-pest control, enters water |
| 1 | ratón (mouse) | grazer; groom/share social verbs |
| 1 | ardilla (squirrel) | climber; carries and buries/plants nuts |
| 1 | topo (mole) | burrower; tunnel network, larder, aerate, worm |
| 2 | halcón (falcon) | airborne apex; must land (vulnerable) to eat |
| 2 | zorro (fox) | ground predator; pounce/strike, cede kills |
| 2 | lobo (wolf) | pack apex; hunts T2 and zorros, regurg shares food with packmates |

### Verbs are your species

Every species has **5 signature verbs on keys 1–5**, drawn from real animal behavior.
Each costs vida or PA, has its own cooldown, and pays **contextual karma**. AI animals
of the same species cast from the same table.

**Why it matters:** the verb bar *is* your ecological role. A squirrel's game is nuts
and burying; a mole's is tunnels and larders; a fox's is ceding meat it does not need.
Playing a species teaches you what that animal actually does — and AI cast the identical
verbs, so the forest is full of animals doing their jobs.

---

## The living map

### Food and flora

A vegetarian spread — berries, apples, carrots, mushrooms, leaves, nuts, insects — plus
littered **mimic** (bushes, 1-in-3) and **toxic** (mushrooms, 1-in-4) fruit that punish
careless eating with a −20 vida bite and no karma change. Plants **regrow fruit on
per-kind clocks**, stripped plants recover, and eaten fruit can **sprout seedlings** that
mature into new plants; planted saplings grow into **old oaks**. Fresh worlds seed below
their caps so the forest can actually grow.

**Why it matters:** the map no longer only trends toward empty. It is a biome with a
birth, a productive life, and a slow recovery — so a well-managed valley feeds the next
generation, and greed is visible in a stripped hillside.

### Water and the rain cycle

Charcos and lagos are **finite**: each holds a `level` against a size-scaled capacity,
and every drink debits that species' sip cost (a wolf empties a puddle faster than a
mouse). The last drop is still drinkable; a body never goes negative. At zero it becomes
a **dry basin** — still solid terrain that blocks you, but no longer a drink target for
the player or for any AI. A global **weather clock** alternates dry spells and rains;
rain **refills by rate × duration** (capped at full) and triggers an **insect burst**
that spikes the insect population before it decays back toward the cap.

**Why it matters:** water is now a contested, shared resource with a rhythm. Droughts
concentrate animals at the remaining wet spots, rains bring bounty, and "do not walk a
thirsty animal to a dry lake" is a rule the AI must genuinely respect.

### Predation and carrion

Zorros and lobos deal **contact damage**; sapo NPCs pressure tier-0 prey. **Optimal
foraging** means no predator hunts prey two sizes smaller beyond a contact snap. Carrion
**rots on a clock**: fresh (+20 vida) → stale (+8) → rotten (−25), always karma-neutral.
Hungry predators **scavenge before hunting**. Kills of any brain spawn fresh carrion.

**Why it matters:** the food web has rules that keep it from collapsing or trivializing.
Scavenging before hunting means a weak wolf cleans up instead of starving; size-scaled
targeting keeps small animals safe unless they get reckless.

### Terrain, solids, and gait

Static elements — refuge trees, burrows, rocks, living plants, **and water bodies** —
are solid and resolve with circular push-out so agents **slide** around them instead of
sticking. Tree **trunks break ground-predator line of sight** (the hunting halcón is
exempt). Each species moves with its **signature gait** from a shared locomotion table:
oruga *inchworm*, sapo *hop*, ratón *scurry*, ardilla *bound*, topo *tunnel*, halcón
*glide*, zorro/lobo *trot*.

**Why it matters:** the forest becomes terrain you navigate, not a picture you float
over. Cover is real, ambushes are real, and every animal reads as itself the moment it
moves — one shared stepping function keeps player and AI perfectly consistent.

### Refuges, the shop, and modals

**Refuges** gate hiding by size — burrow-S, burrow-M, hollow-tree (climbers), thorn-bush,
and old-oak (no fruit, canopy cover vs ground predators). Hiding freezes movement and
eating but **keeps hunger and thirst draining**. The **mid-life shop** (B) runs in
**real time** — predators keep hunting while it is open — and sells per-life,
non-stackable adaptations bought with PA, never into debt. **Modals never overlap:**
shop, birth roulette, judgment, and pause share one centered, sim-frozen ceremony so no
fate or purchase applies silently.

**Why it matters:** hiding is a gamble (safety bought with time), shopping is a risk
(wolves do not pause for you), and the one-modal rule guarantees that every game state
change is something you chose with your eyes open.

### HUD and feedback

The HUD shows only the **controls your species can use**, each with **live cooldowns**,
an emphasized PA readout, edad as per-species **animal-years** next to raw seconds,
a vertical verb list, and **emoji-first karma feeds** split by subject: your deeds in
the right-panel feed, every AI animal's deeds in the left-panel other-animals feed with
its species emoji. A life/karma bar renders over **every** animal.

**Why it matters:** because karma is universal, you can read the moral state of the
whole ecosystem at a glance — who is doing well, who is in danger, and how your choices
ripple outward.

---

## Running it

1. **(Optional, for NanoJev brains)** Start the NanoJev sidecar and note its URL —
   default `http://192.168.100.80:8766/api/evaluate` (see `scripts/karma_jev.gd` →
   `JEV_URL`).
2. Open `project.godot` in Godot 4 and press **F5** (or run `scenes/main.tscn`).
3. A **birth roulette** opens on every fresh run — pick the form you are drawn.

Without the sidecar the game still plays: every species falls back to its deterministic
mocked brain and keeps steering, hunting, and eating.

### Controls

| Key | Action |
|-----|--------|
| WASD / Arrows | Move |
| E | Eat / Drink / Hunt (context by need: kill first, then drink if thirstier, then eat) |
| Q | Shout (attracts attention; shouting species only) |
| H | Hide in / exit a fitting refuge |
| V | Species-sense (Topo / Zorro) |
| C | Carry / bury / plant a nut (Ardilla) |
| B | Open / close the mid-life shop |
| 1–5 | Cast species verbs (1–3 buy shop items while the shop is open) |
| R | Reincarnate (judgment screen only) |

---

## Tests

gdUnit4 suite in `tests/`, including the JEV bridge suites (`test_karma_jev*.gd` —
mocked answers only, no live HTTP) and the per-mechanic suites. Run from the gdUnit4
dock, or headless:

```powershell
$env:GODOT_BIN = "<path-to>\Godot_v4.7.2-stable_win64_console.exe"
& $env:GODOT_BIN --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```

## Structure

```
project.godot
scripts/
  karma_data.gd      — species, diet, tuning, shop tables
  karma_utils.gd     — helpers (scatter, needs, collisions, LOS)
  karma_state.gd     — game state, karma/PA ledger, refuge, shout
  karma_predators.gd — trophic chain + hunter AI
  karma_eat.gd       — eating, hunting, drinking, burrow, sense
  karma_shop.gd      — judgment pools + adaptation catalog
  karma_ai.gd        — per-species agent behavior (micro/macro split)
  karma_jev.gd       — JEV facade: shared plumbing + per-species delegates
  karma_jev_<species>.gd — per-species menu/state builders, answer appliers, logs
  karma_game.gd      — world clock, weather, flora, verbs, tick
  karma_draw.gd      — icon/size/legend lookups (pure)
  karma_hud.gd       — HUD row builders (pure)
  main.gd            — Main node: input, tick, render, HUD, JEV HTTP client + log flush
scenes/main.tscn
tests/               — gdUnit4 suite (incl. test_karma_jev*.gd)
openspec/            — behavior specs + change archive (start at `ai-jev-zorro`)
```

Behavioral numbers live in `KarmaData.TUNING` — do not rebalance outside a spec change.

## License

Private
