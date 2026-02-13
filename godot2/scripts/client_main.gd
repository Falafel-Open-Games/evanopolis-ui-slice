extends "res://scripts/headless_rpc.gd"

const DEFAULT_HOST: String = "127.0.0.1"
const DEFAULT_PORT: int = 9010

var host: String = DEFAULT_HOST
var port: int = DEFAULT_PORT
var game_id: String = ""
var player_id: String = ""
var auth_token: String = ""
var player_index: int = -1
var current_player_index: int = 0
var board_state: Dictionary = { }
var pending_game_started: bool = false
var next_expected_seq: int = 1
var pending_events: Dictionary = { }
var sync_in_progress: bool = false


func _ready() -> void:
    var args: PackedStringArray = OS.get_cmdline_args()
    _parse_args(args)
    assert(not game_id.is_empty())
    assert(not auth_token.is_empty())
    _connect_to_server()


func _parse_args(args: PackedStringArray) -> void:
    var index: int = 0
    while index < args.size():
        var arg: String = args[index]
        if arg == "--host" and index + 1 < args.size():
            host = args[index + 1]
            index += 2
            continue
        if arg == "--port" and index + 1 < args.size():
            port = int(args[index + 1])
            index += 2
            continue
        if arg == "--game-id" and index + 1 < args.size():
            game_id = args[index + 1]
            index += 2
            continue
        if arg == "--auth-token" and index + 1 < args.size():
            auth_token = args[index + 1]
            index += 2
            continue
        if arg == "--player-id":
            _log_note("--player-id is no longer supported; player_id is derived from JWT sub")
            get_tree().quit(1)
            return
        index += 1


func _connect_to_server() -> void:
    var peer: WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
    var result: int = peer.create_client("ws://%s:%d" % [host, port])
    assert(result == OK)
    multiplayer.multiplayer_peer = peer
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)
    print("client: connecting to %s:%d" % [host, port])


func _on_connected_to_server() -> void:
    print("client: connected")
    _rpc_to_server("rpc_auth", [auth_token])


func _on_connection_failed() -> void:
    print("client: connection failed")


func _on_server_disconnected() -> void:
    print("client: server disconnected")
    get_tree().quit(1)


func _handle_game_started(seq: int, new_game_id: String) -> void:
    _queue_event(seq, "_apply_game_started", [new_game_id])


func _handle_board_state(seq: int, board: Dictionary) -> void:
    _queue_event(seq, "_apply_board_state", [board])


func _handle_auth_ok(authorized_player_id: String, exp: int) -> void:
    _apply_auth_ok(authorized_player_id, exp)


func _handle_auth_error(reason: String) -> void:
    _apply_auth_error(reason)


func _handle_join_accepted(seq: int, accepted_player_id: String, assigned_player_index: int, last_seq: int) -> void:
    _queue_event(seq, "_apply_join_accepted", [accepted_player_id, assigned_player_index, last_seq])


func _handle_turn_started(seq: int, player_index_value: int, turn_number: int, cycle: int) -> void:
    _queue_event(seq, "_apply_turn_started", [player_index_value, turn_number, cycle])


func _handle_player_joined(seq: int, player_id_value: String, player_index_value: int) -> void:
    _queue_event(seq, "_apply_player_joined", [player_id_value, player_index_value])


func _handle_dice_rolled(seq: int, die_1: int, die_2: int, total: int) -> void:
    _queue_event(seq, "_apply_dice_rolled", [die_1, die_2, total])


func _handle_pawn_moved(seq: int, from_tile: int, to_tile: int, passed_tiles: Array[int]) -> void:
    _queue_event(seq, "_apply_pawn_moved", [from_tile, to_tile, passed_tiles])


func _handle_tile_landed(
        seq: int,
        tile_index: int,
        tile_type: String,
        city: String,
        owner_index: int,
        toll_due: float,
        action_required: String,
) -> void:
    _queue_event(seq, "_apply_tile_landed", [tile_index, tile_type, city, owner_index, toll_due, action_required])


func _handle_cycle_started(seq: int, cycle: int, inflation_active: bool) -> void:
    _queue_event(seq, "_apply_cycle_started", [cycle, inflation_active])


