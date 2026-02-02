@abstract
class_name Client
extends RefCounted

@abstract func rpc_game_started(new_game_id: String) -> void


@abstract func rpc_turn_started(player_index: int, turn_number: int, cycle: int) -> void


@abstract func rpc_dice_rolled(die_1: int, die_2: int, total: int) -> void


@abstract func rpc_pawn_moved(from_tile: int, to_tile: int, passed_tiles: Array[int]) -> void


@abstract func rpc_tile_landed(tile_index: int) -> void


@abstract func rpc_cycle_started(cycle: int, inflation_active: bool) -> void


@abstract func rpc_action_rejected(reason: String) -> void
