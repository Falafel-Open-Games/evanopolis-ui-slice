@abstract
class_name Client
extends RefCounted

@abstract func rpc_game_started(seq: int, new_game_id: String) -> void


@abstract func rpc_board_state(seq: int, board: Dictionary) -> void


@abstract func rpc_turn_started(seq: int, player_index: int, turn_number: int, cycle: int) -> void


@abstract func rpc_player_joined(seq: int, player_id: String, player_index: int) -> void


@abstract func rpc_dice_rolled(seq: int, die_1: int, die_2: int, total: int) -> void


@abstract func rpc_pawn_moved(seq: int, from_tile: int, to_tile: int, passed_tiles: Array[int]) -> void


@abstract func rpc_tile_landed(
    seq: int,
    tile_index: int,
    tile_type: String,
    city: String,
    owner_index: int,
    toll_due: float,
    action_required: String,
) -> void


@abstract func rpc_cycle_started(seq: int, cycle: int, inflation_active: bool) -> void


@abstract func rpc_action_rejected(seq: int, reason: String) -> void
