# TODO

## Tile Flip Rules (Not Implemented)

- Start tile flip on pass-over to begin a new cycle (Start ↔ Fiat Inflation).
- Bear tile flip on pass-over to change the effect for the next landing (Bear ↔ Bull).


## Inspection Rules

- Inspection blocks mining payouts from the player's properties until cleared.

## Reconnection Test Roadmap

3. Integration test: run server + 2 clients, drop client, reconnect with same player_id, ensure new peer receives events.
4. Integration test: two concurrent connections with same player_id; newest replaces older and older is disconnected.
5. Integration test: expired JWT is rejected on reconnect (auth server + game server).

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

## Reconnection

- Allow a player to reconnect to an existing game using the same player_id.

## Reconnection Test Roadmap

1. Unit test: reconnect with same player_id replaces old peer slot (server-side match).
2. Unit test: reconnect broadcasts continue sequence without duplicate game start (late join).
