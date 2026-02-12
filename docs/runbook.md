# Evanopolis UI Slice - Playtest Runbook

## Goal

Quickly validate movement flow, tile feedback, and buy/skip choice UX.

## Prereqs

- Godot 4.5.1 in PATH.

## Run

1. From `evanopolis-ui-slice/`, run `just dev`.
2. On the boot screen, choose player count (2-6).
3. Optional: set `game_id` to reproduce a prior session.

## Headless Server + Text-Only Clients (godot2)

### Terminal 1: Server

1. Run `just text-only-server`.
2. By default it loads configs from `godot2/configs` and listens on port `9010`.
3. Auth is enforced via JWT; set `AUTH_BASE_URL` (and optionally `AUTH_VERIFY_PATH`) so the server can call `/whoami`.
4. You can also put these in a repo-root `.env` (see `.env.example`).

### Terminal 2: Client 1

1. Run `just text-only-client --game-id demo_002 --auth-token <jwt>`.

### Terminal 3: Client 2

1. Run `just text-only-client --game-id demo_002 --auth-token <jwt>`.

### Notes

- Use the same `--game-id` for all clients.
- `--auth-token` is required; `player_id` is derived from the JWT `sub`.
- Optional server args: `--port`, `--config-dir`, `--config`, `--auth-base-url`, `--auth-verify-path`.
- Optional client args: `--host`, `--port`.

## Playtest Checklist

- Rolling dice moves the pawn the expected number of tiles.
- The UI clearly shows the tile type on landing.
- For unowned properties, the buy vs. end-turn choice is obvious.
- Passing on a buy does not trigger an auction.

## Notes to Capture

- Confusing UI moments or missing info.
- Any rule ambiguity noticed while playing.
- Suggestions for next-week additions.
