## MODIFIED Requirements

### Requirement: Global karma/PA/record functions accept an agent target
`addKarma(n, msg, cls, agent?)`, `addPa(n, agent?)`, and `record(msg, agent?)` SHALL accept an optional agent parameter. When provided, they write to `agent.karma`, `agent.pa`, `agent.lifeLog`. When omitted, they write to `state` (player) as before. Every AI karma entry SHALL carry a non-empty message and SHALL surface in the left-panel other-animals feed prefixed with the actor species emoji followed by the existing text; empty-message karma writes that would silently drop the feed entry SHALL NOT occur.

#### Scenario: Player addKarma unchanged
- **WHEN** `addKarma(10, 'test')` is called without an agent
- **THEN** `state.karma` increases by 10 and `state.lifeLog` records the message

#### Scenario: AI addKarma targets the agent
- **WHEN** `addKarma(10, 'test', 'info', aiAgent)` is called with an agent
- **THEN** `aiAgent.karma` increases by 10 and `aiAgent.lifeLog` records the message

#### Scenario: AI entry reaches the feed with emoji
- **WHEN** an AI agent of any species earns karma
- **THEN** the left-panel feed prepends an entry starting with that species emoji followed by the deed text
