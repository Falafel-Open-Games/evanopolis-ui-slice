set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

_default:
  @just --list

# Run the offline prototype (expects a Godot project under godot/).
dev:
  godot --path godot

# Run the headless text-only prototype (expects a Godot project under godot2/).
text-only:
  godot --headless --log-file /tmp/godot-text-only.log --path godot2

# Run the headless server for multi-match testing.
text-only-server *ARGS:
  godot --headless --log-file /tmp/godot-text-only-server.log --path godot2 res://scenes/server_main.tscn {{ARGS}}

# Run a headless client that connects to the server.
text-only-client *ARGS:
  godot --headless --log-file /tmp/godot-text-only-client.log --path godot2 res://scenes/client_main.tscn {{ARGS}}

# Format GDScript files (godot2).
format-gd:
  gdscript-formatter --use-spaces $(rg --files -g '*.gd' godot2)

# Export the HTML build locally.
build-html:
  mkdir -p build/html-client
  godot --headless --path godot --export-release "Web" build/html-client/index.html

# Export the Linux client build locally.
build-linux:
  godot --headless --path godot --export-release "Linux" ../build/linux-client/evanopolis_client.x86_64

# Run the exported Linux client.
run-linux:
  ./build/linux-client/evanopolis_client.x86_64

# Update build_id in game_config.gd with the current jj revision id.
sync-build-id:
  build_id=$(jj log -r @ --no-graph -T 'change_id.short()' | tr -d '\n') && \
    sed -i -e "s|^@export var build_id: String = \".*\"|@export var build_id: String = \"${build_id}\"|" godot/scripts/autoload/game_config.gd
