extends GutTest

const ClientMain = preload("res://scripts/client_main.gd")


class ClientMainDouble:
    extends "res://scripts/client_main.gd"

    var server_calls: Array[Dictionary] = []
    var next_buy_choice: bool = false
    var turn_prompt_count: int = 0
    var buy_prompt_count: int = 0


    func _rpc_to_server(method: String, args: Array = []) -> void:
        server_calls.append(
            {
                "method": method,
                "args": args,
            },
        )


    func _start_turn_prompt() -> void:
        turn_prompt_count += 1


    func _start_buy_or_end_turn_prompt(tile_index: int, city: String) -> void:
        buy_prompt_count += 1
        if next_buy_choice:
            _request_buy_property(tile_index)
            return
        _request_end_turn()


    func _wait_for_buy_choice() -> bool:
        return next_buy_choice


func test_join_requests_snapshot_sync_and_drops_pre_sync_events() -> void:
    var client: ClientMainDouble = ClientMainDouble.new()
    client.player_id = "p2"
    client.game_id = "pending"

    client._handle_game_started(3, "demo_002")
    client._handle_turn_started(4, 0, 1, 1)

    assert_eq(client.pending_events.size(), 2, "events queue before join acceptance")

    client._handle_join_accepted(0, "p2", 1, 4)
    assert_eq(client.sync_in_progress, true, "join accepted enters sync mode")
    assert_eq(client.server_calls.size(), 1, "client requests sync after join acceptance")
    assert_eq(str(client.server_calls[0].get("method", "")), "rpc_sync_request", "sync request rpc emitted")

    client._handle_state_snapshot(
        0,
        {
            "game_id": "demo_002",
            "turn_number": 2,
            "current_player_index": 1,
            "current_cycle": 1,
            "board_state": {
                "size": 24,
                "tiles": [],
            },
            "players": [],
        },
    )
    client._handle_sync_complete(0, 4)

    assert_eq(client.pending_events.size(), 0, "stale queued events dropped after snapshot sync")
    assert_eq(client.game_id, "demo_002", "game id updated from snapshot")
    assert_eq(client.current_player_index, 1, "current player updated from snapshot")
    assert_eq(client.next_expected_seq, 5, "next sequence advanced to sync final seq")
    assert_eq(client.sync_in_progress, false, "sync mode exits after sync complete")
    assert_eq(client.pending_game_started, false, "no pending game started after flush")

    client.free()


func test_sync_complete_flushes_live_events_queued_during_sync() -> void:
    var client: ClientMainDouble = ClientMainDouble.new()
    client.player_id = "p2"
    client.game_id = "demo_002"

    client._handle_join_accepted(0, "p2", 1, 0)
    assert_eq(client.sync_in_progress, true, "sync mode started")

    client._handle_turn_started(5, 0, 2, 1)
    assert_eq(client.pending_events.size(), 1, "live event queued while sync is in progress")

    client._handle_state_snapshot(
        0,
        {
            "game_id": "demo_002",
            "turn_number": 2,
            "current_player_index": 1,
            "current_cycle": 1,
            "board_state": {
                "size": 24,
                "tiles": [],
            },
            "players": [],
        },
    )
    client._handle_sync_complete(0, 4)

    assert_eq(client.pending_events.size(), 0, "queued live events flushed after sync")
    assert_eq(client.current_player_index, 0, "queued turn event applied after sync complete")
    assert_eq(client.next_expected_seq, 6, "next sequence moved past flushed event")
    assert_eq(client.sync_in_progress, false, "sync mode exited")

    client.free()


func test_queue_event_ignores_sequences_older_than_next_expected() -> void:
    var client: ClientMain = ClientMain.new()
    client.player_index = 0
    client.next_expected_seq = 6

    client._handle_turn_started(5, 1, 3, 1)

    assert_eq(client.pending_events.size(), 0, "stale event is ignored")
    assert_eq(client.current_player_index, 0, "stale event is not applied")

    client.free()


