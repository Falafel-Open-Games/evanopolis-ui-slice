# Incident Resolution Deadlock (2026-03-03)

Issue: `ISS-001`
Status: `Fixed` on `2026-03-03`

## Summary
When a player lands on an `incident` tile, the server marks the turn as requiring `resolve_incident`, but there is no implemented resolution path (no RPC/event handling that clears this pending action and advances the turn).

This creates a deadlock: the match is stuck waiting for an action that no client can perform.

## What Happens Today
1. Player rolls dice and lands on an incident tile.
2. Server emits `rpc_tile_landed(... action_required="resolve_incident")`.
3. Server stores a pending action with type `resolve_incident`.
4. Client has no command/RPC to resolve incident cards.
5. Server rejects other actions for that state (`rpc_end_turn`, `rpc_buy_property`, `rpc_pay_toll`).
6. Turn never advances.

## Why This Is a Deadlock
A deadlock here means the game cannot make forward progress because:
- a required state transition exists (`resolve_incident`),
- but no valid input exists in the protocol to trigger that transition.

## Source References
- `godot2/scripts/match.gd`
  - `_action_required_for_tile` returns `resolve_incident` for incident tiles.
  - `_server_move_pawn` stores pending action for unresolved action types.
  - `rpc_end_turn` only accepts `buy_or_end_turn` and `end_turn`.
  - `rpc_buy_property`/`rpc_pay_toll` are incompatible with incident actions.
- `godot2/scripts/headless_rpc.gd`
  - No incident-resolution RPC in client->server API.
- `godot2/DESIGN.md`
  - Incident draw is described as server-authoritative, but implementation is incomplete.

## Expected Behavior (Target)
On incident landing, the server should resolve the incident authoritatively (draw/apply effect), emit the incident event(s), then either:
- set the next valid pending action, or
- end/advance the turn immediately if no further action is required.

## Impact
- Critical gameplay blocker: any match can stall permanently on first incident landing.
- Test coverage currently validates `action_required=resolve_incident` but does not enforce completion/turn progression.

## Resolution
- Server now resolves incident tiles authoritatively on landing (`draw -> apply effect -> flip tile -> advance turn`).
- Mutation events are emitted during resolution (`rpc_player_balance_changed`, `rpc_player_sent_to_inspection`, `rpc_inspection_voucher_granted` when applicable).
- Incident tiles flip and broadcast `rpc_incident_type_changed`, then turn advances with `rpc_turn_started`.
- Unit tests cover event ordering, tile flip behavior, and progression after incident landing.
