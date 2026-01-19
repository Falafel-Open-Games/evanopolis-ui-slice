# Design Decisions

Log small decisions here so we can track why the UI slice behaves the way it does.

## Template

- Date:
- Decision:
- Rationale:
- Consequences:

## 2026-01-11: Hexagonal board layout placeholder

- Decision: Use a hexagonal board outline and neutral placeholder UI in the offline slice.
- Rationale: Matches the non-Monopoly layout reference and reduces trademark risk while we iterate quickly.
- Consequences: Board visuals are intentionally minimal until the visual direction is finalized.

## 2026-01-11: 3D board scene base

- Decision: Use a 3D Node3D scene with a fixed camera and generated BoxMesh tiles.
- Rationale: Enables spatial board layout while keeping visuals minimal for iteration.
- Consequences: Early UI is a 2D overlay on top of the 3D scene.

## 2026-01-11: Pawn markers and peg pawn shape

- Decision: Add six pawn marker slots per tile (two rows of three) and use a peg-style pawn (base, stem, cap).
- Rationale: Keeps pawn placement clear in crowded tiles and matches the physical board-game feel.
- Consequences: Pawn placement will target marker slots rather than tile centers.

## 2026-01-11: Local game state node for turn flow

- Decision: Keep turn state in a local `GameState` node under the game scene instead of using an autoload.
- Rationale: Makes responsibilities explicit and keeps early iteration contained to the scene.
- Consequences: Other nodes should reference `GameState` via node paths.

## 2026-01-11: Color palette autoload

- Decision: Centralize player and city color constants in the `Palette` autoload.
- Rationale: Avoids color duplication across UI components and board logic.
- Consequences: UI scripts should reference `Palette` for player colors.
