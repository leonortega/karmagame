# Design

## Context

Shipped MVP: single-file `game.js` with `SPECIES`/`TUNING` tables, `state` per life, predators as wander/chase red squares, 3 main specs (20 requirements). See proposal.md - Why. This change keeps the file but grows the entity model: predators become typed agents (Zorro/Lobo) with hunger and fear, plus refuge and carrion entities.

## Goals / Non-Goals

**Goals:**
- Predators as agents with 4 states (wander/hunt/flee/camp) driven by one chain table, so adding a future beast means adding a row, not new code paths.
- Hiding as a timed decision (camp + hunger), never a pause.
- Bad food as readable risk (clock you can see, tint you can learn, sniffer that reveals).

**Non-Goals:**
- No water/swimming for Sapo, no pack behavior, no predator eating carrion, no permanent cross-life unlocks.
- Lobo stays NPC-only; no Águila rival yet (see Open Questions).

## Decisions

- **Chain as data (`PREDATORS` table: hunts[], fears[], speed, perception):** Zorro hunts [T0/T1 player, mates] fears [Lobo]; Lobo hunts [T2 player, grounded Halcón, Zorro] fears []. Alternative hardcoded per-type AI discarded — third beast would fork everything.
- **Spawn table by player tier (T0: 2 Zorro; T1: 2 Zorro; T2: 1 Zorro + 1 Lobo):** guarantees the "no longer top dog" moment exactly at ascension. Alternative always-spawn-Lobo discarded — T0 lives would be unplayable.
- **Refuge = {x, y, maxSize, climbOnly}:** one fit check `size <= maxSize && (!climbOnly || sp.climb)`. Hidden flag freezes move/eat, hunger continues, pursuer camps 3s. Alternative intricate stealth (scent, noise) discarded for MVP-depth.
- **Topo Dig via contextual E (no new key):** E with no food nearby and cooldown ready digs. Keeps one-key-per-verb discipline; H stays purely hide/exit.
- **Carrion = {x, y, age}:** thresholds 30s/60s, checked on eat. Predator kills (NPC or player Pounce) are the only source — no random spawns, so meat means something died.
- **Mimic = bush flag on 1 fruit per 3rd bush:** subtle darker tint base; Keen nose adds outline in vision. Poison is Vida-only by rule — karma stays choice-pure.
- **Halcón auto-land on E (1s grounded, move takes off):** no new key, and the vulnerability window is created by an existing input. Alternative toggle key discarded — one more key for one form is bad economy.
- **T2 pick free, lateral pick 15 PA:** ascension is the reward (don't tax it); lateral choice is convenience (tax it). Alternative taxing T2 discarded — would punish the exact behavior the matrix wants.

## Risks / Trade-offs

- [Chain AI oscillation (hunt↔flee flip-flop near Lobo)] → Mitigación: flee latches until Lobo > 1.5× perception away (hysteresis).
- [Carrion flood from NPC kills] → Mitigación: cap 5 carrions, oldest rotten removed first; mates respawn slowly (1 per 45s, max 4).
- [Topo burrow spam] → Mitigación: max 3 per life + 20s cooldown; dug burrows vanish on death like adaptations.
- [Sapo tongue sniping last-fruits risk-free] → Mitigación: tongue obeys the same last-fruit karma rule — reach doesn't excuse extinction.
- [File size past ~900 lines] → Mitigación: split `game.js` into `entities.js` (chain/refuge/carrion) at apply time if needed; task included.

## Open Questions

- Águila rival for Halcón: needed, or is land-to-eat + Lobo enough sky pressure? Answer in the balance playtest task; adding Águila is a new change, not this one.
