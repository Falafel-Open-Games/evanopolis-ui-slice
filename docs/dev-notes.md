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

## Camera Pose Rig + Movement

- `CameraPoseRig` is an editor-only rig used to define zoom out/in camera poses.
- It contains `TileRef` (instance of `tile.tscn`), `CameraZoomOut`, and `CameraZoomIn`.
- `CameraTileRig` (script on `Environment/Camera3D`) captures the **relative** transforms from `TileRef` to each pose camera at runtime and applies them to any tile.
- Pose camera FOV values are read from the rig; there are no zoom FOV exports on `CameraTileRig`.
- Optional `pose_flip_yaw_180` applies a 180° yaw to the captured poses (default on).
- After capture, `CameraPoseRig` is hidden during gameplay.
- Snap flow: camera snaps to the current player tile on turn start, and to the next player tile on turn end. On dice roll, the camera follows the pawn rotation, then snaps to the ending tile and zooms in.
- Look-at uses the pawn’s **slot marker** on the tile (not the tile center), so slight diagonal framing is expected.
