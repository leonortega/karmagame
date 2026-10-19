## 1. Capture the current look (baseline)

- [ ] 1.1 Capture a full-map frame with many labels and record it as the visual baseline for the change.
- [ ] 1.2 Confirm the existing suite is green before touching draw code.
- [ ] 1.3 Identify which labels change every frame (counts, cooldowns) and which are static, so the cache policy matches reality.

## 2. Cache shaped labels

- [ ] 2.1 Add a bounded shape cache keyed by text and size, used by `_pill` only above a small label-count threshold.
- [ ] 2.2 Clear the cache when the fallback font changes and cap its size so changing counts cannot grow it without bound.
- [ ] 2.3 Draw the static legend as one multiline block.

## 3. Precompute colors

- [ ] 3.1 Precompute species colors once from `KarmaData.SPECIES`, keeping the same fallback color for unknown forms.
- [ ] 3.2 Route agent and player draws through the precomputed map and confirm no color changed.

## 4. Verification and cleanup

- [ ] 4.1 Compare the full-map capture against the baseline and confirm the labels, legend, and colors are identical.
- [ ] 4.2 Run the full gdUnit4 suite and confirm draw-related tests are green.
- [ ] 4.3 Run GDScript diagnostics on the touched scripts and confirm no parse or type errors.
- [ ] 4.4 Boot the main scene once and confirm no label flicker or stale width during a long run.
- [ ] 4.5 Run `ponytail-review` over the diff and fix or explicitly defer every finding.