func _handle_state_snapshot(seq: int, snapshot: Dictionary) -> void:
    _queue_event(seq, "_apply_state_snapshot", [snapshot])


func _handle_sync_complete(seq: int, final_seq: int) -> void:
    _queue_event(seq, "_apply_sync_complete", [final_seq])


func _handle_action_rejected(seq: int, reason: String) -> void:
    _queue_event(seq, "_apply_action_rejected", [reason])


func _queue_event(seq: int, method: String, args: Array) -> void:
    if seq <= 0:
        callv(method, args)
        return
    if seq < next_expected_seq:
        return
    pending_events[seq] = { "method": method, "args": args }
    if player_index < 0:
        return
    if sync_in_progress:
        return
    _flush_events()


func _flush_events() -> void:
    while pending_events.has(next_expected_seq):
        var entry: Dictionary = pending_events[next_expected_seq]
        pending_events.erase(next_expected_seq)
        callv(str(entry.get("method", "")), entry.get("args", []))
        next_expected_seq += 1


func _apply_game_started(new_game_id: String) -> void:
    game_id = new_game_id
    if player_index < 0:
        pending_game_started = true
        return
    _log_server("game started: game_id=%s" % game_id)


func _apply_board_state(board: Dictionary) -> void:
    board_state = board
    var size: int = int(board_state.get("size", 0))
    _log_server("board state: size=%d" % size)


func _apply_auth_ok(authorized_player_id: String, exp: int) -> void:
    if player_id.is_empty():
        player_id = authorized_player_id
    if player_id != authorized_player_id:
        _log_note("auth mismatch: expected %s got %s" % [player_id, authorized_player_id])
        multiplayer.multiplayer_peer.close()
        return
    _log_server("auth ok: player_id=%s exp=%d" % [player_id, exp])
    _rpc_to_server("rpc_join", [game_id, player_id])


func _apply_auth_error(reason: String) -> void:
    _log_note("auth error: reason=%s" % reason)
    multiplayer.multiplayer_peer.close()


func _apply_join_accepted(accepted_player_id: String, assigned_player_index: int, last_seq: int) -> void:
    if accepted_player_id != player_id:
        return
    player_index = assigned_player_index
    _log_server("join accepted: player_id=%s player_index=%d" % [player_id, player_index])
    sync_in_progress = true
    var last_applied_seq: int = next_expected_seq - 1
    _rpc_to_server("rpc_sync_request", [game_id, player_id, last_applied_seq])


func _apply_turn_started(player_index_value: int, turn_number: int, cycle: int) -> void:
    current_player_index = player_index_value
    _log_server("turn started: player=%d, turn=%d, cycle=%d" % [player_index_value, turn_number, cycle])
    if player_index_value != player_index:
        return
    await _start_turn_prompt()


func _apply_player_joined(player_id_value: String, player_index_value: int) -> void:
    _log_server("player joined: player_id=%s player_index=%d" % [player_id_value, player_index_value])


func _apply_dice_rolled(die_1: int, die_2: int, total: int) -> void:
    _log_server("dice rolled: player=%d, die1=%d, die2=%d, total=%d" % [current_player_index, die_1, die_2, total])


func _apply_pawn_moved(from_tile: int, to_tile: int, passed_tiles: Array[int]) -> void:
    _log_server("pawn moved: from=%d, to=%d, passed_tiles=%s" % [from_tile, to_tile, passed_tiles])


func _apply_tile_landed(
        tile_index: int,
        tile_type: String,
        city: String,
        owner_index: int,
        toll_due: float,
        action_required: String,
) -> void:
    if city.is_empty():
        _log_server(
            "tile landed: index=%d, tile_type=%s, owner_index=%d, toll_due=%.2f, action_required=%s" % [
                tile_index,
                tile_type,
                owner_index,
                toll_due,
                action_required,
            ],
        )
        return
    _log_server(
        "tile landed: index=%d, tile_type=%s, city=%s, owner_index=%d, toll_due=%.2f, action_required=%s" % [
            tile_index,
            tile_type,
            city,
            owner_index,
            toll_due,
            action_required,
        ],
    )


