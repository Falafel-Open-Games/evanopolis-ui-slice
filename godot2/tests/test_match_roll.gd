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
    assert_true(is_equal_approx(float(event.get("buy_price", -1.0)), 4.0), "buy price provided for unowned property")
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
    assert_eq(float(event.get("buy_price", -1.0)), 0.0, "non-property has no buy price")
    assert_eq(str(event.get("action_required", "")), "resolve_incident", "incident requires incident resolution")


func test_incident_resolution_emits_events_flips_tile_and_advances_turn() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    game_match._server_move_pawn(4)

    var incident_drawn: Array[Dictionary] = _filter_events(client_a, "rpc_incident_drawn")
    assert_eq(incident_drawn.size(), 1, "incident draw event emitted once")
    var incident_flip: Array[Dictionary] = _filter_events(client_a, "rpc_incident_type_changed")
    assert_eq(incident_flip.size(), 1, "incident tile flip event emitted once")
    if incident_flip.size() == 1:
        assert_eq(str(incident_flip[0].get("incident_kind", "")), "bull", "incident tile flips from bear to bull")

    var mutation_count: int = 0
    mutation_count += _filter_events(client_a, "rpc_player_balance_changed").size()
    mutation_count += _filter_events(client_a, "rpc_player_sent_to_inspection").size()
    mutation_count += _filter_events(client_a, "rpc_inspection_voucher_granted").size()
    assert_true(mutation_count >= 1, "incident resolution emits at least one mutation event")

    var turns: Array[Dictionary] = _filter_events(client_a, "rpc_turn_started")
    assert_eq(turns.size(), 2, "next turn starts after incident resolution")
    assert_eq(int(turns[1].get("player_index", -1)), 1, "turn advanced to next player")
    assert_true(game_match.pending_action.is_empty(), "pending action cleared after incident resolution")

    if incident_flip.size() == 1 and turns.size() == 2:
        var flip_seq: int = int(incident_flip[0].get("seq", -1))
        var next_turn_seq: int = int(turns[1].get("seq", -1))
        assert_true(flip_seq < next_turn_seq, "incident flip emitted before next turn started")


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
    assert_true(is_equal_approx(float(event.get("toll_due", -1.0)), 0.6), "assuncion toll with 2 miner batches at cycle 1")
    assert_eq(float(event.get("buy_price", -1.0)), 0.0, "owned property has no buy price")
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
    assert_eq(float(event.get("buy_price", -1.0)), 0.0, "self-owned property has no buy price")
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
    assert_true(is_equal_approx(game_match.state.players[0].fiat_balance, 16.0), "buyer fiat balance reduced by property price")

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


func test_pay_toll_resolves_pending_action_and_advances_turn() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    var tiles: Array = game_match.board_state.get("tiles", [])
    var tile: Dictionary = tiles[6]
    tile["owner_index"] = 1
    tile["miner_batches"] = 2
    tiles[6] = tile
    game_match.board_state["tiles"] = tiles

    game_match.rpc_roll_dice("demo_002", "alice")
    var pay_reason: String = game_match.rpc_pay_toll("demo_002", "alice")
    assert_eq(pay_reason, "", "pay toll should succeed")
    assert_true(game_match.pending_action.is_empty(), "pending action cleared after pay toll")
    assert_true(is_equal_approx(game_match.state.players[0].fiat_balance, 19.4), "payer fiat reduced by toll")
    assert_true(is_equal_approx(game_match.state.players[1].fiat_balance, 20.6), "owner fiat increased by toll")

    var toll_paid: Array[Dictionary] = _filter_events(client_a, "rpc_toll_paid")
    assert_eq(toll_paid.size(), 1, "toll paid event emitted once")
    var turns: Array[Dictionary] = _filter_events(client_a, "rpc_turn_started")
    assert_eq(turns.size(), 2, "next turn starts after pay toll resolution")
    assert_eq(int(turns[1].get("player_index", -1)), 1, "turn advanced to next player")
    assert_true(int(toll_paid[0].get("seq", -1)) < int(turns[1].get("seq", -1)), "toll paid emitted before next turn started")


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


