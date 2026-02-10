extends GutTest

const Config = preload("res://scripts/config.gd")
const GameMatch = preload("res://scripts/match.gd")
const HeadlessServer = preload("res://scripts/server.gd")
const Client = preload("res://scripts/client.gd")


class TestClient:
    extends Client

    var events: Array[Dictionary] = []


    func rpc_game_started(seq: int, new_game_id: String) -> void:
        events.append(
            {
                "method": "rpc_game_started",
                "seq": seq,
                "game_id": new_game_id,
            },
        )


    func rpc_turn_started(seq: int, player_index: int, turn_number: int, cycle: int) -> void:
        events.append(
            {
                "method": "rpc_turn_started",
                "seq": seq,
                "player_index": player_index,
                "turn_number": turn_number,
                "cycle": cycle,
            },
        )


    func rpc_player_joined(seq: int, player_id: String, player_index: int) -> void:
        events.append(
            {
                "method": "rpc_player_joined",
                "seq": seq,
                "player_id": player_id,
                "player_index": player_index,
            },
        )


    func rpc_dice_rolled(seq: int, die_1: int, die_2: int, total: int) -> void:
        events.append(
            {
                "method": "rpc_dice_rolled",
                "seq": seq,
                "die_1": die_1,
                "die_2": die_2,
                "total": total,
            },
        )


    func rpc_pawn_moved(seq: int, from_tile: int, to_tile: int, passed_tiles: Array[int]) -> void:
        events.append(
            {
                "method": "rpc_pawn_moved",
                "seq": seq,
                "from_tile": from_tile,
                "to_tile": to_tile,
                "passed_tiles": passed_tiles,
            },
        )


    func rpc_tile_landed(seq: int, tile_index: int) -> void:
        events.append(
            {
                "method": "rpc_tile_landed",
                "seq": seq,
                "tile_index": tile_index,
            },
        )


    func rpc_cycle_started(seq: int, cycle: int, inflation_active: bool) -> void:
        events.append(
            {
                "method": "rpc_cycle_started",
                "seq": seq,
                "cycle": cycle,
                "inflation_active": inflation_active,
            },
        )


    func rpc_action_rejected(seq: int, reason: String) -> void:
        events.append(
            {
                "method": "rpc_action_rejected",
                "seq": seq,
                "reason": reason,
            },
        )


func test_match_start_emits_game_started() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    assert_eq(config.player_count, 2, "demo_002 expects two players")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: TestClient = TestClient.new()
    var client_b: TestClient = TestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")
    _assert_player_joined_events(client_a, ["alice"])

    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")

    _assert_player_joined_events(client_a, ["alice", "bob"])
    _assert_game_start_events(_filter_events(client_a, "rpc_game_started"), _filter_events(client_a, "rpc_turn_started"), config.game_id)
    _assert_game_start_events(_filter_events(client_b, "rpc_game_started"), _filter_events(client_b, "rpc_turn_started"), config.game_id)


func test_join_broadcasts_player_joined() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: TestClient = TestClient.new()
    var client_b: TestClient = TestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")

    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")

    var joined_a: Array[Dictionary] = _filter_events(client_a, "rpc_player_joined")
    var joined_b: Array[Dictionary] = _filter_events(client_b, "rpc_player_joined")
    assert_eq(joined_a.size(), 2, "first client should see both join broadcasts")
    assert_eq(joined_b.size(), 1, "second client should see its own join broadcast")
    assert_eq(str(joined_a[0].get("player_id", "")), "alice", "first join is alice")
    assert_eq(str(joined_a[1].get("player_id", "")), "bob", "second join is bob")
    assert_eq(str(joined_b[0].get("player_id", "")), "bob", "second client receives bob join")


func test_join_rejects_duplicate_player_id() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: TestClient = TestClient.new()
    var client_b: TestClient = TestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")

    var result_b: Dictionary = game_match.assign_client("alice", client_b)
    assert_eq(str(result_b.get("reason", "")), "player_id_taken", "duplicate player_id is rejected")


func test_join_rejects_when_match_full() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: TestClient = TestClient.new()
    var client_b: TestClient = TestClient.new()
    var client_c: TestClient = TestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")

    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")

    var result_c: Dictionary = game_match.assign_client("carol", client_c)
    assert_eq(str(result_c.get("reason", "")), "match_full", "extra client is rejected when match is full")


