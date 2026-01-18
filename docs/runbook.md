# Evanopolis UI Slice - Playtest Runbook

## Goal

Quickly validate movement flow, tile feedback, and buy/skip choice UX.

## Prereqs

- Godot 4.5.1 in PATH.

## Run

1. From `evanopolis-ui-slice/`, run `just dev`.
2. On the boot screen, choose player count (2-6).
3. Optional: set `game_id` to reproduce a prior session.

## Playtest Checklist

- Rolling dice moves the pawn the expected number of tiles.
- The UI clearly shows the tile type on landing.
- For unowned properties, the buy vs. end-turn choice is obvious.
- Passing on a buy does not trigger an auction.

## Notes to Capture

- Confusing UI moments or missing info.
- Any rule ambiguity noticed while playing.
- Suggestions for next-week additions.