func test_pay_toll_rejected_without_pending_action() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    var reason: String = game_match.rpc_pay_toll("demo_002", "alice")
    assert_eq(reason, "no_pending_action", "pay toll requires pending action")


func test_pay_toll_rejected_for_insufficient_fiat() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    var tiles: Array = game_match.board_state.get("tiles", [])
    var tile: Dictionary = tiles[6]
    tile["owner_index"] = 1
    tile["miner_batches"] = 2
    tiles[6] = tile
    game_match.board_state["tiles"] = tiles

    game_match.rpc_roll_dice("demo_002", "alice")
    game_match.state.players[0].fiat_balance = 0.1
    var reason: String = game_match.rpc_pay_toll("demo_002", "alice")
    assert_eq(reason, "insufficient_fiat", "pay toll rejects when payer cannot afford toll")


func test_pay_toll_rejected_for_non_current_player() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    var tiles: Array = game_match.board_state.get("tiles", [])
    var tile: Dictionary = tiles[6]
    tile["owner_index"] = 1
    tile["miner_batches"] = 2
    tiles[6] = tile
    game_match.board_state["tiles"] = tiles

    game_match.rpc_roll_dice("demo_002", "alice")
    var reason: String = game_match.rpc_pay_toll("demo_002", "bob")
    assert_eq(reason, "not_current_player", "only current player can pay toll")


func test_pay_toll_rejected_when_pending_action_type_mismatch() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    game_match.rpc_roll_dice("demo_002", "alice")
    var reason: String = game_match.rpc_pay_toll("demo_002", "alice")
    assert_eq(reason, "action_not_allowed", "pay toll rejected when pending action is buy_or_end_turn")


func test_pay_toll_rejected_with_invalid_owner_index() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    var tiles: Array = game_match.board_state.get("tiles", [])
    var tile: Dictionary = tiles[6]
    tile["owner_index"] = 1
    tile["miner_batches"] = 2
    tiles[6] = tile
    game_match.board_state["tiles"] = tiles

    game_match.rpc_roll_dice("demo_002", "alice")
    game_match.pending_action["owner_index"] = 99
    var reason: String = game_match.rpc_pay_toll("demo_002", "alice")
    assert_eq(reason, "invalid_owner", "pay toll rejects invalid owner index")


func test_pay_toll_rejected_when_owner_is_payer() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    var tiles: Array = game_match.board_state.get("tiles", [])
    var tile: Dictionary = tiles[6]
    tile["owner_index"] = 1
    tile["miner_batches"] = 2
    tiles[6] = tile
    game_match.board_state["tiles"] = tiles

    game_match.rpc_roll_dice("demo_002", "alice")
    game_match.pending_action["owner_index"] = 0
    var reason: String = game_match.rpc_pay_toll("demo_002", "alice")
    assert_eq(reason, "invalid_owner", "pay toll rejects self as owner")


func test_pay_toll_rejected_with_invalid_toll_amount() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    var tiles: Array = game_match.board_state.get("tiles", [])
    var tile: Dictionary = tiles[6]
    tile["owner_index"] = 1
    tile["miner_batches"] = 2
    tiles[6] = tile
    game_match.board_state["tiles"] = tiles

    game_match.rpc_roll_dice("demo_002", "alice")
    game_match.pending_action["amount"] = 0.0
    var reason: String = game_match.rpc_pay_toll("demo_002", "alice")
    assert_eq(reason, "invalid_toll_amount", "pay toll rejects non-positive toll amount")


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


