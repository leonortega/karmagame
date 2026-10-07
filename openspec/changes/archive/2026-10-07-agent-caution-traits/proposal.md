## Why

Every agent shares one global stomach: hungry means `hambre < 100` and thirst acts below `sed 30`, identically for a bold zorro and a nervous sapo. The user wants individual temperament — two sapos where one treks for food at 98 and the other lounges until 30 — with independent food and water axes.

## What Changes

- Each agent rolls two traits at spawn, `caution_food` and `caution_water` (uniform 0..1, rerolled every life): 1.0 seeks at the first deficit (today's behavior), 0.0 waits until stocks hit 30.
- Seeking initiation follows the traits: `is_hungry` becomes `hambre < 30 + 70 × caution_food`; thirst acts below `30 + 70 × caution_water` (still only when thirstier than hungry); ladder forage and all five JEV `drink` candidacies use the same gates. Contact eating, payoffs, and regen rules are untouched.
- Universal safety nets stay global: regen thresholds and the starvation overrides (HP < 40%, regen-threshold deeds) ignore personality — a bold animal at 25 hambre still drops everything and eats.
- Urgency at the floor: whenever `hambre` sits at or below 30 (the regen floor — no new number), the animal treats food-seeking as urgent regardless of temperament: it treks toward the nearest edible food every tick (constant movement, stillness suspended) after hide and thirst-by-need, and its appraised emocion reads `Urgencia`.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `ai-species-behavior`: hunger becomes a per-agent threshold (trait rolled at spawn, missing keys default to legacy behavior); agents keep seeking, drinking, and deed behavior otherwise unchanged.
- `ai-survival`: food-seeking beyond contact range and water-seeking beyond drink range initiate at the agent's own thresholds instead of the global ones; at the hunger floor, seeking turns urgent and constant.
- `ai-jev-sapo`: the local emocion fallback gains `Urgencia` for the hunger floor (same flavor-only, never-gating contract as the pressure rule).

## Impact

- Affected code: `KarmaAI.is_hungry` (+ threshold helpers), `ai_forage`, `ai_thirst`, spawn trait rolls (`mk_agent`, `mk_predator`), drink candidacy in all five JEV bridges. Predators gain emergent temperament (bold lobo hunts, cautious lobo scavenges) through the same gate.
- Tests: spawn bounds, threshold unit tests, gated forage/thirst, per-bridge drink candidacy, urgency trek + `Urgencia` label.
- No tuning numbers, diets, payoffs, JEV wire format, or HUD changes; snapshots keep raw `hambre`/`sed` values.
