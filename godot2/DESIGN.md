# Bitcoin Mining Game - Server & Headless Design Notes

## What to Document First (Recommended Focus)
Start with a **textual happy-path sequence** for the first 1-2 turns, then add a **minimal RPC API** that supports that flow. This gives a concrete spine for the state machine and event log, without over-engineering upfront.

For a visual state overview, see `docs/state-machine.md` (Mermaid).

## Goal
Define a clear, minimal game-state model and server event flow for a headless simulation that can later map cleanly to a server-authoritative multiplayer architecture.

## Principles
- State is explicit and serializable.
- No UI concerns in the state.
- Deterministic and testable.
- Single source of truth (server-style mindset).
- Client-triggered invalid actions return `rpc_action_rejected` with a reason; do not assert/crash for client-originated mistakes.

## Headless Topology (Current Decision)
- One headless server process hosts multiple matches.
- Server loads all `.toml` configs from a directory (default: `res://configs`) or a list of explicit config paths.
- Clients run as separate headless processes, one per human player, and connect to a match via `game_id`.

## Transport (Web Export Fit)
- Use Godot's high-level multiplayer API with a WebSocket transport (`WebSocketMultiplayerPeer`) for web exports.
- The transport can be swapped without changing RPCs or game-state logic, since RPCs are on the high-level API.
- Server and client must share identical RPC method lists on the same node path to pass checksum validation.
  - We currently use a shared base script (`headless_rpc.gd`) for this.

## Randomness Authority
- Server is the only authority for randomness.
- RNG is derived from `game_id` (seed = hash(game_id)).
- Clients must not send dice values; server ignores any client-provided rolls.
- Clients may animate optimistically but must display the server result as authoritative.

## Minimal Server Flow (MVP)
### Game Start
1. Server creates a new `GameState` from config (`game_id`, `board_size`, `player_count`).
2. RNG is derived from `game_id` (seed = hash(game_id)).
3. Server emits:
   - `GameStarted { game_id: String }`
   - `TurnStarted { player_index: int, turn_number: int, cycle: int }`

### Join Handshake (Current + Discussion)
Client sends:
- `Join { game_id: String, player_id: String }`

Server responds with either:
- `ActionRejected { reason: String }` on invalid join (unknown game, slot taken, etc.)
- or `JoinAccepted { player_id: String, player_index: int, last_seq: int }` (sent to the joining client), plus a
  broadcast `PlayerJoined { player_id: String, player_index: int }` to all connected clients. The `last_seq`
  value is the most recently emitted broadcast sequence so late-joining clients can align their buffers.
  The normal game start flow happens when all seats are filled (server assigns `player_index`).

Open question (to discuss): allow reducing `player_count` if not all invites are accepted, and define how/when a match can start with fewer players.

### Reconnect Policy (Planned)
Context: Clients authenticate with JWTs and have stable unique player ids (shared with sibling auth projects). A reconnect will arrive with a new peer id.
Planned behavior:
- A reconnect with the same `player_id` should be treated as a resume, not a new join, when the prior session is considered disconnected or when a valid reconnect token is presented.
- Server binds the new peer id to the existing player slot and continues the match from current state.
- If the prior session is still considered connected and no valid reconnect token is provided, the reconnect is rejected.
- The server should track activity (`last_seen`) or heartbeat to detect stale connections and allow reclaiming slots.
Open questions:
- Which token to use for reconnection (JWT alone vs. server-issued session token).
- How long to allow a silent connection before treating it as disconnected (timeout policy).

## Reconnect Policy (JWT-Only, Replace-On-Reconnect)
This builds on the sibling auth design: JWTs are validated via `auth(token)` and `/whoami`, with `sub` as the stable player identity.

### Identity
- `player_id` is derived from JWT `sub`.
- A reconnect will always use a new peer id; the newest connection wins.

### Server State (per match)
- `player_slots[player_index] = { player_id, peer_id, last_seen, connected }`
- `peer_slots[peer_id] = { player_id, player_index }`

### Join/Resume Flow
1. Client connects and sends `auth(token)`.
2. Client sends `rpc_join(game_id, player_id)`.
3. Server behavior:
4. If no existing slot for `player_id` and seats are open, assign a slot and bind the peer.
5. If a slot exists for `player_id`, rebind the slot to the new peer id and disconnect the old peer.