func test_incident_event_order_is_strict() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    game_match._server_move_pawn(4)

    var landed: Array[Dictionary] = _filter_events(client_a, "rpc_tile_landed")
    var drawn: Array[Dictionary] = _filter_events(client_a, "rpc_incident_drawn")
    var balance_changed: Array[Dictionary] = _filter_events(client_a, "rpc_player_balance_changed")
    var incident_flip: Array[Dictionary] = _filter_events(client_a, "rpc_incident_type_changed")
    var turns: Array[Dictionary] = _filter_events(client_a, "rpc_turn_started")

    assert_eq(landed.size(), 1, "one tile landed event")
    assert_eq(drawn.size(), 1, "one incident drawn event")
    assert_eq(balance_changed.size(), 1, "one balance mutation event for first bear card")
    assert_eq(incident_flip.size(), 1, "one incident flip event")
    assert_true(turns.size() >= 2, "at least two turn started events in stream")
    if landed.size() == 1 and drawn.size() == 1 and balance_changed.size() == 1 and incident_flip.size() == 1 and turns.size() >= 2:
        var tile_landed_seq: int = int(landed[0].get("seq", -1))
        var drawn_seq: int = int(drawn[0].get("seq", -1))
        var balance_seq: int = int(balance_changed[0].get("seq", -1))
        var flip_seq: int = int(incident_flip[0].get("seq", -1))
        var next_turn_seq: int = int(turns[turns.size() - 1].get("seq", -1))
        assert_true(tile_landed_seq < drawn_seq, "tile landed emitted before incident draw")
        assert_true(drawn_seq < balance_seq, "incident draw emitted before balance mutation")
        assert_true(balance_seq < flip_seq, "balance mutation emitted before tile flip")
        assert_true(flip_seq < next_turn_seq, "tile flip emitted before next turn started")


func test_incident_tile_flips_back_to_bear_on_second_landing() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    game_match._server_move_pawn(4)
    game_match._server_move_pawn(4)

    var incident_flip: Array[Dictionary] = _filter_events(client_a, "rpc_incident_type_changed")
    assert_eq(incident_flip.size(), 2, "two incident flips emitted across two landings")
    if incident_flip.size() == 2:
        assert_eq(str(incident_flip[0].get("incident_kind", "")), "bull", "first landing flips bear->bull")
        assert_eq(str(incident_flip[1].get("incident_kind", "")), "bear", "second landing flips bull->bear")
    var tile: Dictionary = game_match._tile_from_index(4)
    assert_eq(str(tile.get("incident_kind", "")), "bear", "tile state returns to bear after second landing")


func test_bear_deck_cycles_deterministically() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])

    var card_1: Dictionary = game_match._draw_incident_card("bear")
    var card_2: Dictionary = game_match._draw_incident_card("bear")
    var card_3: Dictionary = game_match._draw_incident_card("bear")
    var card_4: Dictionary = game_match._draw_incident_card("bear")

    assert_eq(str(card_1.get("card_id", "")), "bear_fine_eva_2", "first bear card")
    assert_eq(str(card_2.get("card_id", "")), "bear_fine_eva_3", "second bear card")
    assert_eq(str(card_3.get("card_id", "")), "bear_legal_inspection", "third bear card")
    assert_eq(str(card_4.get("card_id", "")), "bear_fine_eva_2", "bear deck wraps to first card")


func test_landing_on_inspection_marks_player_and_emits_event() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    game_match._server_move_pawn(12)

    assert_true(game_match.state.players[0].in_inspection, "landing on inspection should set in_inspection")
    var sent_to_inspection: Array[Dictionary] = _filter_events(client_a, "rpc_player_sent_to_inspection")
    assert_eq(sent_to_inspection.size(), 1, "inspection landing should emit one inspection mutation event")
    if sent_to_inspection.size() == 1:
        assert_eq(str(sent_to_inspection[0].get("reason", "")), "tile_inspection", "inspection reason")


func test_inspection_player_cannot_roll_until_resolved() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    game_match.state.players[0].in_inspection = true
    game_match.rpc_roll_dice("demo_002", "alice")

    var rejected: Array[Dictionary] = _filter_events(client_a, "rpc_action_rejected")
    assert_eq(rejected.size(), 1, "roll should be rejected while player is in inspection")
    if rejected.size() == 1:
        assert_eq(str(rejected[0].get("reason", "")), "inspection_resolution_required", "inspection rejection reason")