func test_state_snapshot_logs_with_players_present() -> void:
    var client: ClientMain = ClientMain.new()

    client._apply_state_snapshot(
        {
            "game_id": "demo_002",
            "turn_number": 3,
            "current_player_index": 1,
            "current_cycle": 2,
            "has_started": true,
            "board_state": {
                "size": 24,
                "tiles": [],
            },
            "players": [
                {
                    "player_index": 0,
                    "position": 6,
                    "laps": 0,
                    "fiat_balance": 1000000.0,
                    "bitcoin_balance": 0.5,
                    "in_inspection": false,
                },
                {
                    "player_index": 1,
                    "position": 3,
                    "laps": 1,
                    "fiat_balance": 950000.0,
                    "bitcoin_balance": 0.25,
                    "in_inspection": true,
                },
            ],
        },
    )

    assert_eq(client.game_id, "demo_002", "snapshot applies game id")
    assert_eq(client.current_player_index, 1, "snapshot applies current player")
    assert_eq(int(client.board_state.get("size", 0)), 24, "snapshot applies board state")

    client.free()


func test_tile_landed_uses_board_state_details() -> void:
    var client: ClientMainDouble = ClientMainDouble.new()
    client.player_index = 0
    client.current_player_index = 1
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


func test_tile_landed_buy_prompt_submits_buy_property() -> void:
    var client: ClientMainDouble = ClientMainDouble.new()
    client.player_index = 0
    client.current_player_index = 0
    client.next_buy_choice = true

    client._apply_tile_landed(6, "property", "assuncion", -1, 0.0, "buy_or_end_turn")

    assert_eq(client.server_calls.size(), 1, "buy prompt sends one rpc")
    assert_eq(str(client.server_calls[0].get("method", "")), "rpc_buy_property", "buy path sends buy_property rpc")
    var args: Array = client.server_calls[0].get("args", [])
    assert_eq(int(args[2]), 6, "tile index is forwarded for buy")
    client.free()


func test_tile_landed_buy_prompt_submits_end_turn() -> void:
    var client: ClientMainDouble = ClientMainDouble.new()
    client.player_index = 0
    client.current_player_index = 0
    client.next_buy_choice = false

    client._apply_tile_landed(6, "property", "assuncion", -1, 0.0, "buy_or_end_turn")

    assert_eq(client.server_calls.size(), 1, "decline buy sends one rpc")
    assert_eq(str(client.server_calls[0].get("method", "")), "rpc_end_turn", "decline path sends end_turn rpc")
    client.free()


func test_sync_complete_prompts_roll_when_snapshot_has_current_player_turn() -> void:
    var client: ClientMainDouble = ClientMainDouble.new()
    client.player_id = "p2"
    client.game_id = "demo_002"

    client._handle_join_accepted(0, "p2", 1, 4)
    client._handle_state_snapshot(
        0,
        {
            "game_id": "demo_002",
            "turn_number": 3,
            "current_player_index": 1,
            "current_cycle": 1,
            "pending_action": { },
            "board_state": {
                "size": 24,
                "tiles": [],
            },
            "players": [],
        },
    )
    client._handle_sync_complete(0, 4)

    assert_eq(client.turn_prompt_count, 1, "sync resume prompts roll for current player")
    assert_eq(client.buy_prompt_count, 0, "no buy prompt when there is no pending action")
    client.free()


func test_sync_complete_resumes_buy_prompt_from_snapshot_pending_action() -> void:
    var client: ClientMainDouble = ClientMainDouble.new()
    client.player_id = "p2"
    client.game_id = "demo_002"

    client._handle_join_accepted(0, "p2", 1, 4)
    client._handle_state_snapshot(
        0,
        {
            "game_id": "demo_002",
            "turn_number": 3,
            "current_player_index": 1,
            "current_cycle": 1,
            "pending_action": {
                "type": "buy_or_end_turn",
                "tile_index": 6,
            },
            "board_state": {
                "size": 24,
                "tiles": [
                    {
                        "index": 6,
                        "city": "assuncion",
                    },
                ],
            },
            "players": [],
        },
    )
    client._handle_sync_complete(0, 4)

    assert_eq(client.turn_prompt_count, 0, "buy pending action does not prompt roll")
    assert_eq(client.buy_prompt_count, 1, "buy pending action prompts buy or end turn")
    client.free()
