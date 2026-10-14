## Context

See proposal.md (Why) and `specs/ai-jev-oruga/spec.md` for the behavior contract. Current state: `KarmaJevOruga.build_menu` uses static labels (`"Eat leaves"`, `"Drink water"`, `"Seek leaves"`); halcon's bridge already appends `" (you are hungry: eat now!)"` to its eat label at floor hunger (`hambre < regenHambre`), covered by label tests on both sides. Constraint: kinds are the ranker's contract — labels must stay decorrelated from legality (a hint SHALL never add, remove, or reorder candidates).

## Goals / Non-Goals

**Goals:**

- Floor-gated urgency hints on oruga eat/drink/seek_food labels so live `jev_oruga.log` menus show the ranker weighing need.

**Non-Goals:**

- No new candidates, no gate changes, no threshold changes (`regenHambre`/`regenSed` reused as-is); no `emocion` appraisal changes; no schema bump (`jev-oruga/v1` stays — labels are criteria data, same rationale as halcon).

## Decisions

1. **Mirror halcon's floor-gated phrasing, not threshold-gated.**
   Halcon hints only at the floor band (`< regenHambre`), not at mere hunger, keeping the hint scarce enough to mean "act now." Oruga copies that: eat/drink/seek hints fire at `<= regenHambre` / `<= regenSed`. Alternative considered (hint whenever the candidate's need-gate passes, e.g. drink always hinted since it is only offered when thirsty) — rejected: it would make the hint near-permanent and teach the ranker to ignore it, and it would not have fired any differently in the observed window where the real gap is floor-level urgency.

2. **Phrasing follows the halcon template.**
   `"Eat leaves (you are hungry: eat now!)"`, `"Drink water (you are thirsty: drink now!)"`, `"Seek leaves (you are hungry: seek now!)"`. Same voice as the existing precedent so ranker behavior stays comparable across species. Alternatives (numeric need in labels, e.g. showing sed values) rejected: snapshots already carry numeric `hambre`/`sed`; labels carry the qualitative nudge, matching halcon and ardilla practice.

3. **Labels computed inside `build_menu`, tested like halcon's.**
   Plain-vs-hint test pair per candidate (`test_oruga_eat_label_plain_when_sated`, `test_oruga_eat_label_hints_hunger_at_floor`, drink equivalents), mirroring `test_halcon_eat_label_plain_when_sated` / `test_halcon_eat_label_hints_hunger_when_needy`. No HTTP-level test changes (criteria shape unchanged, only values).

## Risks / Trade-offs

- [Risk] Ranker may still prefer wander at floor need (hints nudge, never compel) → Mitigation: that IS the experiment — the next `jev_oruga.log` window shows whether floor-hint menus flip the ~0.8 wander bias; if not, the follow-up is menu-shape work, not more labels.
- [Risk] Hint text is English-facing ranker input while the game is Spanish-flavored → Mitigation: same tradeoff halcon already made (`"you are hungry: eat now!"`); consistency across species matters more to the ranker than locale flavor.
