# Evanopolis UI Slice - AI Context

This doc captures the offline demo constraints and clarifications for agents.

## Scope

- Purpose: an offline, playable build to validate rules, pacing, and UI without auth/multiplayer/blockchain.
- Milestone growth: weekly increments; the demo will eventually become the full game.
- Platforms: desktop for playtesting; web export for itch.io demos.
- Players: 2-6 human seats; no AI. Boot screen should allow selecting player count.
- Data: balance and rules data lives in GDScript constants (for now).
- Language: English only (for the milestone below).

## Current Milestone (Offline Game Loop v0)

Done means:

- Board shows visual pawns/tokens.
- Roll dice button.
- Pawn movement on the board.
- UI shows the landed tile type (property, special property, incident, go, inspection).
- If the tile is a property and unowned, show options to buy or end turn.
- If the player passes the buy opportunity, no auction.
- Visuals: simple meshes + placeholder colors.

## Rules Clarifications

- Dice randomness: seed is derived from a `game_id` generated on boot.
- `game_id` is editable on the boot screen to reproduce matches.
- Focus UI validation on movement and landed tile type for this milestone.