### Disconnect Detection (Optional)
- Heartbeats are optional because the newest connection replaces the old one.
- If you still want stale detection for UX/metrics, track `last_seen` on any RPC.

### Security/UX Defaults
- JWT expiry rejects join/resume; clients must re-auth to get a fresh token.
- Concurrent connections for the same `player_id` are not supported; newest replaces older.

### Reconnect Catch-up Sync (Decision)
- Reconnect sync is server-authoritative and `seq`-driven.
- Client keeps `last_applied_seq` locally and sends it after `rpc_join_accepted`.
- Server always sends a full authoritative snapshot for reconnect in v1.
- After snapshot delivery, server sends `rpc_sync_complete(final_seq)` and client resumes live stream processing.

#### Ordering Rules
- During catch-up, client must pause live event application and queue incoming live events.
- Client applies snapshot atomically, updates `last_applied_seq`, then drains queued live events in `seq` order.
- Duplicate or out-of-order events (`seq <= last_applied_seq`) are ignored.

#### Snapshot Content Rules
- Snapshot contains only authoritative gameplay state required to resume:
- players, balances, board/tile ownership/miners, pawn positions, turn/cycle state, and pending actions.
- Snapshot must not include RNG seed or RNG internal state.
- Dice/randomness remains server-only authority at all times.

### First Action: Roll Dice
Client sends:
- `RollDice { match_id: String, player_id: String }`

Server responds with:
- `DiceRolled { die1: int, die2: int, total: int }`
- `PawnMoved { from: int, to: int }`
- `TileLanded { tile_index: int, tile_type: TileType }`
- Optional follow-up events based on tile type (e.g., payout, buy opportunity, incident).

## Minimal RPC API (Godot Multiplayer RPC)
All calls are Godot Multiplayer RPCs (not REST). Define which side owns each RPC.

## Event Delivery Rule
- Broadcast shared game-state events to all clients in the match (keeps local state in sync).
- Send player-specific responses (e.g., `rpc_join_accepted`, `rpc_action_rejected`) only to the requesting client.
- Broadcast events include a monotonic `seq` (per match). Clients buffer out-of-order broadcast events until missing sequence numbers arrive.
- Player-specific events use `seq = 0` and are applied immediately (not buffered).
- On reconnect, client sends `rpc_sync_request` with `last_applied_seq`; server responds with a full snapshot then `rpc_sync_complete`.

## Board Data Sync Strategy (Decision)
- Use both:
- Send a full board snapshot once at game start (and for late join/reconnect) so every client can resolve tile metadata locally.
- Send landing context on every `rpc_tile_landed` broadcast so clients do not need to infer state-sensitive details.
- Do not resend the full board map each turn; treat it as baseline state.
- If board metadata changes after start (ownership, miners, incident face), send delta events (`rpc_property_acquired`, `rpc_miner_batches_added`, `rpc_incident_type_changed`) so clients stay aligned.

### Landing Action Semantics
- `action_required` in `rpc_tile_landed` is server-authored and should be interpreted as:
- `buy_or_end_turn` for unowned property/special_property.
- `pay_toll` for property/special_property owned by another player.
- `resolve_incident` for `incident` tiles.
- `end_turn` for tiles with no immediate decision/action in this milestone.

### Turn Resolution Contract (v0 Decision)
This section defines the server-authoritative flow needed to complete a full first-player turn after landing, while keeping deterministic ordering for actions submitted outside the active turn.

#### Pending Action Lifecycle
- After `rpc_tile_landed`, server computes and stores a single pending action for the active player:
- `{ type, player_index, tile_index, game_id, metadata }`
- `type` for v0:
- `buy_or_end_turn` (unowned property/special_property)
- `pay_toll` (property/special_property owned by another player, when `toll_due > 0`)
- `end_turn` (all other immediate no-choice landings in this milestone)
- Only one pending action is active per match at a time.
- Pending action is cleared only when resolved (buy success, toll paid, or end turn success).

#### Deferred Intents (No Extra Resolution Phase in v0)
- Actions submitted outside the active turn that could affect board economics (example: miner placement intent) are accepted as intents, not immediate state mutations.
- Each intent records an explicit deterministic activation boundary:
- `effective_from_turn` (default: `current_turn + 1`) or a stricter boundary defined per action family.
- Intents must never mutate the in-progress turn state retroactively.
- v0 keeps turn flow simple (`resolve action -> next turn`) and applies deferred intents only at deterministic boundaries.

