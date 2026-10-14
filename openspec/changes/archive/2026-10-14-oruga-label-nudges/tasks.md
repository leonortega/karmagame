## 1. Label tests (red then green, one behavior per test)

- [x] 1.1 Eat label plain when sated (contact leaves, hambre above regenHambre → no hint) and hints hunger at floor (hambre at/below regenHambre → hint)
- [x] 1.2 Drink label plain above floor (sed above regenSed → no hint) and hints thirst at floor (sed at/below regenSed → hint); seek_food label hints hunger at floor

## 2. Bridge implementation

- [x] 2.1 Floor-gated urgency hints in `KarmaJevOruga.build_menu` eat/drink/seek_food labels (halcon phrasing template); kinds, gates, and ordering untouched
- [x] 2.2 Verify oruga suite green

## 3. Verification gate

- [x] 3.1 Full gdUnit4 suite green (only the 4 known pre-existing failures); `openspec validate oruga-label-nudges` passes
- [x] 3.2 `ponytail-review` pass over the diff; fix or explicitly defer each finding
