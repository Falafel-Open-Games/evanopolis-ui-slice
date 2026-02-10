class_name GameMatch
extends RefCounted

const GameState = preload("res://scripts/state/game_state.gd")
const PlayerState = preload("res://scripts/state/player_state.gd")
const Client = preload("res://scripts/client.gd")
const Config = preload("res://scripts/config.gd")

var config: Config
var clients: Array[Client]
var rng: RandomNumberGenerator
var state: GameState
var has_started: bool = false
var player_ids: Array[String]
var next_event_seq: int = 1


func _init(config_node: Config, client_nodes: Array[Client]) -> void:
    config = config_node
    assert(config)
    clients = []
    clients.resize(config.player_count)
    player_ids = []
    player_ids.resize(config.player_count)
    assert(client_nodes.size() <= clients.size())
    for index in range(client_nodes.size()):
        clients[index] = client_nodes[index]
    rng = RandomNumberGenerator.new()
    state = GameState.new(config)
    rng.seed = state.game_id.hash()


func start_game() -> void:
    if has_started:
        return
    has_started = true
    _broadcast("rpc_game_started", [state.game_id])
    _broadcast("rpc_turn_started", [state.current_player_index, state.turn_number, state.current_cycle])


func register_client_at_index(player_id: String, player_index: int, client: Client) -> String:
    if player_id.is_empty():
        return "invalid_player_id"
    if player_index < 0 or player_index >= clients.size():
        return "invalid_player_index"
    if clients[player_index] != null:
        return "player_slot_taken"
    if _player_index_from_id(player_id) >= 0:
        return "player_id_taken"
    clients[player_index] = client
    player_ids[player_index] = player_id
    if _has_all_clients():
        start_game()
    return ""


func assign_client(player_id: String, client: Client) -> Dictionary:
    if player_id.is_empty():
        return { "reason": "invalid_player_id", "player_index": -1 }
    if _player_index_from_id(player_id) >= 0:
        return { "reason": "player_id_taken", "player_index": -1 }
    var empty_index: int = _first_empty_slot()
    if empty_index < 0:
        return { "reason": "match_full", "player_index": -1 }
    var reason: String = register_client_at_index(player_id, empty_index, client)
    return { "reason": reason, "player_index": empty_index }


func _has_all_clients() -> bool:
    for client in clients:
        if client == null:
            return false
    return true


func _player_index_from_id(player_id: String) -> int:
    for index in range(player_ids.size()):
        if player_ids[index] == player_id:
            return index
    return -1


func _first_empty_slot() -> int:
    for index in range(clients.size()):
        if clients[index] == null:
            return index
    return -1


func rpc_roll_dice(game_id: String, player_id: String) -> void:
    if not has_started:
        _send_to_player(_player_index_from_id(player_id), "rpc_action_rejected", ["match_not_started"])
        return
    if game_id != state.game_id:
        _send_to_player(_player_index_from_id(player_id), "rpc_action_rejected", ["invalid_game_id"])
        return
    var resolved_index: int = _player_index_from_id(player_id)
    if resolved_index < 0:
        return
    if resolved_index != state.current_player_index:
        _send_to_player(resolved_index, "rpc_action_rejected", ["not_current_player"])
        return
    var die_1: int = rng.randi_range(1, 6)
    var die_2: int = rng.randi_range(1, 6)
    var total: int = die_1 + die_2
    _broadcast("rpc_dice_rolled", [die_1, die_2, total])
    _server_move_pawn(total)


func _server_move_pawn(steps: int) -> void:
    var board_size: int = config.board_size
    var player: PlayerState = state.players[state.current_player_index]
    var from_tile: int = player.position
    var to_tile: int = (from_tile + steps) % board_size
    var passed_tiles: Array[int] = _compute_passed_tiles_with_effects(from_tile, steps, board_size)
    player.position = to_tile
    _broadcast("rpc_pawn_moved", [from_tile, to_tile, passed_tiles])
    _broadcast("rpc_tile_landed", [to_tile])


func _compute_passed_tiles_with_effects(from_tile: int, steps: int, board_size: int) -> Array[int]:
    var results: Array[int] = []
    if steps <= 0:
        return results
    var passes_start: bool = from_tile + steps >= board_size
    if passes_start:
        results.append(0)
        var player: PlayerState = state.players[state.current_player_index]
        player.laps += 1
        var next_cycle: int = player.laps + 1
        if next_cycle > state.current_cycle:
            state.current_cycle = next_cycle
            _broadcast("rpc_cycle_started", [state.current_cycle, _is_inflation_cycle(state.current_cycle)])
    return results


func _is_inflation_cycle(cycle: int) -> bool:
    return cycle % 2 == 0


func next_sequence() -> int:
    var seq: int = next_event_seq
    next_event_seq += 1
    return seq


func _broadcast(method: String, args: Array) -> void:
    assert(method != "rpc_action_rejected")
    assert(method != "rpc_join_accepted")
    var seq: int = next_sequence()
    print("server: emit=%s seq=%d args=%s" % [method, seq, args])
    var payload: Array = [seq]
    payload.append_array(args)
    for client in clients:
        if client == null:
            continue
        client.callv(method, payload)


func _send_to_player(player_index: int, method: String, args: Array) -> void:
    if player_index < 0 or player_index >= clients.size():
        return
    var client: Client = clients[player_index]
    if client == null:
        return
    var payload: Array = [0]
    payload.append_array(args)
    client.callv(method, payload)
