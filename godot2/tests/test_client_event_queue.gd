extends GutTest

const ClientMain = preload("res://scripts/client_main.gd")


func test_late_join_flushes_pending_game_start() -> void:
    var client: ClientMain = ClientMain.new()
    client.player_id = "p2"
    client.game_id = "pending"

    client._handle_game_started(3, "demo_002")
    client._handle_turn_started(4, 0, 1, 1)

    assert_eq(client.pending_events.size(), 2, "events queue before join acceptance")

    client._handle_join_accepted(0, "p2", 1, 4)

    assert_eq(client.pending_events.size(), 0, "pending events flushed after join accepted")
    assert_eq(client.game_id, "demo_002", "game id updated from queued game started")
    assert_eq(client.current_player_index, 0, "turn started applied from queued event")
    assert_eq(client.pending_game_started, false, "no pending game started after flush")

    client.free()


func test_tile_landed_uses_board_state_details() -> void:
    var client: ClientMain = ClientMain.new()
    client.player_index = 0
    var board: Dictionary = {
        "size": 24,
        "tiles": [
            {
                "index": 0,
                "tile_type": "start",
                "city": "",
                "incident_kind": "",
                "owner_index": -1,
                "miner_batches": 0,
            },
            {
                "index": 1,
                "tile_type": "property",
                "city": "caracas",
                "incident_kind": "",
                "owner_index": -1,
                "miner_batches": 0,
            },
        ],
    }

    client._apply_board_state(board)
    client._apply_tile_landed(1, "property", "caracas", -1, 0.0, "buy_or_end_turn")
    var tile_info: Dictionary = client._tile_info_from_index(1)

    assert_eq(int(client.board_state.get("size", 0)), 24, "board state should be applied")
    assert_eq(client.board_state.get("tiles", []).size(), 2, "board tiles should be available for lookup")
    assert_eq(str(tile_info.get("tile_type", "")), "property", "tile type should resolve from board state")
    assert_eq(str(tile_info.get("city", "")), "caracas", "city should resolve from board state")

    client.free()
