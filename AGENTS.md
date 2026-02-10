# Evanopolis UI Slice - Agent Notes

This file is the Codex-facing translation of `docs/ai-context.md`. Use it as
the source of truth for project constraints while working in this repo.

## Workflow Notes

- For PR workflow and version control guidance, use `jj` (not git).
- Always track PR bookmarks with origin using `jj bookmark track <branch-name>@origin`.
- Push is the final step and is done by the user (keyed); do not run `jj git push` yourself.
- Before opening a PR, run `just sync-build-id` so the build displays the correct build id.
- When cutting a PR, pick a branch name yourself and track the bookmark with origin without asking.
- Commit messages must use a one-line conventional commit summary, then a blank line, then a fuller descriptive summary.
- Use `jj describe` to finalize PR changes instead of `jj commit` to avoid creating a new empty revision.
- When writing multi-line messages with `jj describe -m`, use a literal blank line (press Enter twice) inside the quoted string. Do not type `\n` or `\\n`.
  Example:
  `jj describe -m "feat: summary

  Body line one.
  Body line two."`
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

## Rules Source of Truth

- Treat `docs/bitcoin-mining-game-design.md` as the canonical game rules/manual.

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
- Prefer fail-fast checks for required nodes; avoid silent `null` guards.
- Use asserts and fail-fast behavior instead of defensive early returns when invariants are under our control. Do not add defensive guards for expected game flow.
- Use direct autoload access (e.g. `GameConfig.board_size = ...`) instead of `get_node_or_null` when the dependency is required.
- Avoid redundant clamps when UI options are controlled and aligned with code enums.
- Avoid variable names that shadow Node properties (e.g. `name`, `owner`, `hash`).
