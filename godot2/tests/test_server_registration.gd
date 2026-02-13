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


func test_sync_request_returns_snapshot_for_registered_peer() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var server: HeadlessServer = HeadlessServer.new()
    server.create_match(config)
    server.authorize_peer(11, "alice")
    server.authorize_peer(12, "bob")
    var first_join: Dictionary = server.register_remote_client("demo_002", "alice", 11, null)
    var second_join: Dictionary = server.register_remote_client("demo_002", "bob", 12, null)
    assert_eq(str(first_join.get("reason", "")), "", "first join succeeds")
    assert_eq(str(second_join.get("reason", "")), "", "second join succeeds")

    var roll_result: Dictionary = server.rpc_roll_dice("demo_002", "alice", 11)
    assert_eq(str(roll_result.get("reason", "")), "", "roll succeeds")

    var sync_result: Dictionary = server.rpc_sync_request("demo_002", "alice", 11)
    assert_eq(str(sync_result.get("reason", "")), "", "sync succeeds")
    assert_true(sync_result.has("snapshot"), "sync includes snapshot")
    var snapshot: Dictionary = sync_result.get("snapshot", { })
    var players: Array = snapshot.get("players", [])
    var board: Dictionary = snapshot.get("board_state", { })
    assert_eq(str(snapshot.get("game_id", "")), "demo_002", "snapshot includes game id")
    assert_eq(players.size(), 2, "snapshot includes player states")
    assert_eq(int(board.get("size", 0)), 24, "snapshot includes board state")
    assert_true(int(sync_result.get("final_seq", -1)) > 0, "sync includes latest broadcast sequence")


func test_sync_request_rejects_peer_player_mismatch() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var server: HeadlessServer = HeadlessServer.new()
    server.create_match(config)
    server.authorize_peer(11, "alice")
    var join_result: Dictionary = server.register_remote_client("demo_002", "alice", 11, null)
    assert_eq(str(join_result.get("reason", "")), "", "join succeeds")

    var sync_result: Dictionary = server.rpc_sync_request("demo_002", "bob", 11)
    assert_eq(str(sync_result.get("reason", "")), "peer_player_mismatch", "sync rejects mismatched player id")


func test_sync_request_rejects_invalid_game_id() -> void:
    var server: HeadlessServer = HeadlessServer.new()
    server.authorize_peer(11, "alice")
    server.peer_slots[11] = {
        "game_id": "demo_002",
        "player_id": "alice",
        "player_index": 0,
    }

    var sync_result: Dictionary = server.rpc_sync_request("missing_game", "alice", 11)
    assert_eq(str(sync_result.get("reason", "")), "invalid_game_id", "sync rejects unknown game id")


func test_sync_request_rejects_unregistered_peer() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var server: HeadlessServer = HeadlessServer.new()
    server.create_match(config)

    var sync_result: Dictionary = server.rpc_sync_request("demo_002", "alice", 11)
    assert_eq(str(sync_result.get("reason", "")), "unregistered_peer", "sync rejects unknown peer slot")


func test_sync_snapshot_reflects_moved_pawn_state() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var server: HeadlessServer = HeadlessServer.new()
    server.create_match(config)
    server.authorize_peer(11, "alice")
    server.authorize_peer(12, "bob")
    var first_join: Dictionary = server.register_remote_client("demo_002", "alice", 11, null)
    var second_join: Dictionary = server.register_remote_client("demo_002", "bob", 12, null)
    assert_eq(str(first_join.get("reason", "")), "", "first join succeeds")
    assert_eq(str(second_join.get("reason", "")), "", "second join succeeds")

    var roll_result: Dictionary = server.rpc_roll_dice("demo_002", "alice", 11)
    assert_eq(str(roll_result.get("reason", "")), "", "roll succeeds")

    var sync_result: Dictionary = server.rpc_sync_request("demo_002", "alice", 11)
    assert_eq(str(sync_result.get("reason", "")), "", "sync succeeds")
    var snapshot: Dictionary = sync_result.get("snapshot", { })
    var players: Array = snapshot.get("players", [])
    assert_eq(players.size(), 2, "snapshot includes both players")
    var player_zero: Dictionary = players[0]
    assert_true(int(player_zero.get("position", 0)) > 0, "snapshot position reflects moved pawn")


func test_peer_disconnect_detaches_match_client_slot() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var server: HeadlessServer = HeadlessServer.new()
    var game_match = server.create_match(config)
    server.authorize_peer(11, "alice")
    var join_result: Dictionary = server.register_remote_client("demo_002", "alice", 11, null)
    assert_eq(str(join_result.get("reason", "")), "", "join succeeds")
    assert_true(server.peer_slots.has(11), "peer slot exists before disconnect")
    assert_true(game_match.clients[0] != null, "client slot bound before disconnect")

    server.handle_peer_disconnected(11)

    assert_false(server.peer_slots.has(11), "peer slot removed on disconnect")
    assert_true(game_match.clients[0] == null, "disconnected peer client detached from match slot")


