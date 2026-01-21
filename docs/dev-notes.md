# Dev Notes

## Board Size Selection

- `GameConfig` autoload stores `board_size` (24/30/36).
- Boot menu writes `GameConfig.board_size` before loading `game.tscn`.
- `BoardLayout` reads `GameConfig.board_size` on scene load to rebuild tiles.

## Board Layout Assembly

- The hex ring is built from SideStrip groups using a finger-joint chain.
- SideStrip1 is the root under `tiles`, SideStrip2..6 are nested children.
- Each child strip offsets along +X and rotates +60 deg on Y.
- This preserves straight sides while turning at each corner.
