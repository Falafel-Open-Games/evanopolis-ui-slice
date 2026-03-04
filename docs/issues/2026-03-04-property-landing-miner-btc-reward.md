# Property Landing Should Trigger Miner BTC Reward (2026-03-04)

Issue: `ISS-009`
Status: `Fixed` on `2026-03-04`

## Summary
Landing on a property with installed miners should award BTC to the property owner, independent of toll payment.

## Problem
- Current flow only applies EVA toll transfer on `pay_toll`.
- Even when the property has miners, no BTC reward event is emitted for the owner.
- This misses the intended "block found on landing event" mechanic discussed in manual playtests.

## Expected Behavior
- Any landing on a property tile with miners should trigger BTC reward for that tile owner.
- Applies to both cases:
- another player lands and pays toll, owner still gets BTC reward,
- owner lands on own tile (no toll), owner still gets BTC reward.
- Reward should be deterministic from authoritative server state (tile miner count and configured reward formula).

## Why This Matters
- Makes miner investment produce the intended recurring upside.
- Improves economy pacing and strategic value of miner placement.
- Aligns game behavior with playtest expectation that landing chance drives mining yield.

## Suggested Acceptance Criteria
- Server emits an owner balance event with positive `btc_delta` when landing occurs on owned property with miners.
- Works for owner-landing and non-owner landing paths.
- Toll behavior remains unchanged (no toll when owner lands; toll transfer when non-owner lands).
- Text client logs the BTC reward in an easy-to-spot line.
- Tests cover:
- no miners => no BTC reward,
- miners + owner landing => BTC reward,
- miners + non-owner landing => toll + BTC reward.
