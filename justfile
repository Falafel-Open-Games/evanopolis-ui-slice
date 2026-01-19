set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

_default:
  @just --list

# Run the offline prototype (expects a Godot project under godot/).
dev:
  godot --path godot

# Export the HTML build locally.
build-html:
  mkdir -p build/html-client
  godot --headless --path godot --export-release "Web" build/html-client/index.html
