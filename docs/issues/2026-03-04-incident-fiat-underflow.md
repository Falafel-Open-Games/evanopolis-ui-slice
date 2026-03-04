# Incident Fiat Underflow Allowed (2026-03-04)

Issue: `ISS-006`

## Summary
During incident resolution, a negative fiat delta can be applied even when the current player has insufficient fiat balance. This allows fiat to go below zero.

## Reproduction (Manual, Deterministic Match)
1. At turn start: `p0(fiat=0.10, ...)`.
2. Player 0 lands on incident tile (`action_required=resolve_incident`).
3. Drawn card is `bear_fine_eva_2` (`fiat_delta=-2.00`).
4. Server applies delta and next turn starts with `p0(fiat=-1.90, ...)`.

## Current Behavior
- Incident balance mutations are applied additively without enforcing non-negative fiat floor.
- Player can continue match with negative fiat.

## Expected Behavior
Server should enforce a clear policy for incident debits when fiat is insufficient, for example:
- clamp at zero, or
- redirect to inspection/debt state, or
- reject/replace card effect with deterministic fallback.

Policy should be explicit in rules/docs and covered by tests.

## Why This Matters
- Economic invariants become inconsistent (`fiat_balance >= 0` no longer holds).
- Downstream actions (buy/toll/inspection fee) become ambiguous with debt state.
- Text-client logs and UX can drift from intended game rules.

## Suggested Acceptance Criteria
- Incident debit path does not produce negative fiat unless debt is an explicit modeled state.
- Behavior is deterministic and documented in `docs/game-rules.md` + `godot2/DESIGN.md`.
- Unit tests cover insufficient-fiat incident debit path.
