## Context

See proposal.md (Why) and specs/hud-clarity/spec.md for the behavior contract. Current state (observed): `src/index.html` holds a static `#controls` list and the HUD spans (`speciesLabel`, `paLabel`, `timeLabel`, `edadLabel`, `verbBar`); `src/script/hud.js:updateHud` jams species/tier plus shout/pounce/dig/sense cooldowns into one `speciesLabel` string and renders `verbBar` as inline spans; `src/script/state.js:addKarma` drops feed entries when `msg` is empty (notably `aiTryShout`) and `logOther` carries no actor prefix; `src/script/data.js` already owns the per-species tables (`SPECIES`, `VERB_DEFS`, `TUNING`) and `src/script/draw.js:speciesIcon` is the single emoji source. Vanilla JS globals with load-order sensitivity; `node:test` suite with DOM stubs in `test/harness.js`.

## Goals / Non-Goals

**Goals:**
- Data-driven per-species controls with verb-style cooldowns, reusing existing `TUNING` cooldowns and `speciesIcon`.
- Display-only edad and labeled time without touching drain/regen math (`effAgeMult()` stays 1.0).
- Minimal-diff presentation edits (markup + render + CSS) with no new deps.

**Non-Goals:**
- No balance changes (PA rates, cooldown durations, karma values unchanged).
- No roster (`otherPanel`) or player-feed behavior change.
- No new water/terrain/food logic; no judgment-matrix change.

## Decisions

- **Controls table next to VERB_DEFS (data.js) + renderer in hud.js over static HTML.** BASE rows (move, H, B) plus per-species extras (E label, Q only for raton/ardilla/topo/sapo, V only for topo/zorro, C only for ardilla); R omitted in-life. Rationale: matches the repo's table-first convention (`PRED`, `TUNING`, `VERB_DEFS`); alternative of hand-editing `index.html` per species would duplicate the shunt logic already in `tryShout`/`sensePulse`/`carryAction`.
- **Split identity from state in the HUD bar.** `speciesLabel` keeps `Name + Tier`; a separate controls/cooldown area owns all `(Ns)` counters. Rationale: fixes the "T1 - Q listo" misread with no spec change to tier semantics; alternative of keeping one string with separators preserves the confusion.
- **SEC_PER_YEAR table in data.js, pure format helper for edad.** Small species (oruga/sapo) fewer seconds per year than apex (halcon/zorro/lobo); `updateNeeds` untouched. Rationale: display-only keeps `vitals-water` math green; per-tier granularity rejected as too coarse for 8 species, per-individual age effects rejected (would change balance).
- **PA emphasis via markup + CSS only.** Icon glyph plus distinct color/weight on the existing `paLabel`; no wallet-progress coupling to shop catalog. Rationale: user asked for icon/color prominence; functional `PA x/y (next buy)` was considered but adds HUD-shop coupling and clutters the bar — defer unless playtest asks.
- **Verb bar as vertical list (`<ul>`/block rows), same data.** Keep name + `(Ns)` + `poor/cd` classes; move layout to CSS. Rationale: smallest diff that fixes wrapping; showing `desc`/`costHp` inline was considered but doubles row height — keep desc as `title` tooltip.
- **Emoji prefix at the `addKarma(..., agent)` boundary + fill empty-message callers.** Central prefix via `speciesIcon(agent.speciesKey)` guarantees every species is covered (not just zorro); `aiTryShout` and silent hunt paths get real messages instead of `''`. Rationale: one choke point beats per-call-site prefixes; alternative of prefixing in `logOther` alone would still drop empty messages. Karma-only scope preserved (no eat/drink logging).

## Risks / Trade-offs

- [Risk] Per-species controls drift from actual key handler gating (`game.js` keydown, `tryShout`/`sensePulse` guards) → Mitigation: renderer reads the same predicates (species allow-lists + `state.*Cd`), covered by HUD tests per species.
- [Risk] Feed noise if "fill gaps" over-logs → Mitigation: karma entries only; hunt/eat without karma stay out; 5-line cap unchanged.
- [Risk] Load-order breakage (globals) when adding tables/helpers → Mitigation: follow `data → utils → state → ... → hud` order, `node --check` touched files, full suite green.
- [Risk] Emoji width variance in ASCII-sensitive layouts → Mitigation: emoji only in feed text content, never in alignment-sensitive canvas tags.

## Migration Plan

- No data migration; static serving unchanged (`serve.bat` / `src/`).
- Rollback: revert the 6 touched source files + CSS; specs remain as unapplied deltas.
- Verify: `node --check` on touched files, full `node --test` suite green, no duplicate `function` names across `src/script/`, `src/index.html` refs resolve.

## Open Questions

- None blocking. Tunables intentionally left at placeholder values for implementation to confirm: exact `SEC_PER_YEAR` numbers, PA icon glyph/color choice, whether verb-row `title` tooltips suffice for `desc` discovery.