func test_pay_inspection_fee_clears_inspection_and_allows_roll() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    game_match.state.players[0].in_inspection = true
    var pay_reason: String = game_match.rpc_pay_inspection_fee("demo_002", "alice")
    assert_eq(pay_reason, "", "pay inspection fee should succeed")
    assert_eq(game_match.state.players[0].in_inspection, false, "inspection should be cleared")
    assert_true(is_equal_approx(game_match.state.players[0].fiat_balance, 10.0), "inspection fee deducted from fiat")

    var balance_changed: Array[Dictionary] = _filter_events(client_a, "rpc_player_balance_changed")
    assert_eq(balance_changed.size(), 1, "paying inspection fee emits one balance change")
    if balance_changed.size() == 1:
        assert_true(is_equal_approx(float(balance_changed[0].get("fiat_delta", 0.0)), -10.0), "inspection fee fiat delta")
        assert_eq(str(balance_changed[0].get("reason", "")), "inspection_fee_paid", "inspection fee reason")

    game_match.rpc_roll_dice("demo_002", "alice")
    var rolls: Array[Dictionary] = _filter_events(client_a, "rpc_dice_rolled")
    assert_eq(rolls.size(), 1, "player can roll after paying inspection fee")


func test_pay_inspection_fee_rejected_when_not_in_inspection() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    var pay_reason: String = game_match.rpc_pay_inspection_fee("demo_002", "alice")
    assert_eq(pay_reason, "not_in_inspection", "cannot pay inspection fee when not in inspection")


func test_use_inspection_voucher_clears_inspection_and_allows_roll() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    game_match.state.players[0].in_inspection = true
    game_match.state.players[0].inspection_free_exits = 1
    var voucher_reason: String = game_match.rpc_use_inspection_voucher("demo_002", "alice")
    assert_eq(voucher_reason, "", "using inspection voucher should succeed")
    assert_eq(game_match.state.players[0].in_inspection, false, "inspection cleared by voucher")
    assert_eq(game_match.state.players[0].inspection_free_exits, 0, "inspection voucher consumed")

    var balance_changed: Array[Dictionary] = _filter_events(client_a, "rpc_player_balance_changed")
    assert_eq(balance_changed.size(), 1, "voucher use emits one balance event")
    if balance_changed.size() == 1:
        assert_eq(str(balance_changed[0].get("reason", "")), "inspection_voucher_used", "voucher use reason")
        assert_true(is_equal_approx(float(balance_changed[0].get("fiat_delta", 1.0)), 0.0), "voucher use has no fiat delta")
        assert_true(is_equal_approx(float(balance_changed[0].get("btc_delta", 1.0)), 0.0), "voucher use has no btc delta")

    game_match.rpc_roll_dice("demo_002", "alice")
    var rolls: Array[Dictionary] = _filter_events(client_a, "rpc_dice_rolled")
    assert_eq(rolls.size(), 1, "player can roll after using inspection voucher")


func test_use_inspection_voucher_rejected_without_vouchers() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    game_match.state.players[0].in_inspection = true
    game_match.state.players[0].inspection_free_exits = 0
    var voucher_reason: String = game_match.rpc_use_inspection_voucher("demo_002", "alice")
    assert_eq(voucher_reason, "no_inspection_voucher", "using inspection voucher requires available vouchers")


