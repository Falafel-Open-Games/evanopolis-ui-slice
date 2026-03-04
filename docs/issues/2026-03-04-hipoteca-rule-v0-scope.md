# Decide Whether `Hipoteca` Is In Scope For v0 (2026-03-04)

Issue: `ISS-010`

## Summary
We need an explicit v0 decision for the `hipoteca` (mortgage) rule.

## Problem
- `Hipoteca` adds extra state transitions and UI/UX complexity.
- v0 is focused on validating core loop pacing and economy with low operational complexity.
- Leaving scope ambiguous risks partial implementation or inconsistent manual-play expectations.

## Decision Needed
- Choose one and document it in game rules + design:
- include a minimal `hipoteca` flow in v0, or
- explicitly defer `hipoteca` to a post-v0 milestone (`WONTFIX for v0`).

## Suggested Acceptance Criteria
- A documented decision exists in:
- `docs/game-rules.md`
- `godot2/DESIGN.md`
- If deferred, docs explicitly state "`hipoteca` is out of scope for v0".
- If included, create follow-up implementation issue(s) with concrete RPC/state-machine impacts.
