extends GutTest

const Config = preload("res://scripts/config.gd")
const GameMatch = preload("res://scripts/match.gd")
const HeadlessServer = preload("res://scripts/server.gd")
const MatchTestClient = preload("res://tests/match_test_client.gd")


func test_roll_rejected_for_non_current_player() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()

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
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()

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


func test_roll_emits_landing_context_for_property_tile() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")
    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")

    game_match.rpc_roll_dice("demo_002", "alice")
    var landed: Array[Dictionary] = _filter_events(client_a, "rpc_tile_landed")
    assert_eq(landed.size(), 1, "tile landed should be emitted after roll")
    var event: Dictionary = landed[0]
    assert_eq(int(event.get("tile_index", -1)), 6, "first roll for demo_002 lands on tile 6")
    assert_eq(str(event.get("tile_type", "")), "property", "landing tile type")
    assert_eq(str(event.get("city", "")), "assuncion", "landing city name")
    assert_eq(int(event.get("owner_index", -99)), -1, "unowned property")
    assert_eq(float(event.get("toll_due", -1.0)), 0.0, "no toll on unowned property")
    assert_eq(str(event.get("action_required", "")), "buy_or_end_turn", "expected action for unowned property")


func test_landing_context_for_non_property_tile() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")
    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")

    game_match._server_move_pawn(4)
    var landed: Array[Dictionary] = _filter_events(client_a, "rpc_tile_landed")
    assert_eq(landed.size(), 1, "tile landed should be emitted")
    var event: Dictionary = landed[0]
    assert_eq(int(event.get("tile_index", -1)), 4, "expected incident tile index")
    assert_eq(str(event.get("tile_type", "")), "incident", "incident tile type")
    assert_eq(str(event.get("city", "")), "", "non-property has no city")
    assert_eq(int(event.get("owner_index", -99)), -1, "non-property has no owner")
    assert_eq(float(event.get("toll_due", -1.0)), 0.0, "non-property has no toll")
    assert_eq(str(event.get("action_required", "")), "resolve_incident", "incident requires incident resolution")


func test_landing_context_for_owned_property_by_other_player() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")
    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")

    var tiles: Array = game_match.board_state.get("tiles", [])
    var tile: Dictionary = tiles[6]
    tile["owner_index"] = 1
    tile["miner_batches"] = 2
    tiles[6] = tile
    game_match.board_state["tiles"] = tiles

    game_match._server_move_pawn(6)
    var landed: Array[Dictionary] = _filter_events(client_a, "rpc_tile_landed")
    assert_eq(landed.size(), 1, "tile landed should be emitted")
    var event: Dictionary = landed[0]
    assert_eq(int(event.get("tile_index", -1)), 6, "expected property tile index")
    assert_eq(str(event.get("tile_type", "")), "property", "property tile type")
    assert_eq(str(event.get("city", "")), "assuncion", "property city")
    assert_eq(int(event.get("owner_index", -99)), 1, "owner is other player")
    assert_true(is_equal_approx(float(event.get("toll_due", -1.0)), 7500.0), "assuncion toll with 2 miner batches at cycle 1")
    assert_eq(str(event.get("action_required", "")), "pay_toll", "owned by other requires pay_toll")


func test_landing_context_for_owned_property_by_self() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")
    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")

    var tiles: Array = game_match.board_state.get("tiles", [])
    var tile: Dictionary = tiles[6]
    tile["owner_index"] = 0
    tile["miner_batches"] = 4
    tiles[6] = tile
    game_match.board_state["tiles"] = tiles

    game_match._server_move_pawn(6)
    var landed: Array[Dictionary] = _filter_events(client_a, "rpc_tile_landed")
    assert_eq(landed.size(), 1, "tile landed should be emitted")
    var event: Dictionary = landed[0]
    assert_eq(int(event.get("owner_index", -99)), 0, "owner is landing player")
    assert_eq(float(event.get("toll_due", -1.0)), 0.0, "self-owned property has no toll")
    assert_eq(str(event.get("action_required", "")), "end_turn", "self-owned property ends turn")


