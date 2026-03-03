# Inspection State Not Enforced (2026-03-03)

Issue: `ISS-002`

## Summary
The board includes an `inspection` tile and player state includes `in_inspection`, but current server flow does not enforce inspection restrictions on future turns.

As implemented now, landing on an inspection tile behaves like a generic `end_turn` tile, and on the next turn the same player can roll dice normally without any inspection exit requirement.

## Current Behavior
1. Player lands on tile type `inspection`.
2. Server sets `action_required = "end_turn"` and auto-advances.
3. No inspection status mutation is applied as part of landing resolution.
4. On next turn, player can call `rpc_roll_dice` normally.

## Expected Behavior
When inspection is triggered (tile landing or incident effect), server should:
- set inspection status on the target player,
- emit an inspection event for clients (for logs/UI),
- gate normal roll on that player's next turn until inspection is resolved.

Inspection resolution should be explicit and server-authoritative (payment, doubles, or free-exit card), after which normal movement resumes.

## Why This Matters
- Rules consistency: inspection currently has no gameplay consequence in headless flow.
- Testability: without enforcement, incident cards that send players to inspection have weak impact.
- Protocol clarity: text-only clients need deterministic prompts and RPC flow for inspection entry/exit.

## Suggested Acceptance Criteria
- Landing on inspection (or inspection incident) marks player as in inspection.
- On turn start, inspected player cannot directly roll.
- Server exposes/uses explicit inspection-resolution flow and events.
- Snapshot/reconnect includes enough inspection state to resume deterministically.
