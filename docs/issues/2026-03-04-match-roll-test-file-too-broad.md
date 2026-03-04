# Match Roll Test File Too Broad (2026-03-04)

Issue: `ISS-005`

## Summary
`godot2/tests/test_match_roll.gd` currently mixes multiple domains in a single large file, which increases review and maintenance cost.

Current size/scope:
- ~679 lines
- 34 tests
- mixed concerns: roll validation, landing context, buy/pay/end-turn flows, incident sequencing/ordering, and inspection behaviors.

## Problem
- Harder to find and update the right tests for a specific subsystem.
- Higher merge conflict risk when multiple PRs touch unrelated turn-flow areas.
- Slower signal when a regression is isolated to one domain.

## Proposed Refactor
Split `test_match_roll.gd` into focused files:

1. `test_match_roll_validation.gd`
- roll authorization and rejection reasons

2. `test_match_turn_actions.gd`
- buy/pay/end-turn resolution and turn advancement

3. `test_match_incidents.gd`
- incident draw/flip/order/deck behavior

4. `test_match_inspection.gd`
- inspection entry/gating/resolution flows

## Acceptance Criteria
- No behavioral test changes; only file organization/refactor.
- Existing assertions remain equivalent after split.
- `just test-godot2` remains green.