func test_end_turn_rejects_invalid_game_id() -> void:
    var server: HeadlessServer = HeadlessServer.new()
    var result: Dictionary = server.rpc_end_turn("missing_game", "alice", 1)
    assert_eq(str(result.get("reason", "")), "invalid_game_id", "end turn rejects invalid game id")


func test_end_turn_rejects_unregistered_peer() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var server: HeadlessServer = HeadlessServer.new()
    server.create_match(config)
    var result: Dictionary = server.rpc_end_turn("demo_002", "alice", 1)
    assert_eq(str(result.get("reason", "")), "unregistered_peer", "end turn rejects unknown peer")


func test_end_turn_rejects_peer_game_id_mismatch() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var server: HeadlessServer = HeadlessServer.new()
    server.create_match(config)
    server.peer_slots[1] = {
        "game_id": "demo_003",
        "player_id": "alice",
        "player_index": 0,
    }
    var result: Dictionary = server.rpc_end_turn("demo_002", "alice", 1)
    assert_eq(str(result.get("reason", "")), "peer_game_id_mismatch", "end turn rejects peer game mismatch")


func test_end_turn_rejects_peer_player_mismatch() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var server: HeadlessServer = HeadlessServer.new()
    server.create_match(config)
    server.peer_slots[1] = {
        "game_id": "demo_002",
        "player_id": "alice",
        "player_index": 0,
    }
    var result: Dictionary = server.rpc_end_turn("demo_002", "bob", 1)
    assert_eq(str(result.get("reason", "")), "peer_player_mismatch", "end turn rejects peer player mismatch")


func test_buy_property_rejects_invalid_game_id() -> void:
    var server: HeadlessServer = HeadlessServer.new()
    var result: Dictionary = server.rpc_buy_property("missing_game", "alice", 6, 1)
    assert_eq(str(result.get("reason", "")), "invalid_game_id", "buy rejects invalid game id")


func test_buy_property_rejects_unregistered_peer() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var server: HeadlessServer = HeadlessServer.new()
    server.create_match(config)
    var result: Dictionary = server.rpc_buy_property("demo_002", "alice", 6, 1)
    assert_eq(str(result.get("reason", "")), "unregistered_peer", "buy rejects unknown peer")


func test_buy_property_rejects_peer_game_id_mismatch() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var server: HeadlessServer = HeadlessServer.new()
    server.create_match(config)
    server.peer_slots[1] = {
        "game_id": "demo_003",
        "player_id": "alice",
        "player_index": 0,
    }
    var result: Dictionary = server.rpc_buy_property("demo_002", "alice", 6, 1)
    assert_eq(str(result.get("reason", "")), "peer_game_id_mismatch", "buy rejects peer game mismatch")


func test_buy_property_rejects_peer_player_mismatch() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var server: HeadlessServer = HeadlessServer.new()
    server.create_match(config)
    server.peer_slots[1] = {
        "game_id": "demo_002",
        "player_id": "alice",
        "player_index": 0,
    }
    var result: Dictionary = server.rpc_buy_property("demo_002", "bob", 6, 1)
    assert_eq(str(result.get("reason", "")), "peer_player_mismatch", "buy rejects peer player mismatch")


func test_sync_snapshot_includes_pending_action() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var server: HeadlessServer = HeadlessServer.new()
    server.create_match(config)
    server.authorize_peer(11, "alice")
    server.authorize_peer(12, "bob")
    assert_eq(str(server.register_remote_client("demo_002", "alice", 11, null).get("reason", "")), "", "alice joins")
    assert_eq(str(server.register_remote_client("demo_002", "bob", 12, null).get("reason", "")), "", "bob joins")

    assert_eq(str(server.rpc_roll_dice("demo_002", "alice", 11).get("reason", "")), "", "roll succeeds")
    var sync_result: Dictionary = server.rpc_sync_request("demo_002", "alice", 11)
    assert_eq(str(sync_result.get("reason", "")), "", "sync succeeds")
    var snapshot: Dictionary = sync_result.get("snapshot", { })
    var pending_action: Dictionary = snapshot.get("pending_action", { })
    assert_eq(str(pending_action.get("type", "")), "buy_or_end_turn", "snapshot includes pending action type")
    assert_eq(int(pending_action.get("tile_index", -1)), 6, "snapshot includes pending tile index")
