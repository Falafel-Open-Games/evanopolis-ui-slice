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
