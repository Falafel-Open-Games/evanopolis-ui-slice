# Evanopolis UI Slice

Offline UI slice for the Evanopolis tabletop game. This repo focuses on a playable, offline mock of the experience so rules, pacing, and UI can be validated without the multiplayer server.

## Goals

- Ship a lightweight offline prototype in Godot 4.5.1.
- Provide a shared place for specs, design decisions, and progress notes.
- Keep iteration small and reviewable (one step per PR).

## Repo Layout

- `docs/` - game specification and design decisions
- `godot/` - Godot project (added in a later step)
- `justfile` - local commands

## Commands

- `just dev` - launch the offline game (requires `godot` in PATH)

## Incremental Plan

1. Repo scaffolding (this step)
2. Godot project skeleton and basic scene
3. Offline game loop v0 (turns, dice, move, event log)
4. Property interactions v0 (buy, rent, ownership)
5. Cards + jail + salida rules
6. Economy extras (jackpot, capital vote, endgame triggers)

## Notes

- See `docs/spec.md` for the current ruleset.
- Track decisions in `docs/design-decisions.md`.
