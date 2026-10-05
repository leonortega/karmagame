## MODIFIED Requirements

### Requirement: Emocion is flavor only plus decision logging from day one

Each macro answer MAY carry an `emocion` label (e.g. Hambre, Miedo, Noble) that SHALL surface only in HUD/feed flavor and SHALL never gate execution. Every live macro decision SHALL append a log entry under schema `jev-zorro/v1` with state snapshot, candidate menu, chosen index with probabilities, and outcome to `user://logs/jev_zorro.log` only when the zorro log flag is on; mocked decisions SHALL never log. Each species owns its schema (`jev-<species>/v1`), its compile-time log flag, and its file (`user://logs/jev_<species>.log`); a disabled species drops entries at log time with no memory growth and no file touch.

#### Scenario: Emocion never blocks

- **WHEN** an answer arrives with choice eat-carrion and emocion Miedo
- **THEN** the zorro eats the carrion and the feed may show the emocion as text only

#### Scenario: Decision log completeness

- **WHEN** a live macro choice is applied while the zorro log flag is on
- **THEN** the log holds the snapshot, the full menu, the chosen index with its probability distribution, and the later outcome in `jev_zorro.log`

#### Scenario: Per-species log isolation

- **WHEN** zorro logging is off and halcon logging is on
- **THEN** no zorro entry is buffered or flushed to any file while halcon entries continue to `jev_halcon.log`

#### Scenario: Mock decisions never log

- **WHEN** a mocked macro choice is applied without the sidecar
- **THEN** no log entry is buffered or flushed for any species
