# Evanopolis UI Slice - Agent Notes

This file is the Codex-facing translation of `docs/ai-context.md`. Use it as
the source of truth for project constraints while working in this repo.

## Workflow Notes

- For PR workflow and version control guidance, use `jj` (not git).
- If you need broader AI instructions, see `/home/fcz/falafel/AGENTS.md`.

## Scope

- Goal: deliver an offline, playable build to validate rules, pacing, and UI.
- No auth, multiplayer, or blockchain for this milestone.
- Weekly increments; the offline demo grows into the full game.
- Target platforms: desktop for playtesting, plus web export for itch.io demos.
- Player seats: 2-6 human players; no AI players.
- Boot screen must allow selecting player count.
- Balance and rules data live in GDScript constants (for now).
- English-only content for this milestone.

## Current Milestone: Offline Game Loop v0

Done means:

- Board shows visual pawns/tokens.
- Roll dice button works.
- Pawns move on the board.
- UI shows the landed tile type: property, special property, incident, go, inspection.
- If a landed tile is an unowned property, show buy or end turn options.
- If the player passes on buying, do not run an auction.
- Visuals can be simple meshes with placeholder colors.

## Rules Clarifications

- Dice randomness: seed from a `game_id` generated on boot.
- `game_id` must be editable on the boot screen to reproduce matches.
- For this milestone, prioritize UI validation for movement and landed tile type.

## GDScript Preferences

- Avoid type inference syntax like `:=`.
- Use explicit types to prevent Variant inference warnings (treated as errors).
