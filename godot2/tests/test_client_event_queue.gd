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
