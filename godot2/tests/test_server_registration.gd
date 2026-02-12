extends GutTest

const Config = preload("res://scripts/config.gd")
const HeadlessServer = preload("res://scripts/server.gd")


func test_join_rejects_invalid_game_id() -> void:
    var server: HeadlessServer = HeadlessServer.new()
    server.authorize_peer(1, "alice")
    var result: Dictionary = server.register_remote_client("missing_game", "alice", 1, null)
    assert_eq(str(result.get("reason", "")), "invalid_game_id", "invalid game id is rejected")


func test_rejects_duplicate_peer_registration() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var server: HeadlessServer = HeadlessServer.new()
    server.create_match(config)
    server.authorize_peer(3, "bob")
    server.peer_slots[3] = {
        "game_id": "demo_002",
        "player_id": "alice",
        "player_index": 0,
    }

    var result_b: Dictionary = server.register_remote_client("demo_002", "bob", 3, null)
    assert_eq(str(result_b.get("reason", "")), "peer_already_registered", "duplicate peer id rejected")


func test_reconnect_rebinds_peer_slot() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var server: HeadlessServer = HeadlessServer.new()
    server.create_match(config)
    server.authorize_peer(11, "alice")
    server.authorize_peer(22, "alice")

    var first_join: Dictionary = server.register_remote_client("demo_002", "alice", 11, null)
    assert_eq(str(first_join.get("reason", "")), "", "first join succeeds")
    assert_true(server.peer_slots.has(11), "first peer slot exists")

    var reconnect_join: Dictionary = server.register_remote_client("demo_002", "alice", 22, null)
    assert_eq(str(reconnect_join.get("reason", "")), "", "reconnect succeeds")
    assert_eq(int(reconnect_join.get("replaced_peer_id", -1)), 11, "old peer id returned")
    assert_false(server.peer_slots.has(11), "old peer slot removed")
    assert_true(server.peer_slots.has(22), "new peer slot registered")