func test_roll_inspection_exit_with_doubles_clears_and_moves() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    game_match.state.players[0].in_inspection = true
    game_match.rng.seed = _find_seed_for_doubles(true)
    var reason: String = game_match.rpc_roll_inspection_exit("demo_002", "alice")
    assert_eq(reason, "", "inspection exit roll should succeed")
    assert_eq(game_match.state.players[0].in_inspection, false, "inspection cleared on doubles")

    var rolls: Array[Dictionary] = _filter_events(client_a, "rpc_dice_rolled")
    assert_eq(rolls.size(), 1, "inspection exit roll emits one dice event")
    var moved: Array[Dictionary] = _filter_events(client_a, "rpc_pawn_moved")
    assert_eq(moved.size(), 1, "doubles inspection exit moves pawn")
    var released: Array[Dictionary] = _filter_events(client_a, "rpc_player_balance_changed")
    assert_eq(released.size(), 1, "doubles inspection exit emits one release mutation event")
    if released.size() == 1:
        assert_eq(str(released[0].get("reason", "")), "inspection_exit_doubles", "release reason on doubles")


func test_roll_inspection_exit_without_doubles_advances_turn_and_stays_inspected() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    game_match.state.players[0].in_inspection = true
    game_match.rng.seed = _find_seed_for_doubles(false)
    var reason: String = game_match.rpc_roll_inspection_exit("demo_002", "alice")
    assert_eq(reason, "", "inspection exit roll should run")
    assert_eq(game_match.state.players[0].in_inspection, true, "player remains inspected when roll is not doubles")

    var rolls: Array[Dictionary] = _filter_events(client_a, "rpc_dice_rolled")
    assert_eq(rolls.size(), 1, "inspection exit roll emits one dice event")
    var moved: Array[Dictionary] = _filter_events(client_a, "rpc_pawn_moved")
    assert_eq(moved.size(), 0, "failed inspection exit does not move pawn")
    var turns: Array[Dictionary] = _filter_events(client_a, "rpc_turn_started")
    assert_eq(turns.size(), 2, "failed inspection exit advances to next player")
    if turns.size() == 2:
        assert_eq(int(turns[1].get("player_index", -1)), 1, "turn advances after failed inspection exit")


func test_snapshot_reflects_inspection_status_after_bear_inspection_card() -> void:
    var config: Config = Config.new("res://configs/demo_002.toml")
    var game_match: GameMatch = GameMatch.new(config, [])
    var client_a: MatchTestClient = MatchTestClient.new()
    var client_b: MatchTestClient = MatchTestClient.new()
    assert_eq(str(game_match.assign_client("alice", client_a).get("reason", "")), "", "first client should register")
    assert_eq(str(game_match.assign_client("bob", client_b).get("reason", "")), "", "second client should register")

    game_match.bear_card_cursor = 2
    game_match._server_move_pawn(4)

    assert_true(game_match.state.players[0].in_inspection, "current player set to inspection after bear inspection card")
    var snapshot: Dictionary = game_match.build_state_snapshot()
    var players: Array = snapshot.get("players", [])
    assert_eq(players.size(), 2, "snapshot keeps two players")
    if players.size() == 2:
        var player_0: Dictionary = players[0]
        assert_true(bool(player_0.get("in_inspection", false)), "snapshot includes inspection=true for player 0")
    var sent_to_inspection: Array[Dictionary] = _filter_events(client_a, "rpc_player_sent_to_inspection")
    assert_eq(sent_to_inspection.size(), 1, "inspection mutation event emitted")
    if sent_to_inspection.size() == 1:
        assert_eq(str(sent_to_inspection[0].get("reason", "")), "bear_legal_inspection", "reason is inspection card id")


func _filter_events(client: MatchTestClient, method: String) -> Array[Dictionary]:
    var results: Array[Dictionary] = []
    for event in client.events:
        if str(event.get("method", "")) == method:
            results.append(event)
    return results


func _find_seed_for_doubles(expect_doubles: bool) -> int:
    var probe_rng: RandomNumberGenerator = RandomNumberGenerator.new()
    for seed_value in range(1, 100000):
        probe_rng.seed = seed_value
        var die_1: int = probe_rng.randi_range(1, 6)
        var die_2: int = probe_rng.randi_range(1, 6)
        var is_doubles: bool = die_1 == die_2
        if is_doubles == expect_doubles:
            return seed_value
    assert(false)
    return 1
