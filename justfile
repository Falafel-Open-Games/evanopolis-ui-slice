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

# Run GUT unit tests (godot2).
test-godot2:
  just import-godot2
  GODOT_USER_DIR=/tmp/godot-user XDG_CONFIG_HOME=/tmp/godot-config XDG_DATA_HOME=/tmp/godot-data \
    godot --headless --path godot2 -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit \
      2> >(sed \
        -e '/^ERROR: Condition "_sock == -1"/d' \
        -e '/^ERROR: Condition "err != OK"/d' \
        -e '/^   at: open (drivers\/unix\/net_socket_unix\.cpp:267)$/d' \
        -e '/^   at: listen (core\/io\/tcp_server\.cpp:57)$/d' \
        >&2) \
    | sed \
        -e '/^   at: open (drivers\/unix\/net_socket_unix\.cpp:267)$/d' \
        -e '/^   at: listen (core\/io\/tcp_server\.cpp:57)$/d'

# Download and install GUT into godot2/addons (godot2).
install-gut:
  mkdir -p /tmp/gut
  curl -L -o /tmp/gut/gut.zip https://github.com/bitwes/Gut/archive/refs/tags/v9.5.0.zip
  rm -rf godot2/addons/gut
  unzip -q /tmp/gut/gut.zip -d /tmp/gut
  mkdir -p godot2/addons
  cp -a /tmp/gut/Gut-9.5.0/addons/gut godot2/addons/

# Import assets and class_names for godot2 (needed for GUT class_name registration).
import-godot2:
  GODOT_USER_DIR=/tmp/godot-user XDG_CONFIG_HOME=/tmp/godot-config XDG_DATA_HOME=/tmp/godot-data \
    godot --headless --path godot2 --import \
      2> >(sed \
        -e '/^ERROR: Condition "_sock == -1"/d' \
        -e '/^ERROR: Condition "err != OK"/d' \
        -e '/^   at: open (drivers\/unix\/net_socket_unix\.cpp:267)$/d' \
        -e '/^   at: listen (core\/io\/tcp_server\.cpp:57)$/d' \
        >&2) \
    | sed \
        -e '/^   at: open (drivers\/unix\/net_socket_unix\.cpp:267)$/d' \
        -e '/^   at: listen (core\/io\/tcp_server\.cpp:57)$/d'

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
