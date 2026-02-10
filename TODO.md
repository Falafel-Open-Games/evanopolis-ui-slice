# TODO

## Tile Flip Rules (Not Implemented)

- Start tile flip on pass-over to begin a new cycle (Start ↔ Fiat Inflation).
- Bear tile flip on pass-over to change the effect for the next landing (Bear ↔ Bull).


## Inspection Rules

- Inspection blocks mining payouts from the player's properties until cleared.

## Reconnection

- Allow a player to reconnect to an existing game using the same player_id (currently rejected as player_id_taken).

## Match Creation (Server + Text-Only Client)

- Add server support for creating new games at runtime (not just loading configs once at startup).
- If text-only client starts without `--game-id`, prompt to create a new match (game_id, board_size, player_count) similar to the TOML config fields.

## Testing Direction

- Keep automated headless tests multi-process (avoid same-process local clients).
- Add a headless integration test that runs a real server + multiple clients over WebSocket RPCs.

## Turn Timers + Penalties

- Define server-side turn timers and penalties for incomplete required actions (dice roll, tile resolution) in `godot2/DESIGN.md`.

## Config Validation

- Enforce player_count bounds (2-6) and reject invalid configs (e.g., 7 players), then add tests.

## UI announcements log
- keep a log of all game event messages, like:
    - turn {turn, cycle, player} start, 
    - pawn moved to {tile},
    - mining rewards from {tile, miners count, payout value} collected by {player},
    - energy toll payed {from player, to player, value, tile}

## Review game economics

- players should be able to profit more from energy tolls
- miners should be easier to construct, but limit to the number of cards in the same city
- players should be able to sell properties?



-------------
DONE
-------------

## UI Cleanup

- Remove dual-currency payment options (fiat/bitcoin) from the game UI.
