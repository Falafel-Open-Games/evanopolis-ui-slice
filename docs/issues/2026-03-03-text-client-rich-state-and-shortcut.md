# Text Client Needs Rich Local State + On-Demand Status Shortcut (2026-03-03)

Issue: `ISS-004`

## Summary
The text-only client currently logs authoritative events and snapshot summaries, but does not maintain a rich, queryable local model for all players/tiles over time.

This makes it hard to inspect current match status on demand while playing.

## Problem
- State is mostly visible as log lines, not as a structured local view the user can inspect at any moment.
- There is no lightweight in-session command/shortcut to print current status immediately.

## Proposed Direction
- Maintain an explicit local state model in text client (players, balances, positions, inspection/vouchers, board ownership/incident face, turn/pending action).
- Add a keyboard shortcut/command to print a compact status snapshot at any time.
  - Initial suggestion: `?`

## Why It Matters
- Improves debugging and playtest usability in headless mode.
- Makes reconnect/state validation easier to verify manually.
- Reduces ambiguity from scrolling logs during longer matches.

## Acceptance Criteria (v0.1 candidate)
- Text client keeps an up-to-date local model from snapshot + ordered events.
- Pressing `?` prints a concise status view without altering game flow.
- Output includes at least: turn owner, current player balances, positions, inspection flags, and current pending action.