func test_join_rejects_invalid_game_id() -> void:
    var server: HeadlessServer = HeadlessServer.new()
    var server_node: Node = Node.new()
    var result: Dictionary = server.register_remote_client("missing_game", "alice", 1, server_node)
    server_node.free()
    assert_eq(str(result.get("reason", "")), "invalid_game_id", "invalid game id is rejected")


func test_roll_rejected_for_non_current_player() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: TestClient = TestClient.new()
    var client_b: TestClient = TestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")

    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")

    game_match.rpc_roll_dice("demo_002", "bob")
    var rejected: Array[Dictionary] = _filter_events(client_b, "rpc_action_rejected")
    assert_eq(rejected.size(), 1, "non-current player roll is rejected")
    assert_eq(str(rejected[0].get("reason", "")), "not_current_player", "rejection reason")


func test_roll_rejected_before_match_start() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: TestClient = TestClient.new()
    var client_b: TestClient = TestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")

    game_match.rpc_roll_dice("demo_002", "alice")
    var rejected: Array[Dictionary] = _filter_events(client_a, "rpc_action_rejected")
    assert_eq(rejected.size(), 1, "roll before match start is rejected")
    assert_eq(str(rejected[0].get("reason", "")), "match_not_started", "rejection reason")


func test_roll_rejects_invalid_game_id() -> void:
    var server: HeadlessServer = HeadlessServer.new()
    var result: Dictionary = server.rpc_roll_dice("missing_game", "alice")
    assert_eq(str(result.get("reason", "")), "invalid_game_id", "invalid game id roll is rejected")


func test_roll_rejects_unregistered_player_id() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var server: HeadlessServer = HeadlessServer.new()
    server.create_match(config)

    var roll_result: Dictionary = server.rpc_roll_dice("demo_002", "ghost", 10)
    assert_eq(str(roll_result.get("reason", "")), "unregistered_peer", "unknown peer is rejected")


func test_roll_rejects_peer_game_id_mismatch() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var config_other: Config = Config.new("res://configs/demo_003.toml")
    var server: HeadlessServer = HeadlessServer.new()
    server.create_match(config)
    server.create_match(config_other)
    server.peer_slots[7] = {
        "game_id": "demo_002",
        "player_id": "alice",
        "player_index": 0,
    }

    var roll_result: Dictionary = server.rpc_roll_dice("demo_003", "alice", 7)
    assert_eq(str(roll_result.get("reason", "")), "peer_game_id_mismatch", "peer game id mismatch is rejected")


func test_roll_rejects_peer_player_mismatch() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var server: HeadlessServer = HeadlessServer.new()
    server.create_match(config)
    server.peer_slots[8] = {
        "game_id": "demo_002",
        "player_id": "alice",
        "player_index": 0,
    }

    var roll_result: Dictionary = server.rpc_roll_dice("demo_002", "bob", 8)
    assert_eq(str(roll_result.get("reason", "")), "peer_player_mismatch", "peer player mismatch is rejected")


func test_broadcast_sequence_is_monotonic() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: TestClient = TestClient.new()
    var client_b: TestClient = TestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")
    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")

    _assert_monotonic_sequences(client_a)
    _assert_monotonic_sequences(client_b)


func test_turn_started_matches_state_player_index() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: TestClient = TestClient.new()
    var client_b: TestClient = TestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")
    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")

    var turn_started: Array[Dictionary] = _filter_events(client_a, "rpc_turn_started")
    assert_eq(turn_started.size(), 1, "turn started event emitted")
    assert_eq(int(turn_started[0].get("player_index", -1)), game_match.state.current_player_index, "turn index matches state")


func test_last_seq_progresses_on_join() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: TestClient = TestClient.new()
    var client_b: TestClient = TestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")
    assert_eq(game_match.last_sequence(), 1, "first join emits player joined")

    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")
    assert_eq(game_match.last_sequence(), 4, "second join emits start events")


