set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Run the offline prototype (expects a Godot project under godot/).
dev:
  if [ ! -f godot/project.godot ]; then
    echo "Missing Godot project at godot/project.godot."
    echo "Create the project in the next step, then re-run 'just dev'."
    exit 1
  fi
  godot --path godot
