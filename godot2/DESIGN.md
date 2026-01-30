# Bitcoin Mining Game - Server & Headless Design Notes

## What to Document First (Recommended Focus)
Start with a **textual happy-path sequence** for the first 1-2 turns, then add a **minimal RPC API** that supports that flow. This gives a concrete spine for the state machine and event log, without over-engineering upfront.

If you want a visual later, add a Mermaid state diagram once the happy-path is stable.

## Goal
Define a clear, minimal game-state model and server event flow for a headless simulation that can later map cleanly to a server-authoritative multiplayer architecture.

## Principles
- State is explicit and serializable.
- No UI concerns in the state.
- Deterministic and testable.
- Single source of truth (server-style mindset).

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
   - `GameStarted { game_id: String, snapshot: GameState }`
   - `TurnStarted { player_index: int, turn_number: int, cycle: int }`

### First Action: Roll Dice
Client sends:
- `RollDice { match_id: String, player_index: int }`

Server responds with:
- `DiceRolled { die1: int, die2: int, total: int }`
- `PawnMoved { from: int, to: int }`
- `TileLanded { tile_index: int, tile_type: TileType }`
- Optional follow-up events based on tile type (e.g., payout, buy opportunity, incident).

## Minimal RPC API (Godot Multiplayer RPC)
All calls are Godot Multiplayer RPCs (not REST). Define which side owns each RPC.

### Client -> Server RPCs
- `rpc_roll_dice(match_id: String, player_index: int)`
- `rpc_end_turn(match_id: String, player_index: int)`
- `rpc_buy_property(match_id: String, player_index: int, tile_index: int)`
- `rpc_pay_toll(match_id: String, player_index: int)`
- `rpc_place_miner_order(match_id: String, player_index: int, orders_by_tile: Dictionary)`

### Server -> Client RPCs (Events)
- `rpc_game_started(game_id: String, snapshot: GameState)`
- `rpc_turn_started(player_index: int, turn_number: int, cycle: int)`
- `rpc_dice_rolled(die1: int, die2: int, total: int)`
- `rpc_pawn_moved(from: int, to: int, passed_tiles: Array[int])`
- `rpc_tile_landed(tile_index: int, tile_type: TileType)`
- `rpc_cycle_started(cycle: int, inflation_active: bool)`
- `rpc_incident_type_changed(tile_index: int, incident_kind: IncidentKind)`
- `rpc_property_acquired(player_index: int, tile_index: int, price: float)`
- `rpc_miner_batches_added(player_index: int, tile_index: int, count: int)`
- `rpc_toll_paid(payer_index: int, owner_index: int, amount: float)`
- `rpc_player_sent_to_inspection(player_index: int, reason: String)`
- `rpc_state_snapshot(snapshot: GameState)`
- `rpc_action_rejected(reason: String)`

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

## Config Inputs (Initial)
- `game_id: String`
- `board_size: int`
- `player_count: int`

## Future Extensions
- Incident decks and discard piles.
- Event log / action history.
- State hash for sync/reconciliation.
- Server event queue.
