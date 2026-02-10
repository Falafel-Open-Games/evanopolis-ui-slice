extends GutTest

const Config = preload("res://scripts/config.gd")
const GameMatch = preload("res://scripts/match.gd")
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
    var match: GameMatch = GameMatch.new(config, [])
    var client_a: TestClient = TestClient.new()
    var client_b: TestClient = TestClient.new()

    var result_a: Dictionary = match.assign_client("alice", client_a)
    assert_eq(str(result_a.get("reason", "")), "", "first client should register")
    assert_eq(client_a.events.size(), 0, "no events until all players join")

    var result_b: Dictionary = match.assign_client("bob", client_b)
    assert_eq(str(result_b.get("reason", "")), "", "second client should register")

    _assert_game_start_events(client_a, config.game_id)
    _assert_game_start_events(client_b, config.game_id)


func _assert_game_start_events(client: TestClient, game_id: String) -> void:
    assert_eq(client.events.size(), 2, "expected two startup events")
    var first: Dictionary = client.events[0]
    assert_eq(str(first.get("method", "")), "rpc_game_started", "first event is game started")
    assert_eq(int(first.get("seq", -1)), 1, "game started seq")
    assert_eq(str(first.get("game_id", "")), game_id, "game id propagated")
    var second: Dictionary = client.events[1]
    assert_eq(str(second.get("method", "")), "rpc_turn_started", "second event is turn started")
    assert_eq(int(second.get("seq", -1)), 2, "turn started seq")
    assert_eq(int(second.get("player_index", -1)), 0, "first turn player index")
    assert_eq(int(second.get("turn_number", -1)), 1, "turn number")
    assert_eq(int(second.get("cycle", -1)), 1, "cycle number")
