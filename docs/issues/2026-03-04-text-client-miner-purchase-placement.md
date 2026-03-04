# Text Client Missing Miner Purchase/Placement Flow (2026-03-04)

Issue: `ISS-007`

## Summary
The headless text client does not yet expose a user flow to buy miner batches and place them on owned properties.

## Problem
- Current text-client gameplay supports roll/land/buy/pay/incident/inspection, but not miner actions.
- Manual tests cannot validate miner economy loops (higher tolls and mining payouts) through text clients.
- Planned protocol support exists in design notes (`rpc_place_miner_order`, `rpc_miner_batches_added`) but is not implemented end-to-end.

## Expected Behavior
Text client should allow the active player to:
- buy miner batches (subject to fiat balance and game limits),
- choose valid owned property tiles for placement,
- submit placement intent/action to server,
- see authoritative placement result events and updated balances/holdings.

## Why This Matters
- Miner investment is a core gameplay/economy mechanic.
- Without this flow, manual playtests under-represent mid/late-game pacing and profitability.
- Blocks meaningful validation of miner-related rules tuning.

## Suggested Acceptance Criteria
- Text client prompt supports miner buy/place during player turn.
- Server validates ownership, limits, and funds before applying.
- Server emits deterministic placement/balance events (`rpc_miner_batches_added` and related deltas).
- Reconnect snapshot includes miner counts and pending miner actions (if any).
- Add tests for happy path and common rejections (insufficient fiat, non-owned tile, max reached).
