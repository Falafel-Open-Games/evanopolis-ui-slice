set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

_default:
  @just --list

# Run the offline prototype (expects a Godot project under godot/).
dev:
  godot --path godot
