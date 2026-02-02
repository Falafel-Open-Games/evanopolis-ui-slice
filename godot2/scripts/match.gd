class_name GameMatch
extends RefCounted

const GameState = preload("res://scripts/state/game_state.gd")
const PlayerState = preload("res://scripts/state/player_state.gd")
const Client = preload("res://scripts/client.gd")

var config: Config
var clients: Array[Client]
var rng: RandomNumberGenerator
var state: GameState


func _init(config_node: Config, client_nodes: Array[Client]) -> void:
    config = config_node
    clients = client_nodes
    assert(config)
    assert(not clients.is_empty())
    rng = RandomNumberGenerator.new()
    state = GameState.new(config)
    rng.seed = state.game_id.hash()


func start_game() -> void:
    _broadcast("rpc_game_started", [state.game_id])
    _send_to_player(state.current_player_index, "rpc_turn_started", [state.current_player_index, state.turn_number, state.current_cycle])


func rpc_roll_dice(game_id: String, player_index: int) -> void:
    if game_id != state.game_id:
        _send_to_player(player_index, "rpc_action_rejected", ["invalid_game_id"])
        return
    if player_index != state.current_player_index:
        _send_to_player(player_index, "rpc_action_rejected", ["not_current_player"])
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


func _broadcast(method: String, args: Array) -> void:
    for client in clients:
        client.callv(method, args)


func _send_to_player(player_index: int, method: String, args: Array) -> void:
    if player_index < 0 or player_index >= clients.size():
        return
    var client: Client = clients[player_index]
    if client == null:
        return
    client.callv(method, args)