func test_three_player_match_starts_on_third_join() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    config.game_id = "demo_003_three"
    config.player_count = 3
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: TestClient = TestClient.new()
    var client_b: TestClient = TestClient.new()
    var client_c: TestClient = TestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")
    assert_eq(_filter_events(client_a, "rpc_game_started").size(), 0, "no game start after first join")

    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")
    assert_eq(_filter_events(client_a, "rpc_game_started").size(), 0, "no game start after second join")
    assert_eq(_filter_events(client_b, "rpc_game_started").size(), 0, "no game start after second join for second client")

    var result_c: Dictionary = game_match.assign_client("carol", client_c)
    assert_eq(str(result_c.get("reason", "")), "", "third client should register")

    var started_a: Array[Dictionary] = _filter_events(client_a, "rpc_game_started")
    var started_b: Array[Dictionary] = _filter_events(client_b, "rpc_game_started")
    var started_c: Array[Dictionary] = _filter_events(client_c, "rpc_game_started")
    assert_eq(started_a.size(), 1, "game started after third join")
    assert_eq(started_b.size(), 1, "game started after third join for second client")
    assert_eq(started_c.size(), 1, "game started after third join for third client")
    assert_eq(int(started_a[0].get("seq", -1)), 4, "game started seq after three joins")


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


func test_rejects_invalid_player_id() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: TestClient = TestClient.new()
    var result: Dictionary = game_match.assign_client("", client_a)
    assert_eq(str(result.get("reason", "")), "invalid_player_id", "empty player_id rejected")


func test_rejects_invalid_player_index() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: TestClient = TestClient.new()
    var reason_negative: String = game_match.register_client_at_index("alice", -1, client_a)
    assert_eq(reason_negative, "invalid_player_index", "negative index rejected")
    var reason_large: String = game_match.register_client_at_index("alice", 99, client_a)
    assert_eq(reason_large, "invalid_player_index", "out-of-range index rejected")


func test_match_full_rejected_via_server_registration() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: TestClient = TestClient.new()
    var client_b: TestClient = TestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client registers")
    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client registers")

    var client_c: TestClient = TestClient.new()
    var result_c: Dictionary = game_match.assign_client("carol", client_c)
    assert_eq(str(result_c.get("reason", "")), "match_full", "extra client rejected")


func test_game_start_emitted_once_after_full() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: TestClient = TestClient.new()
    var client_b: TestClient = TestClient.new()
    var client_c: TestClient = TestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")
    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")

    var started_before: int = _filter_events(client_a, "rpc_game_started").size()
    var result_c: Dictionary = game_match.assign_client("carol", client_c)
    assert_eq(str(result_c.get("reason", "")), "match_full", "extra join rejected")
    var started_after: int = _filter_events(client_a, "rpc_game_started").size()
    assert_eq(started_before, started_after, "game start not emitted again")


func _assert_game_start_events(game_started: Array[Dictionary], turn_started: Array[Dictionary], game_id: String) -> void:
    assert_eq(game_started.size(), 1, "expected one game started event")
    assert_eq(turn_started.size(), 1, "expected one turn started event")
    var first: Dictionary = game_started[0]
    assert_eq(int(first.get("seq", -1)), 3, "game started seq")
    assert_eq(str(first.get("game_id", "")), game_id, "game id propagated")
    var second: Dictionary = turn_started[0]
    assert_eq(int(second.get("seq", -1)), 4, "turn started seq")
    assert_eq(int(second.get("player_index", -1)), 0, "first turn player index")
    assert_eq(int(second.get("turn_number", -1)), 1, "turn number")
    assert_eq(int(second.get("cycle", -1)), 1, "cycle number")


func _assert_player_joined_events(client: TestClient, expected_ids: Array[String]) -> void:
    var joined: Array[Dictionary] = _filter_events(client, "rpc_player_joined")
    assert_eq(joined.size(), expected_ids.size(), "player joined count")
    for index in range(expected_ids.size()):
        var event: Dictionary = joined[index]
        assert_eq(str(event.get("player_id", "")), expected_ids[index], "player joined id")


func _filter_events(client: TestClient, method: String) -> Array[Dictionary]:
    var results: Array[Dictionary] = []
    for event in client.events:
        if str(event.get("method", "")) == method:
            results.append(event)
    return results


func _assert_monotonic_sequences(client: TestClient) -> void:
    var last_seq: int = 0
    for event in client.events:
        var seq_value: int = int(event.get("seq", 0))
        if seq_value <= 0:
            continue
        assert_gt(seq_value, last_seq, "broadcast sequences are increasing")
        last_seq = seq_value
