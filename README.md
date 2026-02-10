# Evanopolis UI Slice

Offline UI slice for the Evanopolis tabletop game. This repo focuses on a playable, offline mock of the experience so rules, pacing, and UI can be validated without the multiplayer server.

## Goals

- Ship a lightweight offline prototype in Godot 4.5.1.
- Provide a shared place for specs, design decisions, and progress notes.
- Keep iteration small and reviewable (one step per PR).

## Repo Layout

- `docs/` - game specification and design decisions
- `godot/` - Godot project
- `godot2/` - refactor/reboot project for headless server + text-only clients
- `justfile` - local commands

## Commands

- `just dev` - launch the offline game (requires `godot` in PATH)
- `just install-gut` - download and install GUT into `godot2/addons` (required before running tests)
- `just test-godot2` - run GUT unit tests (requires `just install-gut` first)
- `just text-only-server` - run the headless server (godot2)
- `just text-only-client` - run a headless text-only client (godot2)
- `just build-linux` - export the Linux client build
- `just run-linux` - run the exported Linux client

## Incremental Plan

1. Repo scaffolding
2. Godot project skeleton and basic scene
3. Offline game loop v0 (movement + buy/rent) (this step)
4. Property interactions v0 (buy, rent, ownership)
5. Cards + jail + salida rules
6. Economy extras (jackpot, capital vote, endgame triggers)

## Notes

- See `docs/spec.md` for the current ruleset.
- See `docs/bitcoin-mining-game-design.md` for the canonical game rules/manual.
- See `docs/ai-context.md` for offline demo scope + rules clarifications.
- See `docs/color-spec.md` for pawn color pairs and usage.
- See `docs/runbook.md` for playtest steps and headless server/text-only client workflow.
- Track decisions in `docs/design-decisions.md`.
