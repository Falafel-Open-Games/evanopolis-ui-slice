# Text Client Missing Market Rate + Off-Turn Economy Actions (2026-03-04)

Issue: `ISS-008`

## Summary
The text client does not currently show the BTC>EVA exchange rate at turn start, and does not offer off-turn economy actions while the player is waiting.

## Problem
- Players cannot quickly see the current conversion context when a turn begins.
- While waiting for other players, there is no command flow to:
- exchange EVA/BTC,
- submit supported off-turn economy intents.

## Expected Behavior
- Turn-start log should include the current BTC>EVA exchange rate.
- When it is not the local player's turn, text client should accept economy commands that are valid as deferred intents:
- buy/sell BTC (per configured conversion rules),
- other approved economy intents aligned with server deterministic activation rules.

## Scope Alignment Note (2026-03-04)
- Miner batch purchase/placement was decided as a current-player pre-roll action in v0.
- Therefore this issue tracks market-rate visibility and off-turn economy commands that remain valid after that decision (not miner placement).

## Why This Matters
- Improves manual playtest visibility for economy decisions.
- Reduces idle time by allowing legitimate between-turn planning/actions.
- Aligns text-client usability with intended game pacing and economy loop depth.

## Suggested Acceptance Criteria
- `rpc_turn_started` logging includes current exchange rate in a stable format.
- Text client provides explicit off-turn command prompts/help for economy actions.
- Server validates and queues off-turn intents deterministically (no retroactive turn mutation).
- Reconnect/snapshot keeps enough state to resume pending economy intents safely.
- Add integration-style tests for off-turn submission + on-turn application order.
