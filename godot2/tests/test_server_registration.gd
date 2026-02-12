extends GutTest

const Config = preload("res://scripts/config.gd")
const HeadlessServer = preload("res://scripts/server.gd")


func test_join_rejects_invalid_game_id() -> void:
    var server: HeadlessServer = HeadlessServer.new()
    var server_node: Node = Node.new()
    var result: Dictionary = server.register_remote_client("missing_game", "alice", 1, server_node)
    server_node.free()
    assert_eq(str(result.get("reason", "")), "invalid_game_id", "invalid game id is rejected")


func test_rejects_duplicate_peer_registration() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var server: HeadlessServer = HeadlessServer.new()
    server.create_match(config)
    server.peer_slots[3] = {
        "game_id": "demo_002",
        "player_id": "alice",
        "player_index": 0,
    }

    var server_node: Node = Node.new()
    var result_b: Dictionary = server.register_remote_client("demo_002", "bob", 3, server_node)
    server_node.free()
    assert_eq(str(result_b.get("reason", "")), "peer_already_registered", "duplicate peer id rejected")