func _tile_info_from_index(tile_index: int) -> Dictionary:
    var tiles: Array = board_state.get("tiles", [])
    for tile_variant in tiles:
        var tile: Dictionary = tile_variant
        if int(tile.get("index", -1)) == tile_index:
            return tile
    return { }


func _apply_cycle_started(cycle: int, inflation_active: bool) -> void:
    _log_server("cycle started: cycle=%d, inflation_active=%s" % [cycle, inflation_active])


func _apply_state_snapshot(snapshot: Dictionary) -> void:
    game_id = str(snapshot.get("game_id", game_id))
    current_player_index = int(snapshot.get("current_player_index", current_player_index))
    board_state = snapshot.get("board_state", { })
    pending_game_started = false
    var turn_number: int = int(snapshot.get("turn_number", 0))
    var cycle: int = int(snapshot.get("current_cycle", 0))
    var has_started: bool = bool(snapshot.get("has_started", false))
    var board_size: int = int(board_state.get("size", 0))
    var players: Array = snapshot.get("players", [])
    _log_server(
        "state snapshot: game_id=%s turn=%d cycle=%d current_player=%d players=%d board_size=%d started=%s"
        % [game_id, turn_number, cycle, current_player_index, players.size(), board_size, has_started],
    )
    var player_summaries: Array[String] = []
    for player_variant in players:
        var player: Dictionary = player_variant
        player_summaries.append(
            "p%d(pos=%d laps=%d fiat=%.2f btc=%.8f inspection=%s)" % [
                int(player.get("player_index", -1)),
                int(player.get("position", -1)),
                int(player.get("laps", 0)),
                float(player.get("fiat_balance", 0.0)),
                float(player.get("bitcoin_balance", 0.0)),
                bool(player.get("in_inspection", false)),
            ],
        )
    if not player_summaries.is_empty():
        _log_server("state snapshot players: %s" % [", ".join(player_summaries)])


func _apply_sync_complete(final_seq: int) -> void:
    var queued_before: int = pending_events.size()
    var dropped_count: int = _drop_stale_pending_events(final_seq)
    var queued_after_drop: int = pending_events.size()
    next_expected_seq = final_seq + 1
    sync_in_progress = false
    _flush_events()
    _log_server(
        "sync complete: final_seq=%d next_expected_seq=%d dropped_events=%d queued_before=%d queued_after_drop=%d"
        % [final_seq, next_expected_seq, dropped_count, queued_before, queued_after_drop],
    )


func _apply_action_rejected(reason: String) -> void:
    _log_server("action rejected: reason=%s" % reason)


func _start_turn_prompt() -> void:
    _log_prompt("press enter to roll dice")
    await _wait_for_enter()
    _request_roll()


func _request_roll() -> void:
    _log_client("roll dice: game_id=%s, player_id=%s" % [game_id, player_id])
    _rpc_to_server("rpc_roll_dice", [game_id, player_id])


func _rpc_to_server(method: String, args: Array = []) -> void:
    var payload: Array = [1, method]
    payload.append_array(args)
    Callable(self, "rpc_id").callv(payload)


func _drop_stale_pending_events(final_seq: int) -> int:
    var stale_keys: Array = []
    for seq_key in pending_events.keys():
        var seq_value: int = int(seq_key)
        if seq_value <= final_seq:
            stale_keys.append(seq_key)
    for key in stale_keys:
        pending_events.erase(key)
    return stale_keys.size()


func _wait_for_enter() -> void:
    if OS.has_method("read_string_from_stdin"):
        OS.read_string_from_stdin()
        return
    _log_note("stdin not available; continuing")


func _log_server(message: String) -> void:
    print("server[p=%d id=%s g=%s]: %s" % [player_index, player_id, game_id, message])


func _log_client(message: String) -> void:
    print("client[p=%d id=%s g=%s]: %s" % [player_index, player_id, game_id, message])


func _log_prompt(message: String) -> void:
    print("prompt[p=%d id=%s g=%s]: %s" % [player_index, player_id, game_id, message])


func _log_note(message: String) -> void:
    print("note[p=%d id=%s g=%s]: %s" % [player_index, player_id, game_id, message])
