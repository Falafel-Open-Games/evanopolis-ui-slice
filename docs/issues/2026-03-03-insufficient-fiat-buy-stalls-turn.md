# Insufficient Fiat Buy On Unowned Property Stalls Turn (2026-03-03)

Issue: `ISS-003`

## Summary
When a player lands on an unowned property and chooses `buy`, if the player's fiat balance is below property price, the server rejects with `insufficient_fiat` and keeps the pending action unresolved.

In the current text-only client flow, this leaves the match waiting for a follow-up action (`end_turn`) that is not automatically sent after the rejection.

## Current Behavior
1. Landing on unowned property sets `action_required = buy_or_end_turn`.
2. Player chooses buy and client sends `rpc_buy_property`.
3. Server checks balance and returns `insufficient_fiat`.
4. Client logs `rpc_action_rejected` reason.
5. Pending action remains open; turn does not advance.

## Why It Matters
- In a two-client headless game, this can appear as a soft lock.
- The active player does not receive an automatic fallback to skip/end turn.
- It is easy to reproduce once economy values are lowered to canonical EVA-scale values.

## Expected Behavior (v0)
- On `insufficient_fiat` for `rpc_buy_property`, player should still be able to resolve the pending action deterministically without stalling the match.
- Acceptable v0 options:
  - Client auto-fallback: immediately send `rpc_end_turn`, or
  - Server-side rule: convert failed buy attempt into end-turn for this pending action.

## Related Mismatch
- Current server economy constants (initial balance and property prices) are out of sync with canonical `docs/game-rules.md`, which increases likelihood and impact of this flow bug after sync.
