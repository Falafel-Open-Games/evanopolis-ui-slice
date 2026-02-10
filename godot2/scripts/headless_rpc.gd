class_name HeadlessRpc
extends Node

@rpc("any_peer")
func rpc_join(game_id: String, player_id: String) -> void:
    _handle_join(game_id, player_id)


@rpc("any_peer")
func rpc_roll_dice(game_id: String, player_id: String) -> void:
    _handle_roll_dice(game_id, player_id)


@rpc("authority")
func rpc_game_started(seq: int, new_game_id: String) -> void:
    _handle_game_started(seq, new_game_id)


@rpc("authority")
func rpc_join_accepted(seq: int, player_id: String, player_index: int, last_seq: int) -> void:
    _handle_join_accepted(seq, player_id, player_index, last_seq)


@rpc("authority")
func rpc_turn_started(seq: int, player_index: int, turn_number: int, cycle: int) -> void:
    _handle_turn_started(seq, player_index, turn_number, cycle)


@rpc("authority")
func rpc_player_joined(seq: int, player_id: String, player_index: int) -> void:
    _handle_player_joined(seq, player_id, player_index)


@rpc("authority")
func rpc_dice_rolled(seq: int, die_1: int, die_2: int, total: int) -> void:
    _handle_dice_rolled(seq, die_1, die_2, total)


@rpc("authority")
func rpc_pawn_moved(seq: int, from_tile: int, to_tile: int, passed_tiles: Array[int]) -> void:
    _handle_pawn_moved(seq, from_tile, to_tile, passed_tiles)


@rpc("authority")
func rpc_tile_landed(seq: int, tile_index: int) -> void:
    _handle_tile_landed(seq, tile_index)


@rpc("authority")
func rpc_cycle_started(seq: int, cycle: int, inflation_active: bool) -> void:
    _handle_cycle_started(seq, cycle, inflation_active)


@rpc("authority")
func rpc_action_rejected(seq: int, reason: String) -> void:
    _handle_action_rejected(seq, reason)


func _handle_join(game_id: String, player_id: String) -> void:
    pass


func _handle_roll_dice(game_id: String, player_id: String) -> void:
    pass


func _handle_game_started(seq: int, new_game_id: String) -> void:
    pass


func _handle_join_accepted(seq: int, player_id: String, player_index: int, last_seq: int) -> void:
    pass


func _handle_turn_started(seq: int, player_index: int, turn_number: int, cycle: int) -> void:
    pass


func _handle_player_joined(seq: int, player_id: String, player_index: int) -> void:
    pass


func _handle_dice_rolled(seq: int, die_1: int, die_2: int, total: int) -> void:
    pass


func _handle_pawn_moved(seq: int, from_tile: int, to_tile: int, passed_tiles: Array[int]) -> void:
    pass


func _handle_tile_landed(seq: int, tile_index: int) -> void:
    pass


func _handle_cycle_started(seq: int, cycle: int, inflation_active: bool) -> void:
    pass


func _handle_action_rejected(seq: int, reason: String) -> void:
    pass