#### Action RPC Validation (v0)
- All client action RPCs must validate, in order:
- `game_id` exists and matches peer slot
- peer is registered and authorized for `player_id`
- `player_id` maps to `current_player_index`
- a compatible pending action exists
- target tile/action arguments match pending action
- On validation failure: `rpc_action_rejected(seq=0, reason)` to requesting peer.

#### Resolution Rules
- `rpc_end_turn(game_id, player_id)`:
- allowed when pending action type is `buy_or_end_turn` or `end_turn`
- clears pending action and advances to next player
- `rpc_buy_property(game_id, player_id, tile_index)`:
- allowed only when pending action type is `buy_or_end_turn` and tile matches
- tile must still be unowned and buyable
- player must have sufficient fiat balance
- on success: deduct fiat, set owner, clear pending action, advance turn
- `rpc_pay_toll(game_id, player_id)`:
- allowed only when pending action type is `pay_toll`
- server uses pending action snapshot values (`amount`, `owner_index`) captured at landing time
- player must have sufficient fiat balance for `amount`
- on success: debit payer, credit owner, emit toll event, clear pending action, advance turn
- Deferred intents do not run in the middle of the current player's landing resolution.
- Auto-advance is server-driven for v0: after buy/skip/toll resolution, server immediately emits next `rpc_turn_started` without waiting for an additional confirmation RPC.

#### Broadcast Order (v0)
- Buy path:
- `rpc_property_acquired`
- `rpc_turn_started` (next player)
- Toll path:
- `rpc_toll_paid`
- `rpc_turn_started` (next player)
- End-turn path:
- `rpc_turn_started` (next player)
- `turn_number` increments after control passes from the last seat to seat 0; otherwise only `current_player_index` advances.

#### Valuation Snapshot Rule
- Any valuation used during landing resolution (for example toll or buy price shown/charged for that resolution) is computed from authoritative state at landing-resolution time and is not affected by deferred intents that activate later.
- This prevents "submit after seeing dice result" timing from altering the already-resolving turn.

#### Reconnect Interaction
- Snapshot must include pending action state for deterministic resume.
- Reconnected client must not infer pending action from older local events; snapshot is authoritative.
- After snapshot + `rpc_sync_complete`, client prompts from snapshot state only.
- Snapshot should include deferred intents (or sufficient canonical data to deterministically rebuild them) when they can affect later turns.

### Text-Only Client Prompt Contract (v0)
- Prompt source of truth is `action_required` from `rpc_tile_landed` or pending action from snapshot on reconnect.
- `buy_or_end_turn` prompt:
- `prompt: buy property on tile=<tile> city=<city>? [y/n]`
- `y` sends `rpc_buy_property`; `n` or empty sends `rpc_end_turn`.
- `pay_toll` prompt:
- `prompt: pay toll amount=<amount> owner=<owner_index> tile=<tile> city=<city> [enter]`
- pressing enter sends `rpc_pay_toll` (no skip option in v0).
- `end_turn` prompt:
- no user choice required; client can send `rpc_end_turn` immediately.
- On reconnect sync:
- if snapshot pending action is `buy_or_end_turn`, show buy prompt again.
- if snapshot pending action is `pay_toll`, show toll prompt again.
- if snapshot pending action is `end_turn`, send `rpc_end_turn`.
- if no pending action and current player is local player, show roll prompt.
- On `rpc_action_rejected`, client logs `reason` and keeps waiting for the next authoritative event/snapshot; it does not invent local state transitions.

### Incident Draw Authority (Decision)
- Incident card draw is server-triggered as part of landing resolution, not a client-request action.
- Clients must not call an RPC to request/roll/draw an incident card.
- After `rpc_tile_landed(... action_required=\"resolve_incident\")`, server emits an incident result event to all clients.

### Why this split
- Startup snapshot gives deterministic local lookups (`tile_type`, `city`) with no per-turn duplication.
- Per-landing context prevents drift and keeps text clients simple for prompts/logging.
- This matches server-authoritative flow while minimizing bandwidth and parser complexity.

