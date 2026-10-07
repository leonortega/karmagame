## Context

See proposal.md (Why). Current state: `KarmaAI.is_hungry` is `hambre < 100` for every agent; `ai_thirst` acts below global `regenSed` (30) when thirstier; ladder `ai_forage` runs unconditionally; all five JEV bridges gate `seek_food` on `is_hungry` and `drink` on `sed < regenSed`. Spawns (`mk_agent`, `mk_predator`) carry no temperament. About 25 call sites read hunger/thirst, all through these gates — one shared rule change covers them.

## Goals / Non-Goals

**Goals:**
- Two uniform traits per agent, one formula each, every gate reading them.

**Non-Goals:**
- No payoff, diet, regen, tuning-number, HUD, or wire-format changes.
- No species means or distributions beyond uniform (rejected: adds 16 numbers with no observed need; revisit with log evidence).
- No urgency/speed scaling (rejected: the request is about *when* agents react; speed is a second change if ever).
- No `wander_poi` idle-travel change (rejected: purposeful wandering is specified no-intent fallback, not seeking initiation; gating it would rewrite JEV wander semantics for four species — explicitly out).

## Decisions

- **Formulas `30 + 70 × caution_*`, thresholds live beside `is_hungry`.** Max reproduces today's behavior exactly (100 food / 100-points-scale water gate is wider than today's 30 — see next point); min waits until stocks hit 30, the regen floor, so no agent ever waits past the point regen already stopped. Alternative (separate tuning keys) rejected: the 30 floor is already the game's shared number.
- **Missing keys default to 1.0 (legacy).** Food behavior is then byte-identical to today for keyless dicts; water gate widens for keyless dicts, but every real agent gets keys at spawn, so only hand-built test dicts see it — and tests set traits explicitly.
- **Safety nets ignore personality.** Regen thresholds and the HP<40% / regen-threshold deed overrides keep global semantics: a bold agent at 25 hambre still drops everything. Personality governs *initiation*, never *survival*.
- **Uniform roll at spawn via `randf()`, both constructors.** `mk_agent` and `mk_predator` assign when absent (predators included per the all-animals scope — emergent: bold lobo hunts, cautious lobo scavenges, through the existing `is_hungry` branch). `randf()` matches existing AI nondeterminism (wander jitter); tests set traits explicitly so suites stay deterministic.
- **Ladder `ai_forage` gated on the personal line; contact eating never gated.** Bumping into food isn't seeking. JEV `seek_food` follows automatically through `is_hungry`; the five `drink` candidacies switch to the water threshold explicitly.
- **Urgency band at `hambre` ≤ 30 (regen floor, no new number).** Below it temperament stops mattering: every agent treks. Precedence is hide → thirst-by-need → contact eating (free) → urgency trek → normal flow (forage/verbs/stillness in ladders; intent steering + mock in JEV paths). Miedo-class danger still outranks hunger; thirst-by-need keeps its existing deficit ordering.
- **Trek net is diet-aware within existing `wanderSeekRange` (1000).** One helper (`ai_urgent_seek` beside the other AI gates): carrion for carnivore diets, insects for insectivores, edible patches otherwise; live-prey hunting is untouched (existing hunt flows cover it). Urgency moves reset `stillT` — movement breaks stillness, no camouflaged-trekking.
- **`Urgencia` slots between `Miedo` and `Esperanza` in the shared fallback.** Threat first, then floor-hunger, then carry, then hunger. All backfilling bridges (sapo, ardilla) inherit it through the one shared function; no bridge edits needed for the label.

## Risks / Trade-offs

- [Risk] Mean seeking drops (uniform [30,100] averages 65 vs today's effective 100) → Mitigation: accepted as the requested variance; starvation overrides still catch everyone at the floor; watch live logs, tune only with evidence.
- [Risk] JEV `hungry` snapshot flag now varies per individual → Mitigation: field type unchanged (bool); ranker already consumes it per-agent.
- [Risk] Predator temperament shifts kill rates → Mitigation: same gates, same values; bold/cautious split is the feature, visible in logs per agent.
- [Risk] Urgency trek overrides JEV macro intent at starvation (need over choice) → Mitigation: intended and precedented (hide/thirst reflexes already preempt intent); intent resumes above the floor; stillness suspends only while urgent.
- [Risk] Adjacent quirk, not this change: ladder thirst-travel doesn't reset `stillT` → Mitigation: left untouched, noted as a one-line follow-up; urgency moves and JEV drink moves both reset correctly.

## Migration Plan

Spawn assignment first (keys present everywhere), then gates, then bridge drink lines — each step covered by its tests, suite green throughout. Rollback is the trait assignments out (missing-key defaults restore legacy food behavior exactly).
