# Implement End-Game By BTC Goal Victory (2026-03-04)

Issue: `ISS-011`

## Summary
Implement match-ending behavior when a player reaches the configured BTC goal, and declare a winner.

## Problem
- Current headless flow tracks balances and turns, but does not finalize the match when BTC victory condition is met.
- This leaves manual tests without authoritative game-over/winner signaling tied to the primary economy objective.

## Expected Behavior
- At the configured evaluation point (per rules), if any player reaches BTC goal:
- mark match as finished,
- emit a deterministic winner/game-over event to all clients,
- block gameplay RPCs that should no longer be accepted after game end.

## Design Notes
- Rules currently mention:
- cycle-based end condition and winner by highest BTC,
- alternate early finish when BTC target is reached.
- Implementation should make the evaluation timing explicit in state machine/docs (for example: immediate on balance change vs end-of-round checkpoint).

## Suggested Acceptance Criteria
- Server has explicit terminal match state and winner metadata.
- Reaching BTC goal triggers one game-over path only once.
- Clients receive a clear event/log indicating winner and reason (`btc_goal_reached`).
- Post-game action attempts are rejected with a dedicated reason.
- Tests cover:
- player reaches BTC goal and game ends,
- tie-break behavior (if applicable by chosen rule),
- no duplicate game-over emissions.
