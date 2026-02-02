extends "res://scripts/headless_rpc.gd"

const Config = preload("res://scripts/config.gd")
const HeadlessServer = preload("res://scripts/server.gd")

const DEFAULT_PORT: int = 9010
const DEFAULT_CONFIG_DIR: String = "res://configs"

var server: HeadlessServer
var config_paths: Array[String] = []
var port: int = DEFAULT_PORT


func _ready() -> void:
    var args: PackedStringArray = OS.get_cmdline_args()
    _parse_args(args)
    _start_server()
    _load_matches()


func _parse_args(args: PackedStringArray) -> void:
    var index: int = 0
    var config_dir: String = DEFAULT_CONFIG_DIR
    while index < args.size():
        var arg: String = args[index]
        if arg == "--config-dir" and index + 1 < args.size():
            config_dir = args[index + 1]
            index += 2
            continue
        if arg == "--config" and index + 1 < args.size():
            config_paths.append(args[index + 1])
            index += 2
            continue
        if arg == "--port" and index + 1 < args.size():
            port = int(args[index + 1])
            index += 2
            continue
        index += 1
    if config_paths.is_empty():
        config_paths = _configs_from_dir(config_dir)


func _start_server() -> void:
    server = HeadlessServer.new()
    var peer: WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
    var result: int = peer.create_server(port, "0.0.0.0")
    assert(result == OK)
    multiplayer.multiplayer_peer = peer
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    print("server: listening on port %d" % port)


func _load_matches() -> void:
    assert(not config_paths.is_empty())
    for path in config_paths:
        var config: Config = Config.new(path)
        assert(not config.game_id.is_empty())
        assert(not server.matches.has(config.game_id))
        server.create_match(config)
        print("server: loaded match game_id=%s from %s" % [config.game_id, path])


func _configs_from_dir(config_dir: String) -> Array[String]:
    var results: Array[String] = []
    var dir: DirAccess = DirAccess.open(config_dir)
    assert(dir)
    dir.list_dir_begin()
    var file_name: String = dir.get_next()
    while file_name != "":
        if not dir.current_is_dir() and file_name.ends_with(".toml"):
            results.append(config_dir.path_join(file_name))
        file_name = dir.get_next()
    dir.list_dir_end()
    results.sort()
    return results


func _on_peer_connected(peer_id: int) -> void:
    print("server: peer connected %d" % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
    print("server: peer disconnected %d" % peer_id)


func _handle_join(game_id: String, player_id: String) -> void:
    var sender_id: int = multiplayer.get_remote_sender_id()
    var result: Dictionary = server.register_remote_client(game_id, player_id, sender_id, self)
    var reason: String = str(result.get("reason", ""))
    var seq: int = int(result.get("seq", 0))
    if not reason.is_empty():
        rpc_id(sender_id, "rpc_action_rejected", seq, reason)
        return
    var assigned_index: int = int(result.get("player_index", -1))
    rpc_id(sender_id, "rpc_join_accepted", seq, player_id, assigned_index)
    print("server: join game_id=%s player_id=%s player=%d peer=%d" % [game_id, player_id, assigned_index, sender_id])


func _handle_roll_dice(game_id: String, player_id: String) -> void:
    var sender_id: int = multiplayer.get_remote_sender_id()
    var result: Dictionary = server.rpc_roll_dice(game_id, player_id, sender_id)
    var reason: String = str(result.get("reason", ""))
    var seq: int = int(result.get("seq", 0))
    if not reason.is_empty():
        rpc_id(sender_id, "rpc_action_rejected", seq, reason)