### Client -> Server RPCs
- `rpc_join(game_id: String, player_id: String)`
- `rpc_roll_dice(match_id: String, player_id: String)`
- `rpc_end_turn(match_id: String, player_id: String)`
- `rpc_buy_property(match_id: String, player_id: String, tile_index: int)`
- `rpc_pay_toll(match_id: String, player_id: String)`
- `rpc_sync_request(game_id: String, player_id: String, last_applied_seq: int)`

### Client -> Server RPCs (Planned)
- `rpc_place_miner_order(match_id: String, player_id: String, orders_by_tile: Dictionary)`

### Server -> Client RPCs (Events)
- `rpc_game_started(seq: int, game_id: String)`
- `rpc_board_state(seq: int, board: BoardState)`
- `rpc_join_accepted(seq: int, player_id: String, player_index: int, last_seq: int)`
- `rpc_turn_started(seq: int, player_index: int, turn_number: int, cycle: int)`
- `rpc_player_joined(seq: int, player_id: String, player_index: int)`
- `rpc_dice_rolled(seq: int, die1: int, die2: int, total: int)`
- `rpc_pawn_moved(seq: int, from: int, to: int, passed_tiles: Array[int])`
- `rpc_tile_landed(seq: int, tile_index: int, tile_type: TileType, city: String, owner_index: int, toll_due: float, action_required: String)`
- `rpc_incident_drawn(seq: int, tile_index: int, incident_kind: IncidentKind, card_id: String)`
- `rpc_cycle_started(seq: int, cycle: int, inflation_active: bool)`
- `rpc_incident_type_changed(seq: int, tile_index: int, incident_kind: IncidentKind)`
- `rpc_property_acquired(seq: int, player_index: int, tile_index: int, price: float)`
- `rpc_miner_batches_added(seq: int, player_index: int, tile_index: int, count: int)`
- `rpc_toll_paid(seq: int, payer_index: int, owner_index: int, amount: float)`
- `rpc_player_sent_to_inspection(seq: int, player_index: int, reason: String)`
- `rpc_state_snapshot(seq: int, snapshot: GameState)`
- `rpc_sync_complete(seq: int, final_seq: int)`
- `rpc_action_rejected(seq: int, reason: String)`

## Core State Structure (Draft)

### GameState
- `game_id: String`
- `turn_number: int`
- `current_player_index: int`
- `current_cycle: int`
- `board: BoardState`
- `players: Array[PlayerState]`
- `pending_actions: Array[PendingAction]`

### BoardState
- `size: int` (total tiles)
- `tiles: Array[TileState]`

### TileState
- `index: int`
- `tile_type: TileType` (start, inspection, incident, property, special_property)
- `city: String` (if property)
- `incident_kind: IncidentKind` (bear, bull) for incident tiles
- `owner_index: int` (-1 if unowned)
- `miner_batches: int`

### PlayerState
- `player_index: int`
- `fiat_balance: float`
- `bitcoin_balance: float`
- `position: int`
- `laps: int`
- `in_inspection: bool`

### PendingAction
- `type: PendingActionType`
- `player_index: int`
- `tile_index: int`
- `game_id: String`
- `amount: float`
- `metadata: Dictionary`

## Derived/Computed Rules (Not stored in state)
- Property price inflation based on cycle.
- Energy toll derived from property price and miner batches.
- BTC payout derived from miner batches and base payout.
- Board layout derived from config (cities/sides).

## Invariants
- `players.size == player_count`
- `board.tiles.size == board.size`
- `current_player_index` in range.
- `owner_index` in tiles is either -1 or a valid player index.
- Each `PlayerState.position` is within `[0, board.size)`.
- Each `TileState.miner_batches` is within `[0, max_miner_batches_per_property]`.
- A tile can have an owner only if `tile_type` is `property` or `special_property`.
- A tile with `tile_type == incident` must have `incident_kind` set, and non-incident tiles must not.
- A player in inspection (`in_inspection == true`) is still allowed to collect energy tolls from their properties.
- Only the current player may perform turn actions (except queued resolution and server timeouts).
- At most one pending action can exist per match, and it must belong to `current_player_index`.

## Config Inputs (Initial)
- `game_id: String`
- `board_size: int`
- `player_count: int`

## Future Extensions
- Incident decks and discard piles.
- Event log / action history.
- State hash for sync/reconciliation.
- Server event queue.