func test_buy_property_resolves_pending_action_and_advances_turn() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")
    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")

    game_match.rpc_roll_dice("demo_002", "alice")
    var buy_reason: String = game_match.rpc_buy_property("demo_002", "alice", 6)
    assert_eq(buy_reason, "", "buy property should succeed")
    assert_true(game_match.pending_action.is_empty(), "pending action cleared after successful buy")

    var tile: Dictionary = game_match._tile_from_index(6)
    assert_eq(int(tile.get("owner_index", -1)), 0, "tile ownership transferred to buyer")
    assert_true(is_equal_approx(game_match.state.players[0].fiat_balance, 950000.0), "buyer fiat balance reduced by property price")

    var acquired: Array[Dictionary] = _filter_events(client_a, "rpc_property_acquired")
    assert_eq(acquired.size(), 1, "property acquired event emitted once")
    var turns: Array[Dictionary] = _filter_events(client_a, "rpc_turn_started")
    assert_eq(turns.size(), 2, "next turn starts after buy resolution")
    assert_eq(int(turns[1].get("player_index", -1)), 1, "turn advanced to next player")
    assert_true(int(acquired[0].get("seq", -1)) < int(turns[1].get("seq", -1)), "property acquired emitted before next turn started")


func test_end_turn_resolves_pending_action_without_purchase() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")
    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")

    game_match.rpc_roll_dice("demo_002", "alice")
    var end_reason: String = game_match.rpc_end_turn("demo_002", "alice")
    assert_eq(end_reason, "", "end turn should succeed")
    assert_true(game_match.pending_action.is_empty(), "pending action cleared after end turn")

    var tile: Dictionary = game_match._tile_from_index(6)
    assert_eq(int(tile.get("owner_index", -1)), -1, "tile remains unowned when buy is skipped")
    var turns: Array[Dictionary] = _filter_events(client_a, "rpc_turn_started")
    assert_eq(turns.size(), 2, "next turn starts after end turn resolution")
    assert_eq(int(turns[1].get("player_index", -1)), 1, "turn advanced to next player")


func test_buy_property_rejected_without_pending_action() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")
    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")

    var reason: String = game_match.rpc_buy_property("demo_002", "alice", 6)
    assert_eq(reason, "no_pending_action", "buy requires pending action")


func test_end_turn_rejected_for_non_current_player() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()

    var result_a: Dictionary = game_match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")
    var result_b: Dictionary = game_match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")

    game_match.rpc_roll_dice("demo_002", "alice")
    var reason: String = game_match.rpc_end_turn("demo_002", "bob")
    assert_eq(reason, "not_current_player", "only current player can resolve pending action")


func test_buy_property_rejected_on_tile_mismatch() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    game_match.rpc_roll_dice("demo_002", "alice")
    var reason: String = game_match.rpc_buy_property("demo_002", "alice", 5)
    assert_eq(reason, "tile_mismatch", "buy must match pending tile")


func test_buy_property_rejected_when_property_already_owned() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    game_match.rpc_roll_dice("demo_002", "alice")
    var tile: Dictionary = game_match._tile_from_index(6)
    tile["owner_index"] = 1
    var tiles: Array = game_match.board_state.get("tiles", [])
    tiles[6] = tile
    game_match.board_state["tiles"] = tiles

    var reason: String = game_match.rpc_buy_property("demo_002", "alice", 6)
    assert_eq(reason, "property_already_owned", "buy rejects if property is already owned")


func test_buy_property_rejected_for_insufficient_fiat() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    game_match.rpc_roll_dice("demo_002", "alice")
    game_match.state.players[0].fiat_balance = 1.0
    var reason: String = game_match.rpc_buy_property("demo_002", "alice", 6)
    assert_eq(reason, "insufficient_fiat", "buy rejects when player cannot afford property")


func test_roll_rejected_while_pending_action_required() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    game_match.rpc_roll_dice("demo_002", "alice")
    game_match.rpc_roll_dice("demo_002", "alice")
    var rejected: Array[Dictionary] = _filter_events(client_a, "rpc_action_rejected")
    assert_true(rejected.size() > 0, "rejection event emitted for extra roll")
    var latest: Dictionary = rejected[rejected.size() - 1]
    assert_eq(str(latest.get("reason", "")), "pending_action_required", "roll blocked until pending action resolved")


func test_turn_number_increments_after_last_player_ends_turn() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    game_match.rpc_roll_dice("demo_002", "alice")
    assert_eq(game_match.rpc_end_turn("demo_002", "alice"), "", "alice ends turn")
    game_match.rpc_roll_dice("demo_002", "bob")
    assert_eq(game_match.rpc_end_turn("demo_002", "bob"), "", "bob ends turn")

    assert_eq(game_match.state.current_player_index, 0, "turn wraps to first player")
    assert_eq(game_match.state.turn_number, 2, "turn number increments after last player resolves turn")


func _filter_events(client: MatchTestClient, method: String) -> Array[Dictionary]:
    var results: Array[Dictionary] = []
    for event in client.events:
        if str(event.get("method", "")) == method:
            results.append(event)
    return results
