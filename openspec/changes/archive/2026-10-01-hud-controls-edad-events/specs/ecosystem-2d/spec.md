## MODIFIED Requirements

### Requirement: Keyboard controls for move, eat, shout, shop
The system SHALL support WASD/arrows for movement, E for eat/drink/strike/Pounce/tongue/Dig/Dive (context by species and need: drink when thirstier with water in range, eat when hungrier with food in range, kill verbs first for carnivores), Q for shout (only for shouting species: raton, ardilla, topo, sapo), B to open/close the mid-life shop, H to hide in / exit a nearby fitting refuge, V for species-sense (Topo/Zorro only), C to carry/drop/bury a nut (Ardilla only), number keys 1-5 to cast species verbs (1-3 to buy shop items while the shop is open), and R to reincarnate from the Judgment screen only. The controls hint SHALL be rendered per possessed species (shared BASE rows plus species extras) as a list with one entry per usable binding in the right panel, each entry showing live cooldown counters in `(Ns)` style while on cooldown, and SHALL omit R from the in-life panel. Species/tier identity SHALL be displayed separately from cooldown state.

#### Scenario: Basic control mapping
- **WHEN** the user presses movement, E, Q, B, H, V, C, number, or R keys in their valid contexts
- **THEN** the corresponding move, species action, shout, shop toggle, hide toggle, sense, carry, purchase, or reincarnate action occurs

#### Scenario: Controls read as a list
- **WHEN** the player looks at the right panel
- **THEN** each usable key binding for the possessed species appears on its own list row (key in bold plus action), not as a single run-on line

#### Scenario: E drinks when thirsty
- **WHEN** the player presses E with water in drink range and sed deficit exceeding hambre deficit
- **THEN** a drink resolves (sed plus small vida gain) instead of an eat

#### Scenario: Non-shouter sees no Q row
- **WHEN** the player possesses a zorro, halcon, or oruga
- **THEN** the controls list shows no Q row

#### Scenario: Sense rows are species-gated
- **WHEN** the player possesses a form without species-sense
- **THEN** the controls list shows no V row

#### Scenario: Reincarnate stays out of life
- **WHEN** the player is alive and looks at the controls list
- **THEN** no R row appears

### Requirement: HUD and cause-effect log are always visible
The page SHALL use a three-column disposition: a left panel with the emoji legend and the other-animals block, the canvas in the center, and a right panel with the player HUD and the player event feed. The system SHALL display species and tier separately from cooldown state, Vida with max, hambre stock, sed stock, edad as per-species animal-years alongside raw seconds (display-only), Karma value with polarity, PA with icon plus emphasized style, elapsed run time with a clear label, shout cooldown state, hidden state with refuge prompt when near a fitting refuge, carried nut state, and species-sense cooldown in the right panel. Cause-effect entries SHALL be split by subject: player entries (last 5, good/bad/info polarity) go to the right-panel feed, while AI-agent karma entries for all agent species go to the left-panel other-animals feed with the actor species emoji prefixed to the existing text. The left-panel other-animals block SHALL hold a single heading with the agent roster rows (icon, karma, vida, last deed) above the other-animals event feed, and the roster format SHALL NOT change in this change. Only karma entries SHALL appear in either feed.

#### Scenario: Player reads consequences
- **WHEN** any karma-relevant event occurs
- **THEN** the HUD values update immediately and a new log entry appears at the top of the matching feed describing cause and effect

#### Scenario: AI deeds stay out of the player feed
- **WHEN** an AI agent earns karma through its own verbs
- **THEN** the entry appears in the left-panel other-animals feed and the right-panel player feed is unchanged

#### Scenario: Refuge prompt appears
- **WHEN** the player stands near a refuge its size fits
- **THEN** a prompt shows the H key and the refuge name

#### Scenario: Needs read at a glance
- **WHEN** hambre drops below its regen threshold or sed drops below its regen threshold
- **THEN** the corresponding bar shows the shortfall state immediately without opening any overlay

#### Scenario: Every species deed reaches the left feed with emoji
- **WHEN** an AI agent of any species earns karma (including shouts and hunts that previously logged empty text)
- **THEN** the left-panel feed prepends an entry starting with that species emoji followed by the deed text
